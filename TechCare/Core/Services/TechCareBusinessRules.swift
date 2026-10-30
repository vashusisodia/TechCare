import Foundation

// MARK: - Section 14: Booking, Quotation & Payment Business Rules & State Machine

enum TechCareBusinessError: LocalizedError, Equatable {
    case invalidAppointmentDate
    case missingRequiredFields(String)
    case privacyChecklistIncomplete
    case noTechnicianAssigned
    case technicianScheduleConflict
    case quoteNotApprovedYet
    case unapprovedPriceIncrease
    case repairNotConfirmedByCustomer
    case paymentAlreadyProcessed
    case reviewNotAllowedBeforeCompletion
    case warrantyExpiredOrInvalid
    case invalidStateTransition(from: BookingStatus, to: BookingStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidAppointmentDate:
            return "Appointment date cannot be in the past. Please choose a valid upcoming slot."
        case .missingRequiredFields(let field):
            return "Please complete required field: \(field)."
        case .privacyChecklistIncomplete:
            return "Please confirm the mandatory Device Privacy & Safety checks before submitting."
        case .noTechnicianAssigned:
            return "A booking cannot proceed or complete without an assigned technician or workshop allocation."
        case .technicianScheduleConflict:
            return "This technician already has a confirmed booking in the selected time slot."
        case .quoteNotApprovedYet:
            return "Business Rule Violation: Repair work cannot start until the customer approves the latest quotation."
        case .unapprovedPriceIncrease:
            return "Business Rule Violation: Customer cannot be charged more than the approved quotation without a revised quote and fresh approval."
        case .repairNotConfirmedByCustomer:
            return "Customer must confirm completion (or resolve disputes) before final payment settlement."
        case .paymentAlreadyProcessed:
            return "This booking has already been paid and verified."
        case .reviewNotAllowedBeforeCompletion:
            return "Reviews can only be submitted after a booking is completed."
        case .warrantyExpiredOrInvalid:
            return "Warranty claim cannot be created because the warranty period has expired or record is invalid."
        case .invalidStateTransition(let from, let to):
            return "Invalid status transition from '\(from.rawValue)' to '\(to.rawValue)'."
        }
    }
}

struct BookingStateMachine {
    /// Validates whether a booking status transition is legal according to Section 14 rules.
    static func canTransition(
        from current: BookingStatus,
        to next: BookingStatus,
        hasAssignedTechnician: Bool,
        requiresPickupWorkshop: Bool,
        latestQuoteStatus: QuoteApprovalStatus?
    ) -> Result<Void, TechCareBusinessError> {
        if current == next { return .success(()) }
        
        // Cancellation is allowed prior to repair completion
        if next == .cancelled {
            switch current {
            case .completed, .paymentPending, .paid:
                return .failure(.invalidStateTransition(from: current, to: next))
            default:
                return .success(())
            }
        }
        
        // Dispute is allowed during quote, repair, testing, confirmation, or payment pending
        if next == .disputed {
            switch current {
            case .quotePending, .repairInProgress, .testing, .awaitingCustomerConfirmation, .completed, .paymentPending:
                return .success(())
            default:
                return .failure(.invalidStateTransition(from: current, to: next))
            }
        }
        
        // Rule 1: Cannot move past matching without an assigned technician or workshop fallback
        let requiresTechStates: [BookingStatus] = [
            .technicianAssigned, .technicianOnTheWay, .technicianArrived,
            .diagnosisInProgress, .quotePending, .quoteApproved,
            .repairInProgress, .testing, .awaitingCustomerConfirmation, .completed
        ]
        if requiresTechStates.contains(next) && !hasAssignedTechnician && !requiresPickupWorkshop {
            return .failure(.noTechnicianAssigned)
        }
        
        // Rule 2: Cannot start repair or testing unless the latest quote is explicitly approved
        if next == .repairInProgress || next == .testing || next == .awaitingCustomerConfirmation || next == .completed {
            guard latestQuoteStatus == .approved else {
                return .failure(.quoteNotApprovedYet)
            }
        }
        
        return .success(())
    }
    
    /// Calculates disclosed cancellation fee according to current booking stage (Rule 10)
    static func calculateCancellationFee(for status: BookingStatus, disclosedVisitFee: Decimal) -> Decimal {
        switch status {
        case .draft, .requested, .matchingTechnician, .technicianAssigned:
            return 0 // Free cancellation before technician dispatches
        case .technicianOnTheWay, .technicianArrived, .diagnosisInProgress, .quotePending:
            return disclosedVisitFee // Visit / inspection fee applies once en-route or diagnosed
        default:
            return disclosedVisitFee
        }
    }
    
    /// Validates payment amount against approved quote (Rule 3 & Rule 4)
    static func validatePaymentAmount(
        requestedAmount: Decimal,
        approvedQuote: RepairQuote?
    ) -> Result<Void, TechCareBusinessError> {
        guard let quote = approvedQuote, quote.approvalStatus == .approved else {
            return .failure(.quoteNotApprovedYet)
        }
        if requestedAmount > quote.totalAmountINR {
            return .failure(.unapprovedPriceIncrease)
        }
        return .success(())
    }
    
    /// Validates review eligibility (Rule 8)
    static func canSubmitReview(for status: BookingStatus) -> Result<Void, TechCareBusinessError> {
        switch status {
        case .completed, .paymentPending, .paid:
            return .success(())
        default:
            return .failure(.reviewNotAllowedBeforeCompletion)
        }
    }
}

// MARK: - Section 8.4: Smart Technician Allocation Service

struct SmartTechnicianAllocator {
    struct ScoredTechnician: Identifiable {
        let technician: Technician
        let score: Double
        let matchReasons: [String]
        var id: UUID { technician.id }
    }
    
    /// Prioritises technicians based on:
    /// 1. Compatible repair skills
    /// 2. Device & brand compatibility
    /// 3. Availability (online + no conflicting booking)
    /// 4. Service area
    /// 5. Reliability & customer ratings
    static func rankTechnicians(
        candidates: [Technician],
        category: DeviceCategory,
        brand: String,
        issue: IssueCategory,
        preferredArea: String,
        appointmentSlot: String,
        existingBookings: [Booking],
        excludedTechnicianIds: [UUID] = []
    ) -> [ScoredTechnician] {
        var results: [ScoredTechnician] = []
        
        for tech in candidates {
            if excludedTechnicianIds.contains(tech.id) { continue }
            if !tech.isAvailableOnline { continue }
            if !tech.supportedCategories.contains(category) { continue }
            
            // Rule 11: Check for conflicting active appointment in the same slot
            let hasConflict = existingBookings.contains { booking in
                booking.technicianId == tech.id &&
                booking.timeSlot == appointmentSlot &&
                !booking.status.isTerminal &&
                booking.status != .disputed
            }
            if hasConflict { continue }
            
            var score: Double = 0
            var reasons: [String] = []
            
            // 1. Compatible repair skill (+40 pts)
            let neededSkill = issue.requiredSkillTag
            if tech.skills.contains(where: { $0.localizedCaseInsensitiveContains(neededSkill) || neededSkill.localizedCaseInsensitiveContains($0) }) {
                score += 40
                reasons.append("Matched Skill: \(neededSkill)")
            } else {
                score += 15
                reasons.append("General \(category.shortName) Specialist")
            }
            
            // 2. Brand compatibility (+25 pts)
            if tech.supportedBrands.contains(where: { $0.localizedCaseInsensitiveContains(brand) || brand.localizedCaseInsensitiveContains($0) }) {
                score += 25
                reasons.append("\(brand) Experienced")
            }
            
            // 3. Service area match (+20 pts)
            if tech.serviceArea.localizedCaseInsensitiveContains(preferredArea) || preferredArea.localizedCaseInsensitiveContains(tech.serviceArea) {
                score += 20
                reasons.append("Serves \(tech.serviceArea)")
            } else {
                score += 8
            }
            
            // 4. Verification & Rating (+15 pts max)
            score += (tech.rating * 2.5)
            if tech.verificationStatus == .identityAndSkillsVerified {
                score += 5
                reasons.append("ID & Skill Tested")
            }
            
            results.append(ScoredTechnician(technician: tech, score: score, matchReasons: reasons))
        }
        
        return results.sorted { $0.score > $1.score }
    }
}

// MARK: - Section 15: Rule-Based Local AI Symptom Categorisation Assistant

struct AISymptomSuggestion: Identifiable, Hashable {
    var id: UUID = UUID()
    let detectedCategory: DeviceCategory
    let suggestedIssues: [IssueCategory]
    let relevantSkills: [String]
    let followUpQuestions: [String]
    let safetyRecommendation: String
    let requiresWorkshopHint: Bool
}

enum LocalAISymptomClassifier {
    /// Analyses natural-language symptom descriptions locally without claiming a confirmed hardware diagnosis.
    static func analyze(symptomText: String, selectedCategory: DeviceCategory?) -> AISymptomSuggestion {
        let lower = symptomText.lowercased()
        
        // Infer category if not provided
        let category: DeviceCategory = selectedCategory ?? {
            if lower.contains("laptop") || lower.contains("macbook") || lower.contains("pc") || lower.contains("windows") || lower.contains("keyboard") || lower.contains("ssd") || lower.contains("fan") {
                return .laptopDesktop
            } else if lower.contains("ipad") || lower.contains("tablet") || lower.contains("pencil") {
                return .tabletIPad
            } else if lower.contains("watch") || lower.contains("earbud") || lower.contains("airpod") || lower.contains("controller") || lower.contains("ps5") {
                return .otherGadget
            } else {
                return .mobilePhone
            }
        }()
        
        var issues: [IssueCategory] = []
        var questions: [String] = []
        var safety = "Back up important files before inspection. Do not share account passwords."
        var workshopHint = false
        
        if lower.contains("hot") || lower.contains("heat") || lower.contains("shut") || lower.contains("slow") || lower.contains("fan") || lower.contains("lag") {
            issues.append(.overheatingPerf)
            if category == .laptopDesktop {
                issues.append(.hardwareDiagnosis)
            }
            questions.append("Does the device shut down abruptly under heavy load or even when idle?")
            questions.append("Do you hear abnormal fan noise or feel heat near the charging area?")
            safety = "Stop using the device on soft surfaces (beds/cushions) and unplug the charger if the chassis feels excessively hot."
        }
        
        if lower.contains("screen") || lower.contains("display") || lower.contains("crack") || lower.contains("touch") || lower.contains("flicker") || lower.contains("line") || lower.contains("black") {
            issues.append(.brokenDisplay)
            questions.append("Is there visible glass cracking, green/pink lines, or unresponsive touch areas?")
            questions.append("Does the device still vibrate or make notification sounds when switched on?")
        }
        
        if lower.contains("battery") || lower.contains("drain") || lower.contains("swollen") || lower.contains("percent") {
            issues.append(.batteryReplacement)
            questions.append("Is the back cover or trackpad lifting slightly (a sign of battery swelling)?")
            safety = "Caution: If the battery appears swollen, avoid charging the device and await technician inspection."
        }
        
        if lower.contains("charg") || lower.contains("port") || lower.contains("power") || lower.contains("dead") || lower.contains("turn on") {
            issues.append(.chargingPort)
            questions.append("Have you tested with another known-working cable and power adapter?")
            questions.append("Does the charging connector feel loose inside the port?")
        }
        
        if lower.contains("water") || lower.contains("liquid") || lower.contains("spill") || lower.contains("motherboard") {
            issues.append(.hardwareDiagnosis)
            workshopHint = true
            questions.append("Approximately how long ago did the liquid exposure occur?")
            safety = "Do NOT attempt to plug in or power on a liquid-exposed device. Keep it powered off for board inspection."
        }
        
        if lower.contains("ram") || lower.contains("ssd") || lower.contains("storage") || lower.contains("upgrade") {
            issues.append(.ramSsdUpgrade)
            questions.append("Do you want to clone your existing operating system to the new SSD?")
        }
        
        if lower.contains("key") || lower.contains("trackpad") || lower.contains("click") {
            if category == .laptopDesktop {
                issues.append(.keyboardTrackpad)
            } else if category == .otherGadget {
                issues.append(.buttonJoystick)
            }
            questions.append("Are specific keys stuck/repeating, or is the entire input unresponsive?")
        }
        
        if lower.contains("speaker") || lower.contains("mic") || lower.contains("sound") || lower.contains("audio") || lower.contains("call") {
            issues.append(.speakerMic)
            questions.append("Does audio work normally when connected to Bluetooth headphones?")
        }
        
        if lower.contains("camera") || lower.contains("blur") || lower.contains("focus") || lower.contains("lens") {
            issues.append(.cameraIssue)
            questions.append("Does the issue affect the rear camera, front camera, or both?")
        }
        
        if issues.isEmpty {
            issues = [category.supportedIssues.first ?? .hardwareDiagnosis]
            questions = [
                "When did you first notice this problem?",
                "Did the issue start after a drop, software update, or power surge?"
            ]
        }
        
        let skills = Array(Set(issues.map { $0.requiredSkillTag }))
        
        return AISymptomSuggestion(
            detectedCategory: category,
            suggestedIssues: issues,
            relevantSkills: skills,
            followUpQuestions: questions,
            safetyRecommendation: safety,
            requiresWorkshopHint: workshopHint
        )
    }
}

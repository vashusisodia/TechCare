import Foundation
import CoreLocation

// MARK: - 1. Role & Authentication Enums

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case customer = "Customer"
    case technician = "Technician"
    case admin = "Admin (Demo)"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .customer: return "person.crop.circle.fill"
        case .technician: return "wrench.and.screwdriver.fill"
        case .admin: return "shield.lefthalf.filled"
        }
    }
}

// MARK: - 2. Device Categories & Issues

enum DeviceCategory: String, Codable, CaseIterable, Identifiable {
    case mobilePhone = "Mobile Phones"
    case laptopDesktop = "Laptops & Desktops"
    case tabletIPad = "Tablets & iPads"
    case otherGadget = "Other Gadgets"
    
    var id: String { rawValue }
    
    var shortName: String {
        switch self {
        case .mobilePhone: return "Phones"
        case .laptopDesktop: return "Laptops & PCs"
        case .tabletIPad: return "Tablets & iPads"
        case .otherGadget: return "Smart Gadgets"
        }
    }
    
    var icon: String {
        switch self {
        case .mobilePhone: return "iphone.gen3"
        case .laptopDesktop: return "laptopcomputer"
        case .tabletIPad: return "ipad.landscape"
        case .otherGadget: return "applewatch.watchface"
        }
    }
    
    var subtitle: String {
        switch self {
        case .mobilePhone: return "Display, battery, charging, camera & board"
        case .laptopDesktop: return "Thermal paste, SSD/RAM, keyboard & OS"
        case .tabletIPad: return "Touch glass, battery, charging & iPadOS"
        case .otherGadget: return "Smartwatches, earbuds, controllers & peripherals"
        }
    }
    
    var sampleBrands: [String] {
        switch self {
        case .mobilePhone:
            return ["Apple", "Samsung", "OnePlus", "Xiaomi / Redmi", "Google Pixel", "Vivo", "Nothing", "Realme"]
        case .laptopDesktop:
            return ["Apple MacBook", "Dell", "HP", "Lenovo", "ASUS", "Acer", "MSI", "Custom Desktop PC"]
        case .tabletIPad:
            return ["Apple iPad", "Samsung Galaxy Tab", "Lenovo Tab", "OnePlus Pad", "Xiaomi Pad"]
        case .otherGadget:
            return ["Apple Watch", "Sony PlayStation / DualSense", "AirPods / Wireless Earbuds", "Logitech / Keychron", "Smart Home Hub"]
        }
    }
    
    func sampleModels(for brand: String) -> [String] {
        switch (self, brand) {
        case (.mobilePhone, "Apple"):
            return ["iPhone 16 Pro", "iPhone 16", "iPhone 15 Pro Max", "iPhone 15", "iPhone 14", "iPhone 13"]
        case (.mobilePhone, "Samsung"):
            return ["Galaxy S24 Ultra", "Galaxy S24+", "Galaxy S23", "Galaxy Z Flip 5", "Galaxy A55 5G", "Galaxy M34"]
        case (.mobilePhone, "OnePlus"):
            return ["OnePlus 12", "OnePlus 12R", "OnePlus 11", "OnePlus Nord CE 4", "OnePlus Open"]
        case (.mobilePhone, "Google Pixel"):
            return ["Pixel 9 Pro", "Pixel 8a", "Pixel 8 Pro", "Pixel 7a"]
        case (.mobilePhone, _):
            return ["Flagship Pro Series", "5G Standard Edition", "Note / Max Series", "Other / Custom Model"]
        case (.laptopDesktop, "Apple MacBook"):
            return ["MacBook Air M3 (13-inch)", "MacBook Air M2", "MacBook Pro 14\" (M3 Pro)", "MacBook Pro 16\"", "MacBook Air M1"]
        case (.laptopDesktop, "Dell"):
            return ["XPS 13 / 15", "Inspiron 15 3000/5000", "Latitude 5440", "Alienware / G15 Gaming"]
        case (.laptopDesktop, "HP"):
            return ["Pavilion 15", "Spectre x360", "Victus Gaming 15", "EliteBook 840", "OMEN 16"]
        case (.laptopDesktop, "Lenovo"):
            return ["ThinkPad X1 Carbon", "IdeaPad Slim 5", "Legion 5 Pro", "Yoga 7i"]
        case (.laptopDesktop, _):
            return ["Ultrabook / Notebook", "Gaming Laptop Series", "Workstation / Desktop Tower", "All-in-One PC"]
        case (.tabletIPad, "Apple iPad"):
            return ["iPad Pro M4 (11\")", "iPad Air M2", "iPad 10th Gen", "iPad mini 6"]
        case (.tabletIPad, _):
            return ["Galaxy Tab S9", "Tab P11 / P12", "Standard Wi-Fi + Cellular Tablet"]
        case (.otherGadget, _):
            return ["Apple Watch Series 9 / Ultra", "AirPods Pro (2nd Gen)", "PS5 DualSense Controller", "Mechanical Wireless Keyboard", "Smart Speaker / Display"]
        }
    }
    
    var supportedIssues: [IssueCategory] {
        IssueCategory.allCases.filter { $0.applicableCategories.contains(self) }
    }
}

enum IssueCategory: String, Codable, CaseIterable, Identifiable {
    // Mobile Phones & Tablets
    case brokenDisplay = "Broken Display / Touch Glass"
    case batteryReplacement = "Battery Drain / Replacement"
    case chargingPort = "Charging Port / Power Issue"
    case speakerMic = "Speaker & Microphone Issue"
    case cameraIssue = "Camera / Lens Fault"
    case softwareOS = "Software / OS Troubleshooting"
    case overheatingPerf = "Overheating & Slow Performance"
    
    // Laptops & Desktops specific
    case keyboardTrackpad = "Keyboard & Trackpad Problem"
    case ramSsdUpgrade = "RAM & SSD Storage Upgrade"
    case hardwareDiagnosis = "Deep Hardware & Motherboard Diagnosis"
    
    // Other Gadgets specific
    case connectivityPairing = "Bluetooth / Sensor / Pairing Fault"
    case buttonJoystick = "Controller Stick Drift / Switch Repair"
    
    var id: String { rawValue }
    
    var applicableCategories: [DeviceCategory] {
        switch self {
        case .brokenDisplay: return [.mobilePhone, .tabletIPad, .laptopDesktop, .otherGadget]
        case .batteryReplacement: return [.mobilePhone, .tabletIPad, .laptopDesktop, .otherGadget]
        case .chargingPort: return [.mobilePhone, .tabletIPad, .laptopDesktop, .otherGadget]
        case .speakerMic: return [.mobilePhone, .tabletIPad, .laptopDesktop]
        case .cameraIssue: return [.mobilePhone, .tabletIPad]
        case .softwareOS: return [.mobilePhone, .tabletIPad, .laptopDesktop]
        case .overheatingPerf: return [.mobilePhone, .laptopDesktop]
        case .keyboardTrackpad: return [.laptopDesktop]
        case .ramSsdUpgrade: return [.laptopDesktop]
        case .hardwareDiagnosis: return [.laptopDesktop, .mobilePhone, .tabletIPad]
        case .connectivityPairing: return [.otherGadget, .mobilePhone, .laptopDesktop]
        case .buttonJoystick: return [.otherGadget]
        }
    }
    
    var icon: String {
        switch self {
        case .brokenDisplay: return "iphone.slash"
        case .batteryReplacement: return "battery.25"
        case .chargingPort: return "bolt.slash.fill"
        case .speakerMic: return "speaker.wave.2.bubble.left.fill"
        case .cameraIssue: return "camera.metering.unknown"
        case .softwareOS: return "gear.badge.xmark"
        case .overheatingPerf: return "thermometer.sun.fill"
        case .keyboardTrackpad: return "keyboard.badge.ellipsis"
        case .ramSsdUpgrade: return "memorychip.fill"
        case .hardwareDiagnosis: return "waveform.path.ecg.rectangle.fill"
        case .connectivityPairing: return "antenna.radiowaves.left.and.right.slash"
        case .buttonJoystick: return "gamecontroller.fill"
        }
    }
    
    /// Indicative estimate range in INR (clearly labelled as non-guaranteed estimate)
    var indicativeRangeINR: (min: Decimal, max: Decimal) {
        switch self {
        case .brokenDisplay: return (1800, 8500)
        case .batteryReplacement: return (1200, 4200)
        case .chargingPort: return (650, 2200)
        case .speakerMic: return (600, 1900)
        case .cameraIssue: return (1400, 5800)
        case .softwareOS: return (499, 1499)
        case .overheatingPerf: return (599, 1800)
        case .keyboardTrackpad: return (1200, 4800)
        case .ramSsdUpgrade: return (1500, 7500)
        case .hardwareDiagnosis: return (299, 3500)
        case .connectivityPairing: return (499, 1800)
        case .buttonJoystick: return (699, 2100)
        }
    }
    
    /// Disclosures when a complex repair may require ESD workshop or pickup-and-drop-off
    var serviceModeNote: String {
        switch self {
        case .hardwareDiagnosis:
            return "Doorstep diagnosis supported. Micro-soldering or BGA board work may require safe workshop pickup & drop-off."
        case .brokenDisplay:
            return "Modular screen assemblies can be replaced at home. Edge-curved OLED bonding may require workshop equipment."
        default:
            return "Eligible for standard doorstep inspection and on-spot repair."
        }
    }
    
    var requiredSkillTag: String {
        switch self {
        case .brokenDisplay: return "Display & OLED Assembly"
        case .batteryReplacement: return "Battery & Power Cell"
        case .chargingPort: return "Charging IC & Port"
        case .speakerMic: return "Audio & Acoustic Repair"
        case .cameraIssue: return "Camera Module Calibration"
        case .softwareOS: return "OS Recovery & Firmware"
        case .overheatingPerf: return "Thermal & Fan Servicing"
        case .keyboardTrackpad: return "Keyboard & Input Assembly"
        case .ramSsdUpgrade: return "SSD/RAM & Storage Upgrade"
        case .hardwareDiagnosis: return "Board-Level Diagnostics"
        case .connectivityPairing: return "RF & Bluetooth Diagnostics"
        case .buttonJoystick: return "Peripheral & Micro-Switch"
        }
    }
}

enum WarrantyStatus: String, Codable, CaseIterable, Identifiable {
    case inManufacturerWarranty = "Under Brand Warranty"
    case expired = "Out of Warranty"
    case techCareWarranty = "Under TechCare Warranty"
    case unknown = "Not Sure"
    
    var id: String { rawValue }
}

// MARK: - 3. Booking, Quote & Payment State Machine Enums (Section 7.9 & 14)

enum BookingStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "Draft"
    case requested = "Requested"
    case matchingTechnician = "Matching Technician"
    case technicianAssigned = "Technician Assigned"
    case technicianOnTheWay = "Technician On The Way"
    case technicianArrived = "Technician Arrived"
    case diagnosisInProgress = "Diagnosis In Progress"
    case quotePending = "Quotation Pending Approval"
    case quoteApproved = "Quotation Approved"
    case repairInProgress = "Repair In Progress"
    case testing = "Quality Testing"
    case awaitingCustomerConfirmation = "Awaiting Customer Confirmation"
    case completed = "Repair Completed"
    case paymentPending = "Payment Pending"
    case paid = "Paid & Closed"
    case cancelled = "Cancelled"
    case disputed = "Disputed / Under Review"
    
    var id: String { rawValue }
    
    /// Customer-facing simplified timeline step index (0 to 5)
    var customerTimelineStep: Int {
        switch self {
        case .draft, .requested, .matchingTechnician:
            return 0 // Request Placed
        case .technicianAssigned, .technicianOnTheWay, .technicianArrived:
            return 1 // Technician Visit
        case .diagnosisInProgress, .quotePending, .quoteApproved:
            return 2 // Diagnosis & Quote
        case .repairInProgress, .testing:
            return 3 // Repair & Testing
        case .awaitingCustomerConfirmation, .completed, .paymentPending:
            return 4 // Confirmation & Payment
        case .paid:
            return 5 // Completed & Warranty Active
        case .cancelled, .disputed:
            return -1
        }
    }
    
    var isTerminal: Bool {
        self == .paid || self == .cancelled
    }
}

enum QuoteApprovalStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "Pending Customer Approval"
    case approved = "Approved by Customer"
    case declined = "Declined by Customer"
    case clarificationRequested = "Clarification Requested"
    case superseded = "Superseded by Revised Quote"
    
    var id: String { rawValue }
}

enum PaymentStatus: String, Codable, CaseIterable, Identifiable {
    case notDue = "Not Due Yet (Pay After Completion)"
    case pending = "Payment Pending"
    case processing = "Verifying with Gateway"
    case paid = "Paid & Verified"
    case failed = "Payment Failed"
    case refunded = "Refunded"
    
    var id: String { rawValue }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case upi = "UPI (GPay / PhonePe / Paytm)"
    case card = "Credit / Debit Card (Razorpay Demo)"
    case netBanking = "NetBanking"
    case cashAfterRepair = "Pay Cash / QR on Completion"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .upi: return "bolt.horizontal.circle.fill"
        case .card: return "creditcard.fill"
        case .netBanking: return "building.columns.fill"
        case .cashAfterRepair: return "indianrupeesign.circle.fill"
        }
    }
}

enum TechnicianVerificationStatus: String, Codable, CaseIterable, Identifiable {
    case identityAndSkillsVerified = "ID & Skill Tested (Demo Verified)"
    case identityOnlyVerified = "Govt ID Verified • Skill Assessment Pending"
    case pendingReview = "Verification Pending"
    
    var id: String { rawValue }
}

// MARK: - 4. Core Domain Models (Section 12)

struct SavedAddress: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String // e.g., "Home", "Hostel / College", "Office"
    var line1: String
    var area: String
    var city: String
    var pincode: String
    var landmark: String
    
    var fullFormatted: String {
        "\(line1), \(area), \(city) - \(pincode)"
    }
}

struct User: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var phone: String
    var role: UserRole
    var savedAddresses: [SavedAddress]
    var accountCreationDate: Date = Date()
}

struct Device: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ownerId: UUID
    var category: DeviceCategory
    var brand: String
    var model: String
    var serialOrIMEIHint: String // Last 4 digits only for privacy
    var warrantyStatus: WarrantyStatus
    var repairHistoryIds: [UUID] = []
    
    var displayName: String {
        "\(brand) \(model)"
    }
}

struct PrivacySafetyChecklist: Codable, Hashable {
    var dataBackedUp: Bool = false
    var sensitiveAppsLockedOrRemoved: Bool = false
    var maintenanceModeEnabledIfSupported: Bool = false
    var physicalConditionRecorded: Bool = false
    var consentsToDiagnosticInspection: Bool = false
    var unlockPasscodePolicyUnderstood: Bool = false
    
    var isMinimumSafetyConfirmed: Bool {
        physicalConditionRecorded && consentsToDiagnosticInspection && unlockPasscodePolicyUnderstood
    }
}

struct RepairRequest: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var customerId: UUID
    var deviceId: UUID
    var reportedIssue: IssueCategory
    var symptomDescription: String
    var powersOn: Bool
    var deviceHistoryNotes: String
    var photoReferences: [String] // Local asset identifiers or demo labels
    var requestedDate: Date
    var preferredTimeSlot: String
    var serviceAddress: SavedAddress
    var currentStatus: BookingStatus
    var assignedTechnicianId: UUID?
    var privacyChecklist: PrivacySafetyChecklist
    var creationTimestamp: Date = Date()
}

struct Technician: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var skills: [String]
    var supportedCategories: [DeviceCategory]
    var supportedBrands: [String]
    var serviceArea: String
    var workingHours: String
    var serviceRadiusKm: Int
    var isAvailableOnline: Bool
    var verificationStatus: TechnicianVerificationStatus
    var qualificationSummary: String
    var experienceYears: Int
    var rating: Double
    var reviewsCount: Int
    var completedJobs: Int
    var visitDiagnosticFeeINR: Decimal
    var subscriptionTier: String // e.g., "TechCare Pro Partner", "Standard Partner"
    var latitude: Double
    var longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "T"
        let last = parts.dropFirst().first?.prefix(1) ?? "C"
        return "\(first)\(last)".uppercased()
    }
}

struct CancellationRecord: Codable, Hashable {
    var cancelledByRole: UserRole
    var reason: String
    var cancellationFeeINR: Decimal
    var timestamp: Date = Date()
}

struct StateTransitionAuditEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var fromStatus: BookingStatus
    var toStatus: BookingStatus
    var actor: String
    var note: String
    var timestamp: Date = Date()
}

struct Booking: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var bookingCode: String // e.g. "TC-2026-4819"
    var repairRequestId: UUID
    var customerId: UUID
    var deviceId: UUID
    var technicianId: UUID?
    var appointmentDate: Date
    var timeSlot: String
    var status: BookingStatus
    var paymentStatus: PaymentStatus
    var disclosedVisitFeeINR: Decimal
    var specialInstructions: String
    var requiresPickupWorkshop: Bool = false
    var declinedTechnicianIds: [UUID] = []
    var cancellationInfo: CancellationRecord? = nil
    var disputeReason: String? = nil
    var auditTrail: [StateTransitionAuditEntry] = []
    var createdAt: Date = Date()
}

struct RepairPartItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var partName: String
    var partQuality: String // e.g. "OEM Grade Replacement", "Authorized Original"
    var unitCostINR: Decimal
    var quantity: Int = 1
    var warrantyMonths: Int
    
    var totalCostINR: Decimal {
        unitCostINR * Decimal(quantity)
    }
}

struct RepairQuote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var bookingId: UUID
    var diagnosis: String
    var recommendedRepair: String
    var parts: [RepairPartItem]
    var partsCostINR: Decimal
    var labourCostINR: Decimal
    var applicableTaxesINR: Decimal // e.g. 18% GST on service/parts
    var visitOrDiagnosticFeeINR: Decimal // Often waived/adjusted if repair proceeds, or explicitly shown
    var visitFeeWaivedOnApproval: Bool
    var totalAmountINR: Decimal
    var estimatedDurationMinutes: Int
    var warrantyTerms: String
    var quoteVersion: Int
    var revisionExplanation: String?
    var customerClarificationNote: String?
    var approvalStatus: QuoteApprovalStatus
    var createdAt: Date = Date()
    var approvalTimestamp: Date? = nil
    
    static func calculateTotal(
        parts: [RepairPartItem],
        labour: Decimal,
        visitFee: Decimal,
        waiveVisitFee: Bool,
        taxRatePercent: Decimal = 18
    ) -> (partsTotal: Decimal, taxAmount: Decimal, grandTotal: Decimal) {
        let partsSum = parts.reduce(Decimal(0)) { $0 + $1.totalCostINR }
        let effectiveVisitFee = waiveVisitFee ? Decimal(0) : visitFee
        let subtotal = partsSum + labour + effectiveVisitFee
        let tax = ((subtotal * taxRatePercent) / Decimal(100)).roundedINR()
        let grandTotal = subtotal + tax
        return (partsSum, tax, grandTotal)
    }
}

struct FunctionalTestChecklist: Codable, Hashable {
    var powerAndBootTestPassed: Bool = true
    var displayAndTouchTestPassed: Bool = true
    var chargingAndBatteryTestPassed: Bool = true
    var audioAndSensorsTestPassed: Bool = true
    var connectivityTestPassed: Bool = true
    var summaryNotes: String = "All post-repair hardware diagnostics passed."
}

struct RepairRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var bookingId: UUID
    var deviceId: UUID
    var technicianId: UUID
    var technicianName: String
    var customerReportedIssue: String
    var diagnosis: String
    var workPerformed: String
    var partsReplaced: [RepairPartItem]
    var approvedQuoteAmountINR: Decimal
    var testResults: FunctionalTestChecklist
    var completionTimestamp: Date
    var technicianNotes: String
    var warrantyExpiryDate: Date
    var warrantyTerms: String
    var invoiceId: UUID?
    var followUpOrComplaintIds: [UUID] = []
}

struct Payment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var bookingId: UUID
    var amountINR: Decimal
    var paymentMethod: PaymentMethod
    var paymentStatus: PaymentStatus
    var gatewayReference: String // e.g. "DEMO-RZP-9928174"
    var createdAt: Date = Date()
    var verifiedAt: Date? = nil
}

struct InvoiceLineItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var subtitle: String
    var amountINR: Decimal
}

struct Invoice: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var bookingId: UUID
    var invoiceNumber: String // e.g. "INV-TC-2026-0084"
    var customerName: String
    var technicianName: String
    var deviceSummary: String
    var itemisedCharges: [InvoiceLineItem]
    var subtotalINR: Decimal
    var taxAmountINR: Decimal
    var discountINR: Decimal
    var totalAmountINR: Decimal
    var paymentMethod: PaymentMethod
    var issueDate: Date = Date()
}

struct Review: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var bookingId: UUID
    var customerId: UUID
    var customerName: String
    var technicianId: UUID
    var rating: Int // 1 to 5
    var comment: String
    var deviceSummary: String
    var timestamp: Date = Date()
}

enum WarrantyClaimStatus: String, Codable, CaseIterable, Identifiable {
    case submitted = "Submitted"
    case underReview = "Under Technical Review"
    case scheduledRevisit = "Free Revisit Scheduled"
    case resolved = "Resolved"
    case rejectedOutOfScope = "Out of Warranty Scope"
    
    var id: String { rawValue }
}

struct WarrantyClaim: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var repairRecordId: UUID
    var bookingId: UUID
    var customerId: UUID
    var issueDescription: String
    var status: WarrantyClaimStatus
    var resolutionNotes: String
    var createdAt: Date = Date()
}

struct SupportComplaint: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var bookingCode: String
    var customerName: String
    var category: String
    var description: String
    var status: String // "Open", "Investigating", "Resolved"
    var createdAt: Date = Date()
}

struct TechnicianEarningBreakdown: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var bookingCode: String
    var completedDate: Date
    var grossRepairAmountINR: Decimal
    var platformCommissionRatePercent: Decimal
    var platformCommissionINR: Decimal
    var taxDeductionINR: Decimal
    var netPayoutINR: Decimal
    var payoutStatus: String // "Settled to Bank", "Pending Weekly Settlement"
}

// MARK: - Decimal Rounding Helper

extension Decimal {
    func roundedINR() -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, 0, .plain)
        return result
    }
}

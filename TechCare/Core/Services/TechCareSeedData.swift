import Foundation

extension TechCareStore {
    static func makeRealisticSeedData() -> TechCareStoreSnapshot {
        // 1. Saved Addresses (India - NCR & Bengaluru)
        let addrHome = SavedAddress(
            label: "Home",
            line1: "Flat 402, Tower B, Lotus Boulevard",
            area: "Sector 100",
            city: "Noida, UP",
            pincode: "201304",
            landmark: "Near Pathways School"
        )
        let addrCollege = SavedAddress(
            label: "College Hostel",
            line1: "Room 214, Block C, Knowledge Park III",
            area: "Greater Noida",
            city: "Greater Noida, UP",
            pincode: "201306",
            landmark: "Opposite Sharda Gate 2"
        )
        let addrOffice = SavedAddress(
            label: "Work / Studio",
            line1: "3rd Floor, CyberHub Co-Work",
            area: "Sector 62",
            city: "Noida, UP",
            pincode: "201309",
            landmark: "Near Electronic City Metro"
        )
        
        let customer = User(
            name: "Aarav Sharma",
            email: "aarav.sharma@techcare.in",
            phone: "+91 98765 43210",
            role: .customer,
            savedAddresses: [addrHome, addrCollege, addrOffice]
        )
        
        // 2. Technicians (Verified & Skill-tagged)
        let techRajesh = Technician(
            name: "Rajesh Verma",
            phone: "+91 98112 34091",
            skills: [
                IssueCategory.brokenDisplay.requiredSkillTag,
                IssueCategory.batteryReplacement.requiredSkillTag,
                IssueCategory.chargingPort.requiredSkillTag,
                IssueCategory.cameraIssue.requiredSkillTag
            ],
            supportedCategories: [.mobilePhone, .tabletIPad],
            supportedBrands: ["Apple", "Samsung", "OnePlus", "Google Pixel", "Apple iPad"],
            serviceArea: "Noida Sector 18 / 62 / 100 & Indirapuram",
            workingHours: "09:00 AM – 08:30 PM",
            serviceRadiusKm: 15,
            isAvailableOnline: true,
            verificationStatus: .identityAndSkillsVerified,
            qualificationSummary: "Aadhaar & Police Clearance Verified • 8 Yrs Smartphone & iPad Micro-Assembly Experience • ESD Tool Kit Equipped",
            experienceYears: 8,
            rating: 4.9,
            reviewsCount: 214,
            completedJobs: 640,
            visitDiagnosticFeeINR: 249,
            subscriptionTier: "TechCare Pro Partner",
            latitude: 28.5450,
            longitude: 77.3680
        )
        
        let techVikram = Technician(
            name: "Vikramaditya Nair",
            phone: "+91 98188 77210",
            skills: [
                IssueCategory.overheatingPerf.requiredSkillTag,
                IssueCategory.ramSsdUpgrade.requiredSkillTag,
                IssueCategory.keyboardTrackpad.requiredSkillTag,
                IssueCategory.softwareOS.requiredSkillTag,
                IssueCategory.hardwareDiagnosis.requiredSkillTag
            ],
            supportedCategories: [.laptopDesktop, .tabletIPad],
            supportedBrands: ["Apple MacBook", "Dell", "HP", "Lenovo", "ASUS", "Custom Desktop PC"],
            serviceArea: "Noida, Greater Noida & Knowledge Park",
            workingHours: "10:00 AM – 08:00 PM",
            serviceRadiusKm: 20,
            isAvailableOnline: true,
            verificationStatus: .identityAndSkillsVerified,
            qualificationSummary: "Govt ID Verified • Diploma in Computer Hardware & Networking • Specialist in MacBook Thermal Servicing, NVMe SSD Upgrades & Power Rails",
            experienceYears: 10,
            rating: 4.8,
            reviewsCount: 179,
            completedJobs: 512,
            visitDiagnosticFeeINR: 299,
            subscriptionTier: "TechCare Pro Partner",
            latitude: 28.4810,
            longitude: 77.4990
        )
        
        let techSneha = Technician(
            name: "Sneha Kulkarni",
            phone: "+91 97170 55123",
            skills: [
                IssueCategory.brokenDisplay.requiredSkillTag,
                IssueCategory.batteryReplacement.requiredSkillTag,
                IssueCategory.speakerMic.requiredSkillTag,
                IssueCategory.softwareOS.requiredSkillTag
            ],
            supportedCategories: [.mobilePhone, .tabletIPad, .otherGadget],
            supportedBrands: ["Apple", "Samsung", "Xiaomi / Redmi", "Vivo", "Nothing", "Apple Watch"],
            serviceArea: "Greater Noida, Sector 62 & Crossing Republik",
            workingHours: "09:30 AM – 07:30 PM",
            serviceRadiusKm: 14,
            isAvailableOnline: true,
            verificationStatus: .identityAndSkillsVerified,
            qualificationSummary: "Govt ID Verified • 6 Yrs Mobile & Wearable Diagnostics • TrueTone & Battery Health Calibration Specialist",
            experienceYears: 6,
            rating: 4.9,
            reviewsCount: 138,
            completedJobs: 385,
            visitDiagnosticFeeINR: 199,
            subscriptionTier: "Standard Partner",
            latitude: 28.5910,
            longitude: 77.3620
        )
        
        let techDanish = Technician(
            name: "Danish Khan",
            phone: "+91 99581 22810",
            skills: [
                IssueCategory.buttonJoystick.requiredSkillTag,
                IssueCategory.connectivityPairing.requiredSkillTag,
                IssueCategory.chargingPort.requiredSkillTag,
                IssueCategory.ramSsdUpgrade.requiredSkillTag
            ],
            supportedCategories: [.otherGadget, .laptopDesktop, .mobilePhone],
            supportedBrands: ["Sony PlayStation / DualSense", "AirPods / Wireless Earbuds", "Logitech / Keychron", "Dell", "HP", "OnePlus"],
            serviceArea: "Noida Sector 100 / 137 & Greater Noida",
            workingHours: "11:00 AM – 09:00 PM",
            serviceRadiusKm: 18,
            isAvailableOnline: true,
            verificationStatus: .identityOnlyVerified,
            qualificationSummary: "Govt ID Verified • Console Controller Hall-Effect Stick Upgrade & Laptop Peripheral Specialist",
            experienceYears: 5,
            rating: 4.7,
            reviewsCount: 86,
            completedJobs: 210,
            visitDiagnosticFeeINR: 199,
            subscriptionTier: "Standard Partner",
            latitude: 28.5120,
            longitude: 77.4050
        )
        
        // 3. Customer Devices
        let devIPhone = Device(
            ownerId: customer.id,
            category: .mobilePhone,
            brand: "Apple",
            model: "iPhone 15 Pro",
            serialOrIMEIHint: "4912",
            warrantyStatus: .expired
        )
        
        var devMacBook = Device(
            ownerId: customer.id,
            category: .laptopDesktop,
            brand: "Apple MacBook",
            model: "MacBook Air M2",
            serialOrIMEIHint: "9034",
            warrantyStatus: .techCareWarranty
        )
        
        let devDell = Device(
            ownerId: customer.id,
            category: .laptopDesktop,
            brand: "Dell",
            model: "Inspiron 15 5510",
            serialOrIMEIHint: "2271",
            warrantyStatus: .expired
        )
        
        let safeChecklist = PrivacySafetyChecklist(
            dataBackedUp: true,
            sensitiveAppsLockedOrRemoved: true,
            maintenanceModeEnabledIfSupported: true,
            physicalConditionRecorded: true,
            consentsToDiagnosticInspection: true,
            unlockPasscodePolicyUnderstood: true
        )
        
        // 4. Active Booking #1: Quote Pending Customer Approval (iPhone 15 Pro Display & Battery Check)
        let reqActive = RepairRequest(
            customerId: customer.id,
            deviceId: devIPhone.id,
            reportedIssue: .brokenDisplay,
            symptomDescription: "Front OLED glass cracked near bottom edge; display shows a faint green line and touch stops responding occasionally.",
            powersOn: true,
            deviceHistoryNotes: "Dropped from desk yesterday. FaceID still works fine.",
            photoReferences: ["front_glass_crack.jpg", "frame_corner_dent.jpg"],
            requestedDate: Date(),
            preferredTimeSlot: "11:00 AM - 01:00 PM",
            serviceAddress: addrHome,
            currentStatus: .quotePending,
            assignedTechnicianId: techRajesh.id,
            privacyChecklist: safeChecklist
        )
        
        let bookingActive = Booking(
            bookingCode: "TC-2026-8412",
            repairRequestId: reqActive.id,
            customerId: customer.id,
            deviceId: devIPhone.id,
            technicianId: techRajesh.id,
            appointmentDate: Date(),
            timeSlot: "11:00 AM - 01:00 PM",
            status: .quotePending,
            paymentStatus: .notDue,
            disclosedVisitFeeINR: 249,
            specialInstructions: "Ring bell twice; ESD mat table space ready in living room.",
            auditTrail: [
                StateTransitionAuditEntry(
                    fromStatus: .diagnosisInProgress,
                    toStatus: .quotePending,
                    actor: techRajesh.name,
                    note: "Submitted itemised Quotation v1 (₹6,490 incl. GST) after doorstep inspection."
                ),
                StateTransitionAuditEntry(
                    fromStatus: .technicianArrived,
                    toStatus: .diagnosisInProgress,
                    actor: techRajesh.name,
                    note: "Technician arrived on time and began 12-point hardware inspection."
                ),
                StateTransitionAuditEntry(
                    fromStatus: .requested,
                    toStatus: .technicianAssigned,
                    actor: techRajesh.name,
                    note: "Assigned to Rajesh Verma (ID & Skill Verified)."
                )
            ]
        )
        
        let partOLED = RepairPartItem(
            partName: "iPhone 15 Pro LTPO OLED Display Assembly",
            partQuality: "OEM Grade Original Pulled / Calibrated",
            unitCostINR: 4800,
            quantity: 1,
            warrantyMonths: 6
        )
        let partSeal = RepairPartItem(
            partName: "IP68 Dust & Water Resistant Frame Adhesive Seal",
            partQuality: "Factory Pre-Cut Gasket",
            unitCostINR: 200,
            quantity: 1,
            warrantyMonths: 6
        )
        let calc1 = RepairQuote.calculateTotal(
            parts: [partOLED, partSeal],
            labour: 500,
            visitFee: 249,
            waiveVisitFee: true
        )
        let quoteActive = RepairQuote(
            bookingId: bookingActive.id,
            diagnosis: "Digitizer flex cable micro-fracture under bottom bezel. FaceID sensor array and motherboard display IC tested healthy. Full OLED assembly & waterproof seal replacement recommended.",
            recommendedRepair: "On-spot OLED Display Assembly replacement + TrueTone programmer transfer + new IP68 frame gasket.",
            parts: [partOLED, partSeal],
            partsCostINR: calc1.partsTotal,
            labourCostINR: 500,
            applicableTaxesINR: calc1.taxAmount,
            visitOrDiagnosticFeeINR: 249,
            visitFeeWaivedOnApproval: true,
            totalAmountINR: calc1.grandTotal,
            estimatedDurationMinutes: 45,
            warrantyTerms: "180-Day TechCare Doorstep Warranty covering touch response, dead pixels, and display flex.",
            quoteVersion: 1,
            approvalStatus: .pending
        )
        
        // 5. Incoming Job Request #2 for Technician Portal Demo (Dell Laptop Overheating)
        let reqIncoming = RepairRequest(
            customerId: customer.id,
            deviceId: devDell.id,
            reportedIssue: .overheatingPerf,
            symptomDescription: "Laptop becomes very hot near the vents and shuts down after 15 minutes of coding or video calls. Fan makes a rattling noise.",
            powersOn: true,
            deviceHistoryNotes: "Purchased 2 years ago, thermal paste never replaced.",
            photoReferences: ["laptop_bottom_vent.jpg"],
            requestedDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date(),
            preferredTimeSlot: "04:00 PM - 06:00 PM",
            serviceAddress: addrCollege,
            currentStatus: .matchingTechnician,
            assignedTechnicianId: techVikram.id,
            privacyChecklist: safeChecklist
        )
        
        let bookingIncoming = Booking(
            bookingCode: "TC-2026-8459",
            repairRequestId: reqIncoming.id,
            customerId: customer.id,
            deviceId: devDell.id,
            technicianId: techVikram.id,
            appointmentDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date(),
            timeSlot: "04:00 PM - 06:00 PM",
            status: .matchingTechnician,
            paymentStatus: .notDue,
            disclosedVisitFeeINR: 299,
            specialInstructions: "Hostel visitor lounge table available on ground floor.",
            auditTrail: [
                StateTransitionAuditEntry(
                    fromStatus: .requested,
                    toStatus: .matchingTechnician,
                    actor: "Smart Allocator",
                    note: "Dispatched to Vikramaditya Nair (98% skill match for Thermal & Fan Servicing)."
                )
            ]
        )
        
        // 6. Completed Historical Booking #3 with Repair Passport, Invoice & Review (MacBook Air M2)
        let pastDate = Calendar.current.date(byAdding: .day, value: -18, to: Date()) ?? Date()
        let reqCompleted = RepairRequest(
            customerId: customer.id,
            deviceId: devMacBook.id,
            reportedIssue: .chargingPort,
            symptomDescription: "MagSafe 3 & USB-C ports intermittent; battery not charging reliably.",
            powersOn: true,
            deviceHistoryNotes: "Happened after voltage fluctuation.",
            photoReferences: ["magsafe_io_board.jpg"],
            requestedDate: pastDate,
            preferredTimeSlot: "02:00 PM - 04:00 PM",
            serviceAddress: addrHome,
            currentStatus: .paid,
            assignedTechnicianId: techVikram.id,
            privacyChecklist: safeChecklist,
            creationTimestamp: pastDate
        )
        
        let bookingCompleted = Booking(
            bookingCode: "TC-2026-7904",
            repairRequestId: reqCompleted.id,
            customerId: customer.id,
            deviceId: devMacBook.id,
            technicianId: techVikram.id,
            appointmentDate: pastDate,
            timeSlot: "02:00 PM - 04:00 PM",
            status: .paid,
            paymentStatus: .paid,
            disclosedVisitFeeINR: 299,
            specialInstructions: "Call before arriving.",
            auditTrail: [
                StateTransitionAuditEntry(
                    fromStatus: .paymentPending,
                    toStatus: .paid,
                    actor: "Payment Verifier (Demo)",
                    note: "Paid ₹2,360 via UPI. Invoice INV-TC-2026-7904 generated.",
                    timestamp: pastDate
                )
            ],
            createdAt: pastDate
        )
        
        let partIO = RepairPartItem(
            partName: "MacBook Air M2 MagSafe / Dual USB-C I/O Board",
            partQuality: "OEM Original Replacement",
            unitCostINR: 1500,
            quantity: 1,
            warrantyMonths: 6
        )
        let calcPast = RepairQuote.calculateTotal(
            parts: [partIO],
            labour: 500,
            visitFee: 299,
            waiveVisitFee: true
        )
        let quoteCompleted = RepairQuote(
            bookingId: bookingCompleted.id,
            diagnosis: "Oxidised pins on modular MagSafe/Thunderbolt I/O board. Logic board CD3217 controller ICs tested intact.",
            recommendedRepair: "Modular I/O Board replacement & ultrasonic port cleaning.",
            parts: [partIO],
            partsCostINR: calcPast.partsTotal,
            labourCostINR: 500,
            applicableTaxesINR: calcPast.taxAmount,
            visitOrDiagnosticFeeINR: 299,
            visitFeeWaivedOnApproval: true,
            totalAmountINR: calcPast.grandTotal, // ₹2,000 + ₹360 GST = ₹2,360
            estimatedDurationMinutes: 35,
            warrantyTerms: "180-Day Warranty on replaced I/O board and charging stability.",
            quoteVersion: 1,
            approvalStatus: .approved,
            createdAt: pastDate,
            approvalTimestamp: pastDate
        )
        
        let invoiceCompleted = Invoice(
            bookingId: bookingCompleted.id,
            invoiceNumber: "INV-TC-2026-7904",
            customerName: customer.name,
            technicianName: techVikram.name,
            deviceSummary: devMacBook.displayName,
            itemisedCharges: [
                InvoiceLineItem(
                    title: partIO.partName,
                    subtitle: "OEM Original Replacement • 6m Warranty",
                    amountINR: 1500
                ),
                InvoiceLineItem(
                    title: "Doorstep Repair & Calibration Labour",
                    subtitle: "Modular I/O Board replacement (Visit fee ₹299 waived)",
                    amountINR: 500
                )
            ],
            subtotalINR: 2000,
            taxAmountINR: 360,
            discountINR: 0,
            totalAmountINR: 2360,
            paymentMethod: .upi,
            issueDate: pastDate
        )
        
        let paymentCompleted = Payment(
            bookingId: bookingCompleted.id,
            amountINR: 2360,
            paymentMethod: .upi,
            paymentStatus: .paid,
            gatewayReference: "DEMO-RZP-883920",
            createdAt: pastDate,
            verifiedAt: pastDate
        )
        
        let recordCompleted = RepairRecord(
            bookingId: bookingCompleted.id,
            deviceId: devMacBook.id,
            technicianId: techVikram.id,
            technicianName: techVikram.name,
            customerReportedIssue: IssueCategory.chargingPort.rawValue,
            diagnosis: quoteCompleted.diagnosis,
            workPerformed: "Replaced modular MagSafe 3 / USB-C I/O board at customer's study table using ESD wrist strap. Verified 67W fast-charge negotiations on both ports.",
            partsReplaced: [partIO],
            approvedQuoteAmountINR: 2360,
            testResults: FunctionalTestChecklist(
                powerAndBootTestPassed: true,
                displayAndTouchTestPassed: true,
                chargingAndBatteryTestPassed: true,
                audioAndSensorsTestPassed: true,
                connectivityTestPassed: true,
                summaryNotes: "USB-PD 20V/3.35A negotiation verified stable. No personal files or user login accessed."
            ),
            completionTimestamp: pastDate,
            technicianNotes: "Advised customer to use surge-protected socket for charger.",
            warrantyExpiryDate: Calendar.current.date(byAdding: .day, value: 162, to: Date()) ?? Date(),
            warrantyTerms: quoteCompleted.warrantyTerms,
            invoiceId: invoiceCompleted.id
        )
        devMacBook.repairHistoryIds = [recordCompleted.id]
        
        let seedReviews: [Review] = [
            Review(
                bookingId: bookingCompleted.id,
                customerId: customer.id,
                customerName: "Aarav Sharma",
                technicianId: techVikram.id,
                rating: 5,
                comment: "Super transparent! Another shop quoted ₹9,500 saying the logic board was dead, but Vikram diagnosed the ₹1,500 modular I/O board right in front of me in 35 mins.",
                deviceSummary: "MacBook Air M2",
                timestamp: pastDate
            ),
            Review(
                bookingId: UUID(),
                customerId: UUID(),
                customerName: "Priya Nair",
                technicianId: techRajesh.id,
                rating: 5,
                comment: "Replaced my iPhone 14 display at home during my lunch break. Used an anti-static mat, transferred TrueTone, and didn't ask for my passcode until the final touch test.",
                deviceSummary: "Apple iPhone 14",
                timestamp: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
            ),
            Review(
                bookingId: UUID(),
                customerId: UUID(),
                customerName: "Rohan Mehta",
                technicianId: techSneha.id,
                rating: 5,
                comment: "Sneha fixed my Galaxy S23 battery swelling issue safely at home and explained the 6-month warranty clearly.",
                deviceSummary: "Samsung Galaxy S23",
                timestamp: Calendar.current.date(byAdding: .day, value: -11, to: Date()) ?? Date()
            )
        ]
        
        let seedComplaints: [SupportComplaint] = [
            SupportComplaint(
                bookingCode: "TC-2026-7102",
                customerName: "Karan Malhotra",
                category: "Part Availability Delay",
                description: "Technician arrived on time, but Asus ROG fan part required next-day workshop sourcing.",
                status: "Resolved",
                createdAt: Calendar.current.date(byAdding: .day, value: -9, to: Date()) ?? Date()
            )
        ]
        
        return TechCareStoreSnapshot(
            currentUser: customer,
            activeRole: .customer,
            devices: [devIPhone, devMacBook, devDell],
            technicians: [techRajesh, techVikram, techSneha, techDanish],
            repairRequests: [reqActive, reqIncoming, reqCompleted],
            bookings: [bookingActive, bookingIncoming, bookingCompleted],
            quotes: [quoteActive, quoteCompleted],
            repairRecords: [recordCompleted],
            payments: [paymentCompleted],
            invoices: [invoiceCompleted],
            reviews: seedReviews,
            warrantyClaims: [],
            complaints: seedComplaints,
            platformCommissionPercent: 12
        )
    }
}

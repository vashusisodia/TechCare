import SwiftUI
import PhotosUI

// MARK: - Sections 7.3, 7.4, 7.5, 7.16 & 15: Device Selection, Issue Reporting, Privacy Checklist, Estimate & AI Categoriser

struct DeviceAndIssueWizardView: View {
    @ObservedObject var store: TechCareStore
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var customModelText: String = ""
    @State private var validationMessage: String? = nil
    @State private var showReviewBeforeTechnicianSelection: Bool = false
    @State private var showAIAssistant: Bool = false
    
    var availableBrands: [String] {
        store.draftCategory.sampleBrands
    }
    
    var availableModels: [String] {
        store.draftCategory.sampleModels(for: store.draftBrand)
    }
    
    var availableIssues: [IssueCategory] {
        store.draftCategory.supportedIssues
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Step Banner
                HStack {
                    TCBadge(text: "STEP 1 OF 3 • DEVICE & ISSUE DETAILS", icon: "cpu.fill", color: TCTheme.teal)
                    Spacer()
                    Button {
                        showAIAssistant = true
                    } label: {
                        Label("AI Symptom Helper", systemImage: "sparkles")
                            .font(.caption.weight(.bold))
                            .foregroundColor(TCTheme.teal)
                    }
                }
                
                // 1. Device Category, Brand, Model & Warranty
                TCCard {
                    VStack(alignment: .leading, spacing: 14) {
                        TCSectionHeader(
                            title: "1. Select Device & Model",
                            subtitle: "Phones and Laptops prioritised; extensible to Tablets & Gadgets"
                        )
                        
                        TCFormField(label: "Device Category", required: true) {
                            Picker("Category", selection: $store.draftCategory) {
                                ForEach(DeviceCategory.allCases) { cat in
                                    Text(cat.shortName).tag(cat)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: store.draftCategory) { _, newCat in
                                store.draftBrand = newCat.sampleBrands.first ?? "Apple"
                                store.draftModel = newCat.sampleModels(for: store.draftBrand).first ?? "Standard Model"
                                store.draftIssue = newCat.supportedIssues.first ?? .brokenDisplay
                            }
                        }
                        
                        HStack(spacing: 12) {
                            TCFormField(label: "Brand", required: true) {
                                Menu {
                                    ForEach(availableBrands, id: \.self) { brand in
                                        Button(brand) {
                                            store.draftBrand = brand
                                            store.draftModel = store.draftCategory.sampleModels(for: brand).first ?? "Standard Model"
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(store.draftBrand)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(10)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            
                            TCFormField(label: "Model", required: true) {
                                Menu {
                                    ForEach(availableModels, id: \.self) { model in
                                        Button(model) {
                                            store.draftModel = model
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(store.draftModel)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(10)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        
                        HStack(spacing: 12) {
                            TCFormField(label: "Warranty Status") {
                                Menu {
                                    ForEach(WarrantyStatus.allCases) { ws in
                                        Button(ws.rawValue) {
                                            store.draftWarrantyStatus = ws
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(store.draftWarrantyStatus.rawValue)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption2)
                                    }
                                    .padding(10)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            
                            TCFormField(label: "Serial / IMEI (Last 4 Digits)") {
                                TextField("e.g. 4829", text: $store.draftSerialHint)
                                    .keyboardType(.numberPad)
                                    .padding(9)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                
                // 2. Issue Reporting & PhotosPicker
                TCCard {
                    VStack(alignment: .leading, spacing: 14) {
                        TCSectionHeader(
                            title: "2. Problem & Symptoms",
                            subtitle: "Describe what happened so the technician brings compatible tools & parts"
                        )
                        
                        TCFormField(label: "Problem Category", required: true) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(availableIssues) { issue in
                                    let isSelected = store.draftIssue == issue
                                    Button {
                                        store.draftIssue = issue
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: issue.icon)
                                                .font(.caption)
                                            Text(issue.rawValue)
                                                .font(.caption.weight(.semibold))
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            Spacer(minLength: 0)
                                        }
                                        .padding(10)
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .background(isSelected ? TCTheme.teal : Color(.tertiarySystemFill))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Toggle(isOn: $store.draftPowersOn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Device Powers On Currently?")
                                    .font(.subheadline.weight(.semibold))
                                Text("Helps technician prepare external power-rail diagnostics if dead")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(TCTheme.teal)
                        
                        TCFormField(label: "Symptom Description", required: true) {
                            TextEditor(text: $store.draftSymptomDescription)
                                .frame(minHeight: 76)
                                .padding(6)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        TCFormField(label: "Relevant Device History (Optional)") {
                            TextField("e.g. Prior screen replacement, water spill, recent OS update", text: $store.draftHistoryNotes)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // PhotosPicker (Section 7.4)
                        VStack(alignment: .leading, spacing: 8) {
                            PhotosPicker(
                                selection: $selectedPhotoItems,
                                maxSelectionCount: 3,
                                matching: .images
                            ) {
                                HStack(spacing: 10) {
                                    Image(systemName: "photo.badge.plus.fill")
                                        .font(.title3)
                                        .foregroundColor(TCTheme.teal)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(store.draftPhotoLabels.isEmpty ? "Attach Damage Photos (Optional)" : "\(store.draftPhotoLabels.count) Photo(s) Attached Locally")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("Kept on device until you explicitly submit the booking request.")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if !store.draftPhotoLabels.isEmpty {
                                        Button("Add Sample") {
                                            store.draftPhotoLabels.append("damage_photo_\(store.draftPhotoLabels.count + 1).jpg")
                                        }
                                        .font(.caption2.weight(.bold))
                                    }
                                }
                                .padding(12)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .onChange(of: selectedPhotoItems) { _, newItems in
                                store.draftPhotoLabels = newItems.enumerated().map { idx, _ in
                                    "device_issue_photo_\(idx + 1).jpg"
                                }
                            }
                            
                            HStack(spacing: 8) {
                                Button {
                                    if !store.draftPhotoLabels.contains("sample_damage_closeup.jpg") {
                                        store.draftPhotoLabels.append("sample_damage_closeup.jpg")
                                    }
                                } label: {
                                    Label("Attach Demo Damage Photo", systemImage: "camera.viewfinder")
                                        .font(.caption2.weight(.semibold))
                                }
                                
                                if !store.draftPhotoLabels.isEmpty {
                                    Button(role: .destructive) {
                                        store.draftPhotoLabels.removeAll()
                                        selectedPhotoItems.removeAll()
                                    } label: {
                                        Text("Clear (\(store.draftPhotoLabels.count))")
                                            .font(.caption2.weight(.semibold))
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 3. Preliminary Estimate & Service Disclosure Card (Section 7.5)
                preliminaryEstimateCard
                
                // 4. Device Privacy & Safety Checklist (Section 7.16)
                privacySafetyChecklistCard
                
                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(TCTheme.danger)
                        .padding(.horizontal, 4)
                }
                
                Button {
                    let trimmed = store.draftSymptomDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        validationMessage = "Please describe the device symptoms before proceeding."
                        return
                    }
                    if !store.draftPrivacyChecklist.isMinimumSafetyConfirmed {
                        validationMessage = "Please confirm the mandatory privacy & safety checkboxes."
                        return
                    }
                    validationMessage = nil
                    showReviewBeforeTechnicianSelection = true
                } label: {
                    HStack {
                        Text("Review & Find Verified Technicians")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(TCPrimaryButtonStyle())
            }
            .padding(18)
        }
        .background(TCTheme.background)
        .navigationTitle("Report Device Issue")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showReviewBeforeTechnicianSelection) {
            TechnicianDiscoveryAndBookingView(store: store)
        }
        .sheet(isPresented: $showAIAssistant) {
            AISymptomAssistantSheet(store: store) { cat, issue, desc in
                store.draftCategory = cat
                store.draftIssue = issue
                store.draftSymptomDescription = desc
            }
        }
    }
    
    // MARK: - Section 7.5: Preliminary Estimate View
    
    private var preliminaryEstimateCard: some View {
        let range = store.draftIssue.indicativeRangeINR
        return TCCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TCBadge(text: "PRELIMINARY ESTIMATE (NOT GUARANTEED)", icon: "indianrupeesign.circle.fill", color: TCTheme.navy)
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Indicative Repair Range")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(INRFormatter.format(range.min)) – \(INRFormatter.format(range.max))")
                            .font(.title3.weight(.bold))
                            .foregroundColor(TCTheme.teal)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Doorstep Visit / Diagnosis Fee")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("₹199 – ₹299")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.primary)
                    }
                }
                
                Divider()
                
                Label(store.draftIssue.serviceModeNote, systemImage: "wrench.adjustable.fill")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text("Important Disclosure: The range above is a non-binding preliminary estimate based on sample part data. The final payable price is determined only after on-spot technician diagnosis and your explicit digital quotation approval.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Section 7.16: Device Privacy & Safety Checklist
    
    private var privacySafetyChecklistCard: some View {
        TCCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "hand.raised.shield.fill")
                        .foregroundColor(TCTheme.teal)
                    Text("Device Privacy & Safety Checklist")
                        .font(.subheadline.weight(.bold))
                }
                
                Text("Technicians are strictly prohibited from accessing personal photos, files, messages, or accounts without explicit authorisation.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    checklistToggle(
                        title: "I have backed up important data (iCloud / Google Drive / SSD)",
                        isOn: $store.draftPrivacyChecklist.dataBackedUp,
                        required: false
                    )
                    checklistToggle(
                        title: "I have locked or hidden sensitive banking/personal apps & removed SIM/SD card if not needed",
                        isOn: $store.draftPrivacyChecklist.sensitiveAppsLockedOrRemoved,
                        required: false
                    )
                    checklistToggle(
                        title: "I have enabled Apple Repair State / Samsung Maintenance Mode if supported",
                        isOn: $store.draftPrivacyChecklist.maintenanceModeEnabledIfSupported,
                        required: false
                    )
                    Divider()
                    checklistToggle(
                        title: "Visible device condition & pre-existing dents/cracks are noted",
                        isOn: $store.draftPrivacyChecklist.physicalConditionRecorded,
                        required: true
                    )
                    checklistToggle(
                        title: "I understand I should NEVER share my passcode upfront; unlocking is only done in my presence during post-repair testing",
                        isOn: $store.draftPrivacyChecklist.unlockPasscodePolicyUnderstood,
                        required: true
                    )
                    checklistToggle(
                        title: "I consent to hardware diagnostic inspection at my doorstep",
                        isOn: $store.draftPrivacyChecklist.consentsToDiagnosticInspection,
                        required: true
                    )
                }
            }
        }
    }
    
    private func checklistToggle(title: String, isOn: Binding<Bool>, required: Bool) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundColor(isOn.wrappedValue ? TCTheme.teal : .secondary)
                    .font(.subheadline)
                Text(title + (required ? " *" : ""))
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section 15: Rule-Based Local AI Symptom Categorisation Sheet

struct AISymptomAssistantSheet: View {
    @ObservedObject var store: TechCareStore
    var onApplySuggestion: (DeviceCategory, IssueCategory, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var userSymptomInput: String = "My laptop becomes very hot and shuts down after 15 minutes."
    @State private var selectedCategoryOverride: DeviceCategory? = nil
    @State private var followUpAnswers: [String: Bool] = [:]
    
    var suggestion: AISymptomSuggestion {
        LocalAISymptomClassifier.analyze(
            symptomText: userSymptomInput,
            selectedCategory: selectedCategoryOverride
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TCCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                TCBadge(text: "LOCAL RULE-BASED AI TRIAGE", icon: "sparkles", color: TCTheme.teal)
                                Spacer()
                            }
                            Text("Describe Your Device Symptoms")
                                .font(.headline)
                            Text("Type what your gadget is doing in plain English. This assistant helps classify the issue and match technician skills—it does not replace physical hardware inspection.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $userSymptomInput)
                                .frame(height: 85)
                                .padding(8)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    samplePromptChip("My laptop becomes very hot and shuts down after 15 minutes.")
                                    samplePromptChip("iPhone screen has a green line and touch stops working.")
                                    samplePromptChip("Phone battery drains fast and back cover feels swollen.")
                                    samplePromptChip("PS5 DualSense left stick drifts to the left.")
                                }
                            }
                        }
                    }
                    
                    // Suggested Categorisation Output
                    TCCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: suggestion.detectedCategory.icon)
                                    .foregroundColor(TCTheme.teal)
                                Text("Detected Category: \(suggestion.detectedCategory.rawValue)")
                                    .font(.subheadline.weight(.bold))
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Likely Problem Categories:")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                                ForEach(suggestion.suggestedIssues) { issue in
                                    HStack {
                                        Image(systemName: issue.icon)
                                            .foregroundColor(TCTheme.teal)
                                        Text(issue.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text("\(INRFormatter.format(issue.indicativeRangeINR.min))–\(INRFormatter.format(issue.indicativeRangeINR.max))")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(TCTheme.navy)
                                    }
                                    .padding(10)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Recommended Technician Skills:")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                                FlowTagsView(tags: suggestion.relevantSkills)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Diagnostic Follow-Up Questions:")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                                ForEach(suggestion.followUpQuestions, id: \.self) { q in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "questionmark.Bubble.fill")
                                            .foregroundColor(TCTheme.info)
                                        Text(q)
                                            .font(.caption)
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(TCTheme.info.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(TCTheme.warning)
                                Text(suggestion.safetyRecommendation)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding(10)
                            .background(TCTheme.warning.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Text("Disclaimer: This is an automated symptom classification to route the right specialist. Confirmed diagnosis requires in-person inspection.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        let primaryIssue = suggestion.suggestedIssues.first ?? .hardwareDiagnosis
                        onApplySuggestion(suggestion.detectedCategory, primaryIssue, userSymptomInput)
                        dismiss()
                    } label: {
                        Text("Apply Classification to Repair Request")
                    }
                    .buttonStyle(TCPrimaryButtonStyle())
                }
                .padding(18)
            }
            .background(TCTheme.background)
            .navigationTitle("AI Issue Categoriser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func samplePromptChip(_ text: String) -> some View {
        Button {
            userSymptomInput = text
        } label: {
            Text(text)
                .font(.caption2)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(TCTheme.tealSoft)
                .foregroundColor(TCTheme.teal)
                .clipShape(Capsule())
        }
    }
}

struct FlowTagsView: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    TCBadge(text: tag, icon: "wrench.and.screwdriver.fill", color: TCTheme.deepBlue)
                }
            }
        }
    }
}

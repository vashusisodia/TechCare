# TechCare — On-Demand & Emergency Doorstep Veterinary Platform

TechCare is a native iOS application developed in **SwiftUI**, **MapKit**, and **Combine**. The platform connects pet owners with veterinary doctors and emergency surgeons for on-demand home visits, rapid diagnostic triage, real-time dispatch, and digital medical record (EMR) management.

---

## Engineering Team

| Engineer | Roll No. | Core Domain | Technical Ownership |
| :--- | :--- | :--- | :--- |
| **Gyanendra Singh Pal** | `2502221530075` | **UI/UX, Frontend Architecture & Release/QA** | • Native SwiftUI component library, design tokens, and branding assets (`TechCareLogoView`)<br>• Multi-stage onboarding and booking funnel views (`OwnerAndPetInfoView`, `SelectPetView`, `DescribeIssueView`)<br>• Modal presentation layers (`BreedPickerSheet`, `PrescriptionInvoiceModalView`)<br>• Dynamic Type, dark mode compliance, and responsive layouts across iPhone and iPad<br>• Build schemes, signing, and entitlements; unit tests and XCUITest UI regressions<br>• iOS permission strings (`NSLocationWhenInUseUsageDescription`) and TestFlight / App Store deployment |
| **Vashu Sisodia** | `2502221530202` | **State Management, Domain Models, Backend & Geospatial** | • Reactive state engine built with `BookingFlowData: ObservableObject`<br>• Core domain models (`PetCategory`, `Veterinarian`, `PastVisitRecord`)<br>• Triage business logic, urgency filtering, and symptom/behaviour state handling<br>• MapKit integration and coordinate mapping for nearby doctors and clinics (`NearbyDoctorsMapView`, `MapLocationPickerSheet`)<br>• Service layer for medical specializations, emergency dispatch call bridge, and prescription/invoice data contracts<br>• Client profile caching, account autofill, and persistence |

> Work split: Gyanendra owns everything the user sees and ships (presentation, testing, release). Vashu owns everything behind it (state, domain, location and data services). Both review each other's pull requests at the boundary — the views bind to `BookingFlowData`.

---

## System Architecture

The application follows the **MVVM (Model-View-ViewModel)** pattern, using Apple's `Combine` framework for predictable, unidirectional data flow.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                           │
│                                                                        │
│   ContentView ────────► InitialWelcomeSplashScreen ──► MainDashboard   │
│        │                                                      │        │
│        ▼                                                      ▼        │
│   OwnerAndPetInfoView ──► SelectPetView ──► DescribeIssueView         │
│        │                                           │                   │
│        ▼                                           ▼                   │
│   MapLocationPickerSheet                  NearbyDoctorsMapView         │
│                                                    │                   │
│                                                    ▼                   │
│                                           PastCheckedVetsView          │
│                                                    │                   │
│                                                    ▼                   │
│                                       PrescriptionInvoiceModalView     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                       Bi-directional State Binding
                      (@ObservedObject / @Published)
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        REACTIVE STATE & LOGIC                          │
│                                                                        │
│                         BookingFlowData                                │
│   • Identity & Context : User profile, contact, registered geocoords   │
│   • Booking Pipeline   : Active patient attributes, breed resolution   │
│   • Clinical Triage    : Symptom selection, behaviour logs, urgency    │
│   • Records Management : Order history, prescriptions, billing cache   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                            Immutable Projections
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                             DOMAIN LAYER                               │
│                                                                        │
│   • PetCategory       : Taxonomy metadata and breed registries         │
│   • Veterinarian      : Certifications, skills, estimated arrival      │
│   • PastVisitRecord   : Clinical record, diagnostics, invoices         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Key Features

* **Guided booking funnel** — owner details → pet selection → issue description → doctor selection.
* **Emergency triage** — symptom and urgency capture so critical cases are prioritised.
* **Nearby doctors on a map** — MapKit-based discovery of available veterinarians and clinics.
* **Location picker** — set or adjust the visit address with a map sheet.
* **Visit history** — review previously consulted vets (`PastCheckedVetsView`).
* **Digital prescriptions & invoices** — view medication plans and billing in a modal (`PrescriptionInvoiceModalView`).
* **Emergency call shortcut** — one-tap dial to the dispatch helpline.

---

## Tech Stack

| Area | Technology |
| :--- | :--- |
| Language | Swift 5 |
| UI | SwiftUI |
| Reactive state | Combine (`ObservableObject`, `@Published`) |
| Maps & location | MapKit, CoreLocation |
| Architecture | MVVM |
| IDE / Build | Xcode, automatic code signing |
| Targets | iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2,7`), iOS 27.0 deployment target |
| Current version | 1.0 |

---

## Getting Started

1. Clone or unzip the repository.
2. Open `TechCare.xcodeproj` in Xcode.
3. Select the **TechCare** scheme and an iPhone or iPad simulator.
4. In *Signing & Capabilities*, choose your own Team (the bundle identifier is currently a placeholder) if you want to run on a device.
5. Press **⌘R** to build and run.

### Permissions

| Key | Purpose |
| :--- | :--- |
| `NSLocationWhenInUseUsageDescription` | Find nearby doctors and set the visit address |

---

## Project Structure

```text
TechCare/
├── TechCare.xcodeproj
└── TechCare/
    ├── App & Entry        (TechCareApp, ContentView, splash screen)
    ├── Views              (booking funnel, dashboard, map, history, modals)
    ├── State              (BookingFlowData)
    ├── Models             (PetCategory, Veterinarian, PastVisitRecord)
    └── Assets             (logo, colours, icons)
```

---

## Roadmap

* Live dispatch tracking and arrival ETA
* Backend sync and user authentication
* Push notifications for booking status
* Online payments and downloadable invoices

---

## Academic Details

Developed as a team project by:

* **Gyanendra Singh Pal** — Roll No. `2502221530075`
* **Vashu Sisodia** — Roll No. `2502221530202`

**Project Mentor**: _add mentor name here_

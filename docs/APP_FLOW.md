# AgroZemex - End-to-End Application & User Flow Specification

This document details the complete operational flow of the AgroZemex application for software engineers, product handovers, and AI assistants.

---

## 1. Application Startup & Initialization Flow

When the user launches AgroZemex, the app executes a non-blocking initialization sequence to ensure fast startup times without ANR (Application Not Responding) hangs.

```mermaid
flowchart TD
    A[App Launch main.dart] --> B[WidgetsBinding.ensureInitialized]
    B --> C[Configure GoogleFonts Runtime Fallback]
    C --> D[Firebase.initializeApp]
    D --> E[Mount AppRoot Widget]
    E --> F[MultiProvider Setup]
    F --> G[Execute Non-blocking AppInit.initializeBackgroundServices]
    G --> H[Mapbox Token & Async Location Init]
    F --> I[RootDecider Check Auth State]
```

---

## 2. Authentication & Root Routing Decision Flow

`RootDecider` evaluates the user state and directs them to either the main app shell or the authentication screen.

```mermaid
flowchart TD
    A[RootDecider Built] --> B{AuthService.isLoading?}
    B -- Yes --> C[Show Circular Loading Spinner]
    B -- No --> D{Firebase User Logged In?}
    D -- Yes --> E[Navigate to MainNavigationShell]
    D -- No --> F[Read saved phone/email from SharedPreferences]
    F --> G{Saved Credential Exists?}
    G -- Yes --> H[Navigate to LoginScreen with Initial Phone]
    G -- No --> E[Navigate to MainNavigationShell as Guest]
```

---

## 3. Main Navigation Shell & Protected Tab Flow

`MainNavigationShell` acts as the persistent container hosting 5 primary screens using an `IndexedStack` to preserve state across tab switches.

```
+-------------------------------------------------------------------+
|                        IndexedStack Body                          |
|                                                                   |
|  Tab 0: HomeScreen          (Land Marketplace - Guest Accessible) |
|  Tab 1: CropHomeScreen      (Crop Marketplace - Guest Accessible) |
|  Tab 2: MapScreen           (Map Boundary Drawing - Protected)   |
|  Tab 3: CropSellScreen      (Sell Crop Listing   - Protected)   |
|  Tab 4: ProfileScreenDash   (User Dashboard      - Protected)   |
|                                                                   |
+-------------------------------------------------------------------+
|                   CustomBottomNav (5 Tab Buttons)                 |
+-------------------------------------------------------------------+
```

### Tab Protection Logic (`_onTabSelected`)

- **Unauthenticated Users**:
  - Can freely view **Tab 0 (HomeScreen)** and **Tab 1 (CropHomeScreen)**.
  - Tapping **Tab 2 (Sell Land/Map)**, **Tab 3 (Sell Crop)**, or **Tab 4 (Profile)** triggers a SnackBar notice (`Please log in to [action]`) and opens `LoginScreen` via modal navigation push.
- **Authenticated Users**:
  - Seamlessly switch between all 5 tabs without losing scroll position or form data thanks to lazy-loaded `IndexedStack`.

---

## 4. User Journeys & Workflow Diagrams

### 4.1 Authentication & Legal Consent Workflow

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as LoginScreen / CreatePasswordScreen
    participant Auth as AuthService
    participant FS as UserFirestoreService
    participant Local as SharedPreferences

    User->>UI: Select Login Method (Phone/Email/Social) & Check T&C Consent Box
    UI->>UI: Validate T&C Checkbox Checked (Block if Unchecked)
    UI->>Auth: signInWithEmailAndPassword() / sendOtp() / signInWithGoogle()
    Auth->>FS: createUserIfNotExists(user, agreedToTerms: true)
    FS-->>Auth: Profile Record Updated (agreedToTerms, termsAgreedAt)
    Auth->>Local: saveEmailToPrefs() / savePhoneToPrefs()
    Auth-->>UI: Authentication Success
    UI->>User: Redirect to MainNavigationShell
```

### 4.2 Details Screen Access & Phone Binding Guard

```mermaid
flowchart TD
    A[User Taps Land/Crop Card] --> B{User Logged In?}
    B -- No --> C[Prompt LoginScreen]
    B -- Yes --> D{Phone Number & T&C Verified in Profile?}
    D -- Yes --> E[Open ListingDetailScreen / CropDetailScreen]
    D -- No --> F[Open PhoneBindingDialog Bottom Sheet]
    F --> G[Input Phone Number & Check Legal Consent Box]
    G --> H[Enter SMS OTP Code]
    H --> I[Execute linkOrUpdateUserPhoneWithOtp]
    I --> J{Verification Success?}
    J -- No --> G
    J -- Yes --> E
```

---

### 4.2 Interactive GIS Land Boundary Drawing & Listing Creation Flow

The land seller draws a polygon boundary on Mapbox satellite imagery to automatically calculate land area in Acres/Hectares.

```mermaid
flowchart TD
    A[User Opens MapScreen Tab 2] --> B[Mapbox Satellite Map Loaded]
    B --> C[User Taps Map to Add Polygon Corner Points]
    C --> D[BoundaryService Renders Live Polyline & Polygon]
    D --> E[AreaStatsPanel Computes Live Land Area in Acres & Hectares]
    E --> F{Minimum 3 Points Set?}
    F -- No --> C
    F -- Yes --> G[User Taps Next / Save Listing]
    G --> H[Open Land Details Form]
    H --> I[Upload Land Images to Firebase Storage]
    I --> J[Write Listing Document to Firestore 'listings' Collection]
    J --> K[Show Success Confirmation & Redirect to Home]
```

---

### 4.3 Land & Crop Marketplace Search & Discovery Flow

```mermaid
flowchart TD
    A[Buyer Opens Home / Crop Marketplace] --> B[Enter Query or Select Category Filter]
    B --> C[ListingSearchService / CropSearchService Triggers]
    C --> D[Generate Lowercase Search Tokens]
    D --> E[Query Firestore with arrayContains Any searchTokens]
    E --> F[Apply Location & Distance Sorting via LocationService]
    F --> G[Render Filtered Listing Cards]
    G --> H[User Taps Card -> Open ListingDetailScreen / CropDetailScreen]
    H --> I[View Details, Photos, Boundary Map, Contact Seller]
```

---

### 4.4 Wishlist & Seller Management Flow

- **Saving Listings**: Users tap the heart icon on any land or crop card to toggle items in their wishlist saved via `WishlistService` in Firestore.
- **Seller Dashboard (`SellerDashboard`)**: Sellers can view their posted listings, track status, edit details, or remove active listings.
- **Admin Control (`AdminPanel`)**: Administrative users can manage platform users, review flagged listings, and monitor platform metrics.

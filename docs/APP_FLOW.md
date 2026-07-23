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

### 4.3 Site Visit Booking & Seller Request Workflow

```mermaid
flowchart TD
    A[Buyer Opens ListingDetailScreen] --> B{Active Booking Exists?}
    B -- Yes: Pending --> C[Lock Action Button: Visit Pending 🔒 Amber]
    B -- Yes: Confirmed --> D[Lock Action Button: Visit Scheduled ✓ Green]
    B -- No / Cancelled --> E[Show Active Book Visit Button]
    E --> F[Buyer Taps Book Visit & Verifies Phone/Terms]
    F --> G[Open BookVisitSheet Date & Time Picker]
    G --> H[Submit Booking Request to Firestore visit_bookings]
    H --> I[Button Dynamically Updates & Locks to Visit Pending]
    H --> J[Seller Dashboard Displays Incoming Visit Request]
    J --> K[Seller Updates Status to Confirmed]
    K --> L[ListingDetailScreen Button Updates in Real-Time to Visit Scheduled]
```

### 4.4 Seller Contact Privacy & Anti-Misuse Consent Workflow

```mermaid
flowchart TD
    A[Land Seller Phone Masked by Default on Card] --> B[Buyer Taps Show Phone Number]
    B --> C{Buyer Authenticated & Phone Verified?}
    C -- No --> D[Trigger Login / PhoneBindingDialog]
    C -- Yes --> E[Open SellerContactDisclaimerDialog]
    E --> F[Display Anti-Misuse Policy & Warning]
    F --> G{Buyer Accepts [x] Anti-Misuse Checkbox?}
    G -- No --> H[Cancel & Keep Phone Masked]
    G -- Yes --> I[Unmask Seller Phone Number on Card]
```

### 4.5 Dynamic Land Specification & Persona Display Flow

```mermaid
flowchart TD
    A[Buyer Opens ListingDetailScreen] --> B[Execute _fetchListingData from Firestore]
    B --> C[Render Lister Persona Badge e.g. Direct Owner vs Agent]
    B --> D[Render Land Category Badge e.g. Agricultural vs Orchard]
    B --> E[Convert Land Area into Acres, Bigha, and Sq. Meters]
    B --> F[Render Technical Specifications Bento Grid]
    F --> G[Display Soil Type, Water Source, 3-Phase Power, Road Access, Fencing, and Ownership Title]
### 4.6 Swipeable Photo Gallery & Fullscreen Pinch-to-Zoom Lightbox

```mermaid
flowchart TD
    A[Buyer Views ListingDetailScreen Hero Section] --> B[Render PageView.builder Photo Carousel]
    B --> C[User Swipes Left / Right Across Uploaded Land Photos]
    C --> D[Update PageController & _currentPhotoIndex]
    D --> E[Update Live Photo Badge Count e.g. 2 / 5 and Active Dot Indicator]
    B --> F[User Taps Any Hero Photo]
    F --> G[Open Fullscreen Lightbox Modal with InteractiveViewer]
    G --> H[Enable Pinch-to-Zoom and Panning Across High-Res Land Images]
### 4.7 Multi-Platform & WhatsApp Land Listing Sharing Flow

```mermaid
flowchart TD
    A[User Taps Share Icon on ListingDetailScreen AppBar] --> B[Open AgroZemex Share Bottom Sheet Modal]
    B --> C[Option 1: Tap Share on WhatsApp]
    C --> D[Generate Formatted Message with Title, Price, Acres/Bigha & Location]
    D --> E[Launch WhatsApp wa.me Scheme with Encoded Text]
    B --> F[Option 2: Tap Share via Other Apps]
    F --> G[Invoke Native Device System Share Sheet share_plus]
    B --> H[Option 3: Tap Copy Share Details]
    H --> I[Copy Formatted Summary to Device Clipboard & Show SnackBar]
### 4.8 Land Home Screen Shimmer Skeleton Loading Flow

```mermaid
flowchart TD
    A[Buyer Navigates to HomeScreen] --> B{_listings.isEmpty && _isLoading?}
    B -- Yes: Initial Load --> C[Render 3 Vertical LandCardShimmer Skeleton Cards]
    B -- No --> D{_listings.isEmpty && !_isLoading?}
    D -- Yes: No Results --> E[Display No Listings Found Text]
    D -- No: Listings Present --> F[Render CustomScrollView with Property Cards]
    F --> G[User Scrolls to Bottom triggering _loadMore]
    G --> H[Append 1 LandCardShimmer Card at Bottom of SliverList]
    H --> I[Firestore Returns Next Page -> Replace Shimmer with Actual Property Card]
### 4.9 Real-Time Connectivity Monitoring & Offline Banner Flow

```mermaid
flowchart TD
    A[ConnectivityService Listens to Hardware & Active Socket Ping] --> B{Internet Connection Active?}
    B -- No / Network Dropped --> C[Update ConnectivityService isConnected = false]
    C --> D[OfflineBanner Animates Down Top Amber/Red Bar]
    D --> E[Display 📡 No Internet Connection • Offline Mode]
    B -- Yes / Network Restored --> F{Was App Previously Offline?}
    F -- Yes --> G[Update ConnectivityService isConnected = true]
    G --> H[OfflineBanner Animates Green Bar: ✓ Connection Restored]
    H --> I[Auto-Dismiss Green Banner After 3 Seconds]
### 4.10 Hive Offline Data Caching & Fallback Flow

```mermaid
flowchart TD
    A[App Startup main.dart] --> B[Execute HiveCacheService.init]
    B --> C[Open land_listings_box, crop_listings_box, and user_preferences_box]
    D[Query Engine: ListingQueryService / CropQueryService] --> E{Network Online & Firestore Query Successful?}
    E -- Yes --> F[Parse Firestore Snapshot Documents]
    F --> G[Asynchronously Write Raw Maps to Hive Cache Boxes]
    F --> H[Return Live Marketplace Models to UI]
    E -- No / Exception --> I[Trigger Catch Block: Hive Cache Fallback]
    I --> J[Read Raw Maps from Hive Cache Boxes]
    J --> K[Parse Cached Maps into Models]
    K --> L[Render Cached Land & Crop Listings on UI Offline]
### 4.11 WGS-84 Survey-Grade Land Area Calculation & Unit Conversion Flow

```mermaid
flowchart TD
    A[Seller Draws Polygon Points on MapScreen] --> B[Calculate Centroid Latitude phi_c in Radians]
    B --> C[Compute WGS-84 Authalic Radius of Curvature R_phi_c]
    C --> D[Execute Spherical Integration with Effective Radius R_phi_c]
    D --> E[Check Boundary Points for Line Segment Crossings via hasSelfIntersection]
    E -- Self-Intersection Detected --> F[Display ⚠️ Crossing Lines Status on AreaStatsPanel]
    E -- Polygon Valid --> G[Pass Area in sq. m to LandAreaUnitConverter]
    G --> H[Convert to Acres, Bigha, Guntha, and Hectares with 99.95%+ Precision]
    H --> I[Render Land Area Stats & Enable Publish Button]
### 4.12 Resilient & Normalized Crop Query Flow

```mermaid
flowchart TD
    A[Buyer Opens CropHomeScreen] --> B[Execute CropQueryService.fetchNextPage]
    B --> C[Query Active Crops Order By created_at DESC]
    C --> D[Retrieve Firestore Documents or Hive Offline Cache]
    D --> E[Execute _applyFilters In-Memory Filtering]
    E --> F[Perform Normalized Case-Insensitive Crop Type Matching]
    E --> G[Evaluate Price Range Filters only if Explicitly Activated by User]
    G --> H[Render All Active Harvest Listings on Crop Marketplace UI]
```

### 4.13 Hardened Crop Listing Creation & Communication Flow

```mermaid
flowchart TD
    A[Farmer Opens CropSellScreen] --> B[PopScope Guard Intercepts Unsaved Navigations]
    B --> C[Select Up to 5 Harvest Photos via pickMultiImage]
    C --> D[Fetch Fast GPS Location with 5s Timeout Fallback]
    D --> E[Validate Positive Price and Quantity Numerical Fields]
    E --> F[Upload Images & Save Crop to Firestore & Hive Cache]
    F --> G[Buyer Opens CropDetailScreen]
    G --> H[View Harvest Details & Inline Verified Seller Card]
    H --> I{Select Seller Action}
    I -- Reveal Phone --> J[Toggle Masked Phone with Verification Guard]
    I -- Call Seller --> K[Trigger Direct Phone Dial tel:]
    I -- WhatsApp --> L[Launch Direct WhatsApp Chat whatsapp://]
    I -- SMS --> M[Launch Direct SMS Composer sms:]
```

### 4.14 Universal Image Engine & ANR Crash Prevention Flow

```mermaid
flowchart TD
    A[Buyer Taps Crop Card on Marketplace] --> B[Push CropDetailScreen with 3s Verification Timeout Guard]
    B --> C[Pass Image Path to UniversalImageWidget]
    C --> D{Evaluate Image Path Format}
    D -- Starts with http / https --> E[Render Remote Network Image via Image.network]
    D -- Local File Path / file:// --> F[Verify File Existence & Render via Image.file]
    D -- Asset Path --> G[Render Local Asset via Image.asset]
    D -- Invalid / Error --> H[Render Fallback Surface Container with Eco Icon]
    E & F & G & H --> I[Display Crop Detail Screen Smoothly without Main Isolate ANR Hang]
```

### 4.15 Firestore-to-Hive JSON Sanitization & Deserialization Flow

```mermaid
flowchart TD
    A[Firestore Query Returns Raw Snapshot Documents] --> B[Execute HiveCacheService._sanitizeForJson Map Transformer]
    B --> C[Convert Timestamp to millisecondsSinceEpoch int]
    B --> D[Convert GeoPoint to lat lng Map]
    C & D --> E[Pass Sanitized Map to jsonEncode]
    E --> F[Persist Clean JSON String into Hive Cache Box]
    F --> G[Offline Fallback: Read JSON String & Parse via jsonDecode]
    G --> H[CropCardModel / ListingCardModel.fromMap Parses Int & Map Primitives]
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

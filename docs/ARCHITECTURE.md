# AgroZemex - Software Architecture & Technical Documentation

## 1. Executive Summary & Project Goal
**AgroZemex** is a mobile/web application designed for agricultural real estate (land marketplace) and crop trading. It enables users to browse, list, buy, and sell agricultural land and crop harvests with interactive GIS Mapbox boundary drawing, location-aware search, real-time filtering, and role-based account management.

---

## 2. Architectural Paradigm

AgroZemex follows **Clean Architecture** principles combined with a **Feature-First** project structure. This separation guarantees testability, maintainability, loose coupling, and clear boundaries between UI, business logic, and external services.

```
lib/
├── core/                   # System initialization, global app root, and design tokens
│   ├── app_root.dart       # Main MultiProvider and global AppRoot widget
│   ├── init.dart           # Asynchronous background service initialization
│   └── theme/              # Design tokens (colors, typography, light theme)
├── features/               # Feature-First Business Modules
│   ├── admin/              # Administrative control panel
│   ├── auth/               # Authentication (Login, Password creation, Auth Service)
│   ├── crops/              # Crop marketplace (Home, Details, Sell, Query/Search)
│   ├── home/               # Land marketplace (Listings, Filters, Buyer Maps)
│   ├── maps/               # Interactive Mapbox GIS polygon drawing & area calculation
│   ├── navigation/         # Central navigation shell & tab management
│   ├── welcome/            # Onboarding & landing screens
│   └── wishlist/           # User saved listings & bookmarks
└── shared/                 # Shared cross-cutting services and widgets
    ├── services/           # Firestore, Storage, Location, Distance, Search tokens
    └── widget/             # Shared UI components (Land & Crop cards)
```

### Core Architecture Layers

1. **Presentation Layer (`screens/`, `widgets/`)**:
   - Contains UI screens and reusable widgets.
   - Listens to providers for reactive UI updates.
   - Delegates state changes and network actions to service layers.

2. **Business Logic & Service Layer (`services/`)**:
   - Encompasses authentication logic (`AuthService`), user state, querying engines (`ListingQueryService`, `CropQueryService`), and search algorithms (`ListingSearchService`, `SearchRankService`).
   - Manages non-blocking background initialization (`AppInit`).

3. **Data Layer & External Integrations (`shared/services/`)**:
   - Communicates with external services: **Firebase Cloud Firestore**, **Firebase Auth**, **Firebase Storage**, **Mapbox SDK**, and **Geolocator**.
   - Handles client-side indexing and search token generation (`search_token_service.dart`).

---

## 3. Tech Stack & Dependencies

### Core Framework & UI
- **Flutter SDK** (`^3.10.3`): Cross-platform UI toolkit.
- **Google Fonts (`Inter`)**: Typography design system with bundled offline `.ttf` font assets.
- **`sliding_up_panel`**: Sliding panel interface for land area stats and map details.

### Backend & Cloud Services
- **Firebase Core & Auth**: Handles identity management, email/password auth, Google Sign-In, and Apple Sign-In.
- **Cloud Firestore**: Real-time NoSQL database for users, land listings, crop listings, and wishlists.
- **Firebase Storage**: Secure cloud storage for image assets (crop photos, land site images).
- **Cloud Functions**: Serverless backend routines.

### Mapping & Location (GIS)
- **`mapbox_maps_flutter`**: Map rendering, polygon creation, boundary calculations, and satellite map layers.
- **`BoundaryService` (`features/maps/services/boundary_service.dart`)**: Geodesic area calculation engine utilizing WGS-84 ellipsoidal authalic radius correction ($R(\phi_c)$) at centroid latitude for survey-grade precision (>99.95% accuracy) and polygon self-intersection detection (`hasSelfIntersection`).
- **`LandAreaUnitConverter` (`shared/services/land_area_unit_converter.dart`)**: High-precision unit conversion service standardizing **Square Meters**, **Acres**, **Bigha**, **Guntha**, and **Hectares**.
- **`geolocator` & `permission_handler`**: User device GPS location tracking and dynamic permissions management.

### Network Connectivity & Offline Architecture
- **`ConnectivityService` (`core/services/connectivity_service.dart`)**: Reactive network monitor extending `ChangeNotifier`. Listens to hardware connectivity changes via `connectivity_plus` and verifies WAN internet reachability using active socket pings.
- **`OfflineBanner` (`shared/widget/offline_banner.dart`)**: Animated global top banner providing real-time visual feedback when internet connection drops (`📡 Offline Mode Active`) or reconnects (`✓ Connection Restored`).
- **`HiveCacheService` (`shared/services/hive_cache_service.dart`)**: High-performance key-value disk caching layer (`hive_flutter`). Manages `land_listings_box`, `crop_listings_box`, and `user_preferences_box`. Includes `_sanitizeForJson` recursive transformer converting Cloud Firestore custom instances (`Timestamp`, `GeoPoint`) to primitive JSON types (`int`, `Map`) to eliminate binary encoding exceptions. Automatically synchronizes online Firestore payloads to local disk and triggers transparent offline fallbacks in `ListingQueryService` and `CropQueryService`.

### Crops Marketplace Engine
- **`CropSellScreen` (`features/crops/screens/crop_sell_screen.dart`)**: Form-hardened harvest creation interface with `PopScope` unsaved draft protection, multi-image batch picker (`pickMultiImage`), 5s GPS location timeout fallback, and strict positive validation.
- **`CropDetailScreen` (`features/crops/screens/crop_detail_screen.dart`)**: Streamlined harvest detail screen featuring an inline Land-Style Verified Crop Seller Card with phone reveal, direct Call (`tel:`), WhatsApp (`whatsapp://`), and SMS (`sms:`) actions.
- **`CropCardShimmer` (`shared/widget/crop_card_shimmer.dart`)**: Skeleton loading widget providing smooth visual feedback on `CropHomeScreen` initial load and pagination.
- **`UniversalImageWidget` (`shared/widget/universal_image_widget.dart`)**: Universal production-grade image renderer routing network URLs, local file paths, and assets with fallback boundaries to eliminate main-isolate ANR freezes.

---

## 4. State Management & Dependency Injection

AgroZemex employs `provider` for dependency injection and state management.

```dart
// MultiProvider configuration in AppRoot
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    Provider(create: (_) => UserFirestoreService()),
    Provider(create: (_) => ListingQueryService()),
    Provider(create: (_) => ListingSearchService()),
    Provider(create: (_) => StorageService()),
    Provider(create: (_) => CropQueryService()),
    Provider(create: (_) => CropSearchService()),
    Provider(create: (_) => WishlistService()),
    Provider<LocationService>(create: (_) => AppInit.locationService),
  ],
  child: MaterialApp(...),
)
```

### Key Service Roles
- **`AuthService`**: Manages current `User` session, login/registration, password reset, and local user preference persistence via `SharedPreferences`.
- **`LocationService`**: Non-blocking background GPS tracking to fetch user coordinates without delaying startup.
- **`ListingQueryService` & `CropQueryService`**: Query builders executing paginated and filtered queries against Firestore collections.

---

## 5. Firestore Database Schemas

### `users` Collection
| Field | Type | Description |
| :--- | :--- | :--- |
| `uid` | String | Unique Firebase Auth identifier |
| `name` | String | User full name / Display name |
| `displayName` | String | User full name alias |
| `photoUrl` | String | Firebase Storage custom profile picture URL |
| `email` | String | User email address |
| `phone` | String | Verified contact phone number |
| `role` | String | User role (`buyer`, `seller`, `admin`) |
| `agreedToTerms` | Boolean | True if user accepted T&C and Privacy Policy |
| `termsAgreedAt` | Timestamp | Timestamp when T&C legal consent was given |
| `createdAt` | Timestamp | Account creation timestamp |

### `listings` Collection (Land Marketplace)
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Listing ID |
| `title` | String | Land listing title |
| `price` | Double | Land price in ₹ |
| `area_sq_m` | Double | Land area in square meters |
| `lister_type` | String | Persona (`owner`, `agent`, `builder`) |
| `land_category` | String | Land usage (`Agricultural`, `Orchard`, `Commercial`, `Barren`) |
| `ownership_status` | String | Title status (`Single Owner`, `Joint Family`, `POA`) |
| `electricity_available`| Boolean | True if 3-Phase agricultural power available |
| `is_fenced` | Boolean | True if barbed wire / boundary wall installed |
| `road_access` | Boolean | True if direct tar/asphalt road access |
| `location` | GeoPoint / Map | Latitude & longitude coordinates |
| `boundary_points` | Array<Map> | LatLng polygon boundary coordinates |
| `photo_paths` | Array<String> | Firebase Storage image URLs |
| `created_by` | String | Reference UID to `users` |
| `search_tokens` | Array<String> | Lowercase prefix search tokens for indexing |

### `crops` Collection (Crop Marketplace)
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Crop listing ID |
| `cropName` | String | Name of the crop (e.g. Wheat, Rice) |
| `pricePerKg` | Double | Price per unit weight |
| `quantityAvailable`| Double | Quantity in kilograms / tons |
| `sellerId` | String | Reference UID to `users` |
| `images` | Array<String> | Firebase Storage image URLs |

### `visit_bookings` Collection (Site Visit Requests)
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique booking document ID |
| `listing_id` | String | Target land listing ID |
| `listing_title` | String | Land listing title |
| `buyer_id` | String | Reference UID to `users` (buyer) |
| `buyer_name` | String | Full name of the buyer |
| `buyer_phone` | String | Verified contact phone number of the buyer |
| `seller_id` | String | Reference UID to `users` (seller) |
| `visit_date` | Timestamp | Scheduled date & time for site visit |
| `status` | String | Request status (`pending`, `confirmed`, `completed`, `cancelled`) |
| `created_at` | Timestamp | Booking submission timestamp |

---

## 6. Security & Environment Configuration

### Credentials & Environment Variables
To ensure zero exposure of secret keys:
- Mapbox access tokens are supplied at build time via runtime environment flags (`--dart-define=MAPBOX_TOKEN=your_token`).
- Google Auth client IDs are supplied via environment flags (`--dart-define=GOOGLE_CLIENT_ID=your_id`).
- Local config files (`firebase_options.dart`) contain target platform metadata without exposing admin keys.

### Security Best Practices
- Validation of input forms (phone, email, password strength) prior to API submission.
- Protected navigation routes ensuring unauthenticated users cannot access listing creation or profile actions.

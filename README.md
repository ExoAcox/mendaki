# 🏔️ Mendaki - Indonesian Mountain Navigation & Tracking

An **Offline-First** mobile navigation and tracking application for Indonesian hiking trails, built with **Flutter**. Designed to help hikers safely navigate mountain routes with full GPX trail support, detailed waypoints, elevation profiles, and topographic map tile caching without requiring an internet connection in the wilderness.

---

## ✨ Key Features

- **🗺️ Offline-First Navigation Map**: Cache topographic map tiles and download GPX tracks to local device storage, enabling seamless navigation even with zero cellular signal.
- **📍 Rich Waypoints & Trail POIs**: Clear visual markers for mountain checkpoints (*pos*), water sources, campsites, basecamps, and summits with elevation in MASL (Meters Above Sea Level).
- **🧭 Dynamic Summit-Up Orientation & Live Compass**: Map automatically rotates so the mountain summit is directed upwards while you are hiking, paired with a live compass needle that always indicates true North.
- **⚠️ Smart Proximity Detection & Floating Alerts**: Real-time GPS distance calculation. If you are far from the mountain (> 15 km), the map stays centered on the trail with an unobtrusive floating notification.
- **📈 Interactive Elevation Profiles**: Visual elevation charts showing trail gain, distance breakdown, and estimated hiking duration.
- **☁️ Supabase Cloud & Stale-While-Revalidate**: Synchronize mountains catalog, hiking routes, and waypoints with Supabase Postgres, with automatic background synchronization for updated GPX files.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK ^3.10.8)
- **Map & Geolocation**:
  - [`flutter_map`](https://pub.dev/packages/flutter_map) ^8.3.2
  - [`latlong2`](https://pub.dev/packages/latlong2) ^0.10.1
  - [`geolocator`](https://pub.dev/packages/geolocator) ^14.1.2
- **Backend & Storage**:
  - [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) ^2.18.3
  - [`path_provider`](https://pub.dev/packages/path_provider) ^2.1.6
- **Data & Environment**:
  - [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) ^6.0.1
  - [`xml`](https://pub.dev/packages/xml) ^6.6.1 (GPX XML Parser)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (version 3.10.8 or higher)
- Android Studio / VS Code with Flutter & Dart extensions installed
- A [Supabase](https://supabase.com/) account (free tier works great)

### 1. Clone the Repository
```bash
git clone https://github.com/<your-username>/mendaki.git
cd mendaki
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Environment Variables (`.env`)
Copy the provided environment template `.env.example` to `.env`:
```bash
cp .env.example .env
```
Open `.env` and fill in your Supabase project credentials:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key-here
GPX_BUCKET=gpx_file
```

> 🔒 **Security Notice**: The `.env` file is included in `.gitignore` to prevent sensitive credentials from ever being committed to public version control.

### 4. Setup Supabase Database & Storage
1. Open the **SQL Editor** in your Supabase dashboard.
2. Execute the DDL schema provided in [`supabase/schema.sql`](supabase/schema.sql) to create the `mountains`, `routes`, and `waypoints` tables.
3. In the Supabase dashboard, go to **Storage** and create a public bucket named `gpx_file` (or match the name configured in `GPX_BUCKET`).

### 5. Run the Application
Launch the app on your connected device or emulator:
```bash
flutter run
```

---

## 🧪 Testing & Code Quality

The repository comes with a comprehensive suite of unit and widget tests covering GPS calculations, waypoint rendering, offline storage, and UI flow:

```bash
# Run all tests
flutter test

# Run code analysis (linter)
flutter analyze
```

---

## 📂 Project Structure

```text
mendaki/
├── android/                 # Android native configuration
├── ios/                     # iOS native configuration
├── lib/
│   ├── core/
│   │   ├── config/          # Supabase & environment configuration
│   │   ├── services/        # GPX parser, Supabase client, & tile cache services
│   │   └── theme/           # Stitch Material 3 design system & palettes
│   ├── models/              # Data models: Mountain, Route, Waypoint
│   ├── screens/
│   │   ├── home_screen.dart        # Mountain catalog, search, and filter view
│   │   ├── detail_screen.dart      # Trail details, waypoints, & elevation stats
│   │   └── navigation_screen.dart  # Interactive live GPS map navigation
│   ├── widgets/
│   │   ├── detail/          # Mountain detail screen UI components
│   │   ├── home/            # Mountain cards, search bar, & filter chips
│   │   └── navigation/      # Custom map pins, compass needle, & radar markers
│   └── main.dart            # Application entry point
├── supabase/
│   └── schema.sql           # Database schema migration
├── test/                    # Widget and unit test suites
├── .env.example             # Environment variables template
└── pubspec.yaml             # Flutter dependencies and assets manifest
```

---

## 🤝 Contributing

Contributions are warmly welcomed! To contribute:
1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'feat: add amazing feature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

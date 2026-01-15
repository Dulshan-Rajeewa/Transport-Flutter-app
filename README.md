# KS Transport - Flutter App

A modern Flutter mobile application for KS Transport - a logistics and transportation management system. Track trips, manage expenses, and monitor your transport business profitability in real-time.

## Features

- **Trip Management**
  - Add and track trips with route, distance, and earnings
  - View complete trip history
  - Delete trips with confirmation

- **Expense Tracking**
  - Categorized expense tracking (Fuel, Maintenance, Toll, etc.)
  - Add descriptions and dates
  - View expense history
  - Delete expenses with confirmation

- **Dashboard Analytics**
  - Total earnings overview
  - Total expenses tracking
  - Net profit calculation
  - Total kilometers driven
  - Recent trips overview

- **Firebase Integration**
  - Real-time data synchronization
  - Cloud Firestore database
  - Automatic data persistence

- **User Interface**
  - Material Design 3
  - Light and Dark theme support
  - Responsive layouts
  - Pull-to-refresh functionality

## Tech Stack

- **Flutter SDK**: Latest stable version
- **State Management**: Provider
- **Navigation**: GoRouter
- **HTTP Client**: Dio & HTTP package
- **Local Storage**: SharedPreferences
- **UI Components**: Material 3
- **Typography**: Google Fonts

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  go_router: ^13.0.0
  firebase_core: ^3.6.0
  cloud_firestore: ^5.4.4
  google_fonts: ^6.1.0
  intl: ^0.19.0
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
```
```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── models/                   # Data models
│   ├── trip.dart
│   └── expense.dart
├── providers/                # State management
│   └── data_provider.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── trips_screen.dart
│   ├── expenses_screen.dart
│   ├── add_trip_screen.dart
│   └── add_expense_screen.dart
├── widgets/                  # Reusable widgets
│   └── dashboard_card.dart
├── services/                 # Firebase services
│   └── firebase_service.dart
└── utils/                    # Utilities and helpers
    └── theme.dart
```
``` Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK or Xcode (for iOS)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ks-transport
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Configuration

Update the API base URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'YOUR_API_URL';
```
### Firebase Configuration

The app is already configured with the Firebase project. The configuration is in `lib/services/firebase_service.dart`:

**Firebase Collections:**
- `trips` - Stores trip records with route, kilometers, earnings, and dates
- `expenses` - Stores expense records with type, amount, description, and dates

**Data Structure:**

Trips:
```dart
{
  route: String,
  kilometers: int,
  earnings: double,
  date: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Expenses:
```dart
{
  type: String,
  amount: double,
  description: String (optional),
  date: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```ndroid:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

**Web:**
## Firebase Setup

This app uses Firebase Firestore for data storage. The Firebase project is already configured with:

**Project ID:** kstransport-e0240  
**Collections:** `trips` and `expenses`

The app automatically syncs with Firebase Firestore in real-time.

## Features to Implement

- [ ] Export data to Excel/PDF
- [ ] Date range filtering
- [ ] Charts and graphs for analytics
- [ ] Trip categories
- [ ] Multiple vehicle support
- [ ] Backup and restore
- [ ] Offline mode support

**iOS:**
```bash
flutter build ios --release
```

## API Integration

The app is designed to work with a REST API backend. Update the `ApiService` class with your actual API endpoints and authentication logic.

Current mock data is provided for demonstration purposes.

## Features to Implement

- [ ] Complete API integration
- [ ] Map integration for tracking
- [ ] Push notifications setup
- [ ] Image upload for profile
- [ ] Payment gateway integration
- [ ] Multi-language support
- [ ] Offline mode support

## 📱 App Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/731d1e7b-af04-40f9-8a20-e68e7d4b8513" width="30%" />
  <img src="https://github.com/user-attachments/assets/4ce0f70e-a4d5-4628-a5fc-4bafe933ff97" width="30%" />
  <img src="https://github.com/user-attachments/assets/09a3dd7e-4cbd-42c7-9ef2-41b29ab2ff33" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/abb68d20-88e7-4d45-8865-885452c3ced2" width="30%" />
  <img src="https://github.com/user-attachments/assets/c7589a51-20bf-442c-bf50-666cebb664b4" width="30%" />
  <img src="https://github.com/user-attachments/assets/6219d65d-084d-4659-86e1-e92a0fee5e2f" width="30%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/681f119c-bfe1-4b87-a1fc-ef68109773f6" width="30%" />
  <img src="https://github.com/user-attachments/assets/75780c37-646c-40f9-9230-b6f89f5fca4e" width="30%" />
  <img src="https://github.com/user-attachments/assets/f83ea652-f98e-4f08-9e4d-e2bc2592e7b8" width="30%" />
</p>

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email dulshanrajeewa@gmail.com or create an issue in the repository.

## Acknowledgments

- Flutter team for the amazing framework
- Material Design for UI guidelines
- All contributors to the open-source packages used

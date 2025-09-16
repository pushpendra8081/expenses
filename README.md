
# Expense Tracker App

A comprehensive Flutter expense tracking application with OCR receipt scanning, AI-powered category suggestions, and detailed expense management features.

## Features

### 📱 Core Functionality
- **Expense Management**: Add, edit, delete, and view expenses
- **Receipt Scanning**: OCR-powered receipt scanning using Google ML Kit
- **Smart Categories**: AI-powered category suggestions based on merchant, amount, and historical data
- **Data Persistence**: Local storage using Hive database
- **Location Tracking**: Optional GPS location capture for expenses
- **Statistics & Analytics**: Detailed expense statistics and insights

### 🤖 AI-Powered Features
- **OCR Text Recognition**: Automatically extract amount, merchant, date, and notes from receipts
- **Smart Category Suggestions**: Multiple algorithms for intelligent expense categorization:
  - Rule-based merchant matching
  - Historical expense analysis
  - Amount-based heuristics
  - Combined confidence scoring

### 📊 Expense Categories
- Food & Dining
- Transportation
- Shopping
- Entertainment
- Bills & Utilities
- Healthcare
- Travel
- Education
- Personal Care
- Home & Garden
- Gifts & Donations
- Business
- Other

## Screenshots

*Screenshots will be added here*

## Installation

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android device or emulator (API level 21+)
- iOS device or simulator (iOS 11.0+)

### State Management
- **Riverpod**: Used for state management and dependency injection
- **Provider Pattern**: Clean separation of business logic and UI

### Database
- **Hive**: Local NoSQL database for fast, efficient data storage
- **Type Adapters**: Custom serialization for expense objects

### Services
- **OCR Service**: Google ML Kit integration for text recognition
- **Suggestion Service**: AI algorithms for category suggestions
- **Location Service**: GPS integration for expense location tracking

## Key Components

### Receipt Scan Screen
The main OCR functionality screen that:
- Captures receipts via camera or gallery
- Processes images using Google ML Kit
- Extracts expense data (amount, merchant, date)
- Provides AI-powered category suggestions
- Persists scan results for user review

### OCR Service
Handles all optical character recognition tasks:
- Image preprocessing and optimization
- Text extraction using ML Kit
- Pattern matching for amounts, dates, and merchants
- Error handling and validation

### Suggestion Service
Provides intelligent category suggestions using:
- **Rule-based matching**: Merchant name and keyword analysis
- **Historical analysis**: Learning from previous expenses
- **Amount heuristics**: Category suggestions based on expense amount
- **Confidence scoring**: Weighted combination of multiple algorithms

## Usage

### Adding Expenses
1. **Manual Entry**: Use the add expense screen to manually input expense details
2. **Receipt Scanning**: Use the scan feature to automatically extract expense data from receipts
3. **Category Selection**: Choose from suggested categories or select manually

### Receipt Scanning Workflow
1. Navigate to the receipt scan screen
2. Choose camera or gallery option
3. Capture or select receipt image
4. Review extracted data (amount, merchant, date)
5. Select from AI-suggested categories
6. Save the expense

### Viewing Expenses
- Browse all expenses in the main list
- Filter by category, date range, or search terms
- View detailed expense information
- Edit or delete existing expenses

## Dependencies

### Core Dependencies
```yaml
flutter:
  sdk: flutter
flutter_riverpod: ^2.4.9
hive: ^2.2.3
hive_flutter: ^1.1.0
```

### OCR & Image Processing
```yaml
google_mlkit_text_recognition: ^0.10.0
image_picker: ^1.0.4
```

### Storage & Persistence
```yaml
shared_preferences: ^2.2.2
path_provider: ^2.1.1
```

### Location Services
```yaml
geolocator: ^10.1.0
permission_handler: ^11.1.0
```

## Permissions

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

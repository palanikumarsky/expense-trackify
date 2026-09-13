# ExpenseTrackify

A cross-platform personal expense tracking app built with Flutter. Track spending, manage payment modes and categories, visualize trends, and export reports — fully offline, with all data stored locally on your device.

---

## Features

- **Dashboard & Analytics** — Summary cards, category-wise charts, and spending breakdowns by payment mode
- **Transaction Management** — Add, edit, and delete transactions with date, amount, category, payment mode, and description
- **Calendar View** — Browse transactions by date on an interactive calendar
- **Custom Categories & Payment Modes** — Create and manage your own categories (e.g. Food, Travel) and modes (e.g. UPI, Credit Card, Cash)
- **Accounts** — Organize transactions across multiple accounts
- **Export Reports** — Download transaction history as PDF or CSV with flexible date range filters
- **Offline-First** — All data is stored locally on-device; no account or internet connection required
- **Dark / Light Theme** — System-aware theming with manual override
- **Multi-currency Support** — Choose from USD, EUR, INR, GBP, JPY, and more

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | flutter_bloc / BLoC pattern |
| Local Database | Drift (SQLite) |
| Charts | fl_chart |
| PDF Generation | pdf + printing |

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.7.2`
- Dart SDK `^3.7.2`

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/expense-trackify.git
   cd expense-trackify
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Drift database code:
   ```bash
   dart run build_runner build
   ```

4. Run the app:
   ```bash
   flutter run
   ```

---

## Project Structure

```
lib/
├── config/
│   ├── database_config/   # Drift database setup
│   └── widgets/           # Shared UI components
├── constants/             # App-wide constants, colors, styles
├── modules/
│   ├── splash/            # Splash screen
│   ├── bottom_navigation_bar/ # App shell navigation
│   ├── home/              # Dashboard & summary
│   ├── transactions/      # Transaction list & detail
│   ├── create_transaction/# Add / edit transaction form
│   ├── calendar/          # Calendar view
│   ├── settings/          # Settings, categories, modes, currency
│   ├── profile/           # User profile & accounts
│   ├── dao/               # Data access objects
│   └── theme/             # Theme management
└── utils/                 # Helpers for DB, dates, files
```

---

## Platform Support

| Platform | Status |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Windows | ✅ |

---

## License

This project is private and not published to pub.dev.

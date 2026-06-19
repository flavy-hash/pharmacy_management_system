# PharmaCare — Pharmacy Management System

A production-ready, offline-first **Pharmacy Management System** built with **Flutter**, **Riverpod** and a local **SQLite** database. It covers medicine inventory, real-time stock tracking, expiry monitoring with local notifications, point-of-sale billing with multiple payment methods, digital PDF receipts, dashboards, reports and role-based authentication.

---

## 1. Features

| Module | Highlights |
|---|---|
| **Medicine Management** | Register / edit / delete medicines, searchable & category-filtered list, full details (batch, manufacturer, prices, mfg/expiry dates). |
| **Stock Management** | Real-time quantity tracking, stock availability **percentage**, colour-coded status (sufficient / low / out), automatic low-stock detection. |
| **Expiry Monitoring** | Flags items expiring within **5 days**, separate "expired" view, local push notifications on login. |
| **Sales & Billing** | Multi-item cart, automatic totals, discounts, stock-deducting transactional checkout, digital **PDF receipts** (share / print). |
| **Payment Methods** | Cash, Credit/Debit Card, Mobile Money (M-Pesa / Airtel / Tigo Pesa), Bank Transfer — with reference capture. |
| **Dashboard** | Key metrics, inventory value, 7-day sales **bar chart** (fl_chart), recent transactions, alerts badge. |
| **Reports** | Daily / Weekly / Monthly sales, revenue by payment method, top sellers, low-stock, expired & inventory summary. |
| **Authentication** | Local salted-SHA-256 login, persisted session, **role-based access** (Admin vs Pharmacist), admin user management. |
| **UI/UX** | Material Design 3, light/dark/system themes, responsive (phone bottom-nav, tablet nav-rail). |

### Demo accounts (seeded on first launch)

| Username | Password | Role |
|---|---|---|
| `admin` | `admin123` | Administrator |
| `pharmacist` | `pharma123` | Pharmacist |

> **Role differences:** only Admins can delete medicines and manage users.

---

## 2. Tech Stack

- **Frontend:** Flutter (Material 3)
- **State management:** Riverpod (`flutter_riverpod`)
- **Database:** SQLite via `sqflite` (+ `sqflite_common_ffi` for desktop)
- **Charts:** `fl_chart`
- **Notifications:** `flutter_local_notifications` + `timezone`
- **Receipts:** `pdf` + `printing`
- **Security:** `crypto` (salted SHA-256), `shared_preferences` (session/theme)
- **Architecture:** Clean / feature-first + MVVM

> **Why local SQLite?** The spec offered *Firebase Firestore or MySQL/Laravel*. To keep the app **runnable with zero external setup** (no Firebase project or backend server) while remaining production-ready for single-pharmacy deployments, data access is isolated behind repository classes. Swapping in Firestore or a REST/Laravel backend only requires re-implementing the repositories — the UI, view-models and models stay unchanged. See [§7 API design](#7-api-design--backend-migration-path).

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation                          │
│   Screens (Widgets)  ◄──watch──►  Riverpod Providers (VM)    │
└───────────────────────────────┬─────────────────────────────┘
                                 │ calls
┌────────────────────────────────▼────────────────────────────┐
│                          Domain                              │
│         Models: Medicine, AppUser, Sale, SaleItem           │
│         Business rules: stock status, expiry, totals        │
└───────────────────────────────┬─────────────────────────────┘
                                 │ via repository interfaces
┌────────────────────────────────▼────────────────────────────┐
│                           Data                               │
│    Repositories ──►  AppDatabase (SQLite)                    │
│    (swap-in point for Firestore / Laravel REST API)         │
└─────────────────────────────────────────────────────────────┘
```

- **MVVM:** Widgets are the *View*; Riverpod `Notifier`/`Provider`s are the *ViewModel*; repositories + models are the *Model*.
- **Unidirectional data flow:** UI watches providers → calls notifier methods → repository mutates DB → provider reloads → UI rebuilds.

---

## 4. Database Design (ERD)

```
┌──────────────────┐        ┌──────────────────────┐
│      users       │        │      medicines       │
├──────────────────┤        ├──────────────────────┤
│ id (PK)          │        │ id (PK)              │
│ username (UQ)    │        │ name                 │
│ full_name        │        │ category             │
│ password_hash    │        │ batch_number         │
│ salt             │        │ manufacturer         │
│ role             │        │ quantity             │
│ created_at       │        │ initial_quantity     │
└────────┬─────────┘        │ reorder_level        │
         │ 1                │ purchase_price       │
         │                  │ selling_price        │
         │ records          │ manufacturing_date   │
         │                  │ expiry_date          │
         │ N                │ created_at / updated │
┌────────▼─────────┐        └──────────┬───────────┘
│      sales       │                   │ 1
├──────────────────┤                   │
│ id (PK)          │                   │ referenced by
│ invoice_number   │                   │
│ customer_name    │        ┌──────────▼───────────┐
│ subtotal         │   1    │     sale_items       │
│ discount         │────────├──────────────────────┤
│ tax              │   N    │ id (PK)              │
│ total            │        │ sale_id (FK→sales)   │
│ payment_method   │        │ medicine_id          │
│ payment_reference│        │ medicine_name        │
│ cashier_id       │        │ quantity             │
│ cashier_name     │        │ unit_price           │
│ created_at       │        │ subtotal             │
└──────────────────┘        └──────────────────────┘
```

**Relationships**
- `users (1) ──< sales (N)` — a cashier records many sales (`sales.cashier_id`).
- `sales (1) ──< sale_items (N)` — `ON DELETE CASCADE`.
- `medicines (1) ──< sale_items (N)` — line items reference the sold medicine; name/price are snapshotted so historical receipts stay accurate.

**Stock integrity:** checkout runs in a **single SQLite transaction** that inserts the sale, inserts each line item, and decrements `medicines.quantity` — so the ledger and inventory can never diverge.

---

## 5. Project Structure

```
lib/
├── main.dart                     # Bootstrap: DB warm-up, prefs, notifications, ProviderScope
├── app.dart                      # MaterialApp + theme + auth gate
├── core/
│   ├── constants/app_constants.dart   # App config, enums (UserRole, PaymentMethod)
│   ├── database/app_database.dart     # SQLite schema, seeding, transactions
│   ├── providers.dart                 # Shared DB + repository providers
│   ├── theme/                         # Material 3 theme + theme-mode notifier
│   ├── utils/                         # Formatters, stock status, password hasher
│   └── widgets/                       # StatCard, EmptyState, AppShell (nav)
└── features/
    ├── auth/         { domain · data · presentation }   # login, session, users, profile
    ├── medicines/    { domain · data · presentation }   # CRUD, list, form, cards
    ├── sales/        { domain · data · presentation }   # cart, POS, checkout, receipts, history
    ├── dashboard/    { presentation }                   # metrics + chart
    ├── reports/      { presentation }                   # sales & inventory reports
    └── notifications/{ presentation } + notification_service.dart
```

Each feature follows **domain → data → presentation** layering.

---

## 6. Getting Started

### Prerequisites
- Flutter SDK **3.10+** (tested on 3.38)
- Android Studio / Xcode for device builds (emulator, simulator, or a physical device)

### Run
```bash
flutter pub get
flutter run            # choose an Android/iOS device or emulator
```

The database, demo users and sample inventory are created automatically on first launch.

### Build a release APK
```bash
flutter build apk --release
```

> On **Windows desktop** builds, enable *Developer Mode* (`start ms-settings:developers`) so plugin symlinks work. Android/iOS builds don't need this.

---

## 7. API Design / Backend Migration Path

The app talks to data **only** through three repository classes. To move from local SQLite to a remote backend, implement the same method contracts against your API:

```dart
abstract class MedicineRepository {
  Future<List<Medicine>> getAll();
  Future<Medicine?>       getById(String id);
  Future<void>            insert(Medicine m);
  Future<void>            update(Medicine m);
  Future<void>            delete(String id);
  Future<void>            decrementStock(String id, int by);
}
```

### Suggested REST endpoints (Laravel/MySQL option)

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/login` | Returns JWT + user |
| `GET` | `/api/medicines` | List inventory |
| `POST` | `/api/medicines` | Register medicine |
| `PUT` | `/api/medicines/{id}` | Update medicine |
| `DELETE` | `/api/medicines/{id}` | Delete (admin) |
| `GET` | `/api/sales?from=&to=` | Sales in range |
| `POST` | `/api/sales` | Record sale (server deducts stock atomically) |
| `GET` | `/api/reports/sales?period=daily` | Aggregated report |

Only the `*_repository.dart` files and `app_database.dart` would change; swap `crypto`-based local auth for the server's JWT in `AuthRepository`.

---

## 8. Development Guide (step by step)

1. **Scaffold & dependencies** — Riverpod, sqflite, fl_chart, notifications, pdf/printing, crypto.
2. **Core layer** — Material 3 theme + dark mode, currency/date formatters, stock-status rules, password hasher.
3. **Database** — schema for `users`, `medicines`, `sales`, `sale_items`; seed demo data.
4. **Domain models** — `Medicine`, `AppUser`, `Sale`/`SaleItem` with `toMap`/`fromMap` + business getters.
5. **Repositories** — data access + transactional checkout, exposed via Riverpod providers.
6. **Auth** — login controller, persisted session, role-based gating, admin user management.
7. **Medicines** — searchable/filterable list, create/edit form, detail sheet with stock bar.
8. **Sales** — cart notifier, POS picker, checkout (payment methods + discount), PDF receipt, history.
9. **Dashboard** — derived stat providers, weekly sales bar chart, recent transactions, alerts badge.
10. **Reports** — period selector with sales aggregation + inventory report tab.
11. **Notifications** — local push on login for expired / expiring / low-stock items.
12. **Shell & wiring** — responsive navigation, auth gate, `main.dart` bootstrap.
13. **Verify** — `flutter analyze` (clean) + `flutter test` (unit tests for business rules).

---

## 9. Testing

```bash
flutter analyze     # static analysis — clean
flutter test        # unit tests for stock/expiry rules
```

---

## 10. Security Notes

- Passwords are stored as **salted SHA-256** hashes (per-user random salt) — never in plaintext.
- Sessions persist only a user id in `shared_preferences`; credentials are re-validated against the DB.
- For a multi-device/cloud deployment, migrate auth to JWT/Firebase (see §7) and add transport encryption.

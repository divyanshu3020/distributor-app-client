# Bhagwati Plastic Manufacturing — B2B Distributor & Operations Platform

A complete B2B Distributor & Factory Operations Mobile & Cloud Platform built with a **Modular Monolith** architecture using **Flutter (Dart)** for cross-platform iOS/Android (100% custom UI) and **Supabase (PostgreSQL, Row-Level Security, Edge Functions, Realtime)** for the backend.

---

## 🏗️ Architecture & Project Structure

```
bhagwati/
├── flutter_client/                         # Flutter Mobile Frontend (Custom B2B UI)
│   ├── lib/
│   │   ├── main.dart                       # App entrypoint, multi-provider, theme setup
│   │   ├── core/                           # Shared foundation
│   │   │   ├── config/env.dart             # Safe environment variable loader (.env)
│   │   │   ├── theme/app_theme.dart        # Industrial theme, palette, button & card styles
│   │   │   ├── services/supabase_service.dart # Supabase client wrapper & table bindings
│   │   │   ├── utils/                      # Currency & Date formatters (INR ₹, IST)
│   │   │   └── widgets/                    # Approximate badges, vehicle cards, custom inputs
│   │   └── features/                       # Modular Monolith feature services
│   │       ├── auth_rbac/                  # Login, RBAC profiles, role-based screen routing
│   │       ├── inventory/                  # 46-product catalog, no green/red indicators, caps
│   │       ├── ordering_vehicles/          # Cart, approx pricing, live package vehicle tiering
│   │       ├── quotes/                     # Locked quotes, instant printable PDF generation
│   │       ├── dispatch_otp/               # Staff dispatch entry & driver SMS/WhatsApp OTP handshake
│   │       ├── announcements/              # Admin broadcast feed for product launches & notices
│   │       ├── notifications/              # FCM push alerts & Zomato/Swiggy-style catchy reorder nudges
│   │       ├── analytics/                  # Super Admin revenue KPIs, inventory velocity & queue load
│   │       ├── admin/                      # Super Admin multi-tab control center
│   │       ├── staff/                      # Restricted Staff stock reconciliation & dispatch console
│   │       └── distributor/                # Distributor multi-tab portal
│   ├── .env.example                        # Template for public Flutter client credentials
│   ├── .gitignore                          # Standard Flutter gitignore (protects .env)
│   └── pubspec.yaml                        # Dependencies: supabase_flutter, pdf, printing, provider
│
└── supabase_backend/                       # Supabase PostgreSQL & Serverless Functions
    ├── supabase/
    │   ├── config.toml                     # Supabase local config (ports, storage, functions)
    │   ├── migrations/
    │   │   ├── 20261118000000_init_schema.sql  # 9 PostgreSQL tables, indexes, triggers & helpers
    │   │   └── 20261118000001_rls_policies.sql # Strict RLS & staff price modification guards
    │   ├── functions/                      # Deno / TypeScript Edge Functions
    │   │   ├── send-delivery-otp/          # Generates SHA-256 OTP & dispatches SMS to driver
    │   │   ├── verify-delivery-otp/        # Validates OTP, marks delivered, sends clearance SMS
    │   │   ├── generate-quote-pdf/         # Locks order pricing, creates quotation & HTML invoice
    │   │   ├── push-notifications/         # Order stages & catchy Zomato/Swiggy-style reorder alerts
    │   │   └── calculate-vehicle-fare/     # Dynamic lead time & package-count vehicle tiering
    │   └── seed.sql                        # 5 vehicle tiers, 46 realistic products & announcements
    ├── .env.example                        # Template for Supabase service role & provider keys
    └── .gitignore                          # Standard backend gitignore (protects secrets)
```

---

## 📋 Rulebook & Core Features Implemented

### 1. Catalog & Inventory Caps (Rule 2)
* **All Products Always Open:** 46 plastic manufacturing products (household buckets, basins, chemical drums, dustbins, crates, chairs, stools, jars, packaging caps) are always visible and open for orders. **No green/red stock indicators are displayed.**
* **Threshold-Triggered Distributor Cap:** When a product's stock drops below its `low_stock_threshold`, the app enforces a `per_distributor_max_cap` (e.g. max 100 packages) to prevent single-buyer hoarding.
* **Made-to-Order & Dynamic Dispatch Dates:** Items with zero or low stock are automatically tagged **"Made to Order" / "Backorder"**. The estimated dispatch date dynamically extends based on current pending queue load across active factory orders (e.g., base 2 days + 1 extra day per 200 queued units).

### 2. Approximate Estimates -> Locked Downloadable PDF Quotes (Rule 3)
* While browsing the catalog and adding items to the cart, all item rates, subtotals, and vehicle freight fees are labeled with an amber **"Approximate Estimate"** badge.
* Tapping **"Place Order & Lock Quote"** locks in the official quotation in the database, generates an official quotation number (`QT-202611-XXXX`), and enables **instant PDF downloading/printing** with full tax and freight breakdown.

### 3. Automated Vehicle Assignment via Package Counts (Rule 4)
* Standardized packaging sizing (~±20% variance) allows total package count to reliably predict vehicle sizing:
  * **1 – 25 packages:** 3-Wheeler Auto / E-Loader (Base ₹350)
  * **26 – 60 packages:** Tata Ace / Small Tempo (Base ₹850)
  * **61 – 100 packages:** Mahindra Bolero Maxi / 8-10ft Pickup (Base ₹1600)
  * **101 – 220 packages:** 14-17ft Full Body Truck (Base ₹3200) — *Automatically assigns Truck tier when packages exceed 100!*
  * **221+ packages:** 20ft+ Multi-Axle Industrial Container (Base ₹5800)
* Only the **Super Admin (Owner)** can modify base vehicle freight rates.

### 4. Dispatch & Delivery Handshake via OTP (No Driver App) (Rule 5)
* **Step 1:** Staff/Admin enters `driver_name`, `driver_phone`, and `vehicle_number`.
* **Step 2:** Order transitions to `dispatched`; distributor receives vehicle plate number and driver contact.
* **Step 3:** On physical arrival, distributor taps **"Acknowledge Driver Arrival"**.
* **Step 4:** Supabase Edge Function `send-delivery-otp` hashes a 6-digit code and dispatches it via SMS/WhatsApp to the **driver's phone**.
* **Step 5:** Driver verbally shares the code; distributor enters it into the order screen in their app.
* **Step 6:** Supabase Edge Function `verify-delivery-otp` confirms the code, marks order `delivered`, and dispatches an immediate clearance SMS to the driver:
  > *"Bhagwati Plastics CLEARANCE: OTP verified successfully. Hand over goods to distributor. Delivery complete."*

### 5. Role-Based Access Control (RBAC) & Column-Level Guards (Rule 7)
Strictly enforced in PostgreSQL Row-Level Security and database triggers:
* **`super_admin` (Owner):** Full read/write access to products, pricing, vehicle fares, announcements, orders, and analytics.
* **`staff` (Accountant/Marketing):** Can perform daily stock reconciliation (updating `stock_quantity` with mandatory reason audit logs) and enter dispatch details. **Strictly blocked at the database trigger level from updating product unit prices or vehicle base fares.**
* **`distributor` (B2B Buyer):** Can browse catalog, place orders, view own quotes, acknowledge arrival, and verify delivery OTP.

---

## ⚙️ Environment Variables Checklist

Before running deployments or live integration tests, fill in your actual credentials into `.env` files:

### `flutter_client/.env`
```env
# Supabase Public Client Credentials (Safe for client bundle with RLS enabled)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# App Environment
APP_ENV=development

# Firebase Cloud Messaging (Push Notifications)
FIREBASE_PROJECT_ID=your-firebase-project-id
FCM_VAPID_KEY=your-web-push-vapid-key-if-using-pwa
```

### `supabase_backend/.env`
```env
# Supabase Server / Edge Function Secrets (NEVER expose in Flutter client)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
SUPABASE_DB_URL=postgresql://postgres:your-db-password@db.your-project-id.supabase.co:5432/postgres

# SMS / WhatsApp OTP Provider (e.g., msg91, twilio, or fast2sms)
OTP_SMS_PROVIDER=msg91
OTP_SMS_API_KEY=your-sms-provider-api-key
OTP_SMS_SENDER_ID=BHAGWT
OTP_EXPIRY_SECONDS=300

# Firebase Admin / Push Notification Server Key
FCM_PROJECT_ID=your-firebase-project-id
FCM_CLIENT_EMAIL=firebase-adminsdk@your-firebase-project-id.iam.gserviceaccount.com
FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"
```

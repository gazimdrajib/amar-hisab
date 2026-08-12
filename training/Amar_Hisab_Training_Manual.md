# Amar Hisab – User Training Manual

**Document Version:** 1.0 (Production Release)
**Last Updated:** 2026-08-05
**Audience:** End-Users (Shop Owners, Cashiers, Managers, Accountants, Academy Administrators)

---

## Table of Contents

1. [Welcome to Amar Hisab](#1-welcome-to-amar-hisab)
2. [Installation & First-Time Setup](#2-installation--first-time-setup)
3. [Point of Sale (POS)](#3-point-of-sale-pos)
4. [Inventory & Stock Management](#4-inventory--stock-management)
5. [Purchase & Suppliers](#5-purchase--suppliers)
6. [Sales History, Returns & Payments](#6-sales-history-returns--payments)
7. [Accounting & Financial Reports](#7-accounting--financial-reports)
8. [Customers & Loyalty](#8-customers--loyalty)
9. [Educational Portal](#9-educational-portal-academy)
10. [Sync & Multi-Branch](#10-cloud-sync--multi-branch)
11. [Backup & Restore](#11-backup--restore)
12. [User & Role Management](#12-user--role-management)
13. [Troubleshooting](#13-troubleshooting)
14. [Glossary](#14-glossary)

---

## 1. Welcome to Amar Hisab

Amar Hisab (আমার হিসাব) is a complete, offline-first business management platform. It replaces your paper ledger, calculator, and collection of disconnected apps with one integrated system.

**Key principles to remember:**

*   **Offline first:** Everything works without internet. Data is stored on your local server and syncs to the cloud only when you enable it.
*   **Double-entry accounting:** Every sale, purchase, expense, and payment automatically creates balanced accounting entries.
*   **Role-based access:** Each user logs in with their own account and sees only what their role permits.
*   **Audit trail:** Every change is logged – who did it, when, and what changed.

> **Task-type icons:**
> - 🟢 **Daily operation** – routine task performed multiple times per day.
> - 🔵 **Setup / configuration** – done once, usually by the Owner or Admin.
> - 🟡 **Periodic** – weekly, monthly, or on-demand tasks.
> - 🔴 **Emergency / rare** – restore, recovery, escalation.

---

## 2. Installation & First-Time Setup

### 2.1 Installing the Server (Owner / IT Admin)

*[Screenshot placeholder – Amar Hisab desktop setup button]*

1.  Download the installer for your platform:
    *   **Windows:** `AmarHisab-Setup-x64.exe`
    *   **macOS:** `AmarHisab-Installer.dmg`
    *   **Linux:** `amarhisab_amd64.deb` or `.AppImage`
2.  Run the installer and accept the default installation directory.
3.  Launch Amar Hisab from the Start Menu / Applications.
4.  The **Setup Wizard** will appear.

### 2.2 Setup Wizard

*[Screenshot placeholder – Setup wizard step 1: language selection]*

1.  **Language:** Choose বাংলা or English.
2.  **New Business or Restore:** Select **Create New Business** (or Restore Backup if you have a prior backup).
3.  **Business Type:** Pick the type that best describes your business:
    *   Pharmacy
    *   Grocery / Super Shop
    *   Academy / Training Center
    *   Clothing Store
    *   Hardware Store
    *   *(others)*
4.  **Business Details:** Enter name, address, contact.
5.  **Currency & Tax:** Default BDT (৳); set default VAT if applicable.
6.  **Admin Account:** Create the **Owner** account. Use a strong password.
7.  Tap **Finish**. The local server starts on port 8080 and the dashboard loads.

### 2.3 Connecting a Client Device

*[Screenshot placeholder – Client device auto-discovery screen]*

1.  Install Amar Hisab on the phone/tablet/computer (Play Store / App Store / desktop installer).
2.  Connect the device to the **same Wi-Fi network** as the server.
3.  Open the app. It will scan the network for the local server (`amarhisab.local`).
4.  Tap **Connect** on the discovered server.
    *   If not found, tap **Enter Server Manually** and type the server's IP address, e.g. `192.168.0.105:8080`.
5.  Log in with the username/password the Owner gave you.

### 2.4 Printer and Scanner Setup

*[Screenshot placeholder – Printer Setup screen with "Test Print"]*

*   **Receipt Printer** – Settings → Printer Setup → Add Printer → choose USB or Bluetooth.
*   **Paper width** – 58mm or 80mm.
*   **Test print** – Use the **Test Print** button to verify.
*   **Barcode scanner** – For USB scanners, plug-and-play. Open any search field and scan.
*   **Cash drawer** – Connect to the RJ11 port on the receipt printer and enable in Settings.

---

## 3. Point of Sale (POS)

### 🟢 3.1 Making a Sale

*[Screenshot placeholder – POS screen with product grid and running total]*

1.  From the main dashboard, tap **Sales → POS Sale**.
2.  Add products:
    *   Scan the barcode with the USB/Bluetooth scanner, **or**
    *   Tap the search icon and type the product name.
3.  Adjust quantities with **+ / –**.
4.  (Optional) Add a customer by entering their mobile number.
5.  If you have permission, apply a **Discount** by percentage or amount.
6.  Tap **Pay Now**.

### 🟢 3.2 Taking a Payment

*[Screenshot placeholder – Payment method selection screen]*

*   Select payment method(s): Cash, bKash, Card, Credit, UDDAAR.
*   Multiple methods can be combined for one sale.
*   Enter the received amount. The **Change** field shows if cash received is greater than amount due.
*   Tap **Confirm Payment**.

### 🟢 3.3 During & After the Sale

*   The receipt prints automatically.
*   Stock is decremented for every item sold.
*   A journal entry is posted (Sales Revenue, Cost of Goods Sold, VAT Outstanding).
*   Cash balance increases automatically.

### 🟢 3.4 Void a Sale

*[Screenshot placeholder – Sale details → 3-dot menu → Void]*

1.  Go to **Sales → Sales History**.
2.  Tap the sale in question.
3.  Tap the **⋮** (3-dot) menu → **Void**.
4.  Confirm. The sale is reversed in accounting, stock is restored, and the void is logged in the audit trail.

*(Only users with `sale:delete` permission – Owner, Admin – can void.)*

---

## 4. Inventory & Stock Management

### 🔵 4.1 Adding a Product

1.  Go to **Products → Add Product**.
2.  Enter:
    *   **Name** (Bengali and English where relevant)
    *   **SKU** and **Barcode**
    *   **Category, Brand, Unit**
    *   **Batch-tracked** toggle – important for expiry-tracked items (medicines, food)
3.  Save.

### 🔵 4.2 Adding a Warehouse

1.  Go to **Inventory → Warehouses**.
2.  Tap **Add Warehouse**.
3.  Provide a name (e.g. "Main Store", "Warehouse 1", "Shop Floor").
4.  Save.

### 🟢 4.3 Viewing Current Stock

1.  Go to **Inventory → Current Stock**.
2.  Use filters to see stock by warehouse, category, or search.
3.  Items nearing low-stock or expiry are highlighted in yellow/red.

### 🟢 4.4 Stock Transfer

1.  Go to **Inventory → Stock Transfer**.
2.  Choose **From** warehouse and **To** warehouse.
3.  Add items and quantities.
4.  Tap **Transfer**.
5.  Source warehouse stock decreases; destination increases.

### 🟢 4.5 Stock Adjustment

*[Screenshot placeholder – Stock adjustment screen with reason field]*

Use this when a physical count doesn't match the system.

1.  Go to **Inventory → Stock Adjustment**.
2.  Select the warehouse.
3.  Add products and enter:
    *   **Current Qty** (what the system shows)
    *   **New Qty** (what you counted physically)
    *   **Reason** (e.g. "Damaged", "Stock count correction", "Theft")
4.  Save. Stock is corrected and the accounting entry is posted to Inventory Difference account.

---

## 5. Purchase & Suppliers

### 🔵 5.1 Adding a Supplier

1.  **Suppliers → Add Supplier**.
2.  Fill in company name, contact, address, payment terms.

### 🟢 5.2 Receiving a Purchase

1.  Go to **Purchase → New Purchase**.
2.  Select **Supplier** and **Receiving Warehouse**.
3.  Add products with:
    *   Quantity
    *   Cost price per unit
    *   (Batch-tracked) Batch number + Expiry date
4.  If paying now, enter **Paid Amount** and method; if on credit, leave zero.
5.  Tap **Save**.

Stock and supplier due are updated immediately.

### 🟢 5.3 Supplier Payment

*[Screenshot placeholder – Supplier detail with payment button]*

1.  Go to **Suppliers** → select one.
2.  Review unpaid invoices.
3.  Tap **Make Payment**.
4.  Enter amount, method, date.
5.  Save.

---

## 6. Sales History, Returns & Payments

### 🟢 6.1 Finding a Sale

*   Go to **Sales → Sales History**.
*   Filter by date, customer, or payment status.
*   Tap any sale to see items, payments, and journal entries.

### 🟢 6.2 Collecting a Due (বাকি আদায়)

1.  From **Sales History**, tap a sale with due > 0.
2.  Tap **Receive Payment**.
3.  Enter amount and method.
4.  Save.

### 🟢 6.3 Processing a Customer Return

*[Screenshot placeholder – Return screen with restock/damaged radio]*

1.  In **Sales History**, open the original sale.
2.  Tap **Return**.
3.  Select the returned items and quantity.
4.  Choose whether to **Restock** or mark as **Damaged**.
5.  Choose refund method (Cash or Credit).
6.  Tap **Process Return**.

Stock and accounting are reversed automatically.

---

## 7. Accounting & Financial Reports

### 🔵 7.1 Chart of Accounts

Amar Hisab automatically seeds the correct chart of accounts based on your Business Type. You don't have to set anything up.

To view it: **Accounting → Chart of Accounts**.

### 🟢 7.2 Viewing Cash Book

1.  Go to **Accounting → Cash Book**.
2.  Pick the date.
3.  Review cash in (sales) / cash out (purchases, expenses).

### 🟢 7.3 Recording an Expense

1.  Go to **Accounting → Expense**.
2.  Choose the expense account (Rent, Utilities, Salaries…).
3.  Enter amount, date, payment method.
4.  Save.

### 🟡 7.4 Financial Reports

*[Screenshot placeholder – Profit & Loss report screen]*

*   **Profit & Loss** – Revenue vs. Expenses over a period.
*   **Balance Sheet** – Assets = Liabilities + Equity, as of a single date.
*   **Trial Balance** – All account balances; use to verify books balance.
*   **General Ledger** – All journal entries posted to one account.

### 🟡 7.5 Exporting to Excel / PDF

On any report screen:

1.  Tap **Export**.
2.  Choose **Excel** or **PDF**.
3.  Save or share the file.

---

## 8. Customers & Loyalty

### 🟢 8.1 Adding a Customer

1.  **Customers → Add Customer**.
2.  Enter name, mobile, address, optional special-discount percent.
3.  Save.

### 🟢 8.2 Customer Ledger

Open a customer to see:
*   All their past sales.
*   Payments received.
*   Current outstanding due.

### 🔵 8.3 Loyalty Points

*[Screenshot placeholder – Loyalty Settings screen]*

1.  Go to **Settings → Loyalty**.
2.  Define points-per-Taka and redemption rules.
3.  Points accumulate automatically on every sale.
4.  Customers can redeem points as discounts.

---

## 9. Educational Portal (Academy)

### 🔵 9.1 Setting Up a Course

1.  Create the course as a **Service** product in **Products → Add Product**.
2.  Choose the Service type.

### 🔵 9.2 Creating a Batch

1.  Go to **Education → Batches → New Batch**.
2.  Select the course/service, name the batch, set start/end dates, max students, instructor.

### 🟢 9.3 Enrolling a Student

1.  Create the student in **Customers** (if not already).
2.  Go to **Education → Enroll Student**.
3.  Pick the student and batch.
4.  Set enrollment date; the system can auto-create a fee invoice.

### 🟢 9.4 Recording Attendance

1.  Go to **Education → Attendance**.
2.  Pick the batch and date.
3.  Mark each student Present / Absent / Late.
4.  Save.

### 🟢 9.5 Student Self-Service (QR Portal)

1.  From **Settings → Portal**, print the public QR code.
2.  Display at the academy entrance.
3.  Students scan with their phone.
4.  They select their Student ID and enter the secret password.
5.  They can view their fee due, attendance, and exam results.

---

## 10. Cloud Sync & Multi-Branch

*(Optional – only when `CLOUD_SYNC_ENABLED=true`)*

### 🔵 10.1 Enabling Cloud Sync

1.  Settings → Cloud Sync.
2.  Create or sign in to an Amar Hisab Cloud account.
3.  Tap **Link This Device**.
4.  Initial sync uploads existing data.

### 🔵 10.2 Adding Another Branch

1.  Install the Local Server at the second branch.
2.  Enable Cloud Sync with the same cloud account.
3.  The branches merge inventories and sales through the cloud.

> Local operations remain independent; sync is eventual. All data is encrypted (AES-256) in transit.

---

## 11. Backup & Restore

### 🟢 11.1 Manual Backup

1.  Insert a USB drive into the server computer.
2.  Go to **Settings → Backup → Local File**.
3.  Tap **Backup Now**.
4.  Store the USB safely.

### 🔵 11.2 Scheduled Backup (Google Drive)

1.  Settings → Backup → Google Drive.
2.  Sign in and grant permissions.
3.  Enable **Scheduled Backup** at a time the server is on (e.g., 11 PM).

### 🔴 11.3 Restoring from Backup

1.  Stop the server if running.
2.  Re-open the app.
3.  On login screen, select **Restore Backup**.
4.  Choose file / Google Drive / Telegram.
5.  Provide the encryption passphrase.
6.  Tap **Restore**.
7.  Verify after the restart.

---

## 12. User & Role Management

### 🔵 12.1 Adding a User

1.  Settings → Users → Add User.
2.  Enter username, full name, temporary password.
3.  Assign role: Owner / Admin / Manager / Cashier / Accountant / Inventory Manager.
4.  Save.

The new user must change the temporary password at first login.

### 🔵 12.2 Editing / Disabling a User

*   **Edit** – change role or reset password.
*   **Disable** – set Active = No; login is blocked but history preserved.
*   **Remove** – only possible if the user has never made a transaction.

---

## 13. Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Server won't start | Port 8080 busy | Change port or stop conflicting app. |
| Client can't find server | mDNS blocked by router | Use IP manually: `192.168.x.x:8080`. |
| Printer doesn't print | Cable/driver | Settings → Printer Setup → Test Print. |
| Barcode scanner ignores input | Scanner in wrong mode | Set USB-HID keyboard mode (see scanner manual). |
| Backup to Drive fails | Token expired | Re-authenticate Google in Backup settings. |
| Sync stuck "Offline" | Token expired or no internet | Sign out/in, check internet. |
| "Database corruption" on startup | Power fail during write | Restore from latest backup. |

If none of the above resolves the issue, contact [support@amarhisab.com](mailto:support@amarhisab.com).

---

## 14. Glossary

| English | বাংলা | Meaning |
|---------|-------|---------|
| Sale | বিক্রয় | Selling a product to a customer |
| Purchase | ক্রয় | Acquiring goods from a supplier |
| Inventory / Stock | মজুদ / স্টক | Quantity of products held |
| Customer | ক্রেতা | Buyer |
| Supplier | সরবরাহকারী | Wholesaler / vendor |
| Invoice | চালান / রশিদ | Bill of sale |
| Due / Outstanding | বাকি | Money still owed |
| Profit & Loss | লাভ ও ক্ষতি | Income minus expenses |
| Balance Sheet | আর্থিক অবস্থা বিবরণী | Statement of assets, liabilities, equity |
| Backup | ব্যাকআপ | Safe copy of your data |
| Loyalty points | লয়্যালটি পয়েন্ট | Rewards earned by customers |
| Portal | পোর্টাল | Self-service web page for students |
| Sync | সিংক | Replicate data to/from cloud |

---

*This manual covers the core operations of Amar Hisab. For the deepest technical detail, see the **Architecture Book**, **Operations Runbook**, and **Production Deployment Guide**.*

import 'package:sqlite3/sqlite3.dart';

/// Version-1 schema for Amar Hisab.
///
/// Contains core, auth, products, inventory and sales DDL. Statements use
/// `CREATE TABLE IF NOT EXISTS` / `CREATE INDEX IF NOT EXISTS` so that
/// migrations are idempotent and safe to re-run.
class SchemaV1 {
  SchemaV1._();

  static const int schemaVersion = 2;

  /// Apply the whole v1 schema to [db]. Caller is expected to run inside a
  /// transaction.
  static void createAll(Database db) {
    for (final statement in _statements) {
      db.execute(statement);
    }
  }

  static const List<String> _statements = [
    // ---------------------------------------------------------------------
    // Core
    // ---------------------------------------------------------------------
    '''
    CREATE TABLE IF NOT EXISTS businesses (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      type        TEXT    NOT NULL DEFAULT 'retail',
      address     TEXT,
      phone       TEXT,
      email       TEXT,
      currency    TEXT    NOT NULL DEFAULT 'BDT',
      tax_default REAL    NOT NULL DEFAULT 0,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL,
      updated_at  TEXT    NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS roles (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL UNIQUE,
      description TEXT,
      is_system   INTEGER NOT NULL DEFAULT 0,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS users (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id   INTEGER NOT NULL REFERENCES businesses(id),
      username      TEXT    NOT NULL,
      password_hash TEXT    NOT NULL,
      salt          TEXT    NOT NULL,
      full_name     TEXT    NOT NULL,
      role_id       INTEGER NOT NULL REFERENCES roles(id),
      is_active     INTEGER NOT NULL DEFAULT 1,
      created_at    TEXT    NOT NULL,
      updated_at    TEXT    NOT NULL,
      UNIQUE (business_id, username)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS permissions (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      role_id   INTEGER NOT NULL REFERENCES roles(id),
      resource  TEXT    NOT NULL,
      action    TEXT    NOT NULL,
      UNIQUE (role_id, resource, action)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS audit_log (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp   TEXT    NOT NULL,
      user_id     INTEGER,
      entity_type TEXT    NOT NULL,
      entity_id   INTEGER,
      action      TEXT    NOT NULL,
      field_name  TEXT,
      old_value   TEXT,
      new_value   TEXT,
      business_id INTEGER
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS settings (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id INTEGER NOT NULL REFERENCES businesses(id),
      key         TEXT    NOT NULL,
      value       TEXT,
      UNIQUE (business_id, key)
    );
    ''',

    // ---------------------------------------------------------------------
    // Products
    // ---------------------------------------------------------------------
    '''
    CREATE TABLE IF NOT EXISTS categories (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id INTEGER NOT NULL REFERENCES businesses(id),
      name        TEXT    NOT NULL,
      description TEXT,
      parent_id   INTEGER REFERENCES categories(id),
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL,
      updated_at  TEXT    NOT NULL,
      UNIQUE (business_id, name)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS brands (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id INTEGER NOT NULL REFERENCES businesses(id),
      name        TEXT    NOT NULL,
      description TEXT,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL,
      updated_at  TEXT    NOT NULL,
      UNIQUE (business_id, name)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS units (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id INTEGER NOT NULL REFERENCES businesses(id),
      name        TEXT    NOT NULL,
      abbreviation TEXT   NOT NULL,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL,
      updated_at  TEXT    NOT NULL,
      UNIQUE (business_id, abbreviation)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS products (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id     INTEGER NOT NULL REFERENCES businesses(id),
      sku             TEXT    NOT NULL,
      barcode         TEXT,
      name            TEXT    NOT NULL,
      description     TEXT,
      category_id     INTEGER REFERENCES categories(id),
      brand_id        INTEGER REFERENCES brands(id),
      unit_id         INTEGER REFERENCES units(id),
      purchase_price  REAL    NOT NULL DEFAULT 0,
      selling_price   REAL    NOT NULL DEFAULT 0,
      tax_rate        REAL    NOT NULL DEFAULT 0,
      min_stock_level REAL    NOT NULL DEFAULT 0,
      is_active       INTEGER NOT NULL DEFAULT 1,
      created_at      TEXT    NOT NULL,
      updated_at      TEXT    NOT NULL,
      UNIQUE (business_id, sku)
    );
    ''',

    // ---------------------------------------------------------------------
    // Inventory
    // ---------------------------------------------------------------------
    '''
    CREATE TABLE IF NOT EXISTS warehouses (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id INTEGER NOT NULL REFERENCES businesses(id),
      name        TEXT    NOT NULL,
      location    TEXT,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL,
      updated_at  TEXT    NOT NULL,
      UNIQUE (business_id, name)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS batches (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id    INTEGER NOT NULL REFERENCES businesses(id),
      product_id     INTEGER NOT NULL REFERENCES products(id),
      warehouse_id   INTEGER NOT NULL REFERENCES warehouses(id),
      batch_number   TEXT,
      purchase_price REAL    NOT NULL DEFAULT 0,
      expiry_date    TEXT,
      received_at    TEXT    NOT NULL,
      quantity       REAL    NOT NULL DEFAULT 0,
      is_active      INTEGER NOT NULL DEFAULT 1,
      created_at     TEXT    NOT NULL,
      UNIQUE (business_id, product_id, warehouse_id, batch_number)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS stock (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id  INTEGER NOT NULL REFERENCES businesses(id),
      product_id   INTEGER NOT NULL REFERENCES products(id),
      warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
      quantity     REAL    NOT NULL DEFAULT 0,
      updated_at   TEXT    NOT NULL,
      UNIQUE (business_id, product_id, warehouse_id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS stock_movements (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id      INTEGER NOT NULL REFERENCES businesses(id),
      product_id       INTEGER NOT NULL REFERENCES products(id),
      warehouse_id     INTEGER NOT NULL REFERENCES warehouses(id),
      batch_id         INTEGER REFERENCES batches(id),
      movement_type    TEXT    NOT NULL,
      quantity         REAL    NOT NULL,
      reference_type   TEXT,
      reference_id     INTEGER,
      note             TEXT,
      performed_by     INTEGER REFERENCES users(id),
      created_at       TEXT    NOT NULL
    );
    ''',

    // ---------------------------------------------------------------------
    // Customers (minimal placeholder – full CRM module ships in a later
    // phase; `sales.customer_id` references this table per Database Book §3.3)
    // ---------------------------------------------------------------------
    '''
    CREATE TABLE IF NOT EXISTS customers (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id INTEGER NOT NULL REFERENCES businesses(id),
      name        TEXT    NOT NULL,
      phone       TEXT,
      email       TEXT,
      address     TEXT,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL,
      updated_at  TEXT    NOT NULL
    );
    ''',

    // ---------------------------------------------------------------------
    // Sales (Database Book §3.3)
    // ---------------------------------------------------------------------
    '''
    CREATE TABLE IF NOT EXISTS sales (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_number  TEXT    NOT NULL UNIQUE,
      customer_id     INTEGER REFERENCES customers(id),
      sale_date       TEXT    NOT NULL,
      sale_type       TEXT    NOT NULL DEFAULT 'POS',
      warehouse_id    INTEGER REFERENCES warehouses(id),
      total_amount    REAL    NOT NULL DEFAULT 0,
      discount_percent REAL   NOT NULL DEFAULT 0,
      discount_amount REAL    NOT NULL DEFAULT 0,
      tax_percent     REAL    NOT NULL DEFAULT 0,
      tax_amount      REAL    NOT NULL DEFAULT 0,
      grand_total     REAL    NOT NULL DEFAULT 0,
      paid_amount     REAL    NOT NULL DEFAULT 0,
      due_amount      REAL    NOT NULL DEFAULT 0,
      status          TEXT    NOT NULL DEFAULT 'Completed',
      payment_status  TEXT    NOT NULL DEFAULT 'Paid',
      note            TEXT,
      business_id     INTEGER NOT NULL REFERENCES businesses(id),
      created_by      INTEGER REFERENCES users(id),
      created_at      TEXT    NOT NULL,
      updated_at      TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS sale_items (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id          INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
      product_id       INTEGER NOT NULL,
      quantity         REAL    NOT NULL,
      unit_price       REAL    NOT NULL,
      discount_percent REAL    NOT NULL DEFAULT 0,
      discount_amount  REAL    NOT NULL DEFAULT 0,
      tax_percent      REAL    NOT NULL DEFAULT 0,
      tax_amount       REAL    NOT NULL DEFAULT 0,
      line_total       REAL    NOT NULL DEFAULT 0
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS sale_payments (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id        INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
      amount         REAL    NOT NULL,
      payment_method TEXT    NOT NULL DEFAULT 'Cash',
      reference      TEXT,
      payment_date   TEXT    NOT NULL,
      created_by     INTEGER REFERENCES users(id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS sales_returns (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id       INTEGER NOT NULL REFERENCES sales(id),
      return_date   TEXT    NOT NULL,
      reason        TEXT,
      restock       INTEGER NOT NULL DEFAULT 0,
      refund_amount REAL    NOT NULL DEFAULT 0,
      refund_method TEXT,
      created_at    TEXT    NOT NULL
    );
    ''',

    // ---------------------------------------------------------------------
    // Suppliers & Purchases (Database Book §3.4)
    // ---------------------------------------------------------------------
    '''
    CREATE TABLE IF NOT EXISTS suppliers (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id INTEGER NOT NULL REFERENCES businesses(id),
      name        TEXT    NOT NULL,
      phone       TEXT,
      email       TEXT,
      address     TEXT,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL,
      updated_at  TEXT    NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS purchases (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_number  TEXT    NOT NULL UNIQUE,
      supplier_id     INTEGER REFERENCES suppliers(id),
      purchase_date   TEXT    NOT NULL,
      warehouse_id    INTEGER REFERENCES warehouses(id),
      total_amount    REAL    NOT NULL DEFAULT 0,
      discount_percent REAL   NOT NULL DEFAULT 0,
      discount_amount REAL    NOT NULL DEFAULT 0,
      tax_percent     REAL    NOT NULL DEFAULT 0,
      tax_amount      REAL    NOT NULL DEFAULT 0,
      grand_total     REAL    NOT NULL DEFAULT 0,
      paid_amount     REAL    NOT NULL DEFAULT 0,
      due_amount      REAL    NOT NULL DEFAULT 0,
      status          TEXT    NOT NULL DEFAULT 'Received',
      payment_status  TEXT    NOT NULL DEFAULT 'Paid',
      note            TEXT,
      business_id     INTEGER NOT NULL REFERENCES businesses(id),
      created_by      INTEGER REFERENCES users(id),
      created_at      TEXT    NOT NULL,
      updated_at      TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS purchase_items (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id      INTEGER NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
      product_id       INTEGER NOT NULL,
      quantity         REAL    NOT NULL,
      unit_price       REAL    NOT NULL,
      discount_percent REAL    NOT NULL DEFAULT 0,
      discount_amount  REAL    NOT NULL DEFAULT 0,
      tax_percent      REAL    NOT NULL DEFAULT 0,
      tax_amount       REAL    NOT NULL DEFAULT 0,
      line_total       REAL    NOT NULL DEFAULT 0
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS supplier_payments (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier_id    INTEGER REFERENCES suppliers(id),
      purchase_id    INTEGER REFERENCES purchases(id) ON DELETE CASCADE,
      amount         REAL    NOT NULL,
      payment_method TEXT    NOT NULL DEFAULT 'Cash',
      reference      TEXT,
      payment_date   TEXT    NOT NULL,
      created_by     INTEGER REFERENCES users(id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS chart_of_accounts (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      account_code TEXT    NOT NULL,
      account_name TEXT    NOT NULL,
      account_type TEXT    NOT NULL,
      parent_id    INTEGER REFERENCES chart_of_accounts(id),
      is_active    INTEGER NOT NULL DEFAULT 1,
      is_system    INTEGER NOT NULL DEFAULT 0,
      business_id  INTEGER NOT NULL REFERENCES businesses(id),
      created_at   TEXT    NOT NULL,
      updated_at   TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS journal_entries (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      entry_number TEXT    NOT NULL UNIQUE,
      entry_date   TEXT    NOT NULL,
      reference    TEXT,
      note         TEXT,
      is_auto      INTEGER NOT NULL DEFAULT 0,
      status       TEXT    NOT NULL DEFAULT 'draft'
                   CHECK (status IN ('draft','posted')),
      business_id  INTEGER NOT NULL REFERENCES businesses(id),
      created_by   INTEGER REFERENCES users(id),
      created_at   TEXT    NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS journal_lines (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      journal_entry_id INTEGER NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
      account_id       INTEGER NOT NULL REFERENCES chart_of_accounts(id),
      debit            REAL    NOT NULL DEFAULT 0,
      credit           REAL    NOT NULL DEFAULT 0,
      description      TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS posting_templates (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      template_code TEXT    NOT NULL UNIQUE,
      description   TEXT,
      business_id   INTEGER NOT NULL REFERENCES businesses(id),
      is_system     INTEGER NOT NULL DEFAULT 0,
      created_at    TEXT    NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS accounting_periods (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      start_date  TEXT    NOT NULL,
      end_date    TEXT    NOT NULL,
      is_closed   INTEGER NOT NULL DEFAULT 0,
      business_id INTEGER NOT NULL REFERENCES businesses(id),
      created_at  TEXT    NOT NULL
    );
    ''',

    // ---------------------------------------------------------------------
    // Sync & Public Portal (Database Book §3.9, Phase 9)
    // ---------------------------------------------------------------------

    /// Transactional outbox – every data mutation is appended here inside the
    /// same SQLite transaction as the business data it describes.
    '''
    CREATE TABLE IF NOT EXISTS change_log (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      change_id    TEXT    NOT NULL UNIQUE,
      entity_type  TEXT    NOT NULL,
      entity_id    INTEGER NOT NULL,
      operation    TEXT    NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
      payload      TEXT,
      old_values   TEXT,
      timestamp_ms INTEGER NOT NULL,
      sequence     INTEGER NOT NULL,
      sync_status  TEXT    NOT NULL DEFAULT 'pending'
                   CHECK (sync_status IN ('pending','synced','conflict')),
      device_id    TEXT    NOT NULL,
      business_id  INTEGER NOT NULL
    );
    ''',

    /// Local sync cursors per device: highest pushed local sequence and the
    /// highest remote (cloud) sequence applied.
    '''
    CREATE TABLE IF NOT EXISTS sync_state (
      device_id              TEXT PRIMARY KEY,
      last_synced_sequence   INTEGER,
      last_synced_timestamp  INTEGER,
      last_remote_sequence   INTEGER
    );
    ''',

    /// Known devices for the business (identity for mTLS / device JWT).
    '''
    CREATE TABLE IF NOT EXISTS device_registry (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      device_id     TEXT    NOT NULL UNIQUE,
      business_id   INTEGER NOT NULL REFERENCES businesses(id),
      device_name   TEXT,
      public_key    TEXT,
      is_authorized INTEGER NOT NULL DEFAULT 1
    );
    ''',

    /// Portal (QR self-service) tokens. `student_id IS NULL` rows are
    /// batch/business QR tokens that scope many students.
    '''
    CREATE TABLE IF NOT EXISTS portal_tokens (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id INTEGER NOT NULL REFERENCES businesses(id),
      student_id  INTEGER,
      batch_id    INTEGER,
      token       TEXT    NOT NULL UNIQUE,
      type        TEXT    NOT NULL DEFAULT 'qr'
                  CHECK (type IN ('student','batch','business')),
      secret_hash TEXT,
      expires_at  TEXT,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL
    );
    ''',

    /// Minimal student registry backing portal self-service (full education
    /// module ships in a later phase).
    '''
    CREATE TABLE IF NOT EXISTS students (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id  INTEGER NOT NULL REFERENCES businesses(id),
      student_code TEXT    NOT NULL,
      name         TEXT    NOT NULL,
      phone        TEXT,
      batch_id     INTEGER,
      secret_hash  TEXT,
      is_active    INTEGER NOT NULL DEFAULT 1,
      created_at   TEXT    NOT NULL,
      updated_at   TEXT,
      UNIQUE (business_id, student_code)
    );
    ''',

    // ---------------------------------------------------------------------
    // Indexes
    // ---------------------------------------------------------------------
    'CREATE INDEX IF NOT EXISTS idx_users_business  ON users (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_users_username  ON users (username);',
    'CREATE INDEX IF NOT EXISTS idx_users_role      ON users (role_id);',
    'CREATE INDEX IF NOT EXISTS idx_perm_role       ON permissions (role_id);',
    'CREATE INDEX IF NOT EXISTS idx_audit_entity    ON audit_log (entity_type, entity_id);',
    'CREATE INDEX IF NOT EXISTS idx_audit_user      ON audit_log (user_id);',
    'CREATE INDEX IF NOT EXISTS idx_audit_business  ON audit_log (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_audit_ts        ON audit_log (timestamp);',
    'CREATE INDEX IF NOT EXISTS idx_settings_biz    ON settings (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_categories_biz  ON categories (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_brands_biz      ON brands (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_units_biz       ON units (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_products_biz    ON products (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_products_cat    ON products (category_id);',
    'CREATE INDEX IF NOT EXISTS idx_products_brand  ON products (brand_id);',
    'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products (barcode);',
    'CREATE INDEX IF NOT EXISTS idx_warehouses_biz  ON warehouses (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_batches_product ON batches (product_id);',
    'CREATE INDEX IF NOT EXISTS idx_batches_wh      ON batches (warehouse_id);',
    'CREATE INDEX IF NOT EXISTS idx_stock_product   ON stock (product_id);',
    'CREATE INDEX IF NOT EXISTS idx_stock_wh        ON stock (warehouse_id);',
    'CREATE INDEX IF NOT EXISTS idx_moves_product   ON stock_movements (product_id);',
    'CREATE INDEX IF NOT EXISTS idx_moves_wh        ON stock_movements (warehouse_id);',
    'CREATE INDEX IF NOT EXISTS idx_moves_ref       ON stock_movements (reference_type, reference_id);',
    'CREATE INDEX IF NOT EXISTS idx_customers_biz   ON customers (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_sales_biz_date  ON sales (business_id, sale_date DESC);',
    'CREATE INDEX IF NOT EXISTS idx_sales_customer  ON sales (customer_id);',
    'CREATE INDEX IF NOT EXISTS idx_sales_invoice   ON sales (invoice_number);',
    'CREATE INDEX IF NOT EXISTS idx_sales_paystatus ON sales (payment_status);',
    'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items (sale_id);',
    'CREATE INDEX IF NOT EXISTS idx_sale_payments_sale ON sale_payments (sale_id);',
    'CREATE INDEX IF NOT EXISTS idx_sales_returns_sale ON sales_returns (sale_id);',
    'CREATE INDEX IF NOT EXISTS idx_suppliers_biz    ON suppliers (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_purchases_biz_date ON purchases (business_id, purchase_date DESC);',
    'CREATE INDEX IF NOT EXISTS idx_purchases_supplier ON purchases (supplier_id);',
    'CREATE INDEX IF NOT EXISTS idx_purchases_invoice ON purchases (invoice_number);',
    'CREATE INDEX IF NOT EXISTS idx_purchases_paystatus ON purchases (payment_status);',
    'CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase ON purchase_items (purchase_id);',
    'CREATE INDEX IF NOT EXISTS idx_supplier_payments_purchase ON supplier_payments (purchase_id);',
    'CREATE INDEX IF NOT EXISTS idx_supplier_payments_supplier ON supplier_payments (supplier_id);',
    'CREATE INDEX IF NOT EXISTS idx_coa_biz        ON chart_of_accounts (business_id);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_coa_code ON chart_of_accounts (business_id, account_code);',
    'CREATE INDEX IF NOT EXISTS idx_coa_type       ON chart_of_accounts (account_type);',
    'CREATE INDEX IF NOT EXISTS idx_je_biz_date    ON journal_entries (business_id, entry_date DESC);',
    'CREATE INDEX IF NOT EXISTS idx_je_status      ON journal_entries (status);',
    'CREATE INDEX IF NOT EXISTS idx_jl_entry       ON journal_lines (journal_entry_id);',
    'CREATE INDEX IF NOT EXISTS idx_jl_account     ON journal_lines (account_id);',
    'CREATE INDEX IF NOT EXISTS idx_templates_biz  ON posting_templates (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_periods_biz    ON accounting_periods (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_changelog_status ON change_log (sync_status, device_id, sequence);',
    'CREATE INDEX IF NOT EXISTS idx_changelog_change ON change_log (business_id, change_id);',
    'CREATE INDEX IF NOT EXISTS idx_device_reg_biz   ON device_registry (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_portal_tokens_token ON portal_tokens (token);',
    'CREATE INDEX IF NOT EXISTS idx_portal_tokens_biz   ON portal_tokens (business_id);',
    'CREATE INDEX IF NOT EXISTS idx_students_biz     ON students (business_id);',
  ];
}

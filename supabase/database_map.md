# Mapa Integral de Base de Datos - Proyecto D'Una

Este documento detalla **todas** las tablas, sus campos, tipos de datos y relaciones existentes en el esquema `public`. **Uso obligatorio antes de cualquier modificación en RPCs o triggers.**

Supabase Project ID: fdkswvzrozijbizdthge

## 1. Módulo Core y Usuarios

### `collaborators`

Asesores o personal de ventas.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `full_name` (text)
- `identification_id` (text)
- `phone` (text) (Nullable)
- `email` (text) (Nullable)
- `charge` (text) (Nullable)
- `is_active` (boolean) (Nullable) [default: true]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `updated_at` (timestamp with time zone) (Nullable) [default: now()]
- `user_id` (uuid) [FK -> auth.users] [default: auth.uid()]
- `is_user_record` (boolean) (Nullable) [default: false]

---

### `financial_parameters`

Configuración de márgenes e impuestos por usuario.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `profit_margin` (numeric) (Nullable) [default: 25.00]
- `tax_rate` (numeric) (Nullable) [default: 16.00]
- `currency_code` (text) (Nullable) [default: 'USD']
- `updated_at` (timestamp with time zone) (Nullable) [default: now()]
- `user_id` (uuid) [FK -> auth.users]
- `pricing_method` (text) [default: 'margin']

---

### `profiles`

Perfil extendido de los usuarios (vinculado a auth.users).

- `id` (uuid) [PK, FK -> auth.users]
- `first_name` (text) (Nullable)
- `last_name` (text) (Nullable)
- `gender` (text) (Nullable)
- `birth_date` (date) (Nullable)
- `national_id` (text)
- `avatar_url` (text) (Nullable)
- `phone` (text) (Nullable)
- `secondary_phone` (text) (Nullable)
- `main_address` (text) (Nullable)
- `main_city` (text) (Nullable)
- `main_state` (text) (Nullable)
- `main_country` (text) (Nullable)
- `is_business_owner` (boolean) (Nullable) [default: false]
- `company_name` (text) (Nullable)
- `company_rif` (text) (Nullable)
- `company_address` (text) (Nullable)
- `company_logo_url` (text) (Nullable)
- `verification_status` (enum: verification_status) (Nullable) [default: 'unverified']
- `updated_at` (timestamp with time zone) (Nullable) [default: now()]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `occupation_id` (uuid) [FK -> occupations.id]
- `secondary_occupation_ids` (ARRAY) (Nullable)
- `verification_type` (text) (Nullable)
- `daily_extra_email_credits` (integer) [default: 0]

---

## 2. Red de Proveedores (Marketplace)

### `sectors`

Sectores comerciales o rubros de la industria.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `name` (text)
- `created_at` (timestamp with time zone) (Nullable) [default: now()]

---

### `supplier_branch_stock`

Existencias y precios por sucursal.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `product_id` (uuid) [FK -> supplier_products.id]
- `branch_id` (uuid) [FK -> supplier_branches.id]
- `quantity` (numeric) (Nullable) [default: 0]
- `price` (numeric) (Nullable) [default: 0]
- `updated_at` (timestamp with time zone) (Nullable) [default: now()]
- `currency` (text) (Nullable) [default: 'USD']

---

### `supplier_branches`

Sucursales físicas de los proveedores.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `supplier_id` (uuid) [FK -> suppliers.id]
- `name` (text)
- `city` (text) (Nullable)
- `external_id` (text)
- `created_at` (timestamp with time zone) (Nullable) [default: now()]

---

### `supplier_products`

Catálogo de productos ofrecidos por proveedores.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `supplier_id` (uuid) [FK -> suppliers.id]
- `model_raw` (text)
- `name` (text)
- `description` (text) (Nullable)
- `model` (text) (Nullable)
- `category_raw` (text) (Nullable)
- `brand_raw` (text) (Nullable)
- `image_urls` (ARRAY) (Nullable)
- `attributes` (jsonb) (Nullable) [default: '{}'::jsonb]
- `is_active` (boolean) (Nullable) [default: true]
- `updated_at` (timestamp with time zone) (Nullable) [default: now()]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `category_id` (uuid) [FK -> categories.id]
- `uom_raw` (text) (Nullable)
- `uom_id` (uuid) [FK -> uoms.id]
- `brand_id` (uuid) [FK -> brands.id]
- `warranty_time` (integer) (Nullable)
- `warranty_unit` (text) (Nullable) [default: 'months']

---

### `supplier_sectors`

Relación entre proveedores y sectores de especialización.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `supplier_id` (uuid) [FK -> suppliers.id]
- `sector_id` (uuid) [FK -> sectors.id]
- `display_order` (integer) (Nullable)

---

### `suppliers`

Entidades proveedoras (Afiliadas y No Afiliadas).

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `name` (text)
- `api_key` (text) [default: encode(gen_random_bytes(32), 'hex')]
- `is_active` (boolean) (Nullable) [default: true]
- `contact_info` (jsonb) (Nullable) [default: '{}'::jsonb]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `banner_url` (text) (Nullable)
- `logo_url` (text) (Nullable)
- `trade_type` (text) (Nullable)
- `allowed_verification_types` (ARRAY) (Nullable)
- `user_id` (uuid) [FK -> auth.users]
- `is_verified` (boolean) (Nullable) [default: false]
- `is_affiliated` (boolean) (Nullable) [default: false]
- `normalized_name` (text) (Nullable)
- `phone` (text) (Nullable)
- `email` (text) (Nullable)
- `tax_id` (text)
- `notes` (text) (Nullable)
- `legal_name` (text) (Nullable)

---

## 3. Catálogo y Referencias Maestras

### `brands`

Marcas asociadas a productos (globales o personalizadas por usuario).

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `name` (text)
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `user_id` (uuid) [FK -> auth.users]
- `is_verified` (boolean) (Nullable) [default: false]
- `normalized_name` (text) (Nullable)

---

### `categories`

Categorías de productos y servicios.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `name` (text)
- `type` (text) (Nullable) [default: 'both']
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `user_id` (uuid) [FK -> auth.users]
- `is_verified` (boolean) (Nullable) [default: false]
- `normalized_name` (text) (Nullable)

---

### `delivery_times`

Tiempos estimados de entrega o ejecución.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `name` (text)
- `is_active` (boolean) (Nullable) [default: true]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `updated_at` (timestamp with time zone) (Nullable) [default: now()]
- `min_value` (integer) (Nullable)
- `max_value` (integer) (Nullable)
- `unit` (text) (Nullable) [default: 'days']
- `type` (text) (Nullable) [default: 'delivery']
- `order_idx` (integer) (Nullable) [default: 0]
- `user_id` (uuid) [FK -> auth.users]
- `is_verified` (boolean) (Nullable) [default: false]

---

### `products`

Inventario maestro o productos propios del usuario.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `user_id` (uuid) [FK -> profiles.id]
- `name` (text)
- `model` (text) (Nullable)
- `specifications` (text) (Nullable)
- `image_url` (text) (Nullable)
- `created_at` (timestamp with time zone) [default: now()]
- `updated_at` (timestamp with time zone) [default: now()]
- `category_id` (uuid) [FK -> categories.id]
- `brand_id` (uuid) [FK -> brands.id]
- `uom_id` (uuid) [FK -> uoms.id]

---

### `service_rates`

Tarifas de cobro/medición para servicios (por hora, día, etc.).

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `name` (text)
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `symbol` (text) (Nullable)
- `user_id` (uuid) [FK -> auth.users] [default: auth.uid()]
- `is_verified` (boolean) (Nullable) [default: false]
- `normalized_name` (text) (Nullable)
- `icon_name` (text) (Nullable)

---

### `services`

Catálogo de servicios ofrecidos por el usuario.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `user_id` (uuid) [FK -> auth.users]
- `name` (text)
- `description` (text) (Nullable)
- `price` (numeric)
- `created_at` (timestamp with time zone) [default: now()]
- `updated_at` (timestamp with time zone) [default: now()]
- `has_warranty` (boolean) (Nullable) [default: false]
- `warranty_time` (integer) (Nullable)
- `warranty_unit` (text) (Nullable)
- `service_rate_id` (uuid) [FK -> service_rates.id]
- `category_id` (uuid) [FK -> categories.id]

---

### `uoms`

Unidades de medida (Units of Measure).

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `name` (text)
- `symbol` (text)
- `created_at` (timestamp with time zone) [default: now()]
- `user_id` (uuid) [FK -> auth.users]
- `is_verified` (boolean) (Nullable) [default: false]
- `normalized_name` (text) (Nullable)
- `icon_name` (text) (Nullable)

---

## 4. Ventas y Cotizaciones

### `clients`

Clientes registrados por el usuario (empresas o personas).

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `user_id` (uuid) [FK -> auth.users]
- `name` (text)
- `type` (text)
- `tax_id` (text)
- `email` (text) (Nullable)
- `phone` (text) (Nullable)
- `address` (text) (Nullable)
- `created_at` (timestamp with time zone) [default: now()]
- `city` (text) (Nullable)
- `state` (text) (Nullable)
- `country` (text) (Nullable)
- `alias` (text) (Nullable)

---

### `commercial_conditions`

Plantillas de condiciones comerciales predefinidas.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `description` (text)
- `is_default_quote` (boolean) (Nullable) [default: false]
- `is_active` (boolean) (Nullable) [default: true]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `updated_at` (timestamp with time zone) (Nullable) [default: now()]
- `is_default_report` (boolean) [default: false]
- `user_id` (uuid) [FK -> auth.users]

---

### `contacts`

Contactos asociados a los clientes.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `client_id` (uuid) [FK -> clients.id]
- `name` (text)
- `role` (text) (Nullable)
- `email` (text) (Nullable)
- `phone` (text) (Nullable)
- `department` (text) (Nullable)
- `is_primary` (boolean) [default: false]
- `created_at` (timestamp with time zone) [default: now()]

---

### `observations`

Observaciones o notas tipo plantilla para los documentos.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `user_id` (uuid) [FK -> auth.users]
- `description` (text)
- `is_default_delivery_note` (boolean) [default: false]
- `is_active` (boolean) [default: true]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]

---

### `quote_conditions`

Condiciones comerciales asociadas a una cotización específica.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `quote_id` (uuid) [FK -> quotes.id]
- `condition_id` (uuid) [FK -> commercial_conditions.id]
- `description` (text)
- `order_index` (integer) (Nullable) [default: 0]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]

---

### `quote_items_products`

Ítems de tipo producto dentro de una cotización.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `quote_id` (uuid) [FK -> quotes.id]
- `product_id` (uuid) [FK -> products.id]
- `supplier_branch_stock_id` (uuid) [FK -> supplier_branch_stock.id]
- `delivery_time_id` (uuid) [FK -> delivery_times.id]
- `name` (text)
- `brand` (text) (Nullable)
- `model` (text) (Nullable)
- `uom` (text) (Nullable)
- `description` (text) (Nullable)
- `quantity` (numeric) [default: 1]
- `cost_price` (numeric) (Nullable) [default: 0]
- `profit_margin` (numeric) (Nullable) [default: 0]
- `unit_price` (numeric) (Nullable) [default: 0]
- `tax_rate` (numeric) (Nullable) [default: 0]
- `tax_amount` (numeric) (Nullable) [default: 0]
- `total_price` (numeric) (Nullable) [default: 0]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `external_provider_name` (text) (Nullable)
- `source_type` (text) (Nullable)
- `uom_icon_name` (text) (Nullable)
- `group_index` (integer) [default: 0]
- `warranty_time` (integer) (Nullable)
- `warranty_unit` (text) (Nullable) [default: 'months']

---

### `quote_items_services`

Ítems de tipo servicio dentro de una cotización.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `quote_id` (uuid) [FK -> quotes.id]
- `service_id` (uuid) [FK -> services.id]
- `execution_time_id` (uuid) [FK -> delivery_times.id]
- `name` (text)
- `description` (text) (Nullable)
- `quantity` (numeric) [default: 1]
- `cost_price` (numeric) (Nullable) [default: 0]
- `profit_margin` (numeric) (Nullable) [default: 0]
- `unit_price` (numeric) (Nullable) [default: 0]
- `tax_rate` (numeric) (Nullable) [default: 0]
- `total_price` (numeric) (Nullable) [default: 0]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `tax_amount` (numeric) (Nullable) [default: 0]
- `rate_symbol` (text) (Nullable)
- `rate_icon_name` (text) (Nullable)
- `order_index` (integer) [default: 0]
- `category_name` (text) (Nullable)
- `execution_time_label` (text) (Nullable)
- `warranty_time` (integer) (Nullable)
- `warranty_unit` (text) (Nullable) [default: 'days']

---

### `quotes`

Cabecera de cotizaciones emitidas.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `quote_number` (text) (Nullable)
- `client_id` (uuid) [FK -> clients.id]
- `contact_id` (uuid) [FK -> contacts.id]
- `advisor_id` (uuid) [FK -> collaborators.id]
- `category_id` (uuid) [FK -> categories.id]
- `status` (text) (Nullable) [default: 'draft']
- `date_issued` (date) (Nullable) [default: CURRENT_DATE]
- `validity_days` (integer) (Nullable) [default: 15]
- `subtotal` (numeric) (Nullable) [default: 0]
- `tax_amount` (numeric) (Nullable) [default: 0]
- `total` (numeric) (Nullable) [default: 0]
- `notes` (text) (Nullable)
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `updated_at` (timestamp with time zone) (Nullable) [default: now()]
- `user_id` (uuid) [FK -> auth.users] [default: auth.uid()]
- `quote_tag` (text) (Nullable)
- `is_archived` (boolean) (Nullable) [default: false]

---

## 5. Operaciones y Logística

### `product_serials`

Registro y trazabilidad de números de serie para productos.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `purchase_item_id` (uuid) [FK -> purchase_items.id]
- `product_id` (uuid) [FK -> products.id]
- `serial_number` (text)
- `status` (text) [default: 'in_stock']
- `created_at` (timestamp with time zone) [default: now()]
- `updated_at` (timestamp with time zone) [default: now()]

---

### `purchase_items`

Detalle de productos adquiridos en una compra.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `purchase_id` (uuid) [FK -> purchases.id]
- `product_id` (uuid) [FK -> products.id]
- `quantity` (numeric)
- `unit_price` (numeric)
- `warranty_time` (integer) (Nullable)
- `warranty_unit` (text) (Nullable)
- `requires_serials` (boolean) [default: false]
- `created_at` (timestamp with time zone) [default: now()]
- `updated_at` (timestamp with time zone) [default: now()]

---

### `purchases`

Registro de facturas o notas de compra a proveedores.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `user_id` (uuid) [FK -> auth.users] [default: auth.uid()]
- `supplier_id` (uuid) [FK -> suppliers.id]
- `document_type` (text)
- `document_number` (text)
- `date` (date)
- `subtotal` (numeric) [default: 0]
- `tax` (numeric) [default: 0]
- `total` (numeric) [default: 0]
- `has_missing_serials` (boolean) [default: false]
- `created_at` (timestamp with time zone) [default: now()]
- `updated_at` (timestamp with time zone) [default: now()]

---

### `shipping_companies`

Empresas transportadoras/couriers registrados.

- `id` (uuid) [PK] [default: uuid_generate_v4()]
- `legal_name` (text)
- `tax_id` (text)
- `name` (text) (Nullable)
- `is_verified` (boolean) [default: false]
- `user_id` (uuid) [FK -> auth.users]
- `created_at` (timestamp with time zone) [default: timezone('utc', now())]

---

### `shipping_methods`

Métodos o sucursales de envío configurados.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `user_id` (uuid) [FK -> profiles.id]
- `label` (text)
- `delivery_option` (text)
- `branch_code` (text) (Nullable)
- `address` (text) (Nullable)
- `city` (text) (Nullable)
- `state` (text) (Nullable)
- `country` (text) (Nullable)
- `is_primary` (boolean) (Nullable) [default: false]
- `use_main_address` (boolean) (Nullable) [default: false]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `company_id` (uuid) [FK -> shipping_companies.id]

---

## 6. Sistema y Auditoría

### `ai_request_logs`

Registro de auditoría de peticiones enviadas a APIs de IA y Odoo.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `model` (text)
- `status` (text)
- `details` (text) (Nullable)
- `created_at` (timestamp with time zone) [default: now()]

---

### `email_logs`

Registro de auditoría de correos electrónicos enviados.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `user_id` (uuid) [FK -> auth.users]
- `recipient_count` (integer) [default: 1]
- `document_type` (text) (Nullable)
- `created_at` (timestamp with time zone) [default: now()]

---

### `email_templates`

Plantillas de correo electrónico personalizadas por usuario para cotizaciones y otros documentos.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `user_id` (uuid) [FK -> auth.users]
- `document_type` (text)
- `subject_template` (text) (Nullable)
- `body_template` (text) (Nullable)
- `use_automated_signature` (boolean) (Nullable) [default: true]
- `created_at` (timestamp with time zone) (Nullable) [default: now()]
- `updated_at` (timestamp with time zone) (Nullable) [default: now()]

---

### `occupation_sectors`

Relación entre ocupaciones y sectores comerciales.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `occupation_name` (text) (Nullable)
- `sector_id` (uuid) [FK -> sectors.id]
- `occupation_id` (uuid) [FK -> occupations.id]

---

### `occupations`

Catálogo de ocupaciones o sectores laborales de los perfiles.

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `name` (text)
- `created_at` (timestamp with time zone) (Nullable) [default: now()]

---

### `verification_documents`

Documentos cargados para la verificación de identidad (KYC/KYB).

- `id` (uuid) [PK] [default: gen_random_uuid()]
- `user_id` (uuid) [FK -> profiles.id]
- `document_type` (text)
- `file_path` (text)
- `status` (text) (Nullable) [default: 'pending']
- `created_at` (timestamp with time zone) (Nullable) [default: now()]

---

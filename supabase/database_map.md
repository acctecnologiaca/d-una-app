# Mapa Integral de Base de Datos - Proyecto D'Una

Este documento detalla **todas** las tablas, sus campos, tipos de datos y relaciones existentes en el esquema `public`. **Uso obligatorio antes de cualquier modificación en RPCs o triggers.**

## 1. Módulo Core y Usuarios

### `profiles`
Perfil extendido de los usuarios (vinculado a `auth.users`).
- `id` (uuid) [PK, FK -> auth.users]
- `first_name`, `last_name`, `gender` (text)
- `birth_date` (date)
- `national_id`, `avatar_url`, `phone`, `secondary_phone` (text)
- `main_address`, `main_city`, `main_state`, `main_country` (text)
- `is_business_owner` (bool) [default: false]
- `company_name`, `company_rif`, `company_address`, `company_logo_url` (text)
- `verification_status` (enum: `unverified`, `pending`, `verified`, `rejected`) [default: 'unverified']
- `verification_type` (text: `individual`, `business`)
- `occupation_id` (uuid) [FK -> occupations]
- `secondary_occupation_ids` (uuid[])
- `updated_at`, `created_at` (timestamptz)

### `collaborators`
Asesores o personal de ventas.
- `id` (uuid) [PK]
- `full_name`, `identification_id`, `phone`, `email`, `charge` (text)
- `is_active` (bool) [default: true]
- `user_id` (uuid) [FK -> auth.users] [default: auth.uid()]
- `updated_at`, `created_at` (timestamptz)

### `financial_parameters`
Configuración de márgenes e impuestos por usuario.
- `id` (uuid) [PK]
- `user_id` (uuid) [Unique, FK -> auth.users]
- `profit_margin` (numeric) [default: 25.00]
- `tax_rate` (numeric) [default: 16.00]
- `currency_code` (text) [default: 'USD']
- `pricing_method` (text: `margin`, etc.) [default: 'margin']
- `updated_at` (timestamptz)

---

## 2. Red de Proveedores (Marketplace)

### `suppliers`
Entidades proveedoras externas.
- `id` (uuid) [PK]
- `name` (text)
- `api_key` (text) [Unique]
- `tax_id`, `legal_name` (text)
- `phone`, `email` (text)
- `is_active` (bool) [default: true]
- `is_verified`, `is_affiliated` (bool) [default: false]
- `trade_type` (text: `WHOLESALE`, `RETAIL`, `BOTH`)
- `allowed_verification_types` (text[])
- `banner_url`, `logo_url` (text)
- `contact_info`, `notes` (jsonb/text)
- `user_id` (uuid) [FK -> auth.users]
- `normalized_name` (text) [Unique]
- `created_at` (timestamptz)

### `supplier_products`
Catálogo de productos ofrecidos por proveedores.
- `id` (uuid) [PK]
- `supplier_id` (uuid) [FK -> suppliers]
- `name`, `description`, `model`, `model_raw` (text)
- `brand_raw`, `category_raw`, `uom_raw` (text)
- `brand_id` (uuid) [FK -> brands]
- `category_id` (uuid) [FK -> categories]
- `uom_id` (uuid) [FK -> uoms]
- `image_urls` (text[])
- `attributes` (jsonb)
- `is_active` (bool) [default: true]
- `updated_at`, `created_at` (timestamptz)

### `supplier_branches`
Sucursales físicas de los proveedores.
- `id` (uuid) [PK]
- `supplier_id` (uuid) [FK -> suppliers]
- `name`, `city`, `external_id` (text)
- `created_at` (timestamptz)

### `supplier_branch_stock`
Existencias y precios por sucursal.
- `id` (uuid) [PK]
- `product_id` (uuid) [FK -> supplier_products]
- `branch_id` (uuid) [FK -> supplier_branches]
- `quantity` (numeric) [default: 0]
- `price` (numeric) [default: 0]
- `currency` (text) [default: 'USD']
- `updated_at` (timestamptz)

---

## 3. Catálogo y Referencias Maestras

### `products`
Inventario propio del usuario.
- `id` (uuid) [PK]
- `user_id` (uuid) [FK -> profiles]
- `name`, `model`, `specifications`, `image_url` (text)
- `brand_id` (uuid) [FK -> brands]
- `category_id` (uuid) [FK -> categories]
- `uom_id` (uuid) [FK -> uoms]
- `updated_at`, `created_at` (timestamptz)

### `brands`
- `id` (uuid) [PK]
- `name`, `normalized_name` (text) [Unique]
- `is_verified` (bool) [default: false]
- `user_id` (uuid) [FK -> auth.users]

### `categories`
- `id` (uuid) [PK]
- `name`, `normalized_name` (text) [Unique]
- `type` (text: `product`, `service`, `both`, `other`) [default: 'both']
- `is_verified` (bool) [default: false]
- `user_id` (uuid) [FK -> auth.users]

### `uoms` (Unidades de Medida)
- `id` (uuid) [PK]
- `name`, `symbol` (text) [Unique]
- `icon_name` (text)
- `is_verified` (bool) [default: false]
- `user_id` (uuid) [FK -> auth.users]

---

## 4. Ventas y Cotizaciones

### `clients`
- `id` (uuid) [PK]
- `user_id` (uuid) [FK -> auth.users]
- `name`, `alias`, `tax_id`, `email`, `phone`, `address` (text)
- `city`, `state`, `country` (text)
- `type` (text: `company`, `person`)
- `created_at` (timestamptz)

### `contacts`
- `id` (uuid) [PK]
- `client_id` (uuid) [FK -> clients]
- `name`, `role`, `email`, `phone`, `department` (text)
- `is_primary` (bool) [default: false]

### `quotes`
- `id` (uuid) [PK]
- `quote_number` (text) [Unique]
- `client_id` (uuid) [FK -> clients]
- `contact_id` (uuid) [FK -> contacts]
- `advisor_id` (uuid) [FK -> collaborators]
- `category_id` (uuid) [FK -> categories]
- `status` (text: `draft`, `sent`, `approved`, etc.) [default: 'draft']
- `date_issued` (date) [default: CURRENT_DATE]
- `validity_days` (int) [default: 15]
- `subtotal`, `tax_amount`, `total` (numeric)
- `notes` (text)
- `updated_at`, `created_at` (timestamptz)

### `quote_items_products`
- `id` (uuid) [PK]
- `quote_id` (uuid) [FK -> quotes]
- `product_id` (uuid) [FK -> products]
- `supplier_product_id` (uuid) [FK -> supplier_products]
- `delivery_time_id` (uuid) [FK -> delivery_times]
- `name`, `brand`, `model`, `uom`, `description` (text)
- `quantity`, `cost_price`, `profit_margin`, `unit_price`, `tax_rate`, `tax_amount`, `total_price` (numeric)

---

## 5. Otras Tablas

- `services`: Catálogo de servicios del usuario.
- `delivery_times`: Opciones de tiempo de entrega (`days`, `weeks`, etc.).
- `commercial_conditions`: Plantillas de condiciones legales.
- `observations`: Plantillas de notas para notas de entrega.
- `purchases` / `purchase_items`: Registro de facturas de compra.
- `product_serials`: Tracking de seriales por producto.
- `sectors` / `occupations`: Clasificación industrial y profesional.
- `shipping_companies` / `shipping_methods`: Logística de envío.
- `verification_documents`: Documentos cargados por usuarios para validación de cuenta.
- `ai_request_logs`: Auditoría de peticiones a modelos de IA.

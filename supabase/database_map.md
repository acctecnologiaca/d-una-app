# Mapa Integral de Base de Datos - Proyecto D'Una

Este documento detalla **todas** las tablas, sus campos, tipos de datos y
relaciones existentes en el esquema `public`. **Uso obligatorio antes de
cualquier modificación en RPCs o triggers.**

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
- `verification_status` (enum: `unverified`, `pending`, `verified`, `rejected`)
  [default: 'unverified']
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
- `pricing_method` (text: `margin`, `markup`) [default: 'margin']
- `updated_at` (timestamptz)

---

## 2. Red de Proveedores (Marketplace)

### `suppliers`

Entidades proveedoras (Afiliadas y No Afiliadas).

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
- `contact_info` (jsonb)
- `notes` (text)
- `user_id` (uuid) [FK -> auth.users] (Dueño o quien lo registró)
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

### `sectors` / `supplier_sectors`

Clasificación de rubros para proveedores.

- `sectors`: `id`, `name`, `normalized_name`, `created_at`
- `supplier_sectors`: `id`, `supplier_id`, `sector_id`, `display_order`

---

## 3. Catálogo y Referencias Maestras

### `products`

Inventario maestro o productos propios del usuario.

- `id` (uuid) [PK]
- `user_id` (uuid) [FK -> profiles]
- `name`, `model`, `specifications`, `image_url` (text)
- `brand_id` (uuid) [FK -> brands]
- `category_id` (uuid) [FK -> categories]
- `uom_id` (uuid) [FK -> uoms]
- `updated_at`, `created_at` (timestamptz)

### `services`

Catálogo de servicios ofrecidos por el usuario.

- `id` (uuid) [PK]
- `user_id` (uuid) [FK -> auth.users]
- `name`, `description` (text)
- `price` (numeric)
- `service_rate_id` (uuid) [FK -> service_rates]
- `category_id` (uuid) [FK -> categories]
- `has_warranty` (bool)
- `warranty_time` (int), `warranty_unit` (text)
- `updated_at`, `created_at` (timestamptz)

### `brands`, `categories`, `uoms`

Tablas de normalización con soporte para verificación global y personalizada.

- Campos comunes: `id`, `name`, `normalized_name`, `is_verified` (bool),
  `user_id` (uuid)
- `categories.type`: `product`, `service`, `both`, `other`.
- `uoms.icon_name`: Referencia a Material Symbol.

### `service_rates` (Tarifas de Servicio)

- `id` (uuid), `name`, `symbol`, `icon_name`, `user_id`, `is_verified`

### `delivery_times` (Tiempos de Entrega/Ejecución)

- `id` (uuid) [PK]
- `name`, `type` (`delivery`, `execution`, `both`), `unit` (`days`, `weeks`,
  etc.)
- `min_value`, `max_value` (int)
- `order_idx` (int)
- `user_id` (uuid) [FK -> auth.users]

---

## 4. Ventas y Cotizaciones

### `clients` / `contacts`

- `clients`: `id`, `user_id`, `name`, `alias`, `tax_id`, `type` (`company`,
  `person`), `address`, `city`, `state`, `country`.
- `contacts`: `id`, `client_id` [FK], `name`, `role`, `email`, `phone`,
  `is_primary`.

### `quotes`

Cabecera de cotización.

- `id` (uuid) [PK]
- `user_id` (uuid) [FK -> auth.users]
- `quote_number` (text) [Unique]
- `client_id`, `contact_id`, `advisor_id`, `category_id` [FKs]
- `status` (enum: `draft`, `sent`, `approved`, `rejected`, `expired`,
  `cancelled`, etc.)
- `date_issued` (date)
- `validity_days` (int)
- `subtotal`, `tax_amount`, `total` (numeric)
- `notes`, `quote_tag` (text)
- `updated_at`, `created_at` (timestamptz)
- `is_archived` (boolean)

### `quote_items_products`

Ítems de producto en una cotización.

- `id` (uuid) [PK]
- `quote_id` [FK], `product_id` [FK], `supplier_product_id` [FK]
- `delivery_time_id` [FK -> delivery_times]
- `name`, `brand`, `model`, `uom`, `description` (text)
- `quantity`, `cost_price`, `profit_margin`, `unit_price`, `tax_rate`,
  `tax_amount`, `total_price` (numeric)
- `warranty_time` (text)
- `external_provider_name` (text) [Nota de fuente no afiliada]

### `quote_items_services`

Ítems de servicio en una cotización.

- `id`, `quote_id`, `service_id`, `service_rate_id`, `execution_time_id` [FKs]
- `name`, `description`, `quantity`, `cost_price`, `profit_margin`,
  `unit_price`, `tax_rate`, `total_price`, `warranty_time`.

### `commercial_conditions` / `quote_conditions`

- `commercial_conditions`: Plantillas base (`id`, `description`,
  `is_default_quote`, `is_default_report`, `user_id`).
- `quote_conditions`: Instancias vinculadas a cotización (`id`, `quote_id`,
  `condition_id`, `description`, `order_index`).

### `observations`

Plantillas de notas para documentos.

- `id`, `user_id`, `description`, `is_default_delivery_note`, `is_active`.

---

## 5. Operaciones y Logística

### `purchases` / `purchase_items`

Registro de facturas de compra.

- `purchases`: `id`, `user_id`, `supplier_id`, `document_type` (`invoice`,
  `delivery_note`), `document_number`, `date`, `total`.
- `purchase_items`: `id`, `purchase_id`, `product_id`, `quantity`, `unit_price`,
  `warranty_time`, `requires_serials`.

### `product_serials`

Seguimiento de números de serie.

- `id`, `purchase_item_id`, `product_id`, `serial_number`, `status` (`in_stock`,
  `sold`, etc.).

### `shipping_companies` / `shipping_methods`

Logística de envío.

- `shipping_companies`: `id`, `legal_name`, `tax_id`, `name`, `is_verified`.
- `shipping_methods`: `id`, `user_id`, `company_id` [FK], `label`,
  `delivery_option` (`pickup`, `shipping`), `address`, `city`.

---

## 6. Sistema y Auditoría

### `occupations` / `occupation_sectors`

Clasificación profesional de usuarios.

- `occupations`: `id`, `name`, `created_at`.
- `occupation_sectors`: `id`, `occupation_id`, `sector_id`.

### `verification_documents`

Documentos para validación KYC/KYB.

- `id`, `user_id`, `document_type`, `file_path`, `status` (`pending`,
  `verified`, `rejected`).

### `ai_request_logs`

Logs de peticiones a OpenAI/Gemini/Odoo.

- `id`, `model`, `status`, `details`, `created_at`.

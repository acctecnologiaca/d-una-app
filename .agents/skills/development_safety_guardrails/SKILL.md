---
name: development_safety_guardrails
description: Mandatory rules and safety procedures to prevent regressions during backend and core logic development.
---

# Development Safety Guardrails

To avoid regressions in business logic, search engines, and accessibility
filters, the following rules MUST be followed before any structural change.

## 1. Zero-Assumption Schema Verification

**NEVER** assume table or column names, even if they were correct in a previous
step.

- Before generating SQL or modifying repositories, run:
  ```sql
  SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'target_table';
  ```
- Cross-check the actual schema against the intended mapping.

## 2. Mandatory Regression Research

Before modifying an RPC or a core service:

- Search for previous `.sql` files or `implementation_plan.md` involving that
  module.
- Identify "Invisible Logic":
  - **Spanish Search**: Check for `to_tsvector`, `unaccent`, and
    `plainto_tsquery`.
  - **Accessibility** (`is_accessible`): MUST STRICTLY ADHERE to business rules
    mapping Profile vs Supplier:
    1. **Business Verified (`VERIFIED` + `business`)**: Has unrestricted access
       to EVERYTHING (Retail & Wholesale).
    2. **Unverified (`UNVERIFIED` / Pending)**: Has access ONLY to Retail.
       Blocked from Wholesale.
    3. **Individual Verified (`VERIFIED` + `individual`)**: Has access to
       Retail, and ONLY to Wholesale suppliers that explicitly list `individual`
       in their `allowed_verification_types`. _Note: Always use case-insensitive
       SQL comparisons (`LOWER()`, `ILIKE`) for these filters._
  - **Grouping**: Ensure `ARRAY_AGG`, `mode()`, and `GROUP BY` maintain the
    correct aggregation (by brand, model, SKU).
  - **UOM Symbols**: UI Badges use `symbol` (e.g., "m."), while dynamic icons
    use `icon_name` (e.g., "straighten").

## 3. Explicit Implementation Plans

For any core change, the `implementation_plan.md` MUST include:

- **"What is preserved"**: A section listing existing logic that will remain
  intact (e.g., "Spanish search logic will be preserved").
- **Schema Mapping**: A clear table of column name changes.
- **Verification Plan**: Specific test cases for regressions (e.g., "Search for
  terms with accents").

## 4. Atomic Database Migrations

To avoid "Multiple Choices / PGRST203" errors:

- Always use `DROP FUNCTION IF EXISTS public.func_name(arg_types)` for **EVERY**
  known signature of the function.
- Do not rely on `CREATE OR REPLACE` alone if parameters are changing.
- Verify that only one version of the function exists after migration:
  ```sql
  SELECT pg_get_function_arguments(oid) FROM pg_proc WHERE proname = 'func_name';
  ```

## 5. UI/UX Design Integrity and Zero Assumptions

- **NEVER assume or alter UI/UX layouts**: When refactoring, paginating, or adding background features (like ads, analytics, or filters), preserve 100% of the existing UI layout, styling tokens (`surfaceContainerHigh`, `surface`, etc.), auto-focus behaviors, and navigation structures.
- **Header & Search Bars**: Do not move search bars out of AppBars into page bodies or alter established visual hierarchies.
- **Pre/Post Verification**: Always check `git diff` against previous commits to verify no unintended visual regressions were introduced.

## 6. State Persistence & Draft Recovery Guardrails

- **Document Forms & Wizards**: Any screen with document creation, editing, or multi-step input MUST implement local draft auto-save and transparent recovery using `DraftStorageService` and `DraftToast`.
- **Reference Protocol**: Consult and adhere to [Draftable Module Guide](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/development_safety_guardrails/draftable_module_guide.md) and the `implement_draftable_module` skill.
- **Key Isolation**: Never mix creation and edition keys. Use `${DraftConstants.module}` for new docs and `${DraftConstants.module}_$documentId` for editing existing docs.

## 7. User Review

- Present the `implementation_plan.md` and wait for explicit approval before
  executing any destructive `DROP` or schema-altering commands.

## 8. Gestión Contextual de Reserva de Inventario (Cotizaciones y Notas de Entrega)

Para evitar la sobreventa de inventario propio y prevenir advertencias espurias en documentos de venta y despacho:

1. **Unificación de la Ecuación de Reserva en Base de Datos:**
   - La columna `products.reserved_quantity` centraliza **dos fuentes inmutables**:
     1. Cotizaciones con estatus `'approved'` (saldo neto pendiente: $\max(0, \text{qty} - \text{despachado\_en\_NEs\_finalizadas})$).
     2. Notas de Entrega creadas desde cero (`quote_id IS NULL`) en estatus activos (`'draft'`, `'sent'`, `'resent'`, `'opened'`).
   - Al pasar una Nota de Entrega a `'finalized'`, se liquida la reserva y se descuenta el inventario físico (`inventory_quantity`).
   - Al pasar a `'cancelled'`, las unidades reservadas se liberan de inmediato retornando al stock libre disponible.
   - El guardrail de base de datos (`validate_quote_items` y trigger de `delivery_notes`) arroja la excepción `STOCK_INSUFFICIENT` si se intenta sobreasignar inventario propio libre.

2. **Acceso Contextual en Notas de Entrega:**
   - **NE desde Cotización Aprobada (`quote_id != null`):** Tiene acceso prioritario a la cantidad reservada por esa cotización (`quoteRemainingBalance`) más cualquier stock libre de almacén (`freeStock`). En productos afiliados o externos, la cuota autorizada es el saldo cotizado.
   - **NE desde Cero (`quote_id == null`):** Únicamente puede consumir stock libre de almacén ($\max(0, \text{inv\_qty} - \text{reserved\_qty})$).

3. **Estándar Oficial de UI para Productos con Reservas:**
   - **Producto 100% Reservado (`effectiveAvailable <= 0` con stock físico en almacén):**
     - La tarjeta **debe bloquearse** (`hasStock = false`, `IgnorePointer`, opacidad reducida `0.5`).
     - El badge `UomStatusBadge` muestra la cantidad física real de almacén (p. ej. `1 ud.`) en lugar de `"Sin stock"`.
     - Subtítulo en rojo (`colors.error`, negrita):
       `'Todo el inventario propio está reservado en cotizaciones aprobadas o notas de entrega no finalizadas.'`.
   - **Producto con Stock Libre Disponible (`effectiveAvailable > 0` con reservas parciales):**
     - La tarjeta **permanece activa** y seleccionable.
     - El badge muestra la disponibilidad libre real a despachar (p. ej. `2 ud.`), y el stepper se acota a ese tope (`max: effectiveAvailable`).
     - Subtítulo informativo neutral (`colors.onSurfaceVariant`):
       `'Hay ${effectiveAvailable} $uom disponibles de ${physicalStock} en inventario propio.'`.
   - **En Cotizaciones (Tarjetas de Selección y Agregado):**
     - Si hay reserva activa, advertir con precisión:
       `'Hay X $uom de inventario propio reservadas en cotizaciones o notas de entrega.'`.

## 9. Homologación Simétrica, Salvaguarda de Monetización y Cierre en Cascada

1. **Aprobación Guiada y Salvaguarda de Proveedores Afiliados en Notas de Entrega:**
   - Vincular una cotización en `draft` o `sent` desde una Nota de Entrega nunca debe auto-aprobarse de forma silenciosa.
   - Si la cotización incluye productos de proveedores afiliados (`QuoteSuppliersOcStatus`), el sistema **debe validar** que todas las Órdenes de Compra correspondientes se encuentren en estatus `approved` o `finalized` antes de permitir la aprobación para despacho.
   - Si existen OCs de afiliados pendientes o no emitidas, la vinculación se bloquea de inmediato mostrando el diálogo de salvaguarda (`Symbols.lock`, "Orden de Compra Requerida").
   - Si la validación pasa, se solicita aprobación explícita y consentida del usuario antes de precargar los ítems y reservar formalmente el inventario.

2. **Detección Asistiva y Vinculación Homologada de Órdenes de Compra en Compras:**
   - En el registro de compras (`AddPurchaseDetailsTab`), la vinculación de Órdenes de Compra utiliza el componente oficial `CustomDropdown<SupplierOrder>` con la lista de órdenes aprobadas de almacén propio del proveedor seleccionado (`pendingApprovedOrdersBySupplierProvider`).
   - El selector soporta tanto la vinculación directa como el reemplazo preventivo mediante `CustomDialog.confirmation` (`[Solo vincular]` / `[Reemplazar]`).
   - Al guardar la compra (`savePurchase`), si existe una orden de compra vinculada, ésta pasa automáticamente a estatus `finalized`, erradicando el riesgo de duplicidad de stock local.

3. **Cierre en Cascada en Lote para Dropshipping Multimarca:**
   - Al confirmar la recepción y estampación de firma del cliente en una Nota de Entrega (`ConfirmDeliveryNoteReceptionDialog`), si la nota proviene de una cotización (`note.quoteId != null`), el sistema ejecuta `finalizeDropshippingOrdersByQuoteId(quoteId)` para cerrar en lote todas las órdenes de compra Dropshipping aprobadas vinculadas a esa cotización.
   - Esto garantiza que órdenes de compra con múltiples proveedores afiliados para un mismo despacho queden conciliadas y finalizadas simultáneamente.

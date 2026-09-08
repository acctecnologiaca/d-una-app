# Regla de Integridad de UI/UX, Reutilización de Componentes y Prohibición de Suposiciones

## Principio Fundamental (Mandatorio)

**NUNCA ASUMIR CAMBIOS DE UI/UX, NUNCA CREAR COMPONENTES DUPLICADOS Y PRESERVAR ESTRICTAMENTE LA ESTRUCTURA VISUAL DEL SISTEMA DE DISEÑO DE D'UNA APP.**

Al desarrollar nuevos módulos, refactorizar pantallas existentes o agregar funcionalidades:

---

### 1. Consulta Previa Obligatoria de la Guía Maestra y Arquetipos
Antes de proponer o escribir cualquier interfaz gráfica, es **obligatorio** consultar:
- **La Guía Maestra de Componentes:** [`shared_components_guide`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/shared_components_guide/SKILL.md) con el inventario de los 47 widgets de `lib/shared/widgets/`.
- **El Arquetipo de Pantalla correspondiente:**
  - *Arquetipo 1 (Listas)*: [`standardize_list_main_screen_ui`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_list_main_screen_ui/SKILL.md)
  - *Arquetipo 2 (Vistas de Documento)*: [`standardize_document_view_screen`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_document_view_screen/SKILL.md)
  - *Arquetipo 3 (Wizards y Creadores)*: [`create_wizard_step`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/create_wizard_step/SKILL.md)
  - *Arquetipo 4 (Detalle de Entidad)*: [`standardize_details_ui`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_details_ui/SKILL.md)
  - *Arquetipo 5 (Formularios)*: [`standardize_form_screen`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_form_screen/SKILL.md)
  - *Arquetipo 6 (Búsqueda)*: [`standardize_search_ui`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/standardize_search_ui/SKILL.md)

---

### 2. Prohibición Estricta de Componentes Duplicados
- **Queda terminantemente prohibido** crear nuevos widgets de botones, campos de texto, selectores desplegables, barras de herramientas, modales de confirmación o toasts en carpetas de características (`lib/features/.../widgets`) si ya existe un componente equivalente en `lib/shared/widgets/`.
- Componentes obligatorios:
  - Text inputs: `CustomTextField`
  - Dropdowns: `CustomDropdown` / `CustomMultiDropdown`
  - Steppers: `CustomStepper` / `EditableQuantityStepper`
  - Ubicación: `CustomLocationPicker`
  - Notificaciones flotantes: `AppToast.showSuccess` / `AppToast.showError` (prohibido `ScaffoldMessenger.showSnackBar` crudo)
  - Diálogos modales: `CustomDialog` y `CustomDialog.destructive`
  - Menús inferiores: `CustomActionSheet` con `BottomSheetActionItem`
  - FABs de listas: `CustomExtendedFab` (oculto en modo selección)

---

### 3. Preservación Estricta de Tokens y Layout
- La disposición espacial (layout), jerarquía de widgets, colores de tema (`surface`, `surfaceContainer`, `primaryContainer`, etc.), márgenes canónicos (16px) y paddings deben mantenerse 100% fieles al diseño establecido.
- **Fórmula de Dynamic Bottom Padding para FABs:**
  En cualquier vista con scroll (`SingleChildScrollView` o `ListView`), es **mandatorio** aplicar:
  - **184.0 px** si hay 2 FABs apilados.
  - **112.0 px** si hay 1 FAB activo.
  - **24.0 px** si no hay FABs.
- **Prohibición de números entre paréntesis en pestañas:** Los tabs nunca deben llevar conteos como `(3)`. Las alertas de validación deben usar `Badge(backgroundColor: colors.error, smallSize: 8)`.

---

### 4. Verificación de Regresiones
- Antes y después de modificar un widget o pantalla, ejecutar validación estática y comparar (`git diff`) para garantizar que no se alteren layouts ni se rompa la consistencia visual del sistema.

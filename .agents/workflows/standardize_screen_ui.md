---
description: Estandarización de pantallas con componentes oficiales (Formularios, Wizards y Listados)
---

# Workflow: Estandarización de Pantallas UI

Sigue estos pasos para homologar pantallas existentes o crear nuevos pasos/formularios usando el Sistema de Diseño oficial de D'Una App.

---

## 1. Reglas Generales de Estandarización

1. **Campos de Texto:**
   - Reemplazar `TextFormField` o `TextField` por **`CustomTextField`**.
   - Mapeo: `decoration: InputDecoration(labelText: 'X')` $\rightarrow$ `label: 'X'`, `controller: _ctrl`, `validator: _val`, `keyboardType`, `inputFormatters`, `enabled`, `readOnly`.

2. **Selectores y Desplegables:**
   - Reemplazar `DropdownButton` o `DropdownButtonFormField` por **`CustomDropdown<T>`** o **`CustomMultiDropdown<T>`**.

3. **Barras de Acción Inferior:**
   - **Formularios estándar (Guardar / Cancelar):** Usar **`FormBottomBar`**.
     - `onCancel`: `() => context.pop()`
     - `onSave`: `_submitForm`
     - `isLoading`: variable de estado de carga
     - `isSaveEnabled`: validación condicional
   - **Flujos por pasos / Wizards (Atrás / Siguiente / Cancelar):** Usar **`WizardButtonBar`**.
     - `onCancel`: `() => context.pop()`
     - `onBack`: `_prevStep`
     - `onNext`: `_nextStep` (o `null` si está deshabilitado)

4. **Layout y Prevención de Overflow:**
   - Envolver el contenido con `SingleChildScrollView`.
   - Para evitar desbordes con el teclado virtual cuando hay barras inferiores fijas, aplicar el patrón `LayoutBuilder` + `ConstrainedBox`.

---

## 2. Creación y Estandarización de Pasos de Wizard

Cuando construyas o adaptes un paso dentro de un Wizard (Arquetipo 3):
1. **Consulta la Skill:** Lee la skill de referencia en [.agents/skills/create_wizard_step/SKILL.md](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/.agents/skills/create_wizard_step/SKILL.md).
2. **Definir Requisitos del Paso:**
   - Datos a capturar (Texto, selección, fechas, imágenes).
   - Posición en el flujo: ¿Primer paso, intermedio o confirmación final?
3. **Estructura del Paso:**
   - Incluir título y descripción contextual del paso.
   - Usar `CustomTextField` y `CustomDropdown` estandarizados.
   - Implementar validación estricta antes de permitir el avance en el callback `onNext`.
4. **Integración con el Orquestador:**
   - Añadir la pantalla del paso al contenedor principal (`IndexedStack` con `WizardProgressBar`).

---

## 3. Verificación
- Ejecutar `flutter analyze` sobre los archivos modificados.
- Comprobar que no existan advertencias de overflow al abrir el teclado.
- Verificar consistencia estética con los design tokens globales.

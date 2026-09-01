# Regla de Integridad de UI/UX y Prohibición de Suposiciones

## Principio Fundamental (Mandatorio)

**NUNCA ASUMIR CAMBIOS DE UI/UX NI MODIFICAR LA ESTRUCTURA VISUAL EXISTENTE SIN AUTORIZACIÓN EXPLICITA.**

Al realizar refactorizaciones, optimizaciones de rendimiento, integración de nuevas características (como banners, analíticas o filtros) o modificaciones arquitectónicas:

1. **Preservación Estricta del Diseño y UX:**
   - La disposición espacial (layout), jerarquía de widgets, colores de tema (`surfaceContainerHigh`, `surface`, etc.), márgenes, paddings y comportamiento de componentes existentes (como la barra de búsqueda en el `AppBar`, autoenfoque del teclado, modales, hojas de acción) **deben mantenerse 100% fieles a su diseño original**.
   - No se permite alterar componentes compartidos (`GenericSearchScreen`, `PaginatedListView`, `CustomSearchBar`, etc.) degradando o cambiando su layout establecido.

2. **Prohibición de Suposiciones Visuales:**
   - Si una tarea requiere agregar un nuevo elemento visual o funcionalidad transversal, debe integrarse adaptándose al diseño y estructura existentes, jamás rediseñando arbitrariamente la pantalla.
   - Cualquier cambio en la experiencia de usuario o en la disposición visual debe ser propuesto y aprobado explícitamente por el usuario en el PDI.

3. **Verificación de Regresiones Visuales:**
   - Antes y después de modificar un widget o pantalla compartida, comparar minuciosamente (`git diff`) con la versión previa para garantizar que no se hayan introducido alteraciones no solicitadas en el layout o flujo de interacción.

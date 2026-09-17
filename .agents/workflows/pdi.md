---
description: Generar un Plan de Implementación (PDI) estructurado paso a paso sin modificar código
---

# Workflow: Generación de PDI (Plan Detallado de Implementación)

Este comando se activa con `/pdi [descripción de la tarea, correcciones o contexto]`.

## Instrucciones de Ejecución

1. **NO REALICES CAMBIOS EN EL CÓDIGO.**
2. Analiza detalladamente el contexto provisto por el usuario, el código fuente relevante, dependencias y arquitectura.
3. Elabora un **PDI (artefacto `implementation_plan.md`)** estructurado paso a paso, optimizado para que **Gemini Flash 3.8 Low** (o cualquier modelo secundario) lo ejecute con precisión.
4. **Código de referencia:** Si consideras que debes dejar código de referencia en el PDI para guiar al modelo ejecutor (firmas de métodos, snippets completos, manejo de estado o llamadas a APIs), **¡hazlo explícitamente!**
5. Asegúrate de incluir:
   - Rutas exactas a los archivos con enlaces markdown (`file:///...`).
   - Lógica detallada de cada clase/función.
   - Nombres claros de variables y constantes.
   - Puntos de verificación y dependencias.
6. **Auto-Stop obligatorio:** Presenta el plan al usuario y detén la ejecución. **No escribas código de implementación** hasta que el usuario responda aprobando el plan.

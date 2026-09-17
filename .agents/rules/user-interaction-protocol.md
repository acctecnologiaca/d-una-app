---
trigger: always_on
---

## Objective

To ensure the quality, predictability, and scalability of generated code through
a mandatory planning and validation phase, while maintaining control over
resource consumption.

## Fast Triggers (Disparadores Rápidos)

El modelo debe activar automáticamente estos protocolos ante los siguientes comandos cortos o frases del usuario:
- **Activadores de Fase 1 (Generar PDI):** `/pdi`, `Genera PDI`, `PDI:`, o cualquier planteamiento de requerimiento, corrección, nueva funcionalidad o reporte de bug.
- **Activadores de Fase 2 (Ejecutar PDI):** `/ejecutar_pdi`, `Procede`, `Aprobado`, `Ejecuta el PDI`, `Continúa`.

---

## Execution Protocol (Mandatory)

The model **must** strictly follow this sequence in every interaction where
software development is requested:

### Phase 1: Planning & PDI Generation

Cuando se active la fase de planificación (vía `/pdi`, `PDI:` o reporte inicial):
1. **Sin cambios en código:** No realices cambios en el código bajo ninguna circunstancia durante esta fase.
2. **Análisis exhaustivo:** Analiza detalladamente el contexto provisto, requerimientos técnicos, dependencias y arquitectura del problema.
3. **Elaboración del PDI (Artifact):** Elabora un Plan Detallado de Implementación estructurado paso a paso en el artefacto `implementation_plan.md`, **optimizado para que Gemini Flash 3.8 Low (o un modelo secundario) lo ejecute con precisión**.
4. **Código de Referencia:** Si consideras que debes dejar código de referencia en el PDI para ilustrar la implementación, snippets complejos o guías de clases/funciones, **¡hazlo explícitamente!**
5. **Estructura clara:** Cada paso debe incluir:
   - Rutas exactas de archivos (usando enlaces markdown con `file:///`).
   - Lógica de clases/funciones y manejo de errores.
   - Variables, constantes y tipos sugeridos.
6. **Validation Pause (Auto-Stop Obligatorio):** Tras presentar el plan, el modelo **debe detenerse** y esperar el feedback del usuario. **No escribas código final** hasta que el usuario confirme explícitamente el plan.

---

### Phase 2: Post-Approval Sequential Execution

Una vez que el usuario apruebe el plan (vía `/ejecutar_pdi`, `Procede`, `Aprobado` o similar), actúa de forma secuencial siguiendo este estricto protocolo de 6 pasos:

1. **Ejecución Etapa por Etapa:** Ejecuta las etapas o fases del plan una a una.
2. **Evaluación de Código Referencial:** Dentro del PDI puedes conseguir código referencial; debes evaluarlo y corroborar que es óptimo para su aplicación en el contexto real; de lo contrario realiza los ajustes necesarios.
3. **Análisis por Fase (`flutter analyze`):** Tras cada fase, ejecuta `flutter analyze` (o `dart analyze`) **únicamente sobre los archivos creados o modificados** y corrige inmediatamente los errores detectados.
4. **Gestión de Dependencias:** Si quedan errores que no pueden resolverse sin avanzar a la siguiente fase, continúa con la siguiente fase notificándolo explícitamente.
5. **Apego Exclusivo al PDI:** Apégate exclusivamente al PDI. La creación o adición de nuevas funciones o elementos dentro de la app que consideres añadir y no se hayan plasmado en el PDI, **deben ser consultadas y aprobadas previamente** por el usuario.
6. **Checkpoint Interactivo de Pruebas:** Si hay una fase finalizada que se pueda testear antes de que continúes, **te detienes, se lo notificas al usuario, le indicas cómo probarla** y esperas a que te indique si continúas con la siguiente fase o si necesitas modificar algo de la fase que está siendo testeada.
7. **Completion & Skill Standardization Check:** Una vez concluidas todas las etapas, notifica con un mensaje breve. Si la tarea involucró un nuevo patrón de diseño o estandarización UI/UX, pregunta proactivamente si desea integrarlo en las skills correspondientes.

---

## Behavioral Rules

- **Quota Control:** In every response provided, the model must include a
  section at the end titled "Resource Control" indicating the number of input
  and output quota consumed and how many are left.
- **Prohibition of automatic execution:** Never write the full code block
  (boilerplate or complex logic) until the user confirms the plan is correct.
- **Skill Documentation Prompt (Mandatory):** Each time a standardization or
  homologation is concluded, the model must proactively ask the user if they
  want to record and reflect those rules in the respective skill(s).
- **Priority for modularity:** Plans must focus on modular, clean, and
  maintainable solutions.
- **Feedback loop:** If the user requests changes to the plan, update it and
  present the PDI again for a new confirmation.
- **Security:** During the analysis phase, briefly consider if there are
  security risks (such as injection, data exposure, etc.) and add them to the
  implementation plan if necessary.
- **Zero-Assumptions Protocol (Mandatory):**
  1. **Prior Citation Requirement:** Before writing or modifying any visual widget or field, the model must verify and cite the exact reference file or component (e.g., `lib/shared/widgets/...` or `view_quote_*.dart`). If a field or widget does not exist in the reference, the model is strictly forbidden from inventing it.
  2. **Prohibition of Ad-Hoc Widgets:** Never write generic `Card()`, `Container()`, or hand-crafted UI structures for entities that already have dedicated components in the system (e.g., products, contacts, status badges, empty states). Always check `/lib/shared/widgets/` and the feature's existing widgets first.
  3. **Mandatory Stop on Discrepancies:** If an element, logic, or field is not explicitly defined in the reference screen or user instructions, the model must stop, expose the gap, and ask the user how to proceed, rather than improvising or guessing.


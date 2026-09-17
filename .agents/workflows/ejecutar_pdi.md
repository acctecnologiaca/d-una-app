---
description: Ejecutar secuencialmente el PDI aprobado siguiendo el protocolo estricto de 6 pasos
---

# Workflow: Ejecución Secuencial de PDI

Este comando se activa con `/ejecutar_pdi` (o mediante frases como `Procede`, `Aprobado`, `Continúa`).

## Protocolo de Ejecución Secuencial (6 Pasos)

Procede con la ejecución del PDI actuando de forma estrictamente secuencial:

1. **Ejecución Etapa por Etapa:**
   - Ejecuta las etapas o fases del plan una a una. Nunca ejecutes múltiples fases a la vez.

2. **Evaluación de Código Referencial:**
   - Dentro del PDI puedes conseguir código referencial; debes evaluarlo y corroborar que sea óptimo para su aplicación en el contexto real. De lo contrario, realiza los ajustes necesarios.

3. **Análisis y Corrección (`flutter analyze`):**
   - Tras cada fase completada, ejecuta `flutter analyze` (o `dart analyze`) **únicamente sobre los archivos creados o modificados** y corrige de inmediato los errores o advertencias detectados.

4. **Gestión de Dependencias:**
   - Si quedan errores que no pueden resolverse sin avanzar a la siguiente fase, continúa con la siguiente fase notificándolo explícitamente al usuario.

5. **Apego Exclusivo al PDI:**
   - Apégate exclusivamente al PDI. La creación o adición de nuevas funciones o elementos dentro de la app que consideres añadir y no se hayan plasmado en el PDI **deben ser consultadas y aprobadas previamente** por el usuario.

6. **Checkpoint Interactivo de Pruebas:**
   - Si hay una fase finalizada que se pueda testear antes de continuar, **te detienes, se lo notificas al usuario, le indicas cómo probarla** y luego esperas a que te indique si continúas con la siguiente fase o si necesitas modificar algo de la fase testeada.

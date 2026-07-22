---
description: Protocolo estricto para análisis y resolución de bugs secuenciales
---

# Protocolo Estricto de Análisis y Resolución de Bugs

Este workflow establece las pautas y fases obligatorias para la corrección de
cualquier anomalía o bug en el proyecto. Debe seguirse de forma rigurosa y
secuencial sin saltarse ningún paso.

---

## 1. Protocolo de Análisis de Bugs (Fase de Diseño)

Cuando el usuario reporta un bug, el Agente debe actuar estrictamente en modo de
planificación y análisis:

1. **Recibir detalles:** Obtener toda la información sobre el bug provista por
   el usuario.
2. **Análisis meticuloso:** Investigar el código fuente, archivos del modelo,
   bases de datos y providers involucrados.
3. **Re-evaluación interna:** Formular una propuesta de solución y re-evaluarla
   minuciosamente de inmediato para descartar efectos secundarios, lógicas
   invisibles o problemas RLS.
4. **Crear Plan de Implementación:** Crear o actualizar el artefacto
   `implementation_plan.md` con todos los detalles técnicos posibles, dividido
   en etapas claras y estructurado para que un modelo de lenguaje (LLM) de menor
   capacidad lo pueda ejecutar paso a paso. Si consideras que el código puede
   ser complejo, déjalo plasmado en el plan para que el otro modelo de lenguaje
   lo copie o se guíe.
5. **Auto-Bloqueo:** **NO ejecutar** el plan. Presentarlo al usuario y esperar
   su feedback explícito.
6. **Decisión del Usuario:** El usuario responderá para autorizar la ejecución
   del plan o sugerir modificaciones.

---

## 2. Protocolo de Resolución de Bugs (Fase de Ejecución)

Una vez que el usuario aprueba el plan de implementación, la ejecución se
realizará de forma secuencial y controlada:

1. **Ejecución Etapa por Etapa:** Ejecutar únicamente los pasos correspondientes
   a la **etapa activa** del plan de implementación.
2. **Análisis por cada Etapa:** Tras finalizar cada etapa, ejecutar
   obligatoriamente `flutter analyze` (o dart analyze) sobre los archivos
   modificados para corregir inmediatamente cualquier advertencia o error del
   linter.
3. **Notificación de Bloqueos:** Si surgen errores que no pueden ser resueltos
   sin avanzar a la siguiente etapa, notificar explícitamente al usuario
   explicando la situación técnica.
4. **Punto de Control Obligatorio:** **Detenerse y esperar confirmación** del
   usuario al finalizar cada etapa del plan. **NO avanzar** a la siguiente etapa
   sin su autorización explícita.

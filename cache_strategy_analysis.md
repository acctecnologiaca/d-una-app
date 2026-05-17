# Estrategia de Caché y Disponibilidad Offline para D'Una

Basado en la naturaleza de la aplicación (una herramienta integral B2B/B2C para gestión de clientes, cotizaciones, inventario y portafolio), la app funciona como el "cerebro" del negocio del usuario. En escenarios del mundo real (visitas a clientes, almacenes subterráneos, zonas de baja cobertura o conduciendo), el usuario necesita acceder a la información de su negocio sin depender de una conexión estable.

A continuación, presento un análisis meticuloso dividiendo la información de la app en **3 niveles de prioridad** para determinar qué debe permanecer en caché (memoria RAM a corto plazo o base de datos local a largo plazo).

---

## Nivel 1: Crítico para el Negocio (Tier 1)
*Información que el usuario **siempre** debe poder leer, incluso si reinicia el teléfono en modo avión. Lo ideal es usar caché persistente (ej. SQLite, Isar, o Hive).*

### 1. Catálogo Propio (Inventario y Servicios)
- **Razón:** El usuario necesita poder decirle a un cliente "Sí lo tengo" o "Este es el precio" en cualquier momento y lugar. No poder dar un precio por falta de internet hace perder ventas.
- **Datos a guardar:** `productsProvider` y `servicesProvider` (nombres, precios, stock actual, iconos).

### 2. Directorio de Clientes
- **Razón:** Funciona como la agenda telefónica comercial. Si el usuario va de camino a visitar a un cliente y se queda sin señal, necesita poder abrir la app para ver la dirección, el teléfono de contacto y el historial básico.
- **Datos a guardar:** `clientsProvider` (nombres, teléfonos, direcciones, correos).

### 3. Parámetros Financieros y de Perfil
- **Razón:** Para que la app siquiera funcione o muestre la UI correctamente (cálculos de impuestos, monedas, foto de perfil), el perfil base debe estar guardado localmente.
- **Datos a guardar:** `userProfileProvider`, configuración de impuestos, moneda base (`settings`).

---

## Nivel 2: Altamente Recomendable (Tier 2)
*Información muy útil para consulta offline. Puede vivir en la caché de memoria RAM de Riverpod mientras la app está abierta, o guardarse localmente si hay espacio.*

### 1. Historial de Cotizaciones Recientes
- **Razón:** En medio de una negociación, el usuario puede necesitar revisar "qué precio le coticé a este cliente la semana pasada".
- **Datos a guardar:** Las últimas 20-50 cotizaciones (`quotesListProvider`). No es necesario guardar el PDF físico en caché, pero sí el resumen de la cotización (monto total, ítems, fecha).

### 2. Inventario de Proveedores y Marcas
- **Razón:** Si un cliente pide un producto que el usuario no tiene en su *Inventario Propio*, el usuario querrá revisar rápidamente si su proveedor de confianza lo maneja.
- **Datos a guardar:** `suppliersProvider` (directorio de proveedores) y catálogos clave descargados previamente.

### 3. Plantillas de Correo y Mensajes
- **Razón:** Útil si el usuario está preparando (redactando) mensajes que se enviarán en cuanto recupere la conexión.

---

## Nivel 3: Dependiente de Conexión (Tier 3)
*Información que carece de sentido o es riesgosa si se muestra desactualizada. No es necesario mantenerla en caché persistente y se debe notificar al usuario que requiere internet.*

### 1. Estadísticas y Reportes (`reports`)
- **Razón:** Ver un reporte financiero del mes pasado sin los datos de las ventas de hoy puede llevar a tomar malas decisiones. Es preferible mostrar el error "Sin conexión" a mostrar un gráfico desactualizado.
- **Acción:** No cachear de forma agresiva. Usar el `FriendlyErrorWidget`.

### 2. Creación y Modificación de Datos Críticos
- **Razón:** Aunque la lectura puede ser offline, la creación de nuevas cotizaciones con *stock sincronizado*, o el cobro de compras, requiere comunicación directa con el servidor para evitar facturar productos agotados. 
- **Excepción:** Se podría permitir crear "borradores" locales (offline-first) que se suban luego, pero es complejo de implementar. Por ahora, los formularios de "Nuevo" deben deshabilitarse sin internet (justo lo que hicimos ocultando los botones FAB).

### 3. Colaboradores y Permisos (`collaborators`)
- **Razón:** Por seguridad, los roles y accesos deben validarse en tiempo real.

---

## Conclusión y Recomendación Arquitectónica

Actualmente, **Riverpod** está haciendo un excelente trabajo de **Caché en Memoria (RAM)**. Como te diste cuenta hoy, si abres "Clientes", se guarda en RAM y sobrevive cortes de internet mientras la app siga viva en segundo plano.

Si en el futuro deseas que esta información sobreviva incluso si **cierras la app por completo (Swipe Up)**, tendríamos que implementar una base de datos local (como `Isar` o `sqflite`) en el patrón de repositorio, de modo que el `FutureProvider` primero lea el archivo local e instantáneamente muestre la UI, y luego pida los datos a Supabase en segundo plano para actualizarse.

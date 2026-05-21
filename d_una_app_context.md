# DOCUMENTO DE CONTEXTO Y ESPECIFICACIÓN TÉCNICA (LLM-READY)
## PROYECTO: D-UNA App

> **Instrucciones para el LLM:** Este documento contiene la especificación unificada absoluta de la plataforma "D-UNA App". Utiliza este texto como contexto base e inmutable para la generación de código, diseño de bases de datos, arquitectura de software y flujos de interfaz de usuario. No asumas reglas externas; rígete estrictamente por las dependencias y lógicas de negocio aquí descritas.

---

## 1. METADATOS Y PROPÓSITO DEL SISTEMA

* **Nombre de la Plataforma:** D-UNA App (también referenciada como D.UNA App).
* **Eslóganes Oficiales:** * "Házlo ahora, házlo D.UNA"
    * "¡Házlo ahora, házlo de una!"
* **Público Objetivo:** Técnicos e instaladores profesionales independientes o autónomos (ej. CCTV, controles de acceso, redes, electricidad, seguridad perimetral).
* **Objetivo Central:** Centralizar y transformar la operatividad comercial y técnica del sector autónomo mediante una interfaz única. Permite la oferta de servicios, gestión de clientes, venta de productos propios, adquisición optimizada con proveedores mayoristas afiliados y automatización de la contabilidad/administración básica del técnico.

---

## 2. ARQUITECTURA DE INTERFAZ Y NAVEGACIÓN (UI/UX)

El sistema se estructura en tres entornos de acceso global e inmediato:

### A. Barra Superior Derecha
* **Perfil de Usuario:** Acceso directo a la identidad, configuraciones de seguridad y estado de verificación comercial del técnico.

### B. Barra de Navegación Inferior Principal (Módulos de Alta Recurrencia)
1.  **Clientes:** Control de cartera de clientes.
2.  **Portafolio:** Catálogos e inventarios unificados.
3.  **Cotizaciones:** Generador transaccional de ofertas comerciales.
4.  **Reportes:** Documentación y cierre de servicios técnicos.

### C. Panel de Navegación Lateral (Navigation Drawer - Módulos Administrativos y de Control)
1.  **Pedidos a Proveedores:** Seguimiento de compras mayoristas.
2.  **Mis Compras:** Historial de facturas y carga de seriales.
3.  **Notas de Entrega:** Validación de entrega física con herramientas de campo.
4.  **Recibos:** Control de cobros y abonos de clientes.
5.  **Colaboradores:** Registro de personal y asignación documental.
6.  **Configuración:** Panel paramétrico global (Dividido estrictamente en 3 secciones).

---

## 3. ESPECIFICACIÓN DE FLUJOS Y MÓDULOS DETALLADOS

### 3.1 Asistente de Registro de Usuario (Onboarding)
Flujo secuencial e ininterrumpido de 7 pasos obligatorios:
* **Paso 1:** Entrada de correo electrónico.
* **Paso 2:** Creación y confirmación de contraseña segura.
* **Paso 3:** Entrada de nombres.
* **Paso 4:** Entrada de apellidos.
* **Paso 5:** Selección de ocupación o sector técnico de desempeño.
* **Paso 6:** Envío automatizado de código OTP al correo electrónico.
* **Paso 7:** Entrada y validación del código OTP para activación final de la cuenta.

### 3.2 Módulo: Perfil de Usuario y Verificación Mayorista
* **Submódulo Datos Básicos:** Username (string único global), nombres, apellidos, ID/Cédula, fecha de nacimiento, género, foto de perfil.
* **Submódulo Datos de Contacto:** Teléfono celular principal (con verificación interna obligatoria), teléfono alternativo, correo electrónico verificado.
* **Submódulo Dirección Principal:** Dirección fiscal, taller u oficina física de operaciones.
* **Submódulo Métodos de Envío Predefinidos:** Agencias de encomienda preferidas para recibir mercancía de mayoristas (ej: MRW, Tealca), incluyendo opciones fijas: "Retiro en sucursal" y "Entrega a domicilio".
* **Submódulo Ocupación Ampliada:** Selección de hasta tres (3) ocupaciones máximas (1 Principal, 2 Secundarias) para segmentación de catálogos mayoristas.
* **Submódulo Seguridad:** Modificación de credenciales de acceso.
* **Submódulo Verificación Documental (Alta con Proveedores):** Flujo para desbloquear precios mayoristas. La app automatiza el envío de datos por correo al proveedor según el tipo de entidad:
    * *Empresa Registrada:* Requiere adjuntar Documento Constitutivo, RIF corporativo y Referencias Comerciales.
    * *Persona Natural / Independiente:* Requiere adjuntar Cédula de Identidad, Certificados de cursos/capacitación técnica verificables y Referencias Comerciales.

### 3.3 Módulo: Gestión de Clientes
CRUD con soporte estricto para dos tipos de modelos de datos:
1.  **Cliente Tipo Empresa (Persona Jurídica):** Razón social, RIF/ID, alias comercial, dirección fiscal y un arreglo de *Personas de Contacto* (Cada contacto tiene de forma obligatoria: Nombre, Apellido, Teléfono, Correo, Cargo, Departamento, Sede).
2.  **Cliente Tipo Persona Natural:** Nombre, Apellido, Cédula de Identidad, Dirección de domicilio, Teléfono, Correo electrónico.

### 3.4 Módulo: Portafolio (Inventarios y Servicios)
Estructura tripartita que alimenta directamente las transacciones comerciales:
* **Inventario Propio:** Registro físico en stock del técnico. Mapea: Modelo/Número de parte, marca, nombre, especificaciones técnicas, categoría, imagen. Está directamente acoplado al módulo "Mis Compras" para heredar costos reales, historial de facturas de origen y cantidades remanentes. Permite calcular precios de venta estimados.
* **Inventario de Proveedores (Acceso en Caliente):** Sincronización en tiempo real vía API con catálogos de distribuidores mayoristas aliados. Atributos expuestos: Precio actualizado de distribuidor, nombre, descripción, marca, código/número de parte y stock disponible (absoluto o estimado). Cuenta con filtrado de proveedores según el rubro comercial del técnico y la funcionalidad de **Carrito de Compras Multi-Proveedor**, consolidando y enviando órdenes independientes automáticamente por correo a cada proveedor involucrado.
* **Servicios Propios (Tarifario):** Catálogo de mano de obra e ingeniería. Registra: Nombre del servicio, descripción de tareas, tipo de precio, tarifa, categoría y cantidad de días de garantía técnica otorgados al cliente final.

### 3.5 Módulo: Cotizaciones
Herramienta de diseño comercial "en caliente". El uso del stock de proveedores es referencial y no genera reserva automática de inventario en esta fase.
* **Sección Productos:** Lista de ítems añadidos. Orígenes admitidos: Inventario Propio, Inventario de Proveedores o Productos Temporales (no indexados). Cada fila requiere: Cantidad, Procedencia (Propio o Nombre del Distribuidor), Precio de costo unitario, Porcentaje de margen de ganancia, Precio de venta calculado, Tiempo estimado de entrega y descripción editable.
* **Sección Servicios:** Lista de servicios propios o temporales. Registra: Cantidad, tiempo estimado de ejecución, descripción alternativa y bandera booleana `is_subcontracted` (Servicio Tercerizado).
* **Sección Cliente:** Vinculación directa con un registro de la base de datos de Clientes y selección de su Persona de Contacto específica.
* **Sección Detalles:** Fecha de emisión, ID correlativo único, días de vigencia de la propuesta, categoría técnica (ej: CCTV, redes; campos editables), etiquetas de búsqueda y notas libres internas/externas.
* **Sección Condiciones:** Cláusulas de pago y comerciales preconfiguradas desde el panel de Ajustes.
* **Sección Resumen Financiero y Utilidad:** Cálculo automático de Subtotal, IVA (tasa variable editable) y Total General. **Vista Confidencial del Técnico:** Muestra la utilidad neta monetaria y los márgenes de rentabilidad calculados en tiempo real.
* **Estatus del Documento:** Pendiente, Enviada, Aprobada. Registra marcas de tiempo históricas de cambios de estado.
* **Lógicas de Negocio Críticas:**
    1.  *Alerta de Stock Cero:* Si un producto de proveedor integrado en una cotización activa se agota en el distribuidor de origen, el sistema arroja una alerta visual inmediata y sugiere proveedores alternativos con disponibilidad para recalcular costos.
    2.  *Autogeneración de Órdenes de Compra:* Al cambiar el estatus de la cotización a "Aprobada", la app segrega los ítems de proveedores y genera de forma automática órdenes de compra independientes dirigidas a cada distribuidor.
    3.  *Salidas:* Exportación nativa a PDF, envío directo por API a WhatsApp o Correo, y función de clonación completa de cotizaciones.

### 3.6 Módulo: Reportes de Servicio Técnico
Documento de cierre legal y técnico de la actividad en campo.
* **Sección Reporte Técnico:** Solicitud inicial del cliente, diagnóstico de fallas en sitio y descripción detallada del servicio/reparación ejecutada.
* **Sección Productos Utilizados:** Permite añadir única y exclusivamente artículos provenientes del *Inventario Propio* del técnico o creados de forma temporal, con sus cantidades y precios correspondientes.
* **Secciones Homólogas:** Replica la estructura de cotizaciones para las secciones de Servicios, Cliente, Detalles de Reporte, Condiciones y Resumen Financiero (Subtotal, IVA, Total, Utilidad oculta y control de Estatus).
* **Lógica de Negocio:** El sistema emite notificaciones push periódicas para reportes en estatus "No Finalizado" para mitigar el olvido de cobros de servicios ejecutados. Soporta PDF, envío por WhatsApp/Correo y clonación.

### 3.7 Módulos del Panel Lateral (Detalle de Datos)
* **Pedidos a Proveedores:** Administrador de órdenes de compra (manuales o autogeneradas). Estructura: *Detalles* (Proveedor, sucursal destino, condiciones de pago/envío), *Productos* (cantidades) y *Resumen* (Totales, estatus del pedido y logs de tiempo).
* **Mis Compras:** Historial de abastecimiento. Permite cargar facturas o notas tanto de proveedores afiliados como externos (manual). **Control de Garantías:** En la sección de productos, obliga al registro campo por campo de los **números de serie individuales** de cada equipo comprado, automatizando el seguimiento cronológico de la vigencia de las garantías de fábrica.
* **Notas de Entrega:** Certificado de entrega física de equipos al cliente final (autogenerable desde Cotización). Secciones: *Detalles* (fecha, cotización origen, orden de compra de cliente, etiquetas), *Cliente*, *Logística de Envío* (dirección de entrega, transportista, condiciones del flete), *Productos* (unidades entregadas acopladas obligatoriamente a sus números de serie de garantía) y *Observaciones Legales* (editables).
    * *Herramientas de Campo:* Interfaz nativa de **Firma Digital** en pantalla táctil para la aceptación conforme del cliente. Integración de la cámara del dispositivo móvil como **Escáner de Códigos de Barra y Seriales** para la carga automatizada de ítems. Soporta PDF, envío digital y clonación.
* **Recibos de Pago:** Emisión y control cronológico de comprobantes de cobro para clientes. Soporta flujos de abonos parciales o pagos totales vinculados a obras.
* **Colaboradores de Campo:** Catálogo de personal (socios, ayudantes, vendedores). Registra: Nombre, Apellido, Cédula, Teléfono, Correo y Rol. Permite indexar estos perfiles nominalmente dentro de Cotizaciones (vendedor asignado) o Reportes (ayudante asignado).

### 3.8 Módulo: Configuración General (Estructura Estricta de 3 Secciones)

| Sección de Configuración | Submódulos Requeridos | Parámetros y Variables de Control |
| :--- | :--- | :--- |
| **Sección 1: Productos y Finanzas** | Marcas de Productos<br>Categorías Generales<br>Unidades de Medida<br>Parámetros Financieros<br>Tipos de Tarifas | - Diccionario global de marcas del mercado.<br>- Categorías unificadas para productos, cotizaciones y reportes.<br>- Unidades de medición (unidades, metros, paquetes, etc.).<br>- Margen de ganancia por defecto, tasa impositiva IVA base, moneda base.<br>- Unidades de cobro de mano de obra (por hora, minuto, metro o global). |
| **Sección 2: Logística** | Proveedores No Afiliados<br>Empresas de Encomienda<br>Tiempos Estándar | - Directorio maestro de distribuidores externos/no integrados.<br>- Catálogo de empresas de transporte de carga.<br>- Preconfiguración de tiempos estándar de entrega de productos y ejecución de obras. |
| **Sección 3: Formatos y Avisos** | Condiciones Comerciales<br>Observaciones Legales<br>Panel de Notificaciones | - Plantillas de cláusulas de pago auto-cargables en Cotizaciones.<br>- Textos legales predefinidos para pies de página de Notas de Entrega.<br>- Interruptores de activación de alertas push, acústicas y visuales del sistema. |

---

## 4. ESPECIFICACIONES TÉCNICAS Y REQUISITOS DE SISTEMA

### 4.1 Arquitectura de Datos Offline (Modo sin Conexión)
* **Mecanismo:** El sistema debe contar con una base de datos local embebida (ej. SQLite, Room, Realm). Ante desconexión a redes, la aplicación retiene el 100% de capacidades de escritura y lectura operacional en caliente.
* **Sincronización:** Al detectar restablecimiento de red, ejecuta un proceso en segundo plano de sincronización bidireccional atómica, resolviendo conflictos priorizando la marca de tiempo más reciente, actualizando inventarios globales, despachando correos en cola y resguardando los documentos en el servidor central.

### 4.2 Integración Empresarial (Ecosistema Odoo)
* **Fase 1:** Conexión inmediata consumiendo los servicios web externos expuestos por las APIs de las instancias de Odoo de los proveedores mayoristas.
* **Fase 2:** Construcción de un módulo/conector propietario nativo para la tienda de aplicaciones de Odoo (Odoo App Store), simplificando la incorporación técnica de nuevos distribuidores con parametrización cero en servidor.

### 4.3 Sistema de Trazabilidad
* **Motor de Bitácoras:** Infraestructura de backend dedicada al registro cronológico lineal e inalterable de instalación y soporte técnico de proyectos en campo.

---

## 5. ROADMAP DE EVOLUCIÓN (ESTRATEGIA DE PRODUCTO MADURO)

* **Cotizaciones Interactivas Web:** Transición del PDF a un endpoint web seguro e interactivo. El cliente final accede a una URL donde puede validar campos, rechazar o aceptar ítems del presupuesto directamente en la nube. Compatible con estándares de correo dinámico interactivo (Gmail/Outlook).
* **Plantillas Predefinidas y Alertas de Seguimiento Comercial:** Modelos base para cotizaciones rápidas. Motor de eventos que alerta sobre propuestas en estado "Enviada" sin respuesta, facilitando plantillas de mensajes rápidos para seguimiento.
* **Foro Comunitario y Gamificación (Sistema de Tokens):** Red técnica interna peer-to-peer. Respuestas correctas validadas por la comunidad otorgan tokens. Los técnicos pueden canjear tokens acumulados por descuentos comerciales reales en distribuidores mayoristas aliados. Consultas de ingeniería avanzada podrán ser cobradas y pagadas entre técnicos utilizando el saldo de tokens del sistema.
* **Directorio Profesional y Reputación:** Apertura de una interfaz pública para que clientes finales busquen técnicos por cercanía y ocupación. Se implementa un sistema de reviews y puntuación comercial basado exclusivamente en servicios completados dentro de la app.
* **Inteligencia de Datos Colectiva (Data Analytics):**
    * *Sugeridor de Márgenes:* Analiza datos estadísticos anonimizados de la comunidad en la misma región/rubro y sugiere el porcentaje óptimo de ganancia para maximizar probabilidades de ganar la licitación.
    * *Indicador de Concurrencia de Mercado:* Alerta en tiempo real que indica si el producto que se está cotizando está siendo ofertado simultáneamente por otros técnicos competidores en la misma zona geográfica y ventana de tiempo.
* **Inventario P2P y Control de Deudas Financieras:** Notificaciones automáticas de cuentas por cobrar sobre presupuestos finalizados con campos para registrar abonos parciales. Habilitación de un Marketplace interno P2P para la compraventa de excedentes de inventario o stock muerto entre los propios técnicos de la comunidad.

---

## 6. CAPA DE INTELIGENCIA ARTIFICIAL (SUSCRIPCIÓN PREMIUM)

Núcleo de procesamiento de lenguaje natural y modelos generativos integrados:
* **Asistente Técnico Experto Conversacional:** Agente LLM en rol de ingeniero especialista según las ocupaciones del usuario. Diagnóstica fallas complejas, mantiene contexto histórico de hilos de conversación y sugiere arquitecturas de hardware basándose estrictamente en el stock disponible del técnico y de los mayoristas integrados.
* **Generador Automatizado de Presupuestos (Voice/Text to Quote):** Transforma un prompt desestructurado de texto o un dictado de voz del técnico (ej: *"Sistemas, cotízame un kit de 8 cámaras con cable para el cliente Pérez"*) en una entidad estructurada de Cotización dentro del módulo correspondiente de forma inmediata.
* **Analizador Inteligente de Documentos Externos:** Procesamiento OCR y LLM para interpretar PDFs, correos electrónicos externos o fotos de requerimientos de clientes finales, convirtiéndolos en cotizaciones automáticas, o transformando cotizaciones internas en informes de venta ejecutivos.
* **Portafolio Digital Automatizado:** Generador web premium que extrae las bitácoras e imágenes de mejores proyectos del técnico para estructurar una página web de portafolio público para captación de clientes.

---

## 7. MODELO ECONÓMICO Y MONETIZACIÓN

1.  **Publicidad Programática e Interna:** Inserción de anuncios vía Google AdWords en pantallas de carga, pies de página o embebidos en vistas de catálogos y reportes. Removible mediante suscripción de membresía mensual. Venta directa de banners patrocinados a marcas y mayoristas.
2.  **Comisiones Transaccionales B2B:** Cobro de una comisión fija establecida estrictamente en el rango de **entre un 2% y un 3% de la venta total** de cada orden de compra procesada y cerrada desde la app hacia los distribuidores afiliados.
    * *Mecanismo de Auditoría y Respaldo por Créditos:* Para usuarios no premium, el sistema exige subir la fotografía de la factura o nota emitida por el mayorista para auditar la comisión. A cambio del documento de prueba, la app premia al usuario con **créditos internos** que puede gastar para activar funciones premium individuales sin pagar membresía o canjear por ofertas.
3.  **Venta de Posicionamiento Destacado (Sponsorship):** Comercialización de los tres (3) primeros lugares de resultados de búsquedas globales y listas principales de inventario de proveedores a marcas comerciales específicas.
4.  **Notificaciones Promocionales Patrocinadas:** Espacios publicitarios pagados por distribuidores mayoristas para el envío masivo o segmentado de alertas push con ofertas directamente al dispositivo del técnico (Estilo MercadoLibre).
5.  **Pasarela de Pagos Nativa ("Luka"):** Integración futura de la pasarela financiera Luka para centralizar transacciones monetarias de compra de equipos y cobro de servicios, cobrando una tasa de intermediación financiera por operación.

# Manual de Instalación y Configuración
## Módulo Conector Odoo ➔ Plataforma D-Una

Este manual describe el procedimiento para instalar y configurar el módulo **D-Una Connector** en su servidor de Odoo (compatible con versiones 14, 15, 16, 17 y 18, tanto Community como Enterprise).

---

## 1. Requisitos Previos

1. Instancia de Odoo con módulos estándar de Inventario (`stock`) y Productos (`product`).
2. Acceso como Administrador del sistema en Odoo.
3. **API Key del Proveedor** otorgada por el equipo de D-Una.
4. Conectividad saliente a Internet (HTTPS puerto 443) hacia el servidor de D-Una.

---

## 2. Instalación del Módulo en Odoo

### Paso 2.1: Copiar la carpeta del módulo
Copie la carpeta completa `odoo_duna_connector` dentro del directorio de addons personalizados (`custom_addons` o `addons`) de su instalación de Odoo:
```bash
# Ejemplo en servidores Linux/Docker:
cp -r odoo_duna_connector /opt/odoo/custom_addons/
chown -R odoo:odoo /opt/odoo/custom_addons/odoo_duna_connector
```

### Paso 2.2: Reiniciar el servicio de Odoo
Reinicie el servicio o contenedor de Odoo para que reconozca los nuevos archivos:
```bash
sudo systemctl restart odoo
# O si utiliza Docker:
docker restart odoo_container
```

### Paso 2.3: Actualizar la lista de aplicaciones en Odoo
1. Inicie sesión en Odoo con usuario Administrador.
2. Vaya a **Ajustes** y active el **Modo Desarrollador** (al final de la página de Ajustes).
3. Vaya al menú superior **Aplicaciones**.
4. En la barra superior, haga clic en **Actualizar lista de aplicaciones** y confirme.
5. En la barra de búsqueda de Aplicaciones, elimine el filtro `"Aplicaciones"` y escriba `D-Una`.
6. En la tarjeta de **D-Una Connector**, haga clic en **Instalar**.

---

## 3. Configuración Inicial y Autenticación

Una vez instalado el módulo:
1. Diríjase a **Ajustes** generales de Odoo y descienda hasta la sección **Conector D-Una** (o acceda desde el menú **Inventario > Conector D-Una > Configuración**).
2. Marque la casilla **[x] Activar Conector D-Una**.
3. **URL del Webhook D-Una:** Mantenga el valor por defecto:
   ```text
   https://fdkswvzrozijbizdthge.supabase.co/functions/v1/odoo_webhook
   ```
4. **API Key del Proveedor:** Pegue la clave secreta proporcionada por D-Una (ej: `91ffeb86820...`).
5. Haga clic en el botón **"Probar Conexión con D-Una"**.
   * Si las credenciales son correctas, aparecerá una notificación verde: `¡Conexión exitosa! Proveedor autenticado: [Nombre de su Empresa]`.

---

## 4. Parametrización Comercial y de Inventario

El módulo le permite definir exactamente qué información comparte y bajo qué reglas:

### A. Sucursales / Almacenes a Sincronizar
* En el campo **Sucursales / Almacenes a Sincronizar**, seleccione los almacenes físicos cuyas existencias desea publicar en D-Una (ej. *Sucursal Centro, Almacén Principal*).
* Los almacenes no seleccionados (ej: garantías, mermas o almacén de uso interno) quedan completamente excluidos de la transmisión.

### B. Precios y Moneda (Conversión a USD)
Dado que D-Una comercializa en dólares estadounidenses (USD):
* **Lista de Precios / Tarifa:** Seleccione la tarifa que desea usar (ej: *Tarifa Mayorista / Aliados D-Una*). Si no selecciona ninguna, se tomará el Precio de Venta público base.
* **Modo de Moneda a USD:**
  * **La tarifa seleccionada ya está expresada en USD:** Si sus precios en esa tarifa ya son en dólares.
  * **Convertir a USD según tasa del día en Odoo:** Si sus precios están en moneda local (ej: Bolívares) y desea que Odoo use su tabla oficial de tasas de cambio (`res.currency`).
  * **Usar factor / tasa personalizada manual:** Si desea fijar una tasa de cambio o factor divisor exclusivo para D-Una.

### C. Reglas de Stock y Prevención de Sobreventa
* **Base de Cálculo de Stock:**
  * **Stock Libre / Neto Disponible [Recomendado]:** Descuenta automáticamente los pedidos de venta que están en preparación en su local para evitar falsos positivos.
  * **Stock Físico Total:** Cantidad total a mano sin descontar reservas.
* **Margen de Seguridad (Buffer):** Puede indicar una cantidad (ej: `2` o `5` unidades) para restar automáticamente al stock publicado. Si tiene 7 unidades y su buffer es 2, en D-Una se mostrarán 5.
* **Ocultar productos con stock en 0:** Recomendado para mantener un catálogo limpio en la app móvil.

---

## 5. Publicación por Producto y Sincronización

### Publicación selectiva por producto:
* En la ficha de cada producto (**Inventario > Productos > Producto**), encontrará una casilla titulada **"Publicar en D-Una"**.
* Puede desmarcarla en cualquier momento para que un producto específico deje de mostrarse en la red sin tener que archivarlo en Odoo.

### Sincronización Inicial Masiva:
1. En la pantalla de Ajustes del Conector, haga clic en el botón **"Sincronizar Catálogo Completo Ahora"**.
2. El sistema compilará los almacenes, productos y existencias seleccionadas y los transmitirá en segundo plano.
3. Para auditar el resultado, vaya a **Inventario > Conector D-Una > Historial de Sincronización**. Podrá observar la fecha, hora, estado (Éxito) y la cantidad de productos transmitidos.

---

## 6. Preguntas Frecuentes (Seguridad, Privacidad y Rendimiento)

### ¿El módulo puede ralentizar mi facturación o punto de venta?
**No.** Todas las transmisiones hacia D-Una se realizan de forma asíncrona en hilos en segundo plano (`threads` independientes). La interfaz de usuario, facturación y operaciones de almacén no experimentan ningún retraso.

### ¿Qué información tiene acceso D-Una?
El módulo tiene dependencias estrictas de `['base', 'product', 'stock']`. **No tiene acceso** a su facturación contable, compras, cuentas bancarias, márgenes de ganancia ni a sus clientes (`res.partner`). Únicamente transmite código SKU, nombre de producto, precio de venta calculado en USD y unidades disponibles por almacén.

### ¿Qué ocurre si se interrumpe mi conexión a Internet?
El módulo captura cualquier corte de red de forma transparente y silenciosa sin arrojar pantallas de error a sus usuarios. Cuando se restablezca la conexión, cualquier actualización posterior o el botón "Sincronizar Catálogo Completo" actualizará la información.

### ¿Puedo pausar la sincronización en cualquier momento?
**Sí.** Basta con desmarcar la casilla **"Activar Conector D-Una"** en Ajustes y guardar. A partir de ese momento no saldrá ninguna información hacia D-Una.

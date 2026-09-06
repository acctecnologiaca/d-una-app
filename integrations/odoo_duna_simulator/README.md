# 🎮 D-Una Simulator · Gemelo Digital de Actividad Comercial (Odoo 17)

El módulo **`odoo_duna_simulator`** es un componente satélite independiente diseñado para emular de forma hiperrealista y controlada el comportamiento de un distribuidor mayorista en su día a día.

Está desarrollado de forma **completamente desacoplada** de `odoo_duna_connector`, garantizando que el conector oficial permanezca limpio, seguro y listo para producción sin código de pruebas.

---

## ⚡ Características Principales

1. **Mecanismo No Invasivo:**
   - Realiza modificaciones de existencias a través del mecanismo nativo de inventario de Odoo 17 (`stock.quant` con `inventory_quantity` y `action_apply_inventory()`).
   - Los triggers de sincronización delta de `odoo_duna_connector` (`stock_sync.py`) se activan de forma 100% natural, despachando los cambios en tiempo real a Supabase.
   - Las modificaciones de tarifas operan sobre `product.template.list_price`, gatillando `product_sync.py`.

2. **Modo Autónomo (`ir.cron`):**
   - Ejecuta un ciclo configurable (por defecto cada 15 min).
   - Eventos probabilísticos automáticos:
     - **70% Venta de Mostrador**: Descuenta entre 1 y 3 unidades en 1 o 2 productos aleatorios con existencias.
     - **20% Reabastecimiento**: Suma entre 10 y 25 unidades a productos que tienen existencias críticas (≤ 5 unidades).
     - **10% Micro-Ajuste de Tarifas**: Aplica una variación aleatoria leve de ±3% a ±5% sobre el precio de lista.

3. **Modo Manual y Escenarios de Estrés (Wizards):**
   - Panel de control integrado en **Inventario > Simulador D-Una**.
   - Interruptor maestro de activación / pausa.
   - Botón `⚡ Ejecutar 1 Ciclo Ahora` para prueba inmediata.
   - Escenarios avanzados:
     - 🛒 **Jornada Pico de Ventas**: Descuento masivo de stock y opción de **agotar deliberadamente a cero** varios SKUs para comprobar el comportamiento de la app D-Una (ocultamiento, badge de agotado, etc.).
     - 📦 **Llegada de Contenedor**: Inyección masiva de existencias filtrada por Marca o Categoría (+25 a +80 unidades).
     - 🏷️ **Ajuste de Precios por Categoría**: Variación porcentual masiva sobre toda una categoría de productos.

4. **Auditoría y Trazabilidad:**
   - Bitácora en tiempo real en `duna.simulator.log` con registro de SKU, almacén, valor anterior, nuevo valor y estado.

---

## 🚀 Instalación y Activación en Odoo 17

### 1. Despliegue con Docker / Codespaces
En `docker-compose.yml`, el módulo se encuentra montado en el volumen:
```yaml
volumes:
  - ./odoo_duna_connector:/mnt/extra-addons/odoo_duna_connector
  - ./odoo_duna_simulator:/mnt/extra-addons/odoo_duna_simulator
```

Si ejecutas los contenedores:
```bash
docker compose down
docker compose up -d
```

### 2. Instalación en la Interfaz Web de Odoo
1. Ingresa a Odoo 17 como Administrador (`http://localhost:8069`).
2. Activa el **Modo Desarrollador** (Ajustes > Activar modo desarrollador).
3. Dirígete a **Aplicaciones > Actualizar lista de aplicaciones**.
4. En el buscador de Aplicaciones, retira el filtro por defecto "Aplicaciones" y busca: `D-Una Simulator`.
5. Haz clic en **Activar / Instalar**.

---

## 🧭 Navegación y Uso

### Panel de Control
- Dirígete al menú: **Inventario > Simulador D-Una > Panel de Control**.
- Observarás el badge de estado (**ACTIVO** o **PAUSADO**), el contador de eventos ejecutados y el último impacto.
- Haz clic en **⚡ Ejecutar 1 Ciclo Ahora** para probar una transacción inmediata.

### Ejecutar Escenarios de Demostración
Desde el panel de control o desde el submenú **Escenarios Manuales**:
- **Jornada Pico**: Elige el almacén, define cuántos productos agotar a 0 y haz clic en `🚀 Ejecutar Jornada Pico`. Observa inmediatamente en la app móvil D-Una cómo se actualizan las existencias.
- **Llegada de Contenedor**: Escribe una marca (ej: `Samsung` o `Xiaomi`) y presiona `📦 Recibir e Inyectar Mercancía`.
- **Ajuste de Precios**: Selecciona la categoría deseada, define el porcentaje (ej: +10%) y haz clic en `🏷️ Aplicar Ajuste de Precios`.

---

## 🛡️ Seguridad y Permisos
- Permisos configurados en `security/ir.model.access.csv`:
  - **Administrador de Inventario** (`stock.group_stock_manager`): Acceso total a configuración, ejecución de wizards y logs.
  - **Usuario de Inventario** (`stock.group_stock_user`): Acceso de solo lectura a métricas e historial de logs.

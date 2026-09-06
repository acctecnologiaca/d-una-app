# Guía Rápida: Levantar Ambiente Odoo de ACC Tecnología en GitHub Codespaces

Esta guía explica cómo tener Odoo 17 con PostgreSQL, el módulo **D-Una Connector** y los **662 productos reales** de CCTV, Alarmas y Energía funcionando en la nube de GitHub sin consumir recursos de su PC.

---

## 1. Archivos que Componen el Paquete

En la carpeta `integrations/odoo_duna_connector/` tiene todo listo:
* `docker-compose.yml`: Levanta Odoo 17 Community y PostgreSQL 15 en la nube.
* `odoo_duna_connector/`: El módulo personalizado de Odoo que desarrollamos.
* `seed_data.py`: Script de siembra automática de empresas, sucursales, precios y productos.
* `test_data/parsed_products.json`: Los 662 productos extraídos de los PDFs de Haovision.

---

## 2. Paso a Paso en GitHub

### Paso 2.1: Crear el repositorio en GitHub
1. Cree un nuevo repositorio en su cuenta de GitHub (puede ser privado), por ejemplo: `odoo-duna-acc`.
2. Suba o haga push de estos archivos a la raíz de ese repositorio:
   ```text
   odoo-duna-acc/
   ├── docker-compose.yml
   ├── seed_data.py
   ├── test_data/
   │   └── parsed_products.json
   └── odoo_duna_connector/
       ├── __init__.py
       ├── __manifest__.py
       ├── models/
       ├── utils/
       ├── views/
       └── security/
   ```

### Paso 2.2: Abrir el Codespace en la nube
1. En la página de su repositorio en GitHub, haga clic en el botón verde **`<> Code`**.
2. Seleccione la pestaña **Codespaces** y haga clic en **"Create codespace on main"**.
3. En unos segundos se abrirá una interfaz de Visual Studio Code directamente en su navegador web.

---

## 3. Iniciar Odoo y Crear la Base de Datos

### Paso 3.1: Levantar los contenedores
En la terminal integrada de Codespaces que aparece abajo, ejecute:
```bash
docker compose up -d
```
Espere unos 20-30 segundos mientras descarga y arranca Odoo y Postgres.

### Paso 3.2: Abrir Odoo en el navegador
1. En la parte inferior de Codespaces, haga clic en la pestaña **PORTS** (Puertos).
2. Verá el puerto `8069`. Haga clic derecho sobre él -> **Port Visibility** -> cámbielo a **Public**.
3. Pase el mouse por encima del puerto y haga clic en el icono del globo terráqueo (**Open in Browser**).
4. Se abrirá una nueva pestaña en su navegador con la pantalla inicial de Odoo:
   * **Database Name:** `odoo`
   * **Email:** `admin`
   * **Password:** `admin`
   * **Country:** Venezuela
   * Deje desmarcado "Demo data" y haga clic en **Create Database**.

### Paso 3.3: Instalar el Módulo D-Una
1. En Odoo, vaya a **Ajustes** y al final de la página active el **Modo Desarrollador**.
2. Vaya al menú superior **Aplicaciones**.
3. En la barra superior, haga clic en **Actualizar lista de aplicaciones** y confirme.
4. En el buscador de Aplicaciones, quite el filtro *"Aplicaciones"* y escriba `D-Una`.
5. En la tarjeta de **D-Una Connector**, haga clic en **Instalar**.

---

## 4. Sembrar los 662 Productos y Sucursales

Regrese a la terminal de Codespaces y ejecute:
```bash
python seed_data.py
```
*(O si desea probar con solo 50 productos primero: `python seed_data.py 50`)*.

El script tardará unos segundos y creará automáticamente:
* ✅ La empresa: **ACC Tecnología, C.A.**
* ✅ Las 3 sedes comerciales: **Barquisimeto (Principal)**, **Caracas** y **Valencia**.
* ✅ El almacén excluido: **Depósito de Mermas / Taller Técnico**.
* ✅ Las tarifas: **PVP Mostrador** y **Tarifa Aliados D-Una (Mayorista)**.
* ✅ La configuración del Conector con el **API Key de ACC Tecnología**.
* ✅ Los productos con existencias y precios en USD distribuidos por ciudad.

---

## 5. ¡A Probar la Integración con D-Una!

1. En Odoo, vaya a **Inventario > Conector D-Una > Configuración**.
2. Haga clic en el botón **"Probar Conexión con D-Una"**.
   * Verá la notificación verde: `¡Conexión exitosa! Proveedor autenticado: ACC TECNOLOGIA`.
3. Haga clic en el botón **"Sincronizar Catálogo Completo Ahora"**.
4. Vaya a **Inventario > Conector D-Una > Historial de Sincronización** para auditar el envío.
5. ¡Listo! Los productos, sucursales y existencias de **ACC Tecnología** estarán disponibles en Supabase y en la App móvil D-Una.

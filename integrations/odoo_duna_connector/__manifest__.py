# -*- coding: utf-8 -*-
{
    'name': 'D-Una Connector · Sincronización de Catálogo y Stock',
    'version': '1.0.0',
    'category': 'Inventory/Sales',
    'summary': 'Sincroniza catálogo, precios en USD y existencias por sucursal con D-Una',
    'description': '''
Módulo Conector Oficial de D-Una para Odoo.
============================================
Permite a los proveedores afiliados transmitir automáticamente sus productos, precios y niveles de stock hacia la plataforma D-Una de forma segura, asíncrona y configurable:
- Compatible con múltiples almacenes/sucursales y selección granular.
- Compatible con tarifas y listas de precios personalizadas.
- Conversión multimoneda a USD automática según tasa del día o manual.
- Control de stock libre de reservas y margen de seguridad (buffer).
- Registro visible de auditoría y prueba de conexión en 1 clic.
''',
    'author': 'D-Una Technologies',
    'website': 'https://d-una.app',
    'license': 'LGPL-3',
    'depends': ['base', 'product', 'stock'],
    'data': [
        'security/ir.model.access.csv',
        'views/res_config_settings_views.xml',
        'views/product_template_views.xml',
        'views/duna_sync_log_views.xml',
        'views/menus.xml',
    ],
    'installable': True,
    'application': True,
    'auto_install': False,
}

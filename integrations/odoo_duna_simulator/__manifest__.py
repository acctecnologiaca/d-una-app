# -*- coding: utf-8 -*-
{
    'name': 'D-Una Simulator · Gemelo Digital de Actividad Comercial',
    'version': '17.0.1.0.0',
    'category': 'Inventory/Simulator',
    'summary': 'Simulador sintético de ventas de mostrador, recepciones y variaciones de precios para D-Una',
    'description': '''
Módulo Simulador de Actividad Comercial para D-Una (Odoo 17)
============================================================
Actúa como un "Gemelo Digital" desacoplado de la operación real para:
- Emular de forma autónoma (ir.cron) ventas de mostrador frecuentes, recepciones periódicas y micro-ajustes de tarifas.
- Disparar de forma 100% no invasiva los eventos delta de 'odoo_duna_connector' sobre 'stock.quant' y 'product.template'.
- Ejecutar bajo demanda escenarios de pruebas de estrés:
  * 🛒 Jornada Pico de Ventas (descuentos masivos y productos agotados en cero).
  * 📦 Llegada de Contenedor (inyección de inventario por marca).
  * 🏷️ Ajuste Masivo de Precios por Categoría.
- Registrar bitácora detallada de auditoría para cada impacto en existencias o tarifas.
''',
    'author': 'D-Una Technologies',
    'website': 'https://d-una.app',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'product',
        'stock',
        'odoo_duna_connector',
    ],
    'data': [
        'security/ir.model.access.csv',
        'data/simulator_default_data.xml',
        'data/ir_cron_data.xml',
        'views/simulator_config_views.xml',
        'views/simulator_log_views.xml',
        'views/peak_sale_wizard_views.xml',
        'views/container_arrival_wizard_views.xml',
        'views/category_price_wizard_views.xml',
        'views/menus.xml',
    ],
    'installable': True,
    'application': True,
    'auto_install': False,
}

# -*- coding: utf-8 -*-
import json
import re
import logging
from odoo import models, fields, api  # type: ignore
from ..utils.duna_client import send_to_duna, test_connection_sync

_logger = logging.getLogger(__name__)


class ResConfigSettings(models.TransientModel):
    _inherit = 'res.config.settings'

    duna_is_active = fields.Boolean(
        string='Activar Conector D-Una',
        config_parameter='duna_connector.is_active',
        default=False,
        help='Activa o pausa globalmente la transmisión en tiempo real hacia D-Una.'
    )
    duna_endpoint_url = fields.Char(
        string='URL del Webhook D-Una',
        config_parameter='duna_connector.endpoint_url',
        default='https://fdkswvzrozijbizdthge.supabase.co/functions/v1/odoo_webhook',
        help='Endpoint HTTPS provisto por D-Una.'
    )
    duna_api_key = fields.Char(
        string='API Key del Proveedor',
        config_parameter='duna_connector.api_key',
        help='Token secreto asignado a su empresa en la plataforma D-Una.'
    )

    duna_warehouse_ids = fields.Many2many(
        'stock.warehouse',
        string='Sucursales / Almacenes a Sincronizar',
        help='Seleccione los almacenes cuyas existencias físicas desea publicar en D-Una.'
    )
    duna_category_ids = fields.Many2many(
        'product.category',
        string='Categorías a Sincronizar',
        help='Si deja este campo vacío, se sincronizarán todas las categorías de productos.'
    )

    duna_pricelist_id = fields.Many2one(
        'product.pricelist',
        string='Lista de Precios / Tarifa D-Una',
        help='Tarifa a utilizar para calcular el precio enviado a D-Una. Si no se indica, se usa el Precio de Venta público base.'
    )
    duna_currency_mode = fields.Selection([
        ('native_usd', 'La tarifa seleccionada ya está expresada en USD'),
        ('convert_odoo_rate', 'Convertir a USD según tasa del día registrada en Odoo'),
        ('custom_rate', 'Usar factor / tasa personalizada manual'),
    ], string='Modo de Moneda a USD', default='native_usd',
       config_parameter='duna_connector.currency_mode',
       help='D-Una opera en USD. Indique cómo convertir sus precios si su moneda contable es distinta.')

    duna_custom_rate = fields.Float(
        string='Tasa Manual (Unidades por 1 USD)',
        default=1.0,
        config_parameter='duna_connector.custom_rate',
        help='Factor divisor si seleccionó tasa personalizada (ej: 40.0 si sus precios están en Bolívares y 1 USD = 40 Bs).'
    )

    duna_stock_mode = fields.Selection([
        ('free_qty', 'Stock Libre / Neto Disponible (Físico menos Reservas de Venta) [Recomendado]'),
        ('qty_available', 'Stock Físico Total a Mano'),
    ], string='Base de Cálculo de Stock', default='free_qty',
       config_parameter='duna_connector.stock_mode',
       help='Recomendamos Stock Libre para evitar vender productos que ya están apartados en pedidos de venta.')

    duna_safety_stock = fields.Integer(
        string='Margen de Seguridad (Buffer a restar)',
        default=0,
        config_parameter='duna_connector.safety_stock',
        help='Unidades que se restarán al stock disponible para mantener reserva exclusiva de mostrador.'
    )
    duna_hide_zero_stock = fields.Boolean(
        string='Ocultar productos con stock en 0',
        default=True,
        config_parameter='duna_connector.hide_zero_stock',
        help='Si está activo, no se enviarán a D-Una existencias con cantidad 0 o menor.'
    )

    duna_brand_mode = fields.Selection([
        ('none', 'No utilizar campo de marca (D-Una detecta por texto)'),
        ('existing_field', 'Usar campo existente en mi Odoo'),
        ('custom_field', 'Habilitar campo auxiliar Marca (D-Una) en productos'),
    ], string='Modo de Marca', default='none',
       config_parameter='duna_connector.brand_mode',
       help='Indique si desea que D-Una utilice un campo existente de su Odoo, agregue un campo auxiliar o detecte la marca automáticamente por el nombre comercial.')

    duna_brand_field_name = fields.Char(
        string='Nombre técnico del campo de marca',
        config_parameter='duna_connector.brand_field_name',
        help='Nombre del campo en product.template (ej: product_brand_id, brand_id, x_marca).'
    )

    duna_sync_images = fields.Boolean(
        string='Sincronizar imágenes de productos',
        default=False,
        config_parameter='duna_connector.sync_images',
        help='Si está activo, enviará la URL pública optimizada de la imagen del producto hacia D-Una.'
    )

    duna_warranty_mode = fields.Selection([
        ('cascade', 'Cascada Inteligente (Reglas, Texto y Manual) [Recomendado]'),
        ('existing_field', 'Mapear campo técnico preexistente de Odoo'),
        ('none', 'No transmitir garantía (Cero Riesgo: NULL)'),
    ], string='Modo de Garantía', default='cascade',
       config_parameter='duna_connector.warranty_mode',
       help='Indique cómo determinar la garantía comercial enviada a D-Una.')

    duna_warranty_field_name = fields.Char(
        string='Nombre técnico del campo de garantía',
        config_parameter='duna_connector.warranty_field_name',
        help='Nombre del campo en product.template (ej: x_garantia, warranty_duration).'
    )

    duna_warranty_extract_from_text = fields.Boolean(
        string='Detectar garantía en nombre o descripción (Regex)',
        default=True,
        config_parameter='duna_connector.warranty_extract_text',
        help='Si está activo, busca patrones como "Garantía 2 años" o "12 meses de garantía" en el texto.'
    )

    duna_warranty_rule_ids = fields.One2many(
        related='company_id.duna_warranty_rule_ids',
        readonly=False,
        string='Reglas de Garantía D-Una'
    )

    def set_values(self):
        super(ResConfigSettings, self).set_values()
        ICP = self.env['ir.config_parameter'].sudo()
        wh_ids = self.duna_warehouse_ids.ids if self.duna_warehouse_ids else []
        cat_ids = self.duna_category_ids.ids if self.duna_category_ids else []
        ICP.set_param('duna_connector.warehouse_ids', json.dumps(wh_ids))
        ICP.set_param('duna_connector.category_ids', json.dumps(cat_ids))
        ICP.set_param('duna_connector.pricelist_id', str(self.duna_pricelist_id.id or ''))

    @api.model
    def get_values(self):
        res = super(ResConfigSettings, self).get_values()
        ICP = self.env['ir.config_parameter'].sudo()

        wh_raw = ICP.get_param('duna_connector.warehouse_ids', '[]')
        cat_raw = ICP.get_param('duna_connector.category_ids', '[]')
        pl_raw = ICP.get_param('duna_connector.pricelist_id', '')

        try:
            wh_ids = json.loads(wh_raw)
        except Exception:
            wh_ids = []

        try:
            cat_ids = json.loads(cat_raw)
        except Exception:
            cat_ids = []

        res.update(
            duna_warehouse_ids=[(6, 0, wh_ids)],
            duna_category_ids=[(6, 0, cat_ids)],
            duna_pricelist_id=int(pl_raw) if pl_raw and pl_raw.isdigit() else False,
        )
        return res

    def action_test_duna_connection(self):
        """Prueba síncrona de conexión hacia Supabase con feedback inmediato en Odoo."""
        self.ensure_one()
        endpoint = self.duna_endpoint_url or ''
        api_key = self.duna_api_key or ''

        result = test_connection_sync(endpoint, api_key)
        msg_type = 'success' if result.get('success') else 'danger'
        title = 'Conector D-Una: Éxito' if result.get('success') else 'Conector D-Una: Error de Conexión'

        return {
            'type': 'ir.actions.client',
            'tag': 'display_notification',
            'params': {
                'title': title,
                'message': result.get('message', ''),
                'type': msg_type,
                'sticky': not result.get('success'),
            }
        }

    def action_sync_all_now(self):
        """Construye y despacha en segundo plano la sincronización total del catálogo y existencias."""
        self.ensure_one()
        ICP = self.env['ir.config_parameter'].sudo()
        is_active = ICP.get_param('duna_connector.is_active', 'False')
        if is_active.lower() not in ('true', '1'):
            return {
                'type': 'ir.actions.client',
                'tag': 'display_notification',
                'params': {
                    'title': 'Conector D-Una Pausado',
                    'message': 'Active el conector antes de realizar una sincronización.',
                    'type': 'warning',
                    'sticky': False,
                }
            }

        # 1. Almacenes / Sucursales
        warehouses = self.duna_warehouse_ids
        if not warehouses:
            warehouses = self.env['stock.warehouse'].search([])

        branches_payload = []
        for wh in warehouses:
            # Resolución inteligente de ciudad
            wh_city = None
            company_partner = wh.company_id.partner_id if wh.company_id else self.env.company.partner_id

            # 1. Si el almacén tiene su propio partner dedicado con ciudad
            if wh.partner_id and wh.partner_id != company_partner and wh.partner_id.city:
                wh_city = wh.partner_id.city.strip()

            # 2. Inferencia por nombre del almacén (ej: "Sucursal Caracas", "Sede Principal (Barquisimeto)")
            if not wh_city and wh.name:
                # Patrón A: Entre paréntesis: "Sede (Barquisimeto)" -> "Barquisimeto"
                m_paren = re.search(r'\((.*?)\)', wh.name)
                if m_paren and len(m_paren.group(1).strip()) >= 3:
                    wh_city = m_paren.group(1).strip()
                else:
                    # Patrón B: Tras prefijo: "Sucursal Caracas", "Depósito Valencia", "Almacén Maracaibo"
                    m_prefix = re.search(r'(?:Sucursal|Sede|Almac[eé]n|Tienda|Dep[oó]sito)\s+(?:de\s+)?([A-Za-zÁÉÍÓÚáéíóúñÑ\s]+)', wh.name, re.IGNORECASE)
                    if m_prefix:
                        wh_city = m_prefix.group(1).strip()

            # 3. Fallback a ciudad del partner o de la compañía
            if not wh_city:
                wh_city = (wh.partner_id.city if wh.partner_id else '') or (company_partner.city if company_partner else '') or 'Principal'

            wh_email = (wh.partner_id.email if wh.partner_id else '') or (company_partner.email if company_partner else '')
            wh_phone = (wh.partner_id.phone if wh.partner_id else '') or (company_partner.phone if company_partner else '')

            branches_payload.append({
                'external_id': 'odoo_wh_%s' % wh.id,
                'name': wh.name,
                'city': wh_city,
                'email': wh_email,
                'phone': wh_phone,
            })

        # 2. Productos
        domain = [
            ('active', '=', True),
            ('default_code', '!=', False),
            ('default_code', '!=', ''),
        ]
        if hasattr(self.env['product.template'], 'sync_with_duna'):
            domain.append(('sync_with_duna', '=', True))

        if self.duna_category_ids:
            cat_ids = self.env['product.category'].search([('id', 'child_of', self.duna_category_ids.ids)]).ids
            domain.append(('categ_id', 'in', cat_ids))

        products = self.env['product.template'].search(domain)

        products_payload = []
        stock_prices_payload = []

        pricelist = self.duna_pricelist_id
        currency_mode = self.duna_currency_mode or 'native_usd'
        custom_rate = self.duna_custom_rate or 1.0
        stock_mode = self.duna_stock_mode or 'free_qty'
        safety_stock = self.duna_safety_stock or 0
        hide_zero = self.duna_hide_zero_stock
        brand_mode = self.duna_brand_mode or 'none'
        brand_field_name = self.duna_brand_field_name or ''
        sync_images = self.duna_sync_images
        base_url = self.env['ir.config_parameter'].sudo().get_param('web.base.url', '')

        usd_currency = self.env['res.currency'].search([('name', '=', 'USD')], limit=1)

        # Pre-carga de configuración y reglas de garantía para optimizar sincronización en lote
        warranty_config = {
            'warranty_mode': self.duna_warranty_mode or 'cascade',
            'warranty_field_name': self.duna_warranty_field_name or '',
            'warranty_extract_text': self.duna_warranty_extract_from_text,
        }
        active_rules = self.env['duna.warranty.rule'].search([
            ('active', '=', True),
            ('company_id', '=', self.env.company.id)
        ], order='sequence, id')

        # Pre-carga de inventario por almacén para eliminar colisiones de caché y optimizar rendimiento
        wh_location_map = {}
        for wh in warehouses:
            if wh.lot_stock_id:
                child_loc_ids = self.env['stock.location'].search([
                    ('id', 'child_of', wh.lot_stock_id.id),
                    ('usage', '=', 'internal')
                ]).ids
                wh_location_map[wh.id] = set(child_loc_ids)

        all_variants = products.mapped('product_variant_ids')
        variant_to_tmpl = {v.id: v.product_tmpl_id.id for v in all_variants}

        # Matriz: (product_tmpl_id, warehouse_id) -> {'qty': float, 'reserved': float}
        stock_matrix = {}
        if all_variants:
            all_internal_loc_ids = set()
            for loc_set in wh_location_map.values():
                all_internal_loc_ids.update(loc_set)

            if all_internal_loc_ids:
                quants = self.env['stock.quant'].search([
                    ('product_id', 'in', all_variants.ids),
                    ('location_id', 'in', list(all_internal_loc_ids))
                ])
                for q in quants:
                    tmpl_id = variant_to_tmpl.get(q.product_id.id)
                    if not tmpl_id:
                        continue
                    q_loc_id = q.location_id.id
                    for wh_id, loc_ids in wh_location_map.items():
                        if q_loc_id in loc_ids:
                            key = (tmpl_id, wh_id)
                            if key not in stock_matrix:
                                stock_matrix[key] = {'qty': 0.0, 'reserved': 0.0}
                            stock_matrix[key]['qty'] += q.quantity
                            stock_matrix[key]['reserved'] += q.reserved_quantity

        for prod in products:
            sku = prod.default_code.strip()

            # Mapeo de marca (Configuración no invasiva)
            brand_name = None
            if brand_mode == 'existing_field' and brand_field_name and hasattr(prod, brand_field_name):
                val = getattr(prod, brand_field_name)
                if val:
                    brand_name = val.name if hasattr(val, 'name') else str(val)
            elif brand_mode == 'custom_field':
                brand_name = getattr(prod, 'duna_brand', None) or None

            if not brand_name and hasattr(prod, 'product_brand_id') and prod.product_brand_id:
                brand_name = prod.product_brand_id.name

            # Resolución de garantía comercial en cascada
            w_time, w_unit, _ = prod.resolve_duna_warranty(
                brand_name=brand_name,
                rules=active_rules,
                config=warranty_config
            )

            # Imágenes (Opcional preventivo)
            image_urls = []
            if sync_images and prod.image_1920 and base_url:
                image_urls.append('%s/web/image/product.template/%s/image_512' % (base_url.rstrip('/'), prod.id))

            # Cálculo de precio base
            price = prod.list_price
            if pricelist:
                try:
                    price = pricelist._get_product_price(prod, 1.0)
                except Exception:
                    price = prod.list_price

            # Conversión de moneda a USD
            price_usd = price
            if currency_mode == 'convert_odoo_rate':
                company = prod.company_id or self.env.company
                from_curr = pricelist.currency_id if pricelist else company.currency_id
                if usd_currency and from_curr and from_curr != usd_currency:
                    try:
                        price_usd = from_curr._convert(price, usd_currency, company, fields.Date.today())
                    except Exception:
                        price_usd = price
            elif currency_mode == 'custom_rate' and custom_rate > 0:
                price_usd = round(price / custom_rate, 4)

            # Metadata adicional
            attributes = {
                'odoo_template_id': prod.id,
                'barcode': prod.barcode or '',
            }

            products_payload.append({
                'sku': sku,
                'name': prod.name,
                'description': prod.description_sale or prod.description or '',
                'category': prod.categ_id.name if prod.categ_id else 'General',
                'uom': prod.uom_id.name if prod.uom_id else 'unid.',
                'brand': brand_name,
                'warranty_time': w_time,
                'warranty_unit': w_unit,
                'image_urls': image_urls,
                'is_active': True,
                'attributes': attributes,
            })

            # 3. Stock por almacén (Extracción directa de matriz exacta)
            for wh in warehouses:
                stock_entry = stock_matrix.get((prod.id, wh.id), {'qty': 0.0, 'reserved': 0.0})
                if stock_mode == 'free_qty':
                    wh_stock = max(0.0, stock_entry['qty'] - stock_entry['reserved'])
                else:
                    wh_stock = stock_entry['qty']

                net_stock = max(0.0, float(wh_stock) - float(safety_stock))

                if hide_zero and net_stock <= 0:
                    continue

                stock_prices_payload.append({
                    'sku': sku,
                    'branch_external_id': 'odoo_wh_%s' % wh.id,
                    'quantity': round(net_stock, 2),
                    'price_usd': round(float(price_usd), 4),
                })

        final_payload = {
            'action': 'sync',
            'branches': branches_payload,
            'products': products_payload,
            'stock_prices': stock_prices_payload,
        }

        summary = 'Sync Total: %s productos, %s existencias en %s almacenes' % (
            len(products_payload),
            len(stock_prices_payload),
            len(branches_payload)
        )

        send_to_duna(self.env, final_payload, event_type='full_sync', summary=summary)

        return {
            'type': 'ir.actions.client',
            'tag': 'display_notification',
            'params': {
                'title': 'Sincronización en Proceso',
                'message': 'Se ha despachado la transmisión de %s productos hacia D-Una en segundo plano. Puede auditar el resultado en el menú Historial de Sincronización.' % len(products_payload),
                'type': 'info',
                'sticky': False,
            }
        }

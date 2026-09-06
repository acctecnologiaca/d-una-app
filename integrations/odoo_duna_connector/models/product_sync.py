# -*- coding: utf-8 -*-
import json
import logging
import re
from odoo import models, fields, api  # type: ignore
from ..utils.duna_client import send_to_duna

_logger = logging.getLogger(__name__)

TRACKED_FIELDS = {
    'name', 'list_price', 'default_code', 'active', 'categ_id',
    'uom_id', 'sync_with_duna', 'duna_brand',
    'duna_warranty_time', 'duna_warranty_unit'
}


class ProductTemplate(models.Model):
    _inherit = 'product.template'

    sync_with_duna = fields.Boolean(
        string='Publicar en D-Una',
        default=True,
        help='Si se desmarca, este producto no será visible en la red de aliados de D-Una.'
    )
    duna_brand = fields.Char(
        string='Marca (D-Una)',
        copy=False,
        help='Campo auxiliar para indicar la marca del fabricante si su Odoo no cuenta con un campo nativo de marca.'
    )
    duna_warranty_time = fields.Integer(
        string='Garantía Manual (Tiempo)',
        default=0,
        help='Garantía específica para este producto. 0 = resolver automáticamente por reglas o texto.'
    )
    duna_warranty_unit = fields.Selection([
        ('months', 'Meses'),
        ('years', 'Años'),
        ('days', 'Días')
    ], string='Unidad Manual', default='months')
    duna_effective_warranty = fields.Char(
        string='Garantía Efectiva D-Una',
        compute='_compute_duna_effective_warranty',
        store=False,
        help='Resultado calculado por el motor de cascada de D-Una.'
    )

    @api.depends('duna_warranty_time', 'duna_warranty_unit', 'duna_brand', 'categ_id', 'name', 'description_sale')
    def _compute_duna_effective_warranty(self):
        for prod in self:
            _, _, desc = prod.resolve_duna_warranty()
            prod.duna_effective_warranty = desc

    @api.model
    def _normalize_warranty_unit(self, raw_unit):
        u = (raw_unit or '').lower().strip()
        if u in ('mes', 'meses', 'm', 'month', 'months'):
            return 'months'
        elif u in ('año', 'años', 'ano', 'anos', 'a', 'year', 'years', 'y'):
            return 'years'
        elif u in ('dia', 'dias', 'día', 'días', 'd', 'day', 'days'):
            return 'days'
        return 'months'

    @api.model
    def _extract_warranty_from_text(self, text):
        if not text:
            return None, None
        # Patrón 1: "Garantía: 24 meses", "Garantia de 1 año", "Warranty: 3 months"
        p1 = re.search(
            r'(?:garant[íi]a|warranty)\s*(?:de\s*)?:?\s*(\d+)\s*(meses?|a[ñn]os?|d[íi]as?|months?|years?|days?|m\b|a\b|y\b|d\b)',
            text, re.IGNORECASE
        )
        if p1:
            num = int(p1.group(1))
            raw_u = p1.group(2).lower()
            return num, self._normalize_warranty_unit(raw_u)

        # Patrón 2: "24 meses de garantía", "1 año de garantia", "30 dias de garantia"
        p2 = re.search(
            r'(\d+)\s*(meses?|a[ñn]os?|d[íi]as?|months?|years?|days?)\s*(?:de\s*)?(?:garant[íi]a|warranty)',
            text, re.IGNORECASE
        )
        if p2:
            num = int(p2.group(1))
            raw_u = p2.group(2).lower()
            return num, self._normalize_warranty_unit(raw_u)

        return None, None

    def resolve_duna_warranty(self, brand_name=None, rules=None, config=None):
        """
        Resuelve la garantía de un producto aplicando la cascada de 5 niveles.
        Retorna: (warranty_time: int or None, warranty_unit: str or None, source_desc: str)
        """
        self.ensure_one()
        ICP = self.env['ir.config_parameter'].sudo() if config is None else None

        # 1. Nivel 1: Manual en producto
        if self.duna_warranty_time and self.duna_warranty_time > 0:
            unit = self.duna_warranty_unit or 'months'
            return self.duna_warranty_time, unit, f"{self.duna_warranty_time} {unit} (Manual producto)"

        # Obtener parámetros de configuración
        mode = config.get('warranty_mode') if config else ICP.get_param('duna_connector.warranty_mode', 'cascade')
        if mode == 'none':
            return None, None, "Sin garantía (Modo desactivado)"

        # 2. Nivel 2: Campo preexistente de Odoo
        if mode == 'existing_field':
            field_name = config.get('warranty_field_name') if config else ICP.get_param('duna_connector.warranty_field_name', '')
            if field_name and hasattr(self, field_name):
                val = getattr(self, field_name)
                if val:
                    if isinstance(val, (int, float)) and val > 0:
                        return int(val), 'months', f"{int(val)} months (Campo {field_name})"
                    val_str = val.name if hasattr(val, 'name') else str(val)
                    parsed_time, parsed_unit = self._extract_warranty_from_text(val_str)
                    if parsed_time:
                        return parsed_time, parsed_unit, f"{parsed_time} {parsed_unit} (Campo {field_name})"

        # 3. Nivel 3: Regex en Texto (Nombre / Descripción)
        extract_text = config.get('warranty_extract_text') if config else (
            ICP.get_param('duna_connector.warranty_extract_text', 'True').lower() in ('true', '1')
        )
        if extract_text:
            text_to_search = f"{self.name or ''} {self.description_sale or ''} {self.description or ''}"
            parsed_time, parsed_unit = self._extract_warranty_from_text(text_to_search)
            if parsed_time:
                return parsed_time, parsed_unit, f"{parsed_time} {parsed_unit} (Detectado en texto)"

        # 4. Nivel 4: Matriz de Reglas
        if rules is None:
            rules = self.env['duna.warranty.rule'].search([
                ('active', '=', True),
                ('company_id', '=', self.company_id.id or self.env.company.id)
            ], order='sequence, id')

        effective_brand = (
            brand_name or self.duna_brand or (
                self.product_brand_id.name if hasattr(self, 'product_brand_id') and self.product_brand_id else ''
            ) or ''
        ).strip().lower()

        for rule in rules:
            rule_brand = (rule.brand_name or '').strip().lower()
            match_brand = False
            if not rule_brand:
                match_brand = True
            elif effective_brand and (rule_brand == effective_brand or rule_brand in effective_brand or effective_brand in rule_brand):
                match_brand = True

            if not match_brand:
                continue

            match_cat = False
            if not rule.category_id:
                match_cat = True
            elif self.categ_id:
                if self.categ_id.id == rule.category_id.id or (
                    self.categ_id.parent_path and str(rule.category_id.id) in self.categ_id.parent_path.split('/')
                ):
                    match_cat = True

            if match_brand and match_cat:
                return rule.warranty_time, rule.warranty_unit, f"{rule.warranty_time} {rule.warranty_unit} (Regla: {rule.name})"

        # 5. Nivel 5: Failsafe (Cero Riesgo)
        return None, None, "Sin garantía especificada (Consultar con proveedor)"


    def write(self, vals):
        res = super(ProductTemplate, self).write(vals)

        # Si ninguno de los campos monitoreados fue alterado, salir rápidamente
        if not (set(vals.keys()) & TRACKED_FIELDS):
            return res

        ICP = self.env['ir.config_parameter'].sudo()
        is_active_connector = ICP.get_param('duna_connector.is_active', 'False')
        if is_active_connector.lower() not in ('true', '1'):
            return res

        for prod in self:
            sku = prod.default_code and prod.default_code.strip()
            if not sku:
                continue

            # Caso de desactivación o exclusión manual
            is_active_prod = bool(prod.active and prod.sync_with_duna)
            if not is_active_prod:
                payload = {
                    'action': 'sync',
                    'branches': [],
                    'products': [{
                        'sku': sku,
                        'name': prod.name,
                        'is_active': False,
                    }],
                    'stock_prices': [],
                }
                send_to_duna(
                    self.env,
                    payload,
                    event_type='product_deactivate',
                    summary='Desactivación D-Una: SKU %s' % sku
                )
                continue

            # Caso de actualización activa
            self._dispatch_single_product_sync(prod, ICP)

        return res

    def unlink(self):
        ICP = self.env['ir.config_parameter'].sudo()
        is_active_connector = ICP.get_param('duna_connector.is_active', 'False')

        if is_active_connector.lower() in ('true', '1'):
            for prod in self:
                sku = prod.default_code and prod.default_code.strip()
                if sku and prod.sync_with_duna:
                    payload = {
                        'action': 'sync',
                        'branches': [],
                        'products': [{
                            'sku': sku,
                            'name': prod.name,
                            'is_active': False,
                        }],
                        'stock_prices': [],
                    }
                    send_to_duna(
                        self.env,
                        payload,
                        event_type='product_deactivate',
                        summary='Eliminación / Soft-delete D-Una: SKU %s' % sku
                    )

        return super(ProductTemplate, self).unlink()

    def _dispatch_single_product_sync(self, prod, ICP):
        """Prepara y envía la sincronización delta de un único producto y sus existencias."""
        sku = prod.default_code.strip()

        # 1. Configuración
        wh_raw = ICP.get_param('duna_connector.warehouse_ids', '[]')
        pl_raw = ICP.get_param('duna_connector.pricelist_id', '')
        currency_mode = ICP.get_param('duna_connector.currency_mode', 'native_usd')
        custom_rate = float(ICP.get_param('duna_connector.custom_rate', '1.0') or 1.0)
        stock_mode = ICP.get_param('duna_connector.stock_mode', 'free_qty')
        safety_stock = int(ICP.get_param('duna_connector.safety_stock', '0') or 0)
        hide_zero = ICP.get_param('duna_connector.hide_zero_stock', 'True').lower() in ('true', '1')

        try:
            wh_ids = json.loads(wh_raw)
        except Exception:
            wh_ids = []

        warehouses = self.env['stock.warehouse'].browse(wh_ids) if wh_ids else self.env['stock.warehouse'].search([])
        pricelist = self.env['product.pricelist'].browse(int(pl_raw)) if pl_raw and pl_raw.isdigit() else None
        usd_currency = self.env['res.currency'].search([('name', '=', 'USD')], limit=1)

        # 2. Precio
        price = prod.list_price
        if pricelist:
            try:
                price = pricelist._get_product_price(prod, 1.0)
            except Exception:
                price = prod.list_price

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

        # 3. Marca (Configuración no invasiva)
        brand_mode = ICP.get_param('duna_connector.brand_mode', 'none')
        brand_field_name = ICP.get_param('duna_connector.brand_field_name', '')
        brand_name = None

        if brand_mode == 'existing_field' and brand_field_name and hasattr(prod, brand_field_name):
            val = getattr(prod, brand_field_name)
            if val:
                brand_name = val.name if hasattr(val, 'name') else str(val)
        elif brand_mode == 'custom_field':
            brand_name = getattr(prod, 'duna_brand', None) or None

        if not brand_name and hasattr(prod, 'product_brand_id') and prod.product_brand_id:
            brand_name = prod.product_brand_id.name

        # 4. Imágenes (Opcional preventivo)
        sync_images = ICP.get_param('duna_connector.sync_images', 'False').lower() in ('true', '1')
        image_urls = []
        if sync_images and prod.image_1920:
            base_url = ICP.get_param('web.base.url', '')
            if base_url:
                image_urls.append('%s/web/image/product.template/%s/image_512' % (base_url.rstrip('/'), prod.id))

        attributes = {
            'odoo_template_id': prod.id,
            'barcode': prod.barcode or '',
        }

        # 4. Stock por almacén
        stock_prices = []
        for wh in warehouses:
            wh_stock = 0.0
            try:
                p_ctx = prod.with_context(warehouse=wh.id, warehouse_id=wh.id, location=wh.lot_stock_id.id if wh.lot_stock_id else False)
                if stock_mode == 'free_qty':
                    wh_stock = getattr(p_ctx, 'free_qty', getattr(p_ctx, 'qty_available', 0.0))
                else:
                    wh_stock = getattr(p_ctx, 'qty_available', 0.0)

                # Fallback directo a stock.quant si el contexto retorna 0
                if wh_stock <= 0 and wh.lot_stock_id:
                    quants = self.env['stock.quant'].search([
                        ('product_id.product_tmpl_id', '=', prod.id),
                        ('location_id', 'child_of', wh.lot_stock_id.id)
                    ])
                    wh_stock = sum(quants.mapped('quantity'))
                    if stock_mode == 'free_qty':
                        reserved = sum(quants.mapped('reserved_quantity'))
                        wh_stock = max(0.0, wh_stock - reserved)
            except Exception:
                wh_stock = 0.0

            net_stock = max(0.0, float(wh_stock) - float(safety_stock))
            if hide_zero and net_stock <= 0:
                continue

            stock_prices.append({
                'sku': sku,
                'branch_external_id': 'odoo_wh_%s' % wh.id,
                'quantity': round(net_stock, 2),
                'price_usd': round(float(price_usd), 4),
            })

        # Garantía comercial resuelta por cascada
        w_time, w_unit, _ = prod.resolve_duna_warranty(brand_name=brand_name)

        payload = {
            'action': 'sync',
            'branches': [],
            'products': [{
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
            }],
            'stock_prices': stock_prices,
        }

        send_to_duna(
            self.env,
            payload,
            event_type='product_update',
            summary='Actualización Delta Producto: %s' % sku
        )

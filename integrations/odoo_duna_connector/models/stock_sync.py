# -*- coding: utf-8 -*-
import json
import logging
from odoo import models, fields, api  # type: ignore
from ..utils.duna_client import send_to_duna

_logger = logging.getLogger(__name__)

STOCK_TRIGGER_FIELDS = {'quantity', 'reserved_quantity', 'inventory_quantity'}


class StockQuant(models.Model):
    _inherit = 'stock.quant'

    def write(self, vals):
        res = super(StockQuant, self).write(vals)

        if not (set(vals.keys()) & STOCK_TRIGGER_FIELDS):
            return res

        self._trigger_duna_stock_sync()
        return res

    def create(self, vals_list):
        records = super(StockQuant, self).create(vals_list)
        records._trigger_duna_stock_sync()
        return records

    def _trigger_duna_stock_sync(self):
        """Calcula y despacha la actualización delta de inventario hacia D-Una."""
        ICP = self.env['ir.config_parameter'].sudo()
        is_active = ICP.get_param('duna_connector.is_active', 'False')
        if is_active.lower() not in ('true', '1'):
            return

        wh_raw = ICP.get_param('duna_connector.warehouse_ids', '[]')
        pl_raw = ICP.get_param('duna_connector.pricelist_id', '')
        currency_mode = ICP.get_param('duna_connector.currency_mode', 'native_usd')
        custom_rate = float(ICP.get_param('duna_connector.custom_rate', '1.0') or 1.0)
        stock_mode = ICP.get_param('duna_connector.stock_mode', 'free_qty')
        safety_stock = int(ICP.get_param('duna_connector.safety_stock', '0') or 0)
        hide_zero = ICP.get_param('duna_connector.hide_zero_stock', 'True').lower() in ('true', '1')

        try:
            allowed_wh_ids = set(json.loads(wh_raw))
        except Exception:
            allowed_wh_ids = set()

        if not allowed_wh_ids:
            allowed_wh_ids = set(self.env['stock.warehouse'].search([]).ids)

        pricelist = self.env['product.pricelist'].browse(int(pl_raw)) if pl_raw and pl_raw.isdigit() else None
        usd_currency = self.env['res.currency'].search([('name', '=', 'USD')], limit=1)

        # Agrupar por par único (producto, almacén)
        pairs_to_update = set()
        for quant in self:
            wh = quant.location_id.warehouse_id
            if not wh:
                wh = self.env['stock.warehouse'].search([
                    '|',
                    ('lot_stock_id', 'parent_of', quant.location_id.id),
                    ('view_location_id', 'parent_of', quant.location_id.id)
                ], limit=1)

            if not wh or wh.id not in allowed_wh_ids:
                continue

            prod = quant.product_id.product_tmpl_id
            if not prod or not prod.active or not prod.default_code:
                continue

            if hasattr(prod, 'sync_with_duna') and not prod.sync_with_duna:
                continue

            pairs_to_update.add((prod, wh))

        if not pairs_to_update:
            return

        stock_prices = []
        for prod, wh in pairs_to_update:
            sku = prod.default_code.strip()

            # Cálculo de precio
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

            # Cálculo de stock disponible real en ESE almacén específico
            wh_quants = self.env['stock.quant'].search([
                ('product_id', 'in', prod.product_variant_ids.ids),
                ('location_id', 'child_of', wh.lot_stock_id.id),
                ('location_id.usage', '=', 'internal')
            ])
            wh_qty = sum(wh_quants.mapped('quantity'))
            if stock_mode == 'free_qty':
                wh_reserved = sum(wh_quants.mapped('reserved_quantity'))
                wh_stock = max(0.0, wh_qty - wh_reserved)
            else:
                wh_stock = wh_qty

            net_stock = max(0.0, float(wh_stock) - float(safety_stock))

            if hide_zero and net_stock <= 0:
                continue

            stock_prices.append({
                'sku': sku,
                'branch_external_id': 'odoo_wh_%s' % wh.id,
                'quantity': round(net_stock, 2),
                'price_usd': round(float(price_usd), 4),
            })

        if not stock_prices:
            return

        payload = {
            'action': 'sync',
            'branches': [],
            'products': [],
            'stock_prices': stock_prices,
        }

        send_to_duna(
            self.env,
            payload,
            event_type='stock_update',
            summary='Actualización Delta Stock: %s registros' % len(stock_prices)
        )

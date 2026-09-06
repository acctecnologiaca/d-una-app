# -*- coding: utf-8 -*-
import random
from odoo import models, fields, api, _  # type: ignore
from odoo.exceptions import UserError  # type: ignore


class DunaSimulatorPeakSaleWizard(models.TransientModel):
    _name = 'duna.simulator.peak.sale.wizard'
    _description = 'Simulador de Jornada Pico de Ventas'

    warehouse_id = fields.Many2one(
        'stock.warehouse',
        string='Almacén / Sucursal',
        required=True,
        default=lambda self: self._default_warehouse_id()
    )
    products_count = fields.Integer(
        string='Productos a Impactar',
        default=8,
        required=True,
        help='Cantidad de productos aleatorios que sufrirán ventas masivas.'
    )
    zero_out_count = fields.Integer(
        string='Productos a Agotar (Stock Cero)',
        default=2,
        required=True,
        help='Cantidad de productos que se llevarán deliberadamente a 0 stock para probar el estado agotado en D-Una.'
    )
    reduction_pct = fields.Float(
        string='Porcentaje de Reducción en Restantes (%)',
        default=60.0,
        required=True,
        help='Porcentaje promedio de inventario que se descontará a los productos que no lleguen a cero.'
    )

    @api.model
    def _default_warehouse_id(self):
        config = self.env['duna.simulator.config'].get_config()
        warehouses = config._get_target_warehouses()
        return warehouses[:1].id if warehouses else False

    def action_execute_peak_sale(self):
        self.ensure_one()
        config = self.env['duna.simulator.config'].get_config()
        warehouse = self.warehouse_id
        location = warehouse.lot_stock_id

        if self.zero_out_count > self.products_count:
            raise UserError(_("La cantidad de productos a agotar (%s) no puede superar el total de productos a impactar (%s).")
                            % (self.zero_out_count, self.products_count))

        # Buscar productos con stock positivo en el almacén
        domain = [
            ('active', '=', True),
            ('default_code', '!=', False),
            ('type', '=', 'product'),
        ]
        if hasattr(self.env['product.product'], 'sync_with_duna'):
            domain.append(('sync_with_duna', '=', True))

        quants = self.env['stock.quant'].search([
            ('location_id', 'child_of', location.id),
            ('quantity', '>', 0),
            ('product_id.active', '=', True),
        ])

        candidate_product_ids = list(set(quants.mapped('product_id').filtered(
            lambda p: p.default_code and (not hasattr(p, 'sync_with_duna') or p.sync_with_duna)
        ).ids))

        if not candidate_product_ids:
            raise UserError(_("No se encontraron productos con existencias activas en el almacén %s.") % warehouse.name)

        target_total = min(self.products_count, len(candidate_product_ids))
        selected_ids = random.sample(candidate_product_ids, target_total)

        zero_target_count = min(self.zero_out_count, target_total)
        zero_ids = set(random.sample(selected_ids, zero_target_count))
        reduced_ids = [pid for pid in selected_ids if pid not in zero_ids]

        zeroed_skus = []
        reduced_skus = []

        # 1. Llevar a cero
        for pid in zero_ids:
            prod = self.env['product.product'].browse(pid)
            ok, prev, target = config._apply_quant_stock_change(
                prod, warehouse, 0.0,
                reason="Jornada Pico (Agotado a 0)",
                event_type='peak_sale',
                exec_type='manual'
            )
            if ok:
                zeroed_skus.append(prod.default_code or prod.name)

        # 2. Reducir stock restante
        factor = max(0.0, 1.0 - (self.reduction_pct / 100.0))
        for pid in reduced_ids:
            prod = self.env['product.product'].browse(pid)
            curr_quant = self.env['stock.quant'].search([
                ('product_id', '=', prod.id),
                ('location_id', '=', location.id)
            ], limit=1)
            curr_qty = curr_quant.quantity if curr_quant else 0.0
            new_qty = max(0.0, round(curr_qty * factor, 2))
            # Garantizar que al menos descuente 1 unidad si tenía stock
            if new_qty == curr_qty and curr_qty > 1.0:
                new_qty = curr_qty - 1.0

            ok, prev, target = config._apply_quant_stock_change(
                prod, warehouse, new_qty,
                reason="Jornada Pico (Descuento -%g%%)" % self.reduction_pct,
                event_type='peak_sale',
                exec_type='manual'
            )
            if ok:
                reduced_skus.append(f"{prod.default_code or prod.name} ({prev:g}->{target:g})")

        summary = _("🛒 Jornada Pico completada en %s: %s productos agotados a 0 [%s] y %s productos reducidos [%s].") % (
            warehouse.name,
            len(zeroed_skus),
            ', '.join(zeroed_skus) if zeroed_skus else 'Ninguno',
            len(reduced_skus),
            ', '.join(reduced_skus) if reduced_skus else 'Ninguno',
        )

        config.write({
            'last_event_date': fields.Datetime.now(),
            'last_event_summary': summary,
            'total_events_count': config.total_events_count + 1,
        })

        return {
            'type': 'ir.actions.client',
            'tag': 'display_notification',
            'params': {
                'title': _("Jornada Pico Simulada"),
                'message': summary,
                'type': 'success',
                'sticky': True,
                'next': {'type': 'ir.actions.act_window_close'},
            }
        }

# -*- coding: utf-8 -*-
import random
from odoo import models, fields, api, _  # type: ignore
from odoo.exceptions import UserError  # type: ignore


class DunaSimulatorContainerWizard(models.TransientModel):
    _name = 'duna.simulator.container.wizard'
    _description = 'Simulador de Llegada de Contenedor (Reabastecimiento Masivo)'

    warehouse_id = fields.Many2one(
        'stock.warehouse',
        string='Almacén de Recepción',
        required=True,
        default=lambda self: self._default_warehouse_id()
    )
    brand_filter = fields.Char(
        string='Filtro de Marca',
        help='Dejar vacío para inyectar a todos los productos, o escribir el nombre de la marca (ej. Samsung, Xiaomi, HP, etc.).'
    )
    category_id = fields.Many2one(
        'product.category',
        string='Categoría (Opcional)',
        help='Opcionalmente restringe la inyección a una categoría específica.'
    )
    mode = fields.Selection([
        ('fixed', 'Cantidad Fija por Producto'),
        ('random_range', 'Rango Aleatorio por Producto'),
    ], string='Modo de Inyección', default='random_range', required=True)

    fixed_qty = fields.Float(
        string='Cantidad Fija (Unid)',
        default=50.0
    )
    min_qty = fields.Integer(
        string='Cantidad Mínima (Unid)',
        default=25
    )
    max_qty = fields.Integer(
        string='Cantidad Máxima (Unid)',
        default=80
    )

    @api.model
    def _default_warehouse_id(self):
        config = self.env['duna.simulator.config'].get_config()
        warehouses = config._get_target_warehouses()
        return warehouses[:1].id if warehouses else False

    def action_execute_container_arrival(self):
        self.ensure_one()
        config = self.env['duna.simulator.config'].get_config()
        warehouse = self.warehouse_id
        location = warehouse.lot_stock_id

        domain = [
            ('active', '=', True),
            ('default_code', '!=', False),
            ('type', '=', 'product'),
        ]
        if hasattr(self.env['product.product'], 'sync_with_duna'):
            domain.append(('sync_with_duna', '=', True))

        if self.category_id:
            domain.append(('categ_id', 'child_of', self.category_id.id))

        products = self.env['product.product'].search(domain)

        # Filtrar por marca si se especificó
        brand_query = (self.brand_filter or '').strip().lower()
        if brand_query:
            filtered_products = []
            for prod in products:
                # Comprobar duna_brand o product_brand_id si existen
                p_brand = ''
                if hasattr(prod, 'duna_brand') and prod.duna_brand:
                    p_brand = prod.duna_brand.strip().lower()
                elif hasattr(prod, 'product_brand_id') and prod.product_brand_id:
                    p_brand = prod.product_brand_id.name.strip().lower()
                elif hasattr(prod.product_tmpl_id, 'duna_brand') and prod.product_tmpl_id.duna_brand:
                    p_brand = prod.product_tmpl_id.duna_brand.strip().lower()

                if brand_query in p_brand or brand_query in (prod.name or '').lower():
                    filtered_products.append(prod)
            products = products.browse([p.id for p in filtered_products])

        if not products:
            raise UserError(_("No se encontraron productos que coincidan con los filtros de marca/categoría."))

        total_injected = 0.0
        affected_count = 0

        for prod in products:
            if self.mode == 'fixed':
                qty_to_add = max(1.0, self.fixed_qty)
            else:
                qty_to_add = float(random.randint(self.min_qty or 25, self.max_qty or 80))

            curr_quant = self.env['stock.quant'].search([
                ('product_id', '=', prod.id),
                ('location_id', '=', location.id)
            ], limit=1)
            curr_qty = curr_quant.quantity if curr_quant else 0.0
            new_qty = curr_qty + qty_to_add

            ok, prev, target = config._apply_quant_stock_change(
                prod, warehouse, new_qty,
                reason="Llegada de Contenedor (+%g)" % qty_to_add,
                event_type='container_arrival',
                exec_type='manual'
            )
            if ok:
                total_injected += qty_to_add
                affected_count += 1

        summary = _("📦 Contenedor registrado en %s: %s SKUs reabastecidos con un total de %g unidades inyectadas.") % (
            warehouse.name, affected_count, total_injected
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
                'title': _("Contenedor Recibido"),
                'message': summary,
                'type': 'success',
                'sticky': True,
                'next': {'type': 'ir.actions.act_window_close'},
            }
        }

# -*- coding: utf-8 -*-
import json
import logging
import random
from odoo import models, fields, api, _  # type: ignore
from odoo.exceptions import UserError, ValidationError  # type: ignore

_logger = logging.getLogger(__name__)


class DunaSimulatorConfig(models.Model):
    _name = 'duna.simulator.config'
    _description = 'Configuración y Panel de Control del Simulador D-Una'
    _rec_name = 'name'

    name = fields.Char(
        string='Nombre',
        default='Panel de Control Simulador D-Una',
        required=True
    )
    is_active = fields.Boolean(
        string='Simulación Activa',
        default=False,
        help='Activa o pausa la generación autónoma de eventos sintéticos en segundo plano.'
    )
    cron_interval_minutes = fields.Integer(
        string='Frecuencia Sugerida (Min)',
        default=15,
        help='Intervalo de ejecución programada del motor de simulación.'
    )

    # Probabilidades
    prob_counter_sale = fields.Integer(
        string='Venta de Mostrador (%)',
        default=70,
        help='Probabilidad de que ocurra una venta de mostrador (descuento de 1 a 3 unid).'
    )
    prob_replenishment = fields.Integer(
        string='Reabastecimiento (%)',
        default=20,
        help='Probabilidad de recepción de mercancía (aumento de 10 a 25 unid en stock bajo).'
    )
    prob_price_change = fields.Integer(
        string='Ajuste de Precios (%)',
        default=10,
        help='Probabilidad de micro-ajuste de tarifa (±3% a ±5%).'
    )

    # Parámetros de Venta
    sale_min_qty = fields.Integer(
        string='Venta Mínima (Unid)',
        default=1
    )
    sale_max_qty = fields.Integer(
        string='Venta Máxima (Unid)',
        default=3
    )
    sale_max_products = fields.Integer(
        string='Máx Productos por Venta',
        default=2
    )

    # Parámetros de Reabastecimiento
    restock_min_qty = fields.Integer(
        string='Reabastecimiento Mínimo (Unid)',
        default=10
    )
    restock_max_qty = fields.Integer(
        string='Reabastecimiento Máximo (Unid)',
        default=25
    )
    restock_threshold = fields.Float(
        string='Umbral de Stock Bajo (Unid)',
        default=5.0,
        help='Productos con existencias menores o iguales a este número tendrán prioridad para reposición.'
    )

    # Parámetros de Precio
    price_min_pct = fields.Float(
        string='Variación Mínima Precio (%)',
        default=3.0
    )
    price_max_pct = fields.Float(
        string='Variación Máxima Precio (%)',
        default=5.0
    )

    # Filtros
    warehouse_ids = fields.Many2many(
        'stock.warehouse',
        'duna_simulator_config_warehouse_rel',
        'config_id',
        'warehouse_id',
        string='Almacenes Participantes',
        help='Si no se selecciona ninguno, participarán los almacenes habilitados en el Conector D-Una.'
    )

    # Métricas y Auditoría
    last_event_date = fields.Datetime(
        string='Último Evento',
        readonly=True
    )
    last_event_summary = fields.Text(
        string='Resumen del Último Evento',
        readonly=True
    )
    total_events_count = fields.Integer(
        string='Total Eventos Ejecutados',
        default=0,
        readonly=True
    )

    @api.constrains('prob_counter_sale', 'prob_replenishment', 'prob_price_change')
    def _check_probabilities(self):
        for rec in self:
            total = rec.prob_counter_sale + rec.prob_replenishment + rec.prob_price_change
            if total != 100:
                raise ValidationError(_(
                    "La suma de las probabilidades debe ser exactamente 100%%. "
                    "Actual: %s%% (Venta: %s%%, Reabastecimiento: %s%%, Precios: %s%%)."
                ) % (total, rec.prob_counter_sale, rec.prob_replenishment, rec.prob_price_change))

    @api.model
    def get_config(self):
        """Obtiene el registro singleton de configuración o crea uno por defecto."""
        config = self.search([], limit=1)
        if not config:
            config = self.create({
                'name': 'Panel de Control Simulador D-Una',
                'is_active': False,
                'prob_counter_sale': 70,
                'prob_replenishment': 20,
                'prob_price_change': 10,
            })
        return config

    def action_toggle_active(self):
        """Alterna el estado activo / pausado del simulador."""
        for rec in self:
            rec.is_active = not rec.is_active
            status_label = _("activada") if rec.is_active else _("pausada")
            rec.message_post(body=_("Simulación de actividad comercial %s.") % status_label) if hasattr(rec, 'message_post') else None
        return True

    def _get_target_warehouses(self):
        """Determina los almacenes válidos considerando la configuración y el conector D-Una."""
        self.ensure_one()
        if self.warehouse_ids:
            return self.warehouse_ids

        ICP = self.env['ir.config_parameter'].sudo()
        wh_raw = ICP.get_param('duna_connector.warehouse_ids', '[]')
        try:
            wh_ids = json.loads(wh_raw)
            if wh_ids:
                warehouses = self.env['stock.warehouse'].browse(wh_ids).exists()
                if warehouses:
                    return warehouses
        except Exception:
            pass

        return self.env['stock.warehouse'].search([])

    def _apply_quant_stock_change(self, product, warehouse, new_quantity, reason, event_type='sale', exec_type='auto'):
        """
        Aplica un cambio de inventario usando el mecanismo estándar de stock.quant en Odoo 17.
        Esto gatilla de forma natural el hook _trigger_duna_stock_sync de odoo_duna_connector.
        """
        location = warehouse.lot_stock_id
        if not location:
            raise UserError(_("El almacén %s no tiene una ubicación interna de stock asignada.") % warehouse.name)

        target_qty = max(0.0, round(float(new_quantity), 2))

        quant = self.env['stock.quant'].search([
            ('product_id', '=', product.id),
            ('location_id', '=', location.id),
            ('lot_id', '=', False),
            ('package_id', '=', False),
            ('owner_id', '=', False),
        ], limit=1)

        prev_qty = quant.quantity if quant else 0.0

        try:
            if quant:
                quant.write({'inventory_quantity': target_qty})
                quant.action_apply_inventory()
            else:
                quant = self.env['stock.quant'].create({
                    'product_id': product.id,
                    'location_id': location.id,
                    'inventory_quantity': target_qty,
                })
                quant.action_apply_inventory()

            # Registro en log
            self.env['duna.simulator.log'].create({
                'name': f"{reason} · {product.default_code or product.name}",
                'event_type': event_type,
                'execution_type': exec_type,
                'warehouse_id': warehouse.id,
                'product_id': product.id,
                'sku': product.default_code or '',
                'previous_value': prev_qty,
                'new_value': target_qty,
                'details': f"Ubicación: {location.complete_name}. Stock previo: {prev_qty} -> Nuevo stock: {target_qty} (Dif: {target_qty - prev_qty:+g}).",
                'state': 'success',
            })
            return True, prev_qty, target_qty
        except Exception as e:
            _logger.error("Error al aplicar inventario simulado en SKU %s: %s", product.default_code, str(e))
            self.env['duna.simulator.log'].create({
                'name': f"ERROR {reason} · {product.default_code or product.name}",
                'event_type': event_type,
                'execution_type': exec_type,
                'warehouse_id': warehouse.id,
                'product_id': product.id,
                'sku': product.default_code or '',
                'previous_value': prev_qty,
                'new_value': target_qty,
                'details': f"Fallo al aplicar inventario: {str(e)}",
                'state': 'error',
            })
            return False, prev_qty, prev_qty

    def _apply_price_change(self, product_tmpl, percentage_delta, reason, event_type='price_change', exec_type='auto'):
        """
        Modifica el list_price de un product.template, lo que activa automáticamente
        el hook write() de product_sync.py en odoo_duna_connector.
        """
        prev_price = product_tmpl.list_price
        factor = 1.0 + (percentage_delta / 100.0)
        new_price = max(0.01, round(prev_price * factor, 2))

        try:
            product_tmpl.write({'list_price': new_price})

            self.env['duna.simulator.log'].create({
                'name': f"{reason} · {product_tmpl.default_code or product_tmpl.name}",
                'event_type': event_type,
                'execution_type': exec_type,
                'product_id': product_tmpl.product_variant_ids[:1].id if product_tmpl.product_variant_ids else False,
                'sku': product_tmpl.default_code or '',
                'previous_value': prev_price,
                'new_value': new_price,
                'details': f"Ajuste porcentual de {percentage_delta:+g}%%. Tarifa anterior: ${prev_price:.2f} -> Nueva: ${new_price:.2f}.",
                'state': 'success',
            })
            return True, prev_price, new_price
        except Exception as e:
            _logger.error("Error al aplicar precio simulado en SKU %s: %s", product_tmpl.default_code, str(e))
            self.env['duna.simulator.log'].create({
                'name': f"ERROR {reason} · {product_tmpl.default_code or product_tmpl.name}",
                'event_type': event_type,
                'execution_type': exec_type,
                'sku': product_tmpl.default_code or '',
                'previous_value': prev_price,
                'new_value': new_price,
                'details': f"Fallo al actualizar tarifa: {str(e)}",
                'state': 'error',
            })
            return False, prev_price, prev_price

    def _exec_counter_sale(self, warehouse, exec_type='auto'):
        """Simula una venta de mostrador descontando existencias."""
        self.ensure_one()
        # Buscar productos activos con SKU y publicados en D-Una
        domain = [
            ('active', '=', True),
            ('default_code', '!=', False),
            ('type', '=', 'product'),
        ]
        if hasattr(self.env['product.product'], 'sync_with_duna'):
            domain.append(('sync_with_duna', '=', True))

        products = self.env['product.product'].search(domain)
        if not products:
            return "Sin productos disponibles para venta."

        # Filtrar productos que tengan stock positivo en este almacén
        quants = self.env['stock.quant'].search([
            ('product_id', 'in', products.ids),
            ('location_id', 'child_of', warehouse.lot_stock_id.id),
            ('quantity', '>', 0)
        ])
        candidate_product_ids = quants.mapped('product_id').ids
        if not candidate_product_ids:
            # Seleccionar cualquiera de los productos
            candidate_product_ids = products.ids

        num_products = random.randint(1, min(self.sale_max_products or 2, len(candidate_product_ids)))
        selected_ids = random.sample(candidate_product_ids, num_products)
        selected_products = self.env['product.product'].browse(selected_ids)

        summaries = []
        for prod in selected_products:
            # Obtener stock actual
            curr_quant = self.env['stock.quant'].search([
                ('product_id', '=', prod.id),
                ('location_id', '=', warehouse.lot_stock_id.id)
            ], limit=1)
            curr_qty = curr_quant.quantity if curr_quant else 0.0

            qty_to_sub = random.randint(self.sale_min_qty or 1, self.sale_max_qty or 3)
            new_qty = max(0.0, curr_qty - qty_to_sub)

            ok, prev, target = self._apply_quant_stock_change(
                prod, warehouse, new_qty,
                reason="Venta Mostrador (-%s)" % qty_to_sub,
                event_type='sale',
                exec_type=exec_type
            )
            if ok:
                summaries.append(f"{prod.default_code}: {prev} -> {target} (-{qty_to_sub})")

        return f"🛒 Venta Mostrador en {warehouse.name}: {', '.join(summaries)}"

    def _exec_replenishment(self, warehouse, exec_type='auto'):
        """Simula una recepción de mercancía sumando existencias a productos con poco stock."""
        self.ensure_one()
        domain = [
            ('active', '=', True),
            ('default_code', '!=', False),
            ('type', '=', 'product'),
        ]
        if hasattr(self.env['product.product'], 'sync_with_duna'):
            domain.append(('sync_with_duna', '=', True))

        products = self.env['product.product'].search(domain)
        if not products:
            return "Sin productos disponibles para reposición."

        # Buscar quants con existencias <= threshold
        low_quants = self.env['stock.quant'].search([
            ('product_id', 'in', products.ids),
            ('location_id', 'child_of', warehouse.lot_stock_id.id),
            ('quantity', '<=', self.restock_threshold or 5.0)
        ])
        candidate_ids = low_quants.mapped('product_id').ids
        if not candidate_ids:
            # Si ninguno está bajo, elegir 1 o 2 al azar
            candidate_ids = random.sample(products.ids, min(2, len(products)))

        selected_ids = random.sample(candidate_ids, min(2, len(candidate_ids)))
        selected_products = self.env['product.product'].browse(selected_ids)

        summaries = []
        for prod in selected_products:
            curr_quant = self.env['stock.quant'].search([
                ('product_id', '=', prod.id),
                ('location_id', '=', warehouse.lot_stock_id.id)
            ], limit=1)
            curr_qty = curr_quant.quantity if curr_quant else 0.0

            qty_to_add = random.randint(self.restock_min_qty or 10, self.restock_max_qty or 25)
            new_qty = curr_qty + qty_to_add

            ok, prev, target = self._apply_quant_stock_change(
                prod, warehouse, new_qty,
                reason="Reabastecimiento (+%s)" % qty_to_add,
                event_type='restock',
                exec_type=exec_type
            )
            if ok:
                summaries.append(f"{prod.default_code}: {prev} -> {target} (+{qty_to_add})")

        return f"📦 Reabastecimiento en {warehouse.name}: {', '.join(summaries)}"

    def _exec_price_adjustment(self, exec_type='auto'):
        """Simula un micro-ajuste de precios (±3% a ±5%)."""
        domain = [
            ('active', '=', True),
            ('default_code', '!=', False),
            ('list_price', '>', 0),
        ]
        if hasattr(self.env['product.template'], 'sync_with_duna'):
            domain.append(('sync_with_duna', '=', True))

        templates = self.env['product.template'].search(domain)
        if not templates:
            return "Sin productos disponibles para ajuste de precio."

        selected_templates = random.sample(templates.ids, min(2, len(templates)))
        summaries = []
        for tmpl_id in selected_templates:
            tmpl = self.env['product.template'].browse(tmpl_id)
            # Determinar signo (positivo o negativo)
            sign = 1 if random.random() > 0.5 else -1
            pct_val = random.uniform(self.price_min_pct or 3.0, self.price_max_pct or 5.0)
            delta_pct = round(sign * pct_val, 1)

            ok, prev, new_p = self._apply_price_change(
                tmpl, delta_pct,
                reason="Micro-Ajuste Tarifa (%+g%%)" % delta_pct,
                event_type='price_change',
                exec_type=exec_type
            )
            if ok:
                summaries.append(f"{tmpl.default_code}: ${prev:.2f} -> ${new_p:.2f} ({delta_pct:+g}%)")

        return f"🏷️ Ajuste de Tarifa: {', '.join(summaries)}"

    def _run_single_tick(self, exec_type='auto'):
        """Ejecuta un ciclo sintético probabilístico."""
        self.ensure_one()
        warehouses = self._get_target_warehouses()
        if not warehouses:
            return "No se encontraron almacenes válidos para la simulación."

        warehouse = random.choice(warehouses)
        roll = random.uniform(0, 100)

        if roll < self.prob_counter_sale:
            summary = self._exec_counter_sale(warehouse, exec_type=exec_type)
        elif roll < (self.prob_counter_sale + self.prob_replenishment):
            summary = self._exec_replenishment(warehouse, exec_type=exec_type)
        else:
            summary = self._exec_price_adjustment(exec_type=exec_type)

        self.write({
            'last_event_date': fields.Datetime.now(),
            'last_event_summary': summary,
            'total_events_count': self.total_events_count + 1,
        })
        return summary

    @api.model
    def cron_run_synthetic_tick(self):
        """Método llamado periódicamente por ir.cron."""
        config = self.get_config()
        if not config.is_active:
            _logger.debug("Simulador D-Una pausado. Omitiendo ciclo ir.cron.")
            return

        ICP = self.env['ir.config_parameter'].sudo()
        is_conn_active = ICP.get_param('duna_connector.is_active', 'False').lower() in ('true', '1')
        if not is_conn_active:
            _logger.info("Conector D-Una no está activo. Omitiendo ciclo de simulación.")
            return

        try:
            summary = config._run_single_tick(exec_type='auto')
            _logger.info("Ciclo Simulador D-Una completado: %s", summary)
        except Exception as e:
            _logger.error("Excepción en ciclo autónomo de Simulador D-Una: %s", str(e), exc_info=True)

    def action_run_simulation_step(self):
        """Ejecuta manualmente 1 ciclo de simulación y muestra notificación al usuario."""
        self.ensure_one()
        summary = self._run_single_tick(exec_type='manual')
        return {
            'type': 'ir.actions.client',
            'tag': 'display_notification',
            'params': {
                'title': _("Simulación Ejecutada"),
                'message': summary,
                'type': 'success',
                'sticky': False,
                'next': {'type': 'ir.actions.act_window_close'},
            }
        }

    def action_open_peak_sale_wizard(self):
        """Abre el wizard de Jornada Pico de Ventas."""
        return {
            'name': _("Simular Jornada Pico de Ventas"),
            'type': 'ir.actions.act_window',
            'res_model': 'duna.simulator.peak.sale.wizard',
            'view_mode': 'form',
            'target': 'new',
            'context': {'default_config_id': self.id},
        }

    def action_open_container_wizard(self):
        """Abre el wizard de Llegada de Contenedor."""
        return {
            'name': _("Simular Llegada de Contenedor"),
            'type': 'ir.actions.act_window',
            'res_model': 'duna.simulator.container.wizard',
            'view_mode': 'form',
            'target': 'new',
            'context': {'default_config_id': self.id},
        }

    def action_open_category_price_wizard(self):
        """Abre el wizard de Variación de Precios por Categoría."""
        return {
            'name': _("Simular Variación de Precios por Categoría"),
            'type': 'ir.actions.act_window',
            'res_model': 'duna.simulator.price.wizard',
            'view_mode': 'form',
            'target': 'new',
            'context': {'default_config_id': self.id},
        }

    def action_view_logs(self):
        """Muestra los logs de auditoría del simulador."""
        return {
            'name': _("Historial de Simulación D-Una"),
            'type': 'ir.actions.act_window',
            'res_model': 'duna.simulator.log',
            'view_mode': 'tree,form',
            'domain': [],
            'context': {},
        }

# -*- coding: utf-8 -*-
from odoo import models, fields, api  # type: ignore


class DunaSimulatorLog(models.Model):
    _name = 'duna.simulator.log'
    _description = 'Registro de Auditoría de Simulación D-Una'
    _order = 'id desc'

    name = fields.Char(
        string='Referencia / Acción',
        required=True,
        index=True
    )
    event_type = fields.Selection([
        ('sale', 'Venta de Mostrador'),
        ('restock', 'Reabastecimiento'),
        ('price_change', 'Ajuste de Tarifa'),
        ('peak_sale', 'Jornada Pico (Estrés)'),
        ('container_arrival', 'Llegada de Contenedor'),
        ('cat_price', 'Ajuste por Categoría'),
    ], string='Tipo de Evento', required=True, default='sale', index=True)

    execution_type = fields.Selection([
        ('auto', 'Autónomo (ir.cron)'),
        ('manual', 'Manual / Escenario'),
    ], string='Modo de Ejecución', default='auto')

    date = fields.Datetime(
        string='Fecha y Hora',
        default=fields.Datetime.now,
        required=True,
        index=True
    )
    warehouse_id = fields.Many2one(
        'stock.warehouse',
        string='Almacén / Sucursal',
        ondelete='set null'
    )
    product_id = fields.Many2one(
        'product.product',
        string='Producto Afectado',
        ondelete='set null'
    )
    sku = fields.Char(
        string='SKU / Código',
        index=True
    )
    previous_value = fields.Float(
        string='Valor Anterior',
        digits=(12, 2)
    )
    new_value = fields.Float(
        string='Nuevo Valor',
        digits=(12, 2)
    )
    difference = fields.Float(
        string='Diferencia / Impacto',
        compute='_compute_difference',
        store=True,
        digits=(12, 2)
    )
    details = fields.Text(string='Detalle del Movimiento')
    state = fields.Selection([
        ('success', 'Exitoso'),
        ('warning', 'Advertencia'),
        ('error', 'Error'),
    ], string='Estado', default='success', index=True)

    @api.depends('previous_value', 'new_value')
    def _compute_difference(self):
        for rec in self:
            rec.difference = (rec.new_value or 0.0) - (rec.previous_value or 0.0)

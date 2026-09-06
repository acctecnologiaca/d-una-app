# -*- coding: utf-8 -*-
from odoo import models, fields  # type: ignore


class DunaSyncLog(models.Model):
    _name = 'duna.sync.log'
    _description = 'Registro de Sincronizaciones D-Una'
    _order = 'create_date desc'
    _rec_name = 'name'

    name = fields.Char(string='Descripción del Evento', required=True)
    event_type = fields.Selection([
        ('ping', 'Prueba de Conexión'),
        ('full_sync', 'Sincronización Completa'),
        ('product_update', 'Actualización de Producto'),
        ('stock_update', 'Actualización de Stock'),
        ('product_deactivate', 'Desactivación de Producto'),
        ('sync', 'Sincronización General'),
    ], string='Tipo de Evento', required=True, default='sync')
    status = fields.Selection([
        ('success', 'Exitoso'),
        ('error', 'Error'),
    ], string='Estado', required=True, default='success')
    status_code = fields.Integer(string='Código HTTP')
    response_message = fields.Text(string='Respuesta del Servidor')
    payload_summary = fields.Text(string='Resumen del Payload')

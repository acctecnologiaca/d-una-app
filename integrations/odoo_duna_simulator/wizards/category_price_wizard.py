# -*- coding: utf-8 -*-
from odoo import models, fields, api, _  # type: ignore
from odoo.exceptions import UserError  # type: ignore


class DunaSimulatorPriceWizard(models.TransientModel):
    _name = 'duna.simulator.price.wizard'
    _description = 'Simulador de Variación Masiva de Precios por Categoría'

    category_id = fields.Many2one(
        'product.category',
        string='Categoría de Producto',
        required=True
    )
    apply_to_child_categories = fields.Boolean(
        string='Incluir Subcategorías',
        default=True
    )
    adjustment_type = fields.Selection([
        ('increase', 'Incrementar Tarifa (+%)'),
        ('decrease', 'Rebajar / Descontar (-%)'),
    ], string='Tipo de Movimiento', default='increase', required=True)

    percentage = fields.Float(
        string='Porcentaje de Cambio (%)',
        default=10.0,
        required=True
    )

    def action_execute_price_adjustment(self):
        self.ensure_one()
        config = self.env['duna.simulator.config'].get_config()

        if self.percentage <= 0:
            raise UserError(_("El porcentaje de variación debe ser mayor que 0."))

        delta = self.percentage if self.adjustment_type == 'increase' else -self.percentage

        domain = [
            ('active', '=', True),
            ('default_code', '!=', False),
            ('list_price', '>', 0),
        ]
        if self.apply_to_child_categories:
            domain.append(('categ_id', 'child_of', self.category_id.id))
        else:
            domain.append(('categ_id', '=', self.category_id.id))

        if hasattr(self.env['product.template'], 'sync_with_duna'):
            domain.append(('sync_with_duna', '=', True))

        templates = self.env['product.template'].search(domain)
        if not templates:
            raise UserError(_("No se encontraron productos activos con tarifa en la categoría seleccionada."))

        affected_count = 0
        for tmpl in templates:
            ok, prev, new_p = config._apply_price_change(
                tmpl, delta,
                reason="Ajuste Masivo %s (%+g%%)" % (self.category_id.name, delta),
                event_type='cat_price',
                exec_type='manual'
            )
            if ok:
                affected_count += 1

        sign_label = _("incrementados") if self.adjustment_type == 'increase' else _("rebajados")
        summary = _("🏷️ Ajuste de precios en categoría '%s': %s productos %s en un %g%%.") % (
            self.category_id.name, affected_count, sign_label, self.percentage
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
                'title': _("Tarifas Actualizadas"),
                'message': summary,
                'type': 'success',
                'sticky': True,
                'next': {'type': 'ir.actions.act_window_close'},
            }
        }

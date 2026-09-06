# -*- coding: utf-8 -*-
from odoo import models, fields, api  # type: ignore


class DunaWarrantyRule(models.Model):
    _name = 'duna.warranty.rule'
    _description = 'Regla de Garantía Comercial D-Una'
    _order = 'sequence, id'

    sequence = fields.Integer(
        string='Prioridad',
        default=10,
        help='Menor número indica mayor prioridad de evaluación.'
    )
    name = fields.Char(
        string='Descripción',
        compute='_compute_name',
        store=True
    )
    brand_name = fields.Char(
        string='Marca / Fabricante',
        index=True,
        help='Nombre de la marca (ej: Hikvision, Dahua). Vacío aplica a cualquier marca.'
    )
    category_id = fields.Many2one(
        'product.category',
        string='Categoría',
        ondelete='cascade',
        index=True,
        help='Categoría de Odoo. Vacío aplica a todas las categorías.'
    )
    warranty_time = fields.Integer(
        string='Tiempo',
        default=12,
        required=True
    )
    warranty_unit = fields.Selection([
        ('months', 'Meses'),
        ('years', 'Años'),
        ('days', 'Días')
    ], string='Unidad', default='months', required=True)

    active = fields.Boolean(
        string='Activo',
        default=True
    )
    company_id = fields.Many2one(
        'res.company',
        string='Compañía',
        default=lambda self: self.env.company,
        required=True,
        index=True
    )

    @api.depends('brand_name', 'category_id', 'warranty_time', 'warranty_unit')
    def _compute_name(self):
        unit_map = {'months': 'meses', 'years': 'años', 'days': 'días'}
        for rule in self:
            brand = rule.brand_name.strip() if rule.brand_name else 'Cualquier Marca'
            cat = rule.category_id.name if rule.category_id else 'Todas las Categorías'
            unit_str = unit_map.get(rule.warranty_unit, rule.warranty_unit or 'meses')
            rule.name = f"{brand} [{cat}] ➔ {rule.warranty_time} {unit_str}"


class ResCompany(models.Model):
    _inherit = 'res.company'

    duna_warranty_rule_ids = fields.One2many(
        'duna.warranty.rule',
        'company_id',
        string='Reglas de Garantía D-Una'
    )

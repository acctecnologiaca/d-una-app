# -*- coding: utf-8 -*-
"""
Script de Siembra Automática de Datos de Prueba para Odoo
Empresa: ACC Tecnología, C.A.
Plataforma: D-Una
"""

import xmlrpc.client
import json
import os
import random
import sys
import time

# Configuración de conexión XML-RPC a Odoo
ODOO_URL = os.getenv("ODOO_URL", "http://localhost:8069")
ODOO_DB = os.getenv("ODOO_DB", "odoo")
ODOO_USER = os.getenv("ODOO_USER", "admin")
ODOO_PASSWORD = os.getenv("ODOO_PASSWORD", "admin")

DUNA_API_KEY = "ed57d7611147275cb0749dfa1af80104784a718a5dd42bd767e68be6f7e8ff0c"
DUNA_ENDPOINT = "https://fdkswvzrozijbizdthge.supabase.co/functions/v1/odoo_webhook"

DATA_JSON_PATH = os.path.join(os.path.dirname(__file__), "test_data", "parsed_products.json")


def connect_odoo():
    print(f"[*] Conectando a Odoo en {ODOO_URL}...")
    common = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common", allow_none=True)
    try:
        uid = common.authenticate(ODOO_DB, ODOO_USER, ODOO_PASSWORD, {})
    except Exception as e:
        print(f"[!] Error de conexión: {e}")
        return None, None
    if not uid:
        print(f"[!] Autenticación fallida en BD '{ODOO_DB}' con usuario '{ODOO_USER}'.")
        return None, None
    print(f"[+] Autenticación exitosa. UID: {uid}")
    models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object", allow_none=True)
    return uid, models


def upgrade_module(uid, models):
    print("\n[*] 0. Verificando y actualizando módulo odoo_duna_connector...")
    try:
        models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'ir.module.module', 'update_list', [[]])
        mod_ids = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'ir.module.module', 'search', [
            [('name', '=', 'odoo_duna_connector'), ('state', '=', 'installed')]
        ])
        if mod_ids:
            models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'ir.module.module', 'button_immediate_upgrade', [mod_ids])
            print("[+] Módulo odoo_duna_connector actualizado exitosamente en la base de datos.")
        else:
            to_install = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'ir.module.module', 'search', [
                [('name', '=', 'odoo_duna_connector')]
            ])
            if to_install:
                models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'ir.module.module', 'button_immediate_install', [to_install])
                print("[+] Módulo odoo_duna_connector instalado con éxito.")
    except Exception as e:
        print(f"[!] Nota al verificar módulo (continuando): {e}")


def setup_company(uid, models):
    print("\n[*] 1. Configurando Empresa: ACC Tecnología, C.A. ...")
    company_ids = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'res.company', 'search', [[]])
    if company_ids:
        main_company_id = company_ids[0]
        models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'res.company', 'write', [
            [main_company_id],
            {
                'name': 'ACC Tecnología, C.A.',
                'street': 'Av. Venezuela con Calle 25, Torre Empresarial',
                'city': 'Barquisimeto',
                'email': 'ventas@acctecnologia.com',
                'phone': '+58 251 2520000',
            }
        ])
        print(f"[+] Empresa principal actualizada: ACC Tecnología, C.A. (ID: {main_company_id})")
        return main_company_id
    return None


def setup_warehouses(uid, models, company_id):
    print("\n[*] 2. Configurando Sucursales y Almacenes...")
    # Verificar almacenes existentes
    wh_records = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.warehouse', 'search_read', [[]], {'fields': ['id', 'name', 'code']})
    wh_map = {w['code']: w['id'] for w in wh_records}

    warehouses_to_create = [
        {'code': 'BQTO', 'name': 'Sede Principal (Barquisimeto)', 'city': 'Barquisimeto'},
        {'code': 'CCS', 'name': 'Sucursal Caracas', 'city': 'Caracas'},
        {'code': 'VLN', 'name': 'Sucursal Valencia', 'city': 'Valencia'},
        {'code': 'RMA', 'name': 'Depósito de Mermas / Taller Técnico', 'city': 'Barquisimeto'},
    ]

    configured_wh_ids = {}

    # Renombrar el primer almacén por defecto si existe a Barquisimeto
    if wh_records:
        first_wh = wh_records[0]
        models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.warehouse', 'write', [
            [first_wh['id']],
            {'name': 'Sede Principal (Barquisimeto)', 'code': 'BQTO'}
        ])
        configured_wh_ids['BQTO'] = first_wh['id']
        print(f"[+] Almacén base renombrado a: Sede Principal (Barquisimeto) [BQTO] (ID: {first_wh['id']})")
    else:
        first_id = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.warehouse', 'create', [{
            'name': 'Sede Principal (Barquisimeto)',
            'code': 'BQTO',
            'company_id': company_id
        }])
        configured_wh_ids['BQTO'] = first_id

    # Crear los almacenes restantes si no existen
    for wh in warehouses_to_create[1:]:
        code = wh['code']
        existing = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.warehouse', 'search', [[('code', '=', code)]])
        if existing:
            configured_wh_ids[code] = existing[0]
            print(f"[i] Almacén ya existente: {wh['name']} [{code}] (ID: {existing[0]})")
        else:
            try:
                new_id = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.warehouse', 'create', [{
                    'name': wh['name'],
                    'code': code,
                    'company_id': company_id
                }])
                configured_wh_ids[code] = new_id
                print(f"[+] Almacén creado: {wh['name']} [{code}] (ID: {new_id})")
            except Exception as e:
                print(f"[!] Error creando almacén {code}: {e}")

    # Obtener contacto de la compañía matriz
    comp_data = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'res.company', 'read', [[company_id]], {'fields': ['partner_id', 'name']})
    company_partner_id = comp_data[0]['partner_id'][0] if comp_data and comp_data[0].get('partner_id') else None
    company_name = comp_data[0]['name'] if comp_data and comp_data[0].get('name') else 'ACC Tecnología'

    phone_map = {
        'BQTO': '+58 251 2520000',
        'CCS': '+58 212 5550000',
        'VLN': '+58 241 8880000',
        'RMA': '+58 251 2520099',
    }

    # Asignar o crear contacto específico para cada sucursal con su ciudad real
    for wh in warehouses_to_create:
        code = wh['code']
        wh_id = configured_wh_ids.get(code)
        if not wh_id:
            continue

        wh_info = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.warehouse', 'read', [[wh_id]], {'fields': ['partner_id']})
        curr_partner_id = wh_info[0]['partner_id'][0] if wh_info and wh_info[0].get('partner_id') else None

        email = f"{code.lower()}@acctecnologia.com"
        phone = phone_map.get(code, '+58 251 2520000')

        if not curr_partner_id or curr_partner_id == company_partner_id:
            branch_partner_id = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'res.partner', 'create', [{
                'name': f"{company_name} - {wh['name']}",
                'parent_id': company_partner_id,
                'type': 'other',
                'city': wh['city'],
                'email': email,
                'phone': phone,
            }])
            models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.warehouse', 'write', [[wh_id], {'partner_id': branch_partner_id}])
            print(f"[+] Asignado contacto de sucursal: {wh['city']} al almacén [{code}]")
        else:
            models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'res.partner', 'write', [[curr_partner_id], {
                'city': wh['city'],
                'email': email,
                'phone': phone,
            }])
            print(f"[+] Actualizada ciudad '{wh['city']}' en el contacto del almacén [{code}]")

    return configured_wh_ids


def setup_pricelists(uid, models):
    print("\n[*] 3. Configurando Tarifas / Listas de Precios...")
    usd_curr = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'res.currency', 'search', [[('name', '=', 'USD')]])
    usd_id = usd_curr[0] if usd_curr else False

    # Tarifa Mostrador
    pvp_id = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.pricelist', 'search', [[('name', '=', 'Precio Mostrador (PVP)')]])
    if not pvp_id:
        pvp_id = [models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.pricelist', 'create', [{
            'name': 'Precio Mostrador (PVP)',
            'currency_id': usd_id
        }])]
        print(f"[+] Creada Tarifa Mostrador (PVP)")

    # Tarifa D-Una Mayorista
    duna_pl_id = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.pricelist', 'search', [[('name', '=', 'Tarifa Aliados D-Una (Mayorista)')]])
    if not duna_pl_id:
        duna_pl_id = [models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.pricelist', 'create', [{
            'name': 'Tarifa Aliados D-Una (Mayorista)',
            'currency_id': usd_id
        }])]
        print(f"[+] Creada Tarifa Aliados D-Una (Mayorista)")

    return pvp_id[0], duna_pl_id[0]


def setup_duna_settings(uid, models, wh_map, duna_pricelist_id):
    print("\n[*] 4. Configurando Parámetros del Conector D-Una en Odoo...")
    # Solo incluir BQTO, CCS y VLN (dejando RMA fuera de D-Una para probar exclusión)
    sync_wh_ids = [wh_map[c] for c in ['BQTO', 'CCS', 'VLN'] if c in wh_map]

    params = [
        ('duna_connector.is_active', 'True'),
        ('duna_connector.endpoint_url', DUNA_ENDPOINT),
        ('duna_connector.api_key', DUNA_API_KEY),
        ('duna_connector.warehouse_ids', json.dumps(sync_wh_ids)),
        ('duna_connector.pricelist_id', str(duna_pricelist_id)),
        ('duna_connector.currency_mode', 'native_usd'),
        ('duna_connector.stock_mode', 'free_qty'),
        ('duna_connector.safety_stock', '0'),
        ('duna_connector.hide_zero_stock', 'True'),
        ('duna_connector.brand_mode', 'custom_field'),
        ('duna_connector.sync_images', 'False'),
        ('duna_connector.warranty_mode', 'cascade'),
        ('duna_connector.warranty_extract_text', 'True'),
    ]

    for key, val in params:
        existing = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'ir.config_parameter', 'search', [[('key', '=', key)]])
        if existing:
            models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'ir.config_parameter', 'write', [existing, {'value': val}])
        else:
            models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'ir.config_parameter', 'create', [{'key': key, 'value': val}])

    print(f"[+] Parámetros configurados exitosamente:")
    print(f"    - Endpoint: {DUNA_ENDPOINT}")
    print(f"    - API Key: {DUNA_API_KEY[:10]}... (ACC Tecnología)")
    print(f"    - Almacenes sincronizados: Barquisimeto, Caracas, Valencia (Excluido: Taller RMA)")
    print(f"    - Garantías: Modo Cascada Inteligente + Extracción Regex activa")


def setup_warranty_rules(uid, models, company_id):
    print("\n[*] 4.1 Configurando Reglas de Garantía Comercial por Marca y Categoría...")
    rules_to_seed = [
        {'sequence': 5, 'brand_name': 'Hikvision', 'warranty_time': 24, 'warranty_unit': 'months'},
        {'sequence': 6, 'brand_name': 'Dahua', 'warranty_time': 24, 'warranty_unit': 'months'},
        {'sequence': 7, 'brand_name': 'Western Digital', 'warranty_time': 36, 'warranty_unit': 'months'},
        {'sequence': 8, 'brand_name': 'ZKTeco', 'warranty_time': 12, 'warranty_unit': 'months'},
        {'sequence': 9, 'brand_name': 'EZVIZ', 'warranty_time': 12, 'warranty_unit': 'months'},
    ]

    # Buscar categoría de baterías / respaldo
    baterias_cats = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.category', 'search', [
        [('name', 'ilike', 'Bater')]
    ])
    if baterias_cats:
        rules_to_seed.append({
            'sequence': 20,
            'brand_name': False,
            'category_id': baterias_cats[0],
            'warranty_time': 6,
            'warranty_unit': 'months'
        })

    # Buscar categoría de cables / accesorios
    cables_cats = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.category', 'search', [
        [('name', 'ilike', 'Cable')]
    ])
    if cables_cats:
        rules_to_seed.append({
            'sequence': 25,
            'brand_name': False,
            'category_id': cables_cats[0],
            'warranty_time': 1,
            'warranty_unit': 'months'
        })

    for r in rules_to_seed:
        domain = [('company_id', '=', company_id), ('warranty_time', '=', r['warranty_time'])]
        if r.get('brand_name'):
            domain.append(('brand_name', '=', r['brand_name']))
        else:
            domain.append(('brand_name', '=', False))

        if r.get('category_id'):
            domain.append(('category_id', '=', r['category_id']))
        else:
            domain.append(('category_id', '=', False))

        existing = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'duna.warranty.rule', 'search', [domain])
        if not existing:
            vals = {
                'company_id': company_id,
                'sequence': r.get('sequence', 10),
                'brand_name': r.get('brand_name') or False,
                'category_id': r.get('category_id') or False,
                'warranty_time': r['warranty_time'],
                'warranty_unit': r['warranty_unit'],
                'active': True,
            }
            models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'duna.warranty.rule', 'create', [vals])
            desc = f"{r.get('brand_name') or 'Categoría'} -> {r['warranty_time']} {r['warranty_unit']}"
            print(f"[+] Regla de garantía creada: {desc}")
        else:
            print(f"[-] Regla de garantía ya existe: {r.get('brand_name') or 'Categoría'}")


def seed_products_and_stock(uid, models, wh_map, limit=None):
    print(f"\n[*] 5. Cargando Catálogo de Productos desde {DATA_JSON_PATH}...")
    if not os.path.exists(DATA_JSON_PATH):
        print(f"[!] Archivo {DATA_JSON_PATH} no encontrado.")
        return

    with open(DATA_JSON_PATH, "r", encoding="utf-8") as f:
        products_data = json.load(f)

    if limit:
        products_data = products_data[:limit]

    print(f"[+] Total de productos a procesar: {len(products_data)}")

    # Obtener ubicaciones internas de cada almacén para asignar stock
    location_map = {}
    for code, wh_id in wh_map.items():
        wh_data = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.warehouse', 'read', [[wh_id]], {'fields': ['lot_stock_id']})
        if wh_data and wh_data[0].get('lot_stock_id'):
            location_map[code] = wh_data[0]['lot_stock_id'][0]

    # Categorías en Odoo
    category_cache = {}

    created_count = 0
    updated_count = 0

    random.seed(42)  # Semilla fija para consistencia en pruebas

    for idx, p in enumerate(products_data):
        sku = p['sku'].strip()
        cat_name = p.get('category', 'General').strip()

        # Cache o creación de categoría
        if cat_name not in category_cache:
            existing_cat = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.category', 'search', [[('name', '=', cat_name)]])
            if existing_cat:
                category_cache[cat_name] = existing_cat[0]
            else:
                new_cat = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.category', 'create', [{'name': cat_name}])
                category_cache[cat_name] = new_cat

        category_id = category_cache[cat_name]

        # Verificar si producto ya existe
        existing_prod = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.template', 'search', [[('default_code', '=', sku)]])

        # Caso de prueba: marcar los productos 10 y 20 con sync_with_duna = False para probar exclusión manual
        sync_with_duna = not (idx in [10, 20])

        prod_vals = {
            'name': p['name'],
            'default_code': sku,
            'description_sale': p.get('description', ''),
            'list_price': p.get('price_usd', 10.0),
            'categ_id': category_id,
            'detailed_type': 'product',  # Almacenable en Odoo 17 (o 'type': 'product')
        }

        # Soporte para sync_with_duna y duna_brand
        try:
            prod_vals['sync_with_duna'] = sync_with_duna
            if p.get('brand'):
                prod_vals['duna_brand'] = p['brand']
        except Exception:
            pass

        if existing_prod:
            tmpl_id = existing_prod[0]
            try:
                models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.template', 'write', [[tmpl_id], prod_vals])
            except Exception:
                prod_vals.pop('duna_brand', None)
                models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.template', 'write', [[tmpl_id], prod_vals])
            updated_count += 1
        else:
            try:
                tmpl_id = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.template', 'create', [prod_vals])
                created_count += 1
            except Exception as e:
                # Si 'detailed_type' falla por versión antigua de Odoo, intentar con 'type'
                prod_vals['type'] = 'product'
                prod_vals.pop('detailed_type', None)
                try:
                    tmpl_id = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.template', 'create', [prod_vals])
                    created_count += 1
                except Exception as e2:
                    print(f"[!] Error creando producto SKU {sku}: {e2}")
                    continue

        # Obtener product.product (variante)
        variant_ids = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'product.product', 'search', [[('product_tmpl_id', '=', tmpl_id)]])
        if not variant_ids:
            continue
        product_id = variant_ids[0]

        # Asignar stock en cada sucursal
        # Caso de prueba: cada 25 productos, poner stock en 0 en todas las sucursales para probar hide_zero_stock
        is_zero_stock_test = (idx % 25 == 0)

        for code, loc_id in location_map.items():
            if is_zero_stock_test:
                qty = 0.0
            elif code == 'BQTO':
                qty = float(random.randint(12, 45))
            elif code == 'CCS':
                qty = float(random.randint(5, 25))
            elif code == 'VLN':
                qty = float(random.randint(2, 15))
            elif code == 'RMA':
                qty = float(random.randint(1, 3))  # Almacén excluido
            else:
                qty = 5.0

            if qty > 0:
                try:
                    q_ids = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.quant', 'search', [
                        [('product_id', '=', product_id), ('location_id', '=', loc_id)]
                    ])
                    if q_ids:
                        models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.quant', 'write', [
                            q_ids, {'inventory_quantity': qty}
                        ])
                        models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.quant', 'action_apply_inventory', [q_ids])
                    else:
                        new_q = models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.quant', 'create', [{
                            'product_id': product_id,
                            'location_id': loc_id,
                            'inventory_quantity': qty,
                        }])
                        models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.quant', 'action_apply_inventory', [[new_q]])
                except Exception:
                    try:
                        # Fallback directo
                        models.execute_kw(ODOO_DB, uid, ODOO_PASSWORD, 'stock.quant', 'create', [{
                            'product_id': product_id,
                            'location_id': loc_id,
                            'quantity': qty,
                        }])
                    except Exception:
                        pass

        if (idx + 1) % 50 == 0 or (idx + 1) == len(products_data):
            print(f"    ... procesados {idx + 1}/{len(products_data)} productos.")

    print(f"\n[+] Siembra finalizada:")
    print(f"    - Creados: {created_count}")
    print(f"    - Actualizados: {updated_count}")
    print(f"    - Total en Odoo: {created_count + updated_count}")


def main():
    print("=" * 65)
    print(" SEEDER AUTOMATIZADO ODOO ➔ D-UNA")
    print(" Empresa: ACC Tecnología, C.A.")
    print("=" * 65)

    uid, models = connect_odoo()
    if not uid:
        sys.exit(1)

    upgrade_module(uid, models)
    company_id = setup_company(uid, models)
    wh_map = setup_warehouses(uid, models, company_id)
    pvp_id, duna_pl_id = setup_pricelists(uid, models)
    setup_duna_settings(uid, models, wh_map, duna_pl_id)
    setup_warranty_rules(uid, models, company_id)

    # Si se pasa argumento numérico en CLI (ej: python seed_data.py 50), limita la cantidad
    limit = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else None
    seed_products_and_stock(uid, models, wh_map, limit=limit)

    print("\n" + "=" * 65)
    print(" ¡AMBIENTE DE PRUEBA 100% LISTO!")
    print(" Siguiente paso:")
    print(" 1. Ingrese a Odoo en su navegador.")
    print(" 2. Vaya a Inventario > Conector D-Una > Configuración.")
    print(" 3. Haga clic en 'Probar Conexión con D-Una' (validará ACC Tecnología).")
    print(" 4. Haga clic en 'Sincronizar Catálogo Completo Ahora'.")
    print("=" * 65)


if __name__ == "__main__":
    main()

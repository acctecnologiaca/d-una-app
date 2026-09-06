# -*- coding: utf-8 -*-
import logging
import threading
import json
import requests
import odoo  # type: ignore

_logger = logging.getLogger(__name__)

TIMEOUT_SECONDS = 30


def _send_request(db_name, endpoint_url, api_key, payload, event_type, summary):
    """Worker que ejecuta la petición HTTP en un hilo secundario sin bloquear Odoo."""
    status = 'error'
    status_code = 0
    response_message = ''
    try:
        headers = {
            'Content-Type': 'application/json',
            'x-api-key': api_key,
        }
        resp = requests.post(
            endpoint_url,
            json=payload,
            headers=headers,
            timeout=TIMEOUT_SECONDS,
        )
        status_code = resp.status_code
        response_message = resp.text[:2000] if resp.text else ''
        if resp.status_code == 200:
            status = 'success'
            _logger.info('D-Una sync OK: %s', summary)
        else:
            _logger.warning('D-Una sync HTTP %s: %s', resp.status_code, resp.text[:500] if resp.text else '')
    except requests.exceptions.Timeout:
        response_message = 'Timeout después de %s segundos' % TIMEOUT_SECONDS
        _logger.warning('D-Una sync timeout: %s', summary)
    except requests.exceptions.ConnectionError:
        response_message = 'No se pudo conectar al servidor de D-Una (Error de red/DNS)'
        _logger.warning('D-Una sync connection error: %s', summary)
    except Exception as e:
        response_message = str(e)[:2000]
        _logger.exception('D-Una sync error inesperado: %s', summary)
    finally:
        # Registrar en la base de datos de Odoo usando un nuevo cursor aislado
        try:
            registry = odoo.registry(db_name)
            with registry.cursor() as cr:
                env = odoo.api.Environment(cr, odoo.SUPERUSER_ID, {})
                env['duna.sync.log'].sudo().create({
                    'name': summary,
                    'event_type': event_type,
                    'status': status,
                    'status_code': status_code,
                    'response_message': response_message,
                    'payload_summary': json.dumps(payload, default=str)[:4000],
                })
        except Exception:
            _logger.exception('No se pudo registrar log de D-Una sync en base de datos')


def send_to_duna(env, payload, event_type='sync', summary='Sincronización D-Una'):
    """Punto de entrada asíncrono. Valida configuración activa y despacha el hilo."""
    ICP = env['ir.config_parameter'].sudo()
    is_active = ICP.get_param('duna_connector.is_active', 'False')
    if is_active.lower() not in ('true', '1'):
        return

    endpoint_url = ICP.get_param('duna_connector.endpoint_url', '')
    api_key = ICP.get_param('duna_connector.api_key', '')

    if not endpoint_url or not api_key:
        _logger.warning('D-Una Connector: endpoint_url o api_key no configurados')
        return

    db_name = env.cr.dbname
    thread = threading.Thread(
        target=_send_request,
        args=(db_name, endpoint_url, api_key, payload, event_type, summary),
        daemon=True,
    )
    thread.start()


def test_connection_sync(endpoint_url, api_key):
    """Petición síncrona usada para el botón 'Probar Conexión' en Ajustes de Odoo."""
    if not endpoint_url or not api_key:
        return {
            'success': False,
            'message': 'Debe configurar la URL del Endpoint y el API Key antes de probar la conexión.'
        }
    try:
        headers = {
            'Content-Type': 'application/json',
            'x-api-key': api_key.strip(),
        }
        resp = requests.post(
            endpoint_url.strip(),
            json={'action': 'ping'},
            headers=headers,
            timeout=15,
        )
        try:
            data = resp.json()
        except Exception:
            data = {}

        if resp.status_code == 200 and data.get('success'):
            supplier_name = data.get('supplier_name', 'Proveedor D-Una')
            return {
                'success': True,
                'supplier_name': supplier_name,
                'message': '¡Conexión exitosa! Proveedor autenticado: %s' % supplier_name
            }
        else:
            err_msg = data.get('error') or resp.text[:300] or ('HTTP Error %s' % resp.status_code)
            return {
                'success': False,
                'message': 'Error de autenticación: %s' % err_msg
            }
    except requests.exceptions.Timeout:
        return {
            'success': False,
            'message': 'Tiempo de espera agotado al intentar conectar con el servidor D-Una.'
        }
    except requests.exceptions.ConnectionError:
        return {
            'success': False,
            'message': 'No se pudo establecer conexión con el servidor. Verifique la URL y su conexión a Internet.'
        }
    except Exception as e:
        return {
            'success': False,
            'message': 'Error inesperado: %s' % str(e)
        }

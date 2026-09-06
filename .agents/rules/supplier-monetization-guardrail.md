# Regla Primordial de Monetización y Canalización de Compras con Proveedores

## Principio Fundamental (Mandatorio e Inviolable)

**LA CONCRECIÓN DE COMPRAS CON PROVEEDORES AFILIADOS A TRAVÉS DE LA APLICACIÓN (ÓRDENES DE COMPRA - OC) ES EL MOTOR PRIMORDIAL Y LA PRINCIPAL FUENTE DE INGRESOS DE LA PLATAFORMA D'UNA.**

Cualquier diseño arquitectónico, flujo de usuario o lógica de negocio que permita eludir, posponer arbitrariamente o desintermediar la emisión de Órdenes de Compra (OC) hacia proveedores afiliados atenta directamente contra el modelo de sostenibilidad de la plataforma.

---

## Directrices Operativas

1. **Precedencia Obligatoria de la Orden de Compra (OC):**
   - Para cualquier producto originado desde el catálogo de un **Proveedor Afiliado**, es **estrictamente obligatorio** que exista una Orden de Compra (OC) emitida en D'Una que se encuentre en estado **aprobada (`approved`) o finalizada (`finalized`)** antes de que dicho ítem pueda ser formalizado en una Nota de Entrega (NE).
   - Queda terminantemente prohibido permitir la entrega comercial de productos de proveedores afiliados eludiendo el embudo transaccional de D'Una o con órdenes en borrador o pendientes.

2. **Integridad Temporal del Inventario y Prevención de Stock Fantasma:**
   - La secuencia operativa de despacho debe respetar la causalidad lógica y contable:
     $$\text{Cotización (CT)} \longrightarrow \text{Orden de Compra (OC)} \longrightarrow \text{Recepción/Registro (RC o Dropshipping)} \longrightarrow \text{Nota de Entrega (NE)}$$
   - Si se permitiera la secuencia invertida ($\text{NE} \longrightarrow \text{OC} \longrightarrow \text{RC}$), la recepción posterior cargaría al inventario propio unidades que ya fueron entregadas en el pasado, generando **stock fantasma** e incongruencia total en los balances y seriales del usuario.

3. **Restricción en Creación Directa de Notas de Entrega (NE):**
   - Si el usuario crea una Nota de Entrega de forma manual e independiente (sin cotización), **únicamente podrá seleccionar productos de su Inventario Propio**.
   - No se permite seleccionar productos del catálogo de proveedores afiliados en una NE manual sin una compra u orden previa.

4. **Flujo de Dropshipping Formalizado:**
   - En despachos directos del proveedor al cliente final (dropshipping), la OC debe emitirse en D'Una indicando la dirección de entrega del cliente. La Nota de Entrega se vincula a esa OC para certificar la recepción sin duplicar ni corromper el stock local.

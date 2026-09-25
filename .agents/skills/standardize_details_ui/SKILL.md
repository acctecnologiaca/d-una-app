---
name: standardize_details_ui
description: Estándar para pantallas de detalle de entidad simple (Arquetipo 4). Incluye AppBar con botón de eliminación preventiva protegida (con CustomDialog.destructive), visualización con InfoBlock.text, FAB de edición y padding dinámico estándar (FabScrollPadding.single = 112.0px).
---

# Standardize Entity Details Screen Skill (Arquetipo 4)

Esta guía establece el estándar para pantallas de visualización de solo lectura de una entidad individual (Producto, Servicio, Cliente, Colaborador) con opciones de Editar y Eliminar.
Referencias canónicas en el proyecto:
- [`product_details_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/portfolio/presentation/inventory/screens/product_details/product_details_screen.dart)
- [`client_details_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/clients/presentation/client_details_screen.dart)

---

## 1. Estructura General

Una pantalla de detalle consta de:
1. **AppBar:**
   - Título: `'Detalles de [Entidad]'` (alineado a la izquierda, `titleSpacing: 0`).
   - Botón de regreso (`Icons.arrow_back`).
   - Botón de eliminación en `actions`: Protegido mediante comprobación de documentos vinculados (si tiene cotizaciones, reportes o compras asociadas, se deshabilita con un `Tooltip` explicativo).
2. **Cuerpo Scrollable:**
   - `SingleChildScrollView` con padding inferior dinámico usando [`FabScrollPadding`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/utils/fab_scroll_padding.dart):
     - Si solo hay FAB de editar: **`bottom: FabScrollPadding.single` (112.0 px)**.
     - Si hay 2 FABs (ej. WhatsApp + Editar): **`bottom: FabScrollPadding.doubleFab` (184.0 px)**.
3. **Bloques de Datos:**
   - Cabecera con imagen o avatar si aplica.
   - Datos clave-valor organizados con [`InfoBlock.text(...)`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/info_block.dart).
   - Badges de estatus con [`UomStatusBadge`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/uom_status_badge.dart) o [`StatusBadge`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/status_badge.dart).
4. **FAB de Edición:**
   - Botón flotante con icono `Icons.edit` y fondo `colors.primaryContainer`.

---

### A. Regla Canónica de Ocultamiento Dinámico de InfoBlocks Vacíos
- **Prohibición de Textos Residuales ('No registrado' / 'Sin observaciones'):** Queda estrictamente prohibido renderizar un `InfoBlock` con etiquetas como `'No registrado'`, `'No especificado'` o valores vacíos cuando el dato no existe.
- **Ocultamiento Limpio:** Si un campo opcional (como teléfono, correo, RIF/cédula, dirección, cargo o departamento) es `null` o está vacío tras `trim()`, el `InfoBlock` completo y su separación vertical (`const SizedBox(height: 24)`) deben **omitirse por completo** del árbol de widgets.
- **Agrupadores de Sección Condicionales:** Si una subsección (como *Información de contacto*) contiene únicamente campos opcionales, el título de la sección solo debe renderizarse si al menos uno de sus campos dependientes tiene valor registrado.


---

## 2. Regla de Oro: Proveedores de Detalle con `autoDispose`

> [!CAUTION]
> **Prohibición de Proveedores de Detalle Persistentes:**
> Todo provider de detalle individual parametrizado por ID (`productDetailProvider`, `purchaseDetailsProvider`, `clientDetailsProvider`, etc.) **DEBE** declararse obligatoriamente con `.autoDispose`:
> ```dart
> final myEntityDetailProvider = FutureProvider.autoDispose.family<MyEntity?, String>((ref, id) async {
>   return ref.read(myEntityRepositoryProvider).getById(id);
> });
> ```
> **Razón Arquitectónica:** Si un `FutureProvider.family` omite `autoDispose`, Riverpod retiene en memoria la instancia original indefinidamente. Si el usuario navega a la lista, realiza modificaciones en otros módulos concurrentes (por ejemplo, finalizar o cancelar una Nota de Entrega que altera el stock de un producto) y vuelve a ingresar a la pantalla de detalle, la vista mostrará valores desactualizados de la caché en lugar de reflejar el estado actual de la base de datos.

---

## 3. Implementación Paso a Paso

```dart
class MyEntityDetailsScreen extends ConsumerStatefulWidget {
  final String entityId;
  const MyEntityDetailsScreen({super.key, required this.entityId});

  @override
  ConsumerState<MyEntityDetailsScreen> createState() => _MyEntityDetailsScreenState();
}

class _MyEntityDetailsScreenState extends ConsumerState<MyEntityDetailsScreen>
    with WidgetsBindingObserver {
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Garantiza invalidación de caché y datos 100% frescos al montar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(myEntityDetailProvider(widget.entityId));
    });

    // 2. Suscripción en tiempo real al registro individual
    _initRealtimeSubscription();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(myEntityDetailProvider(widget.entityId));
    }
  }

  void _initRealtimeSubscription() {
    _realtimeChannel = Supabase.instance.client
        .channel('public:my_entity_${widget.entityId}_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'my_entity_table',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.entityId,
          ),
          callback: (payload) {
            if (mounted) {
              ref.invalidate(myEntityDetailProvider(widget.entityId));
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Obtención asíncrona de la entidad
    final entityAsync = ref.watch(myEntityDetailProvider(widget.entityId));

    return entityAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (entity) {
        if (entity == null) {
          return const Scaffold(body: Center(child: Text('Registro no encontrado')));
        }

        // Comprobación preventiva de borrado si tiene documentos vinculados
        final hasLinkedDocsAsync = ref.watch(entityHasLinkedDocsProvider(entity.id));
        final hasLinkedDocs = hasLinkedDocsAsync.value ?? true;
        final canDelete = !hasLinkedDocs && !hasLinkedDocsAsync.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: Text('Detalles de ${entity.displayName}'),
            centerTitle: false,
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
            elevation: 0,
            titleSpacing: 0,
            titleTextStyle: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: colors.onSurface,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              Tooltip(
                message: canDelete
                    ? 'Eliminar registro'
                    : 'No se puede eliminar: tiene documentos asociados',
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: canDelete
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.38),
                  ),
                  onPressed: canDelete
                      ? () async {
                          final confirm = await CustomDialog.show<bool>(
                            context: context,
                            dialog: CustomDialog.destructive(
                              title: 'Eliminar Registro',
                              contentText: '¿Estás seguro de que deseas eliminar este registro permanentemente?',
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: colors.error),
                                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref.read(myEntityListProvider.notifier).delete(entity.id);
                            if (context.mounted) {
                              AppToast.showSuccess(context, 'Registro eliminado exitosamente');
                              context.pop();
                            }
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            // Padding dinámico para evitar que el FAB tape el contenido
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: FabScrollPadding.single, // 112.0 px (MD3 nativo con 40px de despeje)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entity.name,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                InfoBlock.text(
                  icon: Symbols.category,
                  label: 'Categoría',
                  value: entity.categoryName,
                ),
                const SizedBox(height: 16),
                InfoBlock.text(
                  icon: Symbols.calendar_today,
                  label: 'Fecha de registro',
                  value: entity.formattedDate,
                ),
                const SizedBox(height: 16),
                InfoBlock.text(
                  icon: Symbols.notes,
                  label: 'Observaciones',
                  value: entity.notes.isEmpty ? 'Sin observaciones' : entity.notes,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/my-entity/edit/${entity.id}', extra: entity),
            backgroundColor: colors.primaryContainer,
            child: Icon(Icons.edit, color: colors.onPrimaryContainer),
          ),
        );
      },
    );
  }
}
```

> [!IMPORTANT]
> **Prohibición de Padding Artificial:** El `FloatingActionButton` debe colocarse directamente en la propiedad `floatingActionButton` del `Scaffold`. Queda **estrictamente prohibido** envolverlo en `Padding(bottom: 40.0)`.

---

## 4. Checklist de Verificación para Detalles de Entidad

- [ ] ¿El proveedor de detalle de la entidad está definido obligatoriamente con `FutureProvider.autoDispose.family`?
- [ ] ¿Se programó `WidgetsBinding.instance.addPostFrameCallback` en `initState` para forzar la invalidación inicial del proveedor de detalle?
- [ ] ¿Se implementa `WidgetsBindingObserver` con invalidación en `AppLifecycleState.resumed`?
- [ ] ¿Está implementada la suscripción Postgres Realtime para escuchar cambios en el registro individual (`column: 'id'`, `value: entityId`)?
- [ ] ¿Se desuscribe el canal Realtime y se remueve el observer en `dispose()`?
- [ ] ¿El AppBar tiene botón de eliminar protegido con validación preventiva de vínculos?
- [ ] ¿La confirmación de borrado utiliza `CustomDialog.destructive` con botón rojo?
- [ ] ¿Los campos de datos informativos utilizan `InfoBlock.text`?
- [ ] ¿El padding inferior del scroll view aplica la constante canónica `FabScrollPadding.single` (`112.0 px`) con 1 FAB o `FabScrollPadding.doubleFab` (`184.0 px`) con 2 FABs?
- [ ] ¿El FAB de editar reposa directamente en el `Scaffold` sin envoltorios `Padding(bottom: 40.0)`?
- [ ] ¿El FAB de editar utiliza `colors.primaryContainer` y `colors.onPrimaryContainer`?


---
name: standardize_details_ui
description: Estándar para pantallas de detalle de entidad simple (Arquetipo 4). Incluye AppBar con botón de eliminación preventiva protegida (con CustomDialog.destructive), visualización con InfoBlock.text, FAB de edición y padding dinámico (112px).
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
   - `SingleChildScrollView` con padding inferior dinámico:
     - Si solo hay FAB de editar: **`bottomPadding: 112.0 px`**.
     - Si hay 2 FABs (ej. WhatsApp + Editar): **`bottomPadding: 184.0 px`**.
3. **Bloques de Datos:**
   - Cabecera con imagen o avatar si aplica.
   - Datos clave-valor organizados con [`InfoBlock.text(...)`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/info_block.dart).
   - Badges de estatus con [`UomStatusBadge`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/uom_status_badge.dart) o [`StatusBadge`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/status_badge.dart).
4. **FAB de Edición:**
   - Botón flotante con icono `Icons.edit` y fondo `colors.primaryContainer`.

---

## 2. Implementación Paso a Paso

```dart
class MyEntityDetailsScreen extends ConsumerStatefulWidget {
  final MyEntity entity;
  const MyEntityDetailsScreen({super.key, required this.entity});

  @override
  ConsumerState<MyEntityDetailsScreen> createState() => _MyEntityDetailsScreenState();
}

class _MyEntityDetailsScreenState extends ConsumerState<MyEntityDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 1. Sincronización reactiva: obtener la versión fresca de la entidad desde el provider
    final listAsync = ref.watch(myEntityListProvider);
    final entity = listAsync.valueOrNull?.firstWhere(
          (e) => e.id == widget.entity.id,
          orElse: () => widget.entity,
        ) ?? widget.entity;

    // 2. Comprobación preventiva de borrado (ejemplo: si tiene documentos asociados)
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
          bottom: 112.0, // Regla matemática de 1 FAB
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la entidad
            Text(
              entity.name,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Campos clave-valor organizados con InfoBlock
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
  }
}
```

---

## 3. Checklist de Verificación para Detalles de Entidad

- [ ] ¿El AppBar tiene botón de eliminar protegido con validación preventiva de vínculos?
- [ ] ¿La confirmación de borrado utiliza `CustomDialog.destructive` con botón rojo?
- [ ] ¿Los campos de datos informativos utilizan `InfoBlock.text`?
- [ ] ¿El padding inferior del scroll view aplica la fórmula dinámica (`112.0 px` con 1 FAB)?
- [ ] ¿El FAB de editar utiliza `colors.primaryContainer` y `colors.onPrimaryContainer`?

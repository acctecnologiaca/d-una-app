---
name: standardize_form_screen
description: Estándar para pantallas de formulario y edición directa (Arquetipo 5). Incluye Flutter Form con GlobalKey, prevención de descarte accidental (PopScope), CustomLocationPicker, CustomMultiDropdown, FormBottomBar y feedback con AppToast.
---

# Standardize Form Screen Skill (Arquetipo 5)

Esta guía define el estándar para pantallas de entrada y edición directa de datos en D'Una App.
Referencias canónicas en el proyecto:
- [`edit_client_person_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/clients/presentation/screens/edit_client/edit_client_person_screen.dart)
- [`add_collaborator_screen.dart`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/features/collaborators/presentation/screens/add_collaborator_screen.dart)

---

## 1. Estructura General de un Formulario Estándar

Un formulario estándar consta de:
1. **AppBar:** [`StandardAppBar`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/standard_app_bar.dart) o `AppBar` estándar con título descriptivo y botón de regreso.
2. **Control de Abandono (`PopScope`):** Si el usuario ha modificado campos (`_hasChanges`), advertir con un diálogo de confirmación antes de permitir salir.
3. **Cuerpo Scrollable:** `SingleChildScrollView` dentro de `Expanded`, con padding estándar `const EdgeInsets.all(16.0)` o `EdgeInsets.fromLTRB(16, 24, 16, 40)`.
4. **Campos Estandarizados:** Usar exclusivamente los componentes de `lib/shared/widgets/`.
5. **Barra de Acciones Inferior:** [`FormBottomBar`](file:///c:/Users/aleja/flutter_apps/MVP/d_una_app/lib/shared/widgets/form_bottom_bar.dart) fija al fondo de la pantalla.

---

## 2. Implementación Paso a Paso

```dart
class MyFormScreen extends ConsumerStatefulWidget {
  final String? entityId;
  const MyFormScreen({super.key, this.entityId});

  @override
  ConsumerState<MyFormScreen> createState() => _MyFormScreenState();
}

class _MyFormScreenState extends ConsumerState<MyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _notesController;
  String? _selectedCategory;
  List<String> _selectedTags = [];
  String? _country;
  String? _state;
  String? _city;

  bool _isSubmitting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _notesController = TextEditingController();

    // Rastrear cambios para advertir abandono accidental
    _nameController.addListener(_markAsChanged);
    _notesController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final confirm = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog(
        title: '¿Descartar cambios?',
        content: const Text('Tienes modificaciones sin guardar. ¿Deseas salir y perder los cambios?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(myEntityNotifierProvider.notifier).save(...);
      if (mounted) {
        AppToast.showSuccess(context, 'Guardado exitosamente');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error al guardar: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: const StandardAppBar(title: 'Editar Registro'),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Campo de Texto Estándar
                      CustomTextField(
                        label: 'Nombre*',
                        controller: _nameController,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 24),

                      // 2. Dropdown Estándar
                      CustomDropdown<String>(
                        label: 'Categoría',
                        value: _selectedCategory,
                        items: const ['Servicio', 'Producto', 'Insumo'],
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                            _hasChanges = true;
                          });
                        },
                        itemLabelBuilder: (val) => val,
                      ),
                      const SizedBox(height: 24),

                      // 3. Ubicación Geográfica (si aplica)
                      CustomLocationPicker(
                        initialCountry: _country,
                        initialState: _state,
                        initialCity: _city,
                        onChanged: (loc) {
                          _country = loc.country;
                          _state = loc.state;
                          _city = loc.city;
                          _hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 4. Notas Multilínea
                      CustomTextField(
                        label: 'Notas adicionales',
                        controller: _notesController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Barra fija al pie
            Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 8.0,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom
                    : 24.0,
              ),
              child: FormBottomBar(
                onCancel: () async {
                  final canLeave = await _onWillPop();
                  if (canLeave && context.mounted) context.pop();
                },
                onSave: _isSubmitting ? null : _submitForm,
                saveLabel: _isSubmitting ? 'Guardando...' : 'Guardar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 3. Checklist de Verificación para Formularios

- [ ] ¿El formulario cuenta con `GlobalKey<FormState>` y validadores en cada campo requerido?
- [ ] ¿Se utiliza `PopScope` con diálogo de confirmación para no perder datos si `_hasChanges == true`?
- [ ] ¿La barra de botones inferior usa `FormBottomBar` protegida con el padding inferior del dispositivo?
- [ ] ¿Las notificaciones de éxito o fallo usan `AppToast.showSuccess` y `AppToast.showError`?
- [ ] ¿Se usan `CustomTextField`, `CustomDropdown`, `CustomLocationPicker` y `CustomMultiDropdown` en vez de widgets crudos?

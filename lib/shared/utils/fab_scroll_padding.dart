/// Utilidad canónica para calcular el padding inferior de vistas desplazables
/// (ListView, SingleChildScrollView, PaginatedListView) que conviven con
/// Floating Action Buttons en D'Una App bajo el estándar nativo de Material Design 3.
///
/// Garantiza una holgura visual confortable (clearance) de 40px entre el contenido y el FAB más alto.
class FabScrollPadding {
  FabScrollPadding._();

  /// Holgura estándar cuando no hay ningún FAB activo en pantalla (24px).
  static const double none = 24.0;

  /// Padding para 1 FAB o Extended FAB (16px base + 56px FAB + 40px clearance = 112px).
  static const double single = 112.0;

  /// Padding calibrado para listas paginadas con indicador de pie de página
  /// (16px base + 56px FAB + 16px holgura texto / 48px tarjeta = 88px).
  static const double list = 88.0;

  /// Padding para 2 FABs apilados verticalmente (16px base + 112px FABs + 16px gap + 40px clearance = 184px).
  static const double doubleFab = 184.0;

  /// Padding para 3 FABs apilados verticalmente (16px base + 168px FABs + 32px gaps + 40px clearance = 256px).
  static const double tripleFab = 256.0;

  /// Calcula dinámicamente el padding inferior requerido a partir del número de FABs activos.
  static double calculate(int activeFabsCount) {
    switch (activeFabsCount) {
      case 3:
        return tripleFab;
      case 2:
        return doubleFab;
      case 1:
        return single;
      default:
        return none;
    }
  }
}

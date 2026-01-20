class Validators {
  static String? required(String? value, {String message = 'Campo requerido'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo requerido';
    }
    // Simple email regex, or use a package like email_validator if available.
    // Using the one from RegisterEmailScreen ref
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Correo inválido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo requerido';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'Falta minúscula';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'Falta mayúscula';
    }
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return 'Falta número';
    }
    if (!RegExp(r'(?=.*[\W_])').hasMatch(value)) {
      return 'Falta símbolo especial';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}

/// Constantes de configuración para los proveedores de autenticación OAuth.
///
/// El [googleWebClientId] es el ID de cliente de tipo "Web application"
/// creado en Google Cloud Console. Se pasa como serverClientId a GoogleSignIn
/// para que Google emita un idToken validable por Supabase.
///
/// NOTA: El Client Secret NO se almacena aquí — vive únicamente en
/// Supabase Dashboard > Authentication > Providers > Google.
class AuthConstants {
  AuthConstants._(); // Prevenir instanciación

  static const String googleWebClientId =
      '822357856005-qmo8rkp1vl7h02mg83si3pnu1luraong.apps.googleusercontent.com';
}

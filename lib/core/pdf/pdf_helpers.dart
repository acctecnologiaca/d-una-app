import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/settings/data/models/shipping_method.dart';
import '../../features/collaborators/domain/models/collaborator.dart';

class PdfSenderInfo {
  final String name;
  final String rif;
  final String address;
  final String? logoUrl;
  final String? phone;
  final String? email;

  PdfSenderInfo({
    required this.name,
    required this.rif,
    required this.address,
    this.logoUrl,
    this.phone,
    this.email,
  });
}

class PdfHelpers {
  /// Carga una imagen desde una URL y la convierte en MemoryImage para PDF
  static Future<pw.MemoryImage?> loadNetworkImage(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(url.trim()))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('Error loading PDF network image ($url): $e');
    }
    return null;
  }

  /// Carga una imagen desde los assets y la convierte en MemoryImage para PDF
  static Future<pw.MemoryImage?> loadAssetImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading PDF asset image: $e');
    }
    return null;
  }

  /// Formatea montos usando el formateador estándar de la app
  static String formatCurrency(double amount) {
    return CurrencyFormatter.format(amount);
  }

  /// Formatea fechas al estilo dd/MM/yyyy
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Resuelve la información del emisor con lógica de fallback si no hay empresa
  static PdfSenderInfo resolvePdfSenderInfo(UserProfile profile, String? userEmail) {
    final isBusiness = profile.isBusinessOwner && 
                       profile.companyName != null && 
                       profile.companyName!.isNotEmpty;

    if (isBusiness) {
      return PdfSenderInfo(
        name: profile.companyName!,
        rif: profile.companyRif ?? profile.nationalId ?? '',
        address: profile.companyAddress ?? profile.mainAddress ?? '',
        logoUrl: profile.companyLogoUrl,
        phone: profile.phone,
        email: userEmail,
      );
    } else {
      // Fallback: Nombre personal
      final fullName = '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
      return PdfSenderInfo(
        name: fullName.isNotEmpty ? fullName : 'Usuario',
        rif: profile.nationalId ?? '',
        address: profile.mainAddress ?? '',
        logoUrl: null, // Sin logo para perfiles personales por defecto
        phone: profile.phone,
        email: userEmail,
      );
    }
  }

  /// Obtiene el ShippingMethod completo con su relación company:shipping_companies(*) desde Supabase
  static Future<ShippingMethod?> fetchShippingMethodById(
    String? shippingMethodId,
  ) async {
    if (shippingMethodId == null || shippingMethodId.trim().isEmpty) return null;
    try {
      final data = await Supabase.instance.client
          .from('shipping_methods')
          .select('*, company:shipping_companies(*)')
          .eq('id', shippingMethodId.trim())
          .maybeSingle();

      if (data != null) {
        return ShippingMethod.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching shipping method by ID ($shippingMethodId): $e');
    }
    return null;
  }

  /// Obtiene el Collaborator completo desde Supabase
  static Future<Collaborator?> fetchCollaboratorById(
    String? collaboratorId,
  ) async {
    if (collaboratorId == null || collaboratorId.trim().isEmpty) return null;
    try {
      final data = await Supabase.instance.client
          .from('collaborators')
          .select()
          .eq('id', collaboratorId.trim())
          .maybeSingle();

      if (data != null) {
        return Collaborator.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching collaborator by ID ($collaboratorId): $e');
    }
    return null;
  }
}

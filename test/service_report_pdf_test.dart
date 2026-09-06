import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:d_una_app/core/pdf/templates/service_report_pdf_template.dart';
import 'package:d_una_app/features/reports/data/models/models.dart';
import 'package:d_una_app/features/profile/domain/models/user_profile.dart';
import 'package:d_una_app/features/profile/domain/models/user_company.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test ServiceReportPdfTemplate with long text and multiple items', () async {
    final report = ServiceReport(
      id: 'test-id-long',
      userId: 'user-123',
      reportNumber: 'RS-2026-0099',
      clientId: 'client-123',
      status: 'draft',
      serviceDate: DateTime.now(),
      subtotal: 550.0,
      taxAmount: 88.0,
      total: 638.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      clientName: 'Corporación Industrial de Venezuela C.A.',
      clientTaxId: 'J-30987654-1',
      contactName: 'Ing. Carlos Mendoza',
      clientPhone: '+58 212 9876543',
      clientEmail: 'cmendoza@corpvzl.com',
      clientAddress: 'Zona Industrial La Yaguara, Galpón 14, Caracas',
      interventionType: 'corrective',
      categoryName: 'Sistemas Hidráulicos y Neumáticos',
      advisorName: 'Téc. Alejandro Morales',
      startTime: '08:30 AM',
      endTime: '04:15 PM',
      durationMinutes: 465,
      requestDescription:
          'El cliente reporta caída constante de presión en la línea principal del compresor de aire #2. Se evidencia fuga de aire audible en el manifold de distribución y sobrecalentamiento intermitente en la unidad de refrigeración auxiliar.',
      workDescription:
          '1. Desmontaje completo de la válvula de retención y limpieza con solvente dieléctrico.\n2. Reemplazo de empaquetaduras y sellos tóricos viton en el colector principal.\n3. Calibración de presostato de corte a 125 PSI y verificación de presiones operativas.\n4. Pruebas de hermeticidad con nitrógeno a 150 PSI sin fugas detectadas durante 30 minutos continuos.\n5. Purga y reemplazo del aceite sintético ISO VG 46 en el cárter del compresor.',
      recommendations:
          '- Realizar inspección preventiva semanal de drenajes de condensado.\n- Reemplazar filtro de admisión de aire en un lapso no mayor a 30 días.\n- Programar el próximo mantenimiento mayor para dentro de 6 meses.',
    );

    final products = List.generate(
      8,
      (i) => ServiceReportItemProduct(
        id: 'prod-$i',
        reportId: 'test-id-long',
        name:
            'Válvula de bola en acero inox 1/2" NPT Grado Industrial Modelo V-$i',
        brand: 'Parker Hannifin',
        model: 'PV-100$i',
        uom: 'Ud',
        quantity: 2.0,
        costPrice: 15.0,
        profitMargin: 40.0,
        unitPrice: 25.0,
        taxRate: 16.0,
        taxAmount: 8.0,
        totalPrice: 50.0,
        warrantyTime: 6,
        warrantyUnit: 'months',
      ),
    );

    final services = List.generate(
      4,
      (i) => ServiceReportItemService(
        id: 'serv-$i',
        reportId: 'test-id-long',
        name:
            'Mano de obra especializada en ajuste de presostato y pruebas de carga etapa $i',
        rateSymbol: 'Horas',
        quantity: 3.0,
        costPrice: 15.0,
        profitMargin: 50.0,
        unitPrice: 30.0,
        taxRate: 16.0,
        taxAmount: 14.4,
        totalPrice: 90.0,
        warrantyTime: 30,
        warrantyUnit: 'days',
      ),
    );

    final conditions = [
      ServiceReportCondition(
        id: 'cond-1',
        reportId: 'test-id-long',
        description:
            'La garantía cubre defectos de mano de obra y piezas reemplazadas durante 30 días continuos.',
        orderIndex: 0,
      ),
      ServiceReportCondition(
        id: 'cond-2',
        reportId: 'test-id-long',
        description:
            'No cubre fallas ocasionadas por fluctuaciones eléctricas extremas o manipulación no autorizada.',
        orderIndex: 1,
      ),
    ];

    final profile = UserProfile(
      id: 'user-123',
      firstName: 'Juan',
      lastName: 'Pérez',
      isBusinessOwner: true,
      company: UserCompany(
        id: 'comp-123',
        userId: 'user-123',
        companyName: 'Servicios de Ingeniería Integral C.A.',
        companyRif: 'J-12345678-9',
        companyAddress: 'Av Principal, Local 1',
      ),
      phone: '+58 412 1234567',
    );

    final template = ServiceReportPdfTemplate(
      report: report,
      products: products,
      services: services,
      conditions: conditions,
      userProfile: profile,
      userEmail: 'juan@test.com',
    );

    final bytes = await template.generate(PdfPageFormat.letter);
    expect(bytes, isNotEmpty);
  });
}

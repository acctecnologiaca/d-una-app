import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/email_template.dart';
import '../../data/repositories/email_templates_repository.dart';

part 'email_templates_provider.g.dart';

@riverpod
EmailTemplatesRepository emailTemplatesRepository(EmailTemplatesRepositoryRef ref) {
  return EmailTemplatesRepository(Supabase.instance.client);
}

@riverpod
class EmailTemplatesList extends _$EmailTemplatesList {
  @override
  Future<List<EmailTemplate>> build() async {
    final repository = ref.watch(emailTemplatesRepositoryProvider);
    return repository.getEmailTemplates();
  }

  Future<void> saveTemplate(EmailTemplate template) async {
    final repository = ref.read(emailTemplatesRepositoryProvider);
    await repository.saveEmailTemplate(template);
    ref.invalidateSelf();
  }
}

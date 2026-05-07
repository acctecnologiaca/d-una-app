// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_templates_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$emailTemplatesRepositoryHash() =>
    r'2af24731d82c7449f4f9bbc91a3e7b812a226a45';

/// See also [emailTemplatesRepository].
@ProviderFor(emailTemplatesRepository)
final emailTemplatesRepositoryProvider =
    AutoDisposeProvider<EmailTemplatesRepository>.internal(
      emailTemplatesRepository,
      name: r'emailTemplatesRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$emailTemplatesRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EmailTemplatesRepositoryRef =
    AutoDisposeProviderRef<EmailTemplatesRepository>;
String _$emailTemplatesListHash() =>
    r'60e2c57c420536b4263697a811fa6302360e61e0';

/// See also [EmailTemplatesList].
@ProviderFor(EmailTemplatesList)
final emailTemplatesListProvider =
    AutoDisposeAsyncNotifierProvider<
      EmailTemplatesList,
      List<EmailTemplate>
    >.internal(
      EmailTemplatesList.new,
      name: r'emailTemplatesListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$emailTemplatesListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EmailTemplatesList = AutoDisposeAsyncNotifier<List<EmailTemplate>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

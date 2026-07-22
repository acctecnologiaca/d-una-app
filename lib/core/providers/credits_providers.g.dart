// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credits_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$creditsRepositoryHash() => r'a6a229c49334c2f66eb31b49804fa1484715521e';

/// See also [creditsRepository].
@ProviderFor(creditsRepository)
final creditsRepositoryProvider =
    AutoDisposeProvider<CreditsRepository>.internal(
      creditsRepository,
      name: r'creditsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$creditsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CreditsRepositoryRef = AutoDisposeProviderRef<CreditsRepository>;
String _$userCreditsStatusHash() => r'1c3c79641a0c455ca02be7fa47a4319834aa63e6';

/// See also [UserCreditsStatus].
@ProviderFor(UserCreditsStatus)
final userCreditsStatusProvider =
    AutoDisposeAsyncNotifierProvider<UserCreditsStatus, CreditStatus>.internal(
      UserCreditsStatus.new,
      name: r'userCreditsStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userCreditsStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserCreditsStatus = AutoDisposeAsyncNotifier<CreditStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

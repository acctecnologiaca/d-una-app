// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'occupations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$occupationsRepositoryHash() =>
    r'e16939c7eae5989a4dd167f47f3e4e40229a7897';

/// See also [occupationsRepository].
@ProviderFor(occupationsRepository)
final occupationsRepositoryProvider =
    AutoDisposeProvider<OccupationsRepository>.internal(
      occupationsRepository,
      name: r'occupationsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$occupationsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OccupationsRepositoryRef =
    AutoDisposeProviderRef<OccupationsRepository>;
String _$occupationsHash() => r'130f07542af5e354c76160ca2578433b18c38fe8';

/// See also [occupations].
@ProviderFor(occupations)
final occupationsProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      occupations,
      name: r'occupationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$occupationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OccupationsRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$occupationNameHash() => r'49797d23ff051f722a67c9e2071b667be4d258cb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [occupationName].
@ProviderFor(occupationName)
const occupationNameProvider = OccupationNameFamily();

/// See also [occupationName].
class OccupationNameFamily extends Family<String?> {
  /// See also [occupationName].
  const OccupationNameFamily();

  /// See also [occupationName].
  OccupationNameProvider call(String? id) {
    return OccupationNameProvider(id);
  }

  @override
  OccupationNameProvider getProviderOverride(
    covariant OccupationNameProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'occupationNameProvider';
}

/// See also [occupationName].
class OccupationNameProvider extends AutoDisposeProvider<String?> {
  /// See also [occupationName].
  OccupationNameProvider(String? id)
    : this._internal(
        (ref) => occupationName(ref as OccupationNameRef, id),
        from: occupationNameProvider,
        name: r'occupationNameProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$occupationNameHash,
        dependencies: OccupationNameFamily._dependencies,
        allTransitiveDependencies:
            OccupationNameFamily._allTransitiveDependencies,
        id: id,
      );

  OccupationNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String? id;

  @override
  Override overrideWith(String? Function(OccupationNameRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: OccupationNameProvider._internal(
        (ref) => create(ref as OccupationNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String?> createElement() {
    return _OccupationNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OccupationNameProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OccupationNameRef on AutoDisposeProviderRef<String?> {
  /// The parameter `id` of this provider.
  String? get id;
}

class _OccupationNameProviderElement extends AutoDisposeProviderElement<String?>
    with OccupationNameRef {
  _OccupationNameProviderElement(super.provider);

  @override
  String? get id => (origin as OccupationNameProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

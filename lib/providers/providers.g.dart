// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gCsHash() => r'44677d75ed08dea3c5c042daa8dd363c2ef7b641';

/// See also [GCs].
@ProviderFor(GCs)
final gCsProvider = FutureProvider<List<Map<String, dynamic>>>.internal(
  GCs,
  name: r'gCsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$gCsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GCsRef = FutureProviderRef<List<Map<String, dynamic>>>;
String _$iPsHash() => r'73cdf5d6e3f15cfb415688208988aeb7f555eec8';

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

/// See also [IPs].
@ProviderFor(IPs)
const iPsProvider = IPsFamily();

/// See also [IPs].
class IPsFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [IPs].
  const IPsFamily();

  /// See also [IPs].
  IPsProvider call(
    bool containWC,
  ) {
    return IPsProvider(
      containWC,
    );
  }

  @override
  IPsProvider getProviderOverride(
    covariant IPsProvider provider,
  ) {
    return call(
      provider.containWC,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'iPsProvider';
}

/// See also [IPs].
class IPsProvider extends FutureProvider<List<Map<String, dynamic>>> {
  /// See also [IPs].
  IPsProvider(
    bool containWC,
  ) : this._internal(
          (ref) => IPs(
            ref as IPsRef,
            containWC,
          ),
          from: iPsProvider,
          name: r'iPsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product') ? null : _$iPsHash,
          dependencies: IPsFamily._dependencies,
          allTransitiveDependencies: IPsFamily._allTransitiveDependencies,
          containWC: containWC,
        );

  IPsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.containWC,
  }) : super.internal();

  final bool containWC;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(IPsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IPsProvider._internal(
        (ref) => create(ref as IPsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        containWC: containWC,
      ),
    );
  }

  @override
  FutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _IPsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IPsProvider && other.containWC == containWC;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, containWC.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin IPsRef on FutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `containWC` of this provider.
  bool get containWC;
}

class _IPsProviderElement
    extends FutureProviderElement<List<Map<String, dynamic>>> with IPsRef {
  _IPsProviderElement(super.provider);

  @override
  bool get containWC => (origin as IPsProvider).containWC;
}

String _$middleMenHash() => r'99e31726d44baa7a804f4a6f87e5c8a14a25edbd';

/// See also [middleMen].
@ProviderFor(middleMen)
const middleMenProvider = MiddleMenFamily();

/// See also [middleMen].
class MiddleMenFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [middleMen].
  const MiddleMenFamily();

  /// See also [middleMen].
  MiddleMenProvider call(
    bool containWC,
  ) {
    return MiddleMenProvider(
      containWC,
    );
  }

  @override
  MiddleMenProvider getProviderOverride(
    covariant MiddleMenProvider provider,
  ) {
    return call(
      provider.containWC,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'middleMenProvider';
}

/// See also [middleMen].
class MiddleMenProvider extends FutureProvider<List<Map<String, dynamic>>> {
  /// See also [middleMen].
  MiddleMenProvider(
    bool containWC,
  ) : this._internal(
          (ref) => middleMen(
            ref as MiddleMenRef,
            containWC,
          ),
          from: middleMenProvider,
          name: r'middleMenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$middleMenHash,
          dependencies: MiddleMenFamily._dependencies,
          allTransitiveDependencies: MiddleMenFamily._allTransitiveDependencies,
          containWC: containWC,
        );

  MiddleMenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.containWC,
  }) : super.internal();

  final bool containWC;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(MiddleMenRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MiddleMenProvider._internal(
        (ref) => create(ref as MiddleMenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        containWC: containWC,
      ),
    );
  }

  @override
  FutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _MiddleMenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MiddleMenProvider && other.containWC == containWC;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, containWC.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MiddleMenRef on FutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `containWC` of this provider.
  bool get containWC;
}

class _MiddleMenProviderElement
    extends FutureProviderElement<List<Map<String, dynamic>>>
    with MiddleMenRef {
  _MiddleMenProviderElement(super.provider);

  @override
  bool get containWC => (origin as MiddleMenProvider).containWC;
}

String _$wcGroupsHash() => r'd9efc6afb87e37fcf9f8cc092e583bc99e40da04';

/// See also [wcGroups].
@ProviderFor(wcGroups)
final wcGroupsProvider = FutureProvider<List<Map<String, dynamic>>>.internal(
  wcGroups,
  name: r'wcGroupsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$wcGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WcGroupsRef = FutureProviderRef<List<Map<String, dynamic>>>;
String _$authHash() => r'4b33f72b29b1f56bc203d5004d03f4e87ef3ff17';

/// See also [auth].
@ProviderFor(auth)
final authProvider = StreamProvider<bool>.internal(
  auth,
  name: r'authProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthRef = StreamProviderRef<bool>;
String _$disburseDataHash() => r'6faf173eeb9d59233d285b0fc886ca173612f015';

/// See also [disburseData].
@ProviderFor(disburseData)
final disburseDataProvider =
    AutoDisposeStreamProvider<QuerySnapshot<Map<String, dynamic>>>.internal(
  disburseData,
  name: r'disburseDataProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$disburseDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DisburseDataRef
    = AutoDisposeStreamProviderRef<QuerySnapshot<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

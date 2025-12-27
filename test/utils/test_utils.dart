import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a [ProviderContainer] and automatically disposes it at the end of the test.
ProviderContainer createContainer({
  ProviderContainer? parent,
  List<dynamic> overrides = const [],
  List<ProviderObserver>? observers,
}) {
  final container = ProviderContainer(
    parent: parent,
    overrides: [
      ...overrides,
    ],
    observers: observers,
  );

  addTearDown(container.dispose);

  return container;
}

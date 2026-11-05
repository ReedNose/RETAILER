import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retail_preorder_app/data/mock/mock_retail_repository.dart';
import 'package:retail_preorder_app/state/retail_providers.dart';

/// A provider container that always runs on the in-memory demo repository,
/// so tests never touch the network whatever backend_url says.
ProviderContainer demo_container() => ProviderContainer(
      overrides: [
        retail_repository_provider.overrideWithValue(MockRetailRepository()),
      ],
    );

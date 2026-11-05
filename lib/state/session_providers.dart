import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';

/// null means nobody is logged in.
final current_user_provider = StateProvider<AppUser?>((ref) => null);

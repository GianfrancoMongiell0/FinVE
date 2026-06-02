import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global toggle: true = balances visible, false = ocultos
final balanceVisibleProvider = StateProvider<bool>((ref) => true);

import 'package:flutter/foundation.dart';

class MemoryCardController extends ChangeNotifier {
  VoidCallback? _onSkip;
  VoidCallback? _onFavourite;

  void register({
    required VoidCallback onSkip,
    required VoidCallback onFavourite,
  }) {
    _onSkip = onSkip;
    _onFavourite = onFavourite;
  }

  void skip() => _onSkip?.call();
  void favourite() => _onFavourite?.call();

  @override
  void dispose() {
    _onSkip = null;
    _onFavourite = null;
    super.dispose();
  }
}

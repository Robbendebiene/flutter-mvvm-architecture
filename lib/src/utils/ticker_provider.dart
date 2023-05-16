import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide View;
import 'package:flutter/scheduler.dart';

import '/src/base/view.dart';


/// Mixin that allows the view model to act as a [TickerProvider].
///
/// This is basically a copy of [TickerProviderStateMixin] hence it is used in the same way.
///
/// Example usage:
/// ```dart
/// class MyViewModel extends ViewModel with TickerProvider {
///   late final AnimationController _myAnimationController;
///
///   void init() async {
///     _myAnimationController = AnimationController(
///       vsync: this, // the TickerProvider,
///       duration: const Duration(seconds: 1),
///     );
///   }
/// }
/// ```

mixin MakeTickerProvider on ViewModel implements TickerProvider {

  // The below code is mostly a copy of the TickerProviderStateMixin
  // https://github.com/flutter/flutter/blob/4d9e56e694/packages/flutter/lib/src/widgets/ticker_provider.dart#L287-L397

  Set<Ticker>? _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    if (_tickerModeNotifier == null) {
      // Setup TickerMode notifier before we vend the first ticker.
      _updateTickerModeNotifier();
    }
    assert(_tickerModeNotifier != null);
    _tickers ??= <_DisposingTicker>{};
    final _DisposingTicker result = _DisposingTicker(onTick, this, debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null)
      ..muted = !_tickerModeNotifier!.value;
    _tickers!.add(result);
    return result;
  }

  void _removeTicker(_DisposingTicker ticker) {
    assert(_tickers != null);
    assert(_tickers!.contains(ticker));
    _tickers!.remove(ticker);
  }

  ValueNotifier<bool>? _tickerModeNotifier;

  @override
  void activate() {
    super.activate();
    // We may have a new TickerMode ancestor, get its Notifier.
    _updateTickerModeNotifier();
    _updateTickers();
  }

  void _updateTickers() {
    if (_tickers != null) {
      final bool muted = !_tickerModeNotifier!.value;
      for (final Ticker ticker in _tickers!) {
        ticker.muted = muted;
      }
    }
  }

  void _updateTickerModeNotifier() {
    final ValueNotifier<bool> newNotifier = TickerMode.getNotifier(context);
    if (newNotifier == _tickerModeNotifier) {
      return;
    }
    _tickerModeNotifier?.removeListener(_updateTickers);
    newNotifier.addListener(_updateTickers);
    _tickerModeNotifier = newNotifier;
  }

  @override
  void dispose() {
    assert(() {
      if (_tickers != null) {
        for (final Ticker ticker in _tickers!) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was disposed with an active Ticker.'),
              ErrorDescription(
                '$runtimeType created a Ticker via its MakeTickerProvider, but at the time '
                'dispose() was called on the mixin, that Ticker was still active. All Tickers must '
                'be disposed before calling super.dispose().',
              ),
              ErrorHint(
                'Tickers used by AnimationControllers '
                'should be disposed by calling dispose() on the AnimationController itself. '
                'Otherwise, the ticker will leak.',
              ),
              ticker.describeForError('The offending ticker was'),
            ]);
          }
        }
      }
      return true;
    }());
    _tickerModeNotifier?.removeListener(_updateTickers);
    _tickerModeNotifier = null;
    super.dispose();
  }
}

class _DisposingTicker extends Ticker {
  _DisposingTicker(super.onTick, this._creator, { super.debugLabel });

  final MakeTickerProvider _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}

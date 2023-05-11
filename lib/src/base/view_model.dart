part of 'view.dart';


abstract class ViewModel {
  T getService<T extends Service>() => GetIt.I<T>();

  /// The location in the tree of the corresponding widget.
  ///
  /// The [ViewModel] receives its [BuildContext] after creating them with
  /// [View.create] and before calling [init]. The association is permanent:
  /// the [State] object will never change its [BuildContext]. However,
  /// the [BuildContext] itself can be moved around the tree.

  BuildContext get context {
    assert(() {
      if (_element == null) {
        throw FlutterError(
          'This widget has been unmounted, so the State no longer has a context (and should be considered defunct). \n'
          'Consider canceling any active work during "dispose" or using the "mounted" getter to determine if the State is still active.',
        );
      }
      return true;
    }());
    return _element!;
  }
  ViewElement? _element;

  /// Whether the corresponding widget is currently in a tree.

  bool get mounted => _element != null;

  /// Called when this object is inserted into the tree.
  ///
  /// This is the first time the [BuildContext] is available.

  @protected
  @mustCallSuper
  void init() {}

  @protected
  @mustCallSuper
  void activate() {}

  @protected
  @mustCallSuper
  void deactivate() {}

  @protected
  @mustCallSuper
  void dispose() {
    _element = null;
  }
}

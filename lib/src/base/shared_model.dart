import 'package:flutter/widgets.dart';

/// SharedModel is used to provide data to a sub-tree. It can only be accessed by descendent Views in the `create((locate) => ...)` callback using the `locate` function.
///
/// Since it is part of the tree the data is automatically scoped.
/// If you need to globally provide a model inject it at the root of your app's widget tree.
///
/// Only use SharedModel when necessary. Prefer storing state in ViewModels and pass data via properties (prop drilling) if applicable.
/// An example where you might wanna use SharedModel is a shopping cart state that is required in views scattered across your app.
///
/// **Note:** If your shared model construction depends on changing state it will not be updated/recreated automatically.
/// In order to do this you have to pass a `Key` e.g. a `ValueKey` wrapping your model `ValueKey(myModel)`.
///
/// Example with dispose function:
/// ```dart
/// class MyModel {
///   dispose() {}
/// }
///
/// SharedModel(
///   create: MyModel.new,
///   dispose: (MyModel model) => model.dispose(),
///   child: Container(
///     ...
///   ),
/// ),
/// ```

class SharedModel<T> extends ProxyWidget {
  final T Function() create;
  final void Function(T state)? dispose;

  const SharedModel({
    required this.create,
    required super.child,
    this.dispose,
    super.key,
  });

  @override
  SharedModelElement<T> createElement() => SharedModelElement<T>(this);
}

class SharedModelElement<T> extends ComponentElement {
  final T _state;
  SharedModelElement(SharedModel<T> widget) :
    _state = widget.create(),
    super(widget);

  @override
  Widget build() {
    return _SharedModelProvider(
      state: _state,
      child: (widget as SharedModel<T>).child,
    );
  }

  @override
  void unmount() {
    (widget as SharedModel<T>).dispose?.call(_state);
    super.unmount();
  }
}

class _SharedModelProvider<T> extends InheritedWidget {
  final T state;

  const _SharedModelProvider({
    required this.state,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(_SharedModelProvider<T> oldWidget) {
    // this should always return false as the state object is never replaced
    assert(state == oldWidget.state);
    return false;
  }
}

/// Callback used to retrieve SharedModels.
/// ```dart
/// final myModel = locate<SharedModelType>();
/// ```

// used to hide context from View Model
// usually one would use dependOnInheritedWidgetOfExactType to rebuild this widget on dependency changes
// also dependOnInheritedWidgetOfExactType should not be called on mount/initState because it will never be re-called
// but since SharedModels never change this is a safe contract
class Locate {
  final BuildContext _context;
  Locate(this._context);

  X call<X extends Object>() {
    final result = _context.getInheritedWidgetOfExactType<_SharedModelProvider<X>>();
    assert(result != null, 'Cannot find "$X" in the current context.');
    return result!.state;
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action, View;
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_mvvm_architecture/base.dart';
import 'package:mobx/mobx.dart';

import 'shared_model.dart';

part 'view_model.dart';
part 'view_fragment.dart';
part 'request.dart';

/// Callback used to register a disposer for disposal.
typedef RegisterDispose = void Function(VoidCallback disposer);

/// ATTENTION: It is important that you explicitly specify the view model type in the class definition like in the example below.
/// ```dart
/// class SecondView extends View<SecondViewModel> {
///   SecondView({
///     super.key
///   }) : super(create: (_) => SecondViewModel());
///
///   @override
///   Widget build(context, viewModel) {}
/// }
/// ```
/// If the ViewModel depends on `SharedModel`s then get them in the View's `create` method and pass them via constructor.
/// ```dart
/// class FirstView extends View<FirstViewModel> {
///   FirstView({
///     super.key
///   }) : super(create: (require) => FirstViewModel(
///       require<AModel>(),
///       require<BModel>(),
///   ));
///
///   @override
///   Widget build(context, viewModel) {}
/// }
/// ```
abstract class View<T extends ViewModel> extends Widget {
  /// Callback used to create and bind the view model for this view.
  ///
  /// Use the `Require` callback to retrieve any `SharedModel`s.
  /// ```dart
  /// final myModel = require<SharedModelType>();
  /// ```

  // This could have been a class function that must be implemented by the users
  // like: T create(RequireCallback require);
  // Having this in the constructor is only beneficial when parameters are passed to the view models construction.
  // Having it in the constructor allows to directly pass them to the view model without first exposing them as a final variable on the view.
  // Having model variables on the view is discouraged and users could be tempted to use them instead of the view model.
  final T Function(Require require) create;

  const View({
    required this.create,
    super.key,
  });

  Widget build(BuildContext context, T viewModel);

  /// Override this to add any sort of reactions based on the current view model.
  ///
  /// This function will be called once when the widget is mounted.
  /// It is called after the view model's creation and before the first build.
  ///
  /// Any sort of dispose functions like [ReactionDisposer] can be auto disposed by passing it to `disposeWithWidget`.
  ///
  /// Implementers of this function must call super at the beginning passing the original parameters.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void react(context, vm, disposeWithWidget) {
  ///   super.react(context, vm, disposeWithWidget);
  ///   disposeWithWidget(reaction(
  ///     (_) => vm.myProperty,
  ///     (v) => print('Do something with $v'),
  ///   ));
  /// }
  /// ```

  @mustCallSuper
  void react(BuildContext context, T vm, RegisterDispose disposeWithWidget) {
    final sub = vm._requests.stream.listen((request) {
      if (context.mounted) requestHandler(context, vm, request);
    });
    disposeWithWidget(sub.cancel);
  }

  /// Override this to handle custom `request(MyCustomRequest)` calls from the View Model.
  ///
  /// This is typically implemented in a separate Mixin that can be mixed in the View.
  ///
  /// Example override:
  /// ```dart
  /// void requestHandler(BuildContext context, T vm, Request request) {
  ///   super.requestHandler(context, vm, request);
  ///   if (request is MyCustomRequest) {
  ///     /* do something */
  ///     request.respond(/* custom response */);
  ///   }
  /// }
  /// ```
  /// Implementers of this function must call super at the beginning passing the original parameters.

  @mustCallSuper
  void requestHandler(BuildContext context, T vm, Request request) {}

  @override
  @protected
  Element createElement() => ViewElement(this);
}


class ViewElement<T extends ViewModel> extends Element {
  late final T _viewModel;

  final List<VoidCallback> _disposers = [];

  ViewElement(super.widget);

  Widget build() {
    return Observer(
      builder: (context) => (widget as View<T>).build(context, _viewModel),
      name: '$widget',
      warnWhenNoObservables: false,
    );
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    assert(_child == null);
    // create view model and setup reactions
    final view = widget as View<T>;
    _viewModel = view.create(Require(this));
    view.react(this, _viewModel, _disposers.add);
    // trigger first build
    rebuild();
    assert(_child != null);
  }

  @override
  void update(View<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
  }

  @override
  void activate() {
    // How to handle when views/view models is moved in the tree?
    // We could pass the require method again to give view models a chance to
    // revaluate their dependencies.
    // It was decided against doing so as a view model should be pure, meaning
    // it does not care about its context or place in the tree
    super.activate();
    _viewModel.activate();
    markNeedsBuild();
  }

  @override
  void deactivate() {
    _viewModel.deactivate();
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    for (var disposer in _disposers) {
      disposer();
    }
    _viewModel.dispose();
  }


  // Code copied from ComponentElement \\

  Element? _child;

  bool _debugDoingBuild = false;
  @override
  bool get debugDoingBuild => _debugDoingBuild;

  @override
  Element? get renderObjectAttachingChild => _child;

  @override
  @pragma('vm:notify-debugger-on-exception')
  void performRebuild() {
    Widget? built;
    try {
      assert(() {
        _debugDoingBuild = true;
        return true;
      }());
      built = build();
      assert(() {
        _debugDoingBuild = false;
        return true;
      }());
      debugWidgetBuilderValue(widget, built);
    } catch (e, stack) {
      _debugDoingBuild = false;
      built = ErrorWidget.builder(
        _reportException(
          ErrorDescription('building $this'),
          e,
          stack,
          informationCollector: () => <DiagnosticsNode>[
            if (kDebugMode)
              DiagnosticsDebugCreator(DebugCreator(this)),
          ],
        ),
      );
    } finally {
      super.performRebuild();
    }
    try {
      _child = updateChild(_child, built, slot);
      assert(_child != null);
    } catch (e, stack) {
      built = ErrorWidget.builder(
        _reportException(
          ErrorDescription('building $this'),
          e,
          stack,
          informationCollector: () => <DiagnosticsNode>[
            if (kDebugMode)
              DiagnosticsDebugCreator(DebugCreator(this)),
          ],
        ),
      );
      _child = updateChild(null, built, slot);
    }
  }

  FlutterErrorDetails _reportException(
    DiagnosticsNode context,
    Object exception,
    StackTrace? stack, {
    InformationCollector? informationCollector,
  }) {
    final FlutterErrorDetails details = FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'widgets library',
      context: context,
      informationCollector: informationCollector,
    );
    FlutterError.reportError(details);
    return details;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
    super.forgetChild(child);
  }
}

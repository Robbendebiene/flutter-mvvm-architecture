import 'package:flutter/material.dart' hide Action, View;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import 'service.dart';

part 'view_model.dart';

/// Callback used to register a reaction disposer for disposal.
typedef RegisterDispose = void Function(ReactionDisposer disposer);

/// ATTENTION: It is important that you explicitly specify the view model type in the class definition like in the example below.
/// ```
/// class ExampleView extends View<ExampleViewModel> {
///   const ExampleView({
///     super.key
///   }) : super(create: ExampleViewModel.new);
///   ...
/// }
/// ```
/// Otherwise the view model cannot be found by any [ViewFragment]s.

abstract class View<T extends ViewModel> extends Widget {
  final T Function() create;

  const View({
    required this.create,
    super.key,
  });

  Widget build(BuildContext context, T viewModel);

  /// Override this to add any sort of reactions based on the current view model.
  ///
  /// This will be called once by the widget on `initState`.
  ///
  /// The [ReactionDisposer] of any created reaction can be auto disposed by passing it to `disposeWithWidget`.

  @mustCallSuper
  void hookReactions(BuildContext context, T vm, RegisterDispose disposeWithWidget) {}

  @override
  Element createElement() => ViewElement(this);
}

class ViewElement<T extends ViewModel> extends ComponentElement {
  final T _viewModel;

  final List<ReactionDisposer> _reactionDisposers = [];

  ViewElement(View<T> widget) :
    _viewModel = widget.create(),
    super(widget) {
      _viewModel._element = this;
      widget.hookReactions(this, _viewModel, _reactionDisposers.add);
    }

  @override
  Widget build() {
    return ViewModelProvider<T>(
      viewModel: _viewModel,
      child: Observer(
        builder: (context) => (widget as View<T>).build(context, _viewModel),
        name: '$widget',
        warnWhenNoObservables: false,
      ),
    );
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _viewModel.init();
  }

  @override
  void update(View<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
  }

  @override
  void activate() {
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
    for (var disposer in _reactionDisposers) {
      disposer();
    }
    _viewModel.dispose();
  }
}


/// A widget that depends on a view model but doesn't provide one.
///
/// Make sure that the [ViewFragment] is below the [View] with the dependent [ViewModel] in the tree.
///
/// Specify the dependant view model like this:
/// ```
/// class ExampleViewFragment extends ViewFragment<ExampleViewModel> {
///   ...
/// }
/// ```

abstract class ViewFragment<T extends ViewModel> extends Widget {
  const ViewFragment({super.key});

  Widget build(BuildContext context, T viewModel);

  @override
  Element createElement() => ViewFragmentElement(this);
}

class ViewFragmentElement<T extends ViewModel> extends ComponentElement {
  ViewFragmentElement(ViewFragment<T> widget) : super(widget);

  @override
  Widget build() {
    return Observer(
      builder: (context) => (widget as ViewFragment<T>).build(context, _viewModel),
      name: '$widget',
    );
  }

  @override
  void update(ViewFragment<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
  }

  /// Get a view model of the given type that was declared above in the tree.

  T get _viewModel {
    final result = dependOnInheritedWidgetOfExactType<ViewModelProvider<T>>();
    assert(result != null, 'The ViewFragment "$widget" cannot find "$T" in the current context.');
    return result!.viewModel;
  }
}


/// Inherited widget to provide the view model to descendent widgets.

class ViewModelProvider<VM extends ViewModel> extends InheritedWidget {
  final VM viewModel;

  const ViewModelProvider({
    required this.viewModel,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(ViewModelProvider oldWidget) {
    return viewModel != oldWidget.viewModel;
  }
}

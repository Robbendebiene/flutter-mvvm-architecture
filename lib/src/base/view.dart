import 'package:flutter/material.dart' hide Action;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import 'view_model.dart';

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
  /// For every created reaction a respective [ReactionDisposer] must be `yield` so it can be disposed correctly.
  ///
  /// **Note:** You must `yield*` the `super` call, otherwise other mixed in reactions will be lost.

  @mustCallSuper
  Iterable<ReactionDisposer> hookReactions(BuildContext context, T vm) sync* {}

  @override
  Element createElement() => _ViewElement(this);
}

class _ViewElement<T extends ViewModel> extends ComponentElement {
  final T _viewModel;

  late final List<ReactionDisposer> _reactionDisposers;

  _ViewElement(View<T> widget) :
    _viewModel = widget.create(),
    super(widget) {
      _reactionDisposers = widget.hookReactions(this, _viewModel).toList(growable: false);
    }

  @override
  Widget build() {
    return _ViewModelProvider<T>(
      viewModel: _viewModel,
      child: Observer(
        builder: (context) => (widget as View<T>).build(context, _viewModel),
        name: '$widget',
        warnWhenNoObservables: false,
      ),
    );
  }

  @override
  void update(View<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
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
  Element createElement() => _ViewFragmentElement(this);
}

class _ViewFragmentElement<T extends ViewModel> extends ComponentElement {
  _ViewFragmentElement(ViewFragment<T> widget) : super(widget);

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
    final result = dependOnInheritedWidgetOfExactType<_ViewModelProvider<T>>();
    assert(result != null, 'The ViewFragment "$widget" cannot find "$T" in the current context.');
    return result!.viewModel;
  }
}


/// Inherited widget to provide the view model to descendent widgets.

class _ViewModelProvider<VM extends ViewModel> extends InheritedWidget {
  final VM viewModel;

  const _ViewModelProvider({
    required this.viewModel,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(_ViewModelProvider oldWidget) {
    return viewModel != oldWidget.viewModel;
  }
}

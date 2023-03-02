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
/// Otherwise the view model cannot be found via its type using the `dependOnInheritedWidgetOfExactType` method.

abstract class View<T extends ViewModel> extends StatefulWidget with _GetViewModel {
  final T Function() create;

  const View({
    required this.create,
    super.key,
  });

  Widget build(BuildContext context);

  /// Override this to add any sort of reactions based on the current view model.
  ///
  /// This will be called once by the widget on `initState`.
  ///
  /// For every created reaction a respective [ReactionDisposer] must be `yield` so it can be disposed correctly.
  ///
  /// **Note:** You must `yield*` the `super` call, otherwise other reaction disposers will be lost wherefore the reactions won't be disposed correctly.

  @mustCallSuper
  Iterable<ReactionDisposer> hookReactions(BuildContext context, covariant ViewModel vm) sync* {}

  @override
  State<View<T>> createState() => _ViewState<T>();
}

class _ViewState<T extends ViewModel> extends State<View<T>> {
  late final T _viewModel;

  late final List<ReactionDisposer> _reactionDisposers;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.create();
    // TODO: Maybe use addPostFrameCallback if the context in the reactions is immeditely used.
    _reactionDisposers = widget.hookReactions(context, _viewModel).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => _ViewModelProvider<T>(
    viewModel: _viewModel,
    // builder is important here to get the context below the inherited widget (_ViewModelProvider)
    child: Observer(
      builder: widget.build,
    ),
  );

  @override
  void dispose() {
    for (var disposer in _reactionDisposers) {
      disposer();
    }
    _viewModel.dispose();
    super.dispose();
  }
}


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

/// Any widget that depends on a view model but doesn't provide one.

abstract class ViewFragment extends StatelessObserverWidget with _GetViewModel {
  const ViewFragment({super.key});
}



mixin _GetViewModel {

  /// Get a view model of the given type that was declared above in the tree.

  VM $<VM extends ViewModel>(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_ViewModelProvider<VM>>();
    assert(result != null, 'No $VM found in context');
    return result!.viewModel;
  }
}
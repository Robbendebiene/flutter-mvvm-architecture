import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_mobx/flutter_mobx.dart';

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

  @override
  State<View<T>> createState() => _ViewState<T>();
}

class _ViewState<T extends ViewModel> extends State<View<T>> {
  late final T _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.create();
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
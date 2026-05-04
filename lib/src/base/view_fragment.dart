part of 'view.dart';

/// A view that depends on a foreign view model and doesn't create its own.
/// The view model has to be passed as a property.
///
/// Prefer creating smaller independent components and pass the state down via properties (prop drilling).
/// Only use a ViewFragment if your view becomes too large and you want to split it into smaller chunks where prop drilling would cause a lot of overhead.
///
/// Specify the dependant view model like this:
/// ```
/// class ExampleViewFragment extends ViewFragment<ExampleViewModel> {
///   ExampleViewFragment(super.viewModel, {super.key});
///   ...
/// }
/// ```

abstract class ViewFragment<T extends ViewModel> extends Widget {
  final T _viewModel;
  const ViewFragment(this._viewModel, { super.key });

  Widget build(BuildContext context, T viewModel);

  @override
  Element createElement() => ViewFragmentElement<T>(this);
}

class ViewFragmentElement<T extends ViewModel> extends ComponentElement {
  ViewFragmentElement(ViewFragment<T> super.widget);

  @override
  Widget build() {
    return Observer(
      builder: (context) {
        final viewFragmentWidget = (widget as ViewFragment<T>);
        return viewFragmentWidget.build(context, viewFragmentWidget._viewModel);
      },
      name: '$widget',
    );
  }

  @override
  void update(ViewFragment<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
  }
}

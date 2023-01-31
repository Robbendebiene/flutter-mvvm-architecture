# Views

This architecture splits Views into 3 main components: Views, View Fragments and classic Widgets. While Views and View Fragments are technically Widgets themselves, they are treated differently here because they provide the connection to the underlying View Models.
All of these components can be freely arranged or nested.

## View

A View encompasses a set of connected screen components. It's main goal is to provide exactly one View Model to it's children. The View Model can be accessed via the View's `BuildContext` using the `$` locator function like so: `$<MyViewModel>(context);`
Any Observables (typically provided by a View Model) used inside the build method will automatically rebuild the View.

**Example:**

```dart
class MainView extends View<MainViewModel> {
  const MainView({
    super.key
  }) : super(create: MainViewModel.new);

  @override
  Widget build(BuildContext context) {
    // Access the view model
    final vm = $<MainViewModel>(context);
    ...
  }
}
```

## View Fragment

View Fragments are a simplified version of Views. They do not provide any View Model themselves, but can use `$` locator function to access any View Models above them. The main use of View Fragment's is to split up large Views into smaller components/fragments. Like Views they will automatically rebuild on any changes to Observables used inside their build method.

**Example:**

```dart
class MyViewSection extends ViewFragment {
  @override
  Widget build(BuildContext context) {
    // Access the view model
    final vm = $<ViewModelB>(context);
    ...
  }
}
```

## Widgets

This can be any Flutter Widget. The most common ones are Sateless- and Stateful Widgets. They have no access to any of the View Models in the hierarchy and also do not automatically rebuild when using any Observables inside their build function.

**Note:** Technically they somewhat have access to the View Models and can also rebuild themselves on Observable changes using for example the `Observer` Widget. However for the sake of this architecture **they should do neither of this**.

Instead Widgets should be View Model independent components. Any required values (like a String) or callbacks (like onTap) should be passed via constructor parameters. This means most of their rebuilds will be triggered from the outside by passing new arguments to their constructors.

## Conclusion

Rule of thumb. If the Widget you are building
- can be composed with others
- is used low in the widget hierarchy
- can be used multiple times throughout the app
- generically layouts other Widgets

make it a classic Widget with parameters and callbacks.
It's always worth trying if you can make a generic version of this Widget that may be used multiple times throughout the app or function as the base Widget for other View specific widgets.

If the Widget layouts or manages multiple other Widgets and requires values or methods from a View Model it should probably be a View or View Fragment.

For example a toggle button should get its state from the outside via constructor arguments. This button may be in another Widget (View Fragment) that layouts multiple Widgets, like a list of settings. Here the View Model properties and methods should be retrieved and passed to the toggle button.

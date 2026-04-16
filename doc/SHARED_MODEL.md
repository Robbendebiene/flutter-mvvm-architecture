# Shared Model

`SharedModel` provides shared state to a subtree using Flutter’s `InheritedWidget`. If you require a global store inject it above your App widget.

You can provide a dispose callback to dispose your shared state when the widget gets disposed.

**Example:**

```dart
SharedModel(
  create: ShoppingCart.new,
  // optional
  dispose: (cart) => cart.dispose(),
  // everything below this tree can access the model
  child: const App(),
)
```

The `SharedModel` can **only** be retrieved in the `create` function of the View using the `require` callback. This ensures consistency and forces the View Models to stay pure and only receive their dependencies via the constructor.

**Example:**

```dart
class MainView extends View<MainViewModel> {
  const MainView({
    super.key
  }) : super(create: (require) => MainViewModel(
    myDependency: require<SharedDependency>(),
  ));

  ...
}
```

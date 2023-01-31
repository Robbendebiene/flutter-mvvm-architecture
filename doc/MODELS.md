# Models

In the broad sense a Model is a class that most of the time describes some real word object or concept. Models can be distiguished in a lot of different types like domain objects, value objects etc. but for simplicity this architecture ignores this.

The architecture heavily depends on the principle that any changes get propagated automatically to any dependents. Therefore a model has to be either immutable or entirely composed of *Observables* from the **mobx** package.

## Immutable models

Immutable means that all model fields are declared as `final` and either contain primitive data (`int`, `double`, `bool`, `String`) or other classes which are deemed immutable themselves due to the previous rule.

**Example:**

```dart
class ExampleModel {
  final String var1;
  final int? var2;

  const ExampleModel({
    required this.var1,
    this.var2,
  });
}
```

Whenever an immutable model should be updated the entire model needs to be replaced. To simplify this process each immutable model should provide a `copyWith` method. This method can usually be generated from your IDE.

**Example:**

```dart
class ExampleModel {
  ...

  ExampleModel copyWith({
    String? var1,
    int? var2,
  }) {
    return ExampleModel(
      var1: var1 ?? this.var1,
      var2: var2 ?? this.var2,
    );
  }
}
```

**Attention:**
Be aware that declaring a variable of a specific class as `final` does not make any sub-class fields immutable. A common example is declaring a List like so:

```dart
final List<int> myList = [1, 2, 3];
```

The list can still be modified as usual:

```dart
myList.removeLast();
myList.add(5);

print(myList); // Outputs: [1, 2, 5]
```

Declaring it as `final` only prevents you from reassigning another List to the variable `myList`.

```dart
final List<int> myList = [1, 2, 3];

myList = [0]; // Should throw an exception.
```

This particular problem can be solved by creating the List through the `List.unmodifiable()` constructor.
However when you are using a List in most cases you probably want to add or remove items at some point. This brings us to our second model type which uses: *Observables*.

## Observable models

Fields of Observable models can (usually) be mutated freely in contrast to immutable models. They are declared by creating an `Observable` that wraps the original value, which allows for easy detection of any mutation to the underlying value.

**Example:**
```dart
class Counter {
  final _value = Observable(0);

  int get value => _value.value;
  set value(int newValue) => _value.value = newValue;
}
```

In order to listen/react to any changes made to an `Observable` *mobx* provides **Reactions**. Together with `Observable` they build the main workhorse of the entire state management system. If you are **using** (accessing or reading) any Observables directly or indirectly inside a `View` or `ViewFragment` then any changes to them will automatically rebuild the widget.

There are also multiple ways to react to changes in code, by using one of the reaction methods provided by *mobx* like: `autorun`, `reaction` or `when`.

While variables of an Observable model get wrapped inside an `Observable`, class methods should be wrapped inside an `Action`. Actions coalesce all notifications (triggered by making changes to Observables) and ensure the changes are notified only after the entire Action completes.

**Example:**

```dart
class Counter {
  final _value = Observable(0);

  late final increment = Action(_increment);

  void _increment() {
    _value.value++;
  }
}
```

Let's get back to our original problem. We want to create a List of items, which should be mutable, but we also wan't to be able to listen to any changes. Be carefull here, we **cannot** simply wrap our list with an `Observable`, like so:
```dart
final myList = Observable([1, 2, 3]); // This will not detect any changes made to the List. It will only detect if the entire List got replaced.
```

In order to observe classes like `List`, `Stream`, `Map`, `Future` etc. we have to use their Observable counterpart: `ObservableList`, `ObservableStream`, `ObservableMap`, `ObservableFuture`.

**Example:**

```dart
final myList = ObservableList.of([1, 2, 3]); // This will detect any changes made to the List.
```


## Conclusion
Use Immutable models for small classes that only hold a few properties of primitive data or are short-lived. Existing example classes are [Rect](https://api.flutter.dev/flutter/dart-ui/Rect-class.html) or [Offset](https://api.flutter.dev/flutter/dart-ui/Offset-class.html).
For more complex models like models that contain collections or other models prefer using Observables and Actions.
# View Models

View Models are an abstraction of the View exposing public properties and commands. Any callback methods required by the View must be provided directly by the View Model. Thus the View must not contain any own callback methods, the only exceptions build anonymous wrapper functions like this:

```dart
GestureDetector(
  onTap: (_) => viewModel.myMethod(),
);
```

For this architecture it is required that any exposed/provided properties by the View Model are directly read/derived from **Observables**. The View and ViewFragments will then automatically bind to the Observables in order to get notified on any changes and rebuild accordingly.
Any ephemeral states can be stored in the View Model. Shared or persistent states must be managed by a Service.


**Example:**
```dart

class MyUserService extends Service {
  final _user = Observable<User?>();

  late final login = Action((String name, String password) async {
    ...

    _user.value = User();
  });

  late final logout = Action(() async {
    ...

    _user.value = null;
  });

  bool get isLoggedIn => _user.value != null;

  User get getCurrentUser => _user.value!;
}


class MyViewModel extends ViewModel {

  User get _user => getService<MyUserService>().getCurrentUser();

  String get name => _user.name;

  String get surname => _user.surname;

  late final fullName = Computed(() {
    return '${_user.name} ${_user.surname}';
  });

  late final updateUserName = Action((String name) {
    _user.name = name;
  });
}
```

### Technical

If you need to do any cleanup in your View Model when the associated View gets destroyed, simply override the `dispose` method and put your cleanup code there.

```dart
class MyViewModel extends ViewModel {

  dispose() {
    // my cleanup code
  }
}
```
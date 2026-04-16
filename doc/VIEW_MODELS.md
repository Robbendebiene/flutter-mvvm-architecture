# View Models

View Models are an abstraction of the View exposing public properties and commands. Any callback methods required by the View must be provided directly by the View Model. Thus the View must not contain any own callback methods, the only exceptions build anonymous wrapper functions like this:

```dart
GestureDetector(
  onTap: (_) => viewModel.myMethod(),
);
```

For this architecture it is required that any exposed/provided properties by the View Model are directly read/derived from **Observables**. The View and ViewFragments will then automatically bind to the Observables in order to get notified on any changes and rebuild accordingly.
Any ephemeral states can be stored in the View Model. Shared or persistent states must be managed by a SharedModel.


**Example:**
```dart

class MyUserService {
  final _user = Observable<User?>();

  void login(String name, String password) async {
    ...

    runInAction(() => _user.value = User());
  }

  void logout() async {
    ...

    runInAction(() => _user.value = null);
  }

  bool get isLoggedIn => _user.value != null;

  User get currentUser => _user.value!;
}


class MyViewModel extends ViewModel {

  final MyUserService _userService;

  ViewModel(this._userService);

  User get _user => _userService.currentUser;

  String get name => _user.name;

  String get surname => _user.surname;

  late final fullName = Computed(() {
    return '${_user.name} ${_user.surname}';
  });

  void updateUserName(String name) {
    runInAction(() => _user.name = name);
  }
}
```

### Dependency Injection
Sometimes View Models require a shared app state. The shared state can be provided via a `SharedModel` and retrieved inside the `create` callback via the `require` function.

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

### Technical

If you need to do any cleanup in your View Model when the associated View gets destroyed, simply override the `dispose` method and put your cleanup code there.

```dart
class MyViewModel extends ViewModel {

  dispose() {
    // my cleanup code
  }
}
```
# Repositories and Services

## Repository

Repositories can be seen as certain kinds of Services. They sit between the data and business layer. Their goal is to abstract any underlying technical API calls to simple read/write methods. When creating a Repository you should implement the `CrudRepository` class, as it forces you to implement the most basic methods of a Repository: `create`, `read`, `update`, `delete`.

```dart
abstract class CrudRepository<T, K> implements Repository {
  Stream<T> readAll();
  Future<T> create(T entity);
  Future<T> read(K id);
  Future<T> update(T entity);
  Future<T> delete(T entity);
}
```

As you can see all methods are async because it's very common that the underlying API calls are somewhat asynchronous.
When creating a Repository it is recommended to write an interface for it. This allows for the possibility to plug in different data sources by only swapping the Repository implementation.

**Example:**

```dart
// Repository interface
abstract class UserDataRepository implements CrudRepository<User, String> {

}
// Concrete implementation for a local storage API
class LocalUserDataRepository implements UserDataRepository {
  ...
}
// Concrete implementation for an online storage API, like a Database
class OnlineUserDataRepository implements UserDataRepository {
  ...
}
```

## Services

Services typically operate on Repositories and thus shouldn't read nor write any persistent data directly. They are used by other Services or View Models.
In contrast to Repositories, Services provide more specific methods. Together with models they build the main realm of the apps business logic.

```dart
class UserService extends Service {
  User GetByUserName(string userName) {
    ...
  }
  string GetUserNameByEmail(string email) {
    ...
  }
  bool ChangePassword(string userName, string newPassword) {
    ...
  }
  bool SendPasswordReminder(string userName) {
    ...
  }
  bool RegisterNewUser(RegisterNewUserModel model) {
    ...
  }
  ...
}
```

### Technical

Any persistent Services and Repositories can be registered on App start using the *get_it* service locator:

```dart
void main() {
  // register a service class using registerSingleton, registerLazySingleton or registerFactory
  GetIt.I.registerSingleton<BuildingRepository>( OfflineBuildingRepository() );

  runApp(const MyApp());
}
```

Services can also be unregistered, overridden or registered later using the `GetIt.I` instance.
To access any of the registered Services and Repositories, **do not** directly use *get_it*. Instead use the wrapper methods `getService` and `getRepository` provided by extending the  `Service` or `View Model` classes.

### Conclusion:

The different responsibilities can be nicely illustrated by the bank metaphor:
The bank holds your money in a vault, the vault is a **Database**. The teller can deposit or withdraw from the vault, the teller is the **Repository**. The customer is the one who asks the teller to deposit or withdraw, the customer is the **Service**.
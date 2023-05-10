
import 'package:mobx/mobx.dart';

/// A mixin for models that want to store their values. When storing as JSON `T` usually will be of type `Map<String, dynamic>`.
///
/// Changes that affect the record value will be propagated and can be used by other models, building a tree of dependencies.
/// ```dart
/// class MyModel with Record<Map<String, dynamic>> {
///   final myProperty = Observable<int>();
///   final anotherModel = AnotherModel();
///
///   @override
///   late final observableRecord = Computed(() => {
///     'myProperty': myProperty.value,
///     'anotherModel': anotherModel.value.asRecord,
///   });
/// }
///
/// class AnotherModel with Record<Map<String, dynamic>> {
///   final anotherProperty = Observable<int>();
///
///   @override
///   late final observableRecord = Computed(() => {
///     'anotherProperty': anotherProperty.value,
///   });
/// }
/// ```

mixin Record<T extends Object> {

  /// The actual record value of the `Computable` constructed by `observableRecord`.

  T get asRecord => observableRecord.value;

  /// Constructs the record value and wraps it inside a `Computable`.
  ///
  /// Most likely you want to implement this as a `late final` variable.
  ///
  /// ```dart
  ///@override
  ///late final observableRecord = Computed(() => {
  ///   'myProperty': myProperty.value,
  ///   'anotherModel': anotherModel.value.asRecord,
  ///});
  /// ```

  Computed<T> get observableRecord;
}

part of 'view.dart';

/// The ViewModel is constructed when the View is mounted to the tree and owned by the View.
///
/// By design it does not get the `BuildContext` of the view to decouple it as much as possible.
/// If you require context e.g. to show a dialog or notifications use the `request()` method.
///
/// If you require context due to other reasons (e.g. Localizations or MediaQuery) try:
/// - moving the context access to the View and if necessary pass the result to the View Model
/// - implementing a custom `Request` with a respective handler in the View
///
/// If the ViewModel depends on `SharedModel`s then get them in the View's `create` method and pass them via constructor.
///
/// Example:
/// ```dart
/// class MyViewModel extends ViewModel {
///   final SharedModelA a;
///   final SharedModelB b;
///
///   MyViewModel(this.a, this.b);
/// }
/// ```
/// For async operations consider checking whether the `isDisposed` property is still `false` to exit any routine when the View is unmounted/disposed.

abstract class ViewModel {

  /// Called when this object is inserted into the tree.

  ViewModel();

  // use sync true to allow synchronous responses
  final _requests = StreamController<Request>(sync: true);

  /// Dispatch requests to the subscribed view.
  ///
  /// This is a helper function to easily implement things like showing dialogs or notifications.
  ///
  /// The View may react to the requests and even respond.

  O request<R, O>(Request<R, O> request) {
    _requests.add(request);
    return request._response;
  }

  /// Check whether the widget this view model belongs to is unmounted/disposed.

  bool get isDisposed => _requests.isClosed;

  @protected
  @mustCallSuper
  void activate() {}

  @protected
  @mustCallSuper
  void deactivate() {}

  @protected
  @mustCallSuper
  void dispose() {
    _requests.close();
  }
}

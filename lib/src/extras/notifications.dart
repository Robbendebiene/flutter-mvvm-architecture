import 'package:flutter/material.dart' hide View;

import '../../base.dart';

/// A helper [Request] used together with the `NotificationHandler` to show a snackbar.
/// Base model used by the `NotificationMediator` and `NotificationHandler` to exchange data.
///
/// Returns a future upon request which completes when the snackbar closes.
///
/// You max extend the class and later access it in the `notificationBuilder` like so:
///
/// ```dart
/// Widget notificationBuilder(BuildContext context, Notification request) {
///   if (request is CustomNotificationClass1) {
///     ...
///   }
///   else if (request is CustomNotificationClass2) {
///     ...
///   }
/// }
/// ```

class Notification extends AsyncRequest<SnackBarClosedReason> {
  final String message;
  final String actionLabel;
  final Duration duration;
  final bool persist;
  final VoidCallback? action;
  final VoidCallback? onVisible;

  Notification(this.message, {
    this.actionLabel = '',
    this.action,
    this.duration = const Duration(seconds: 4),
    this.persist = false,
    this.onVisible,
  }) :
    assert(
      (action == null && actionLabel.isEmpty) || (action != null && actionLabel.isNotEmpty),
      action != null
        ? 'An "action" is defined but no "actionLabel" was provided.'
        : 'An "actionLabel" is defined but no "action" was provided.',
    );
}


/// Used to build and display [Notification]s.
///
/// Example usage:
/// ```dart
/// class MyViewModel extends ViewModel {
///   void someFunc() {
///     final notification = request(Notification(...));
///   }
/// }
///
/// class MyView extends View<MyViewModel> with NotificationHandler {
///   const MyView({super.key}) : super(create: MyViewModel.new);
///
///   ...
/// }
/// ```
///
/// Override the `notificationBuilder` method in the `View` to customize the snack bar widget.

mixin NotificationHandler<T extends ViewModel> on View<T> {

  /// Override this to build a custom prompt widget dialog.

  SnackBar notificationBuilder(BuildContext context, T vm, Notification request) {
    return _defaultNotificationBuilder(context, vm, request);
  }

  @override
  void requestHandler(BuildContext context, T vm, Request request) {
    super.requestHandler(context, vm, request);
    if (request is Notification) {
      final messenger = ScaffoldMessenger.of(context);
      final controller = messenger.showSnackBar(
        notificationBuilder(context, vm, request),
      );
      controller.closed.then(request.respond);
    }
  }
}

/// This is mostly required when directly being used on a View that contains the `Scaffold`/`ScaffoldMessenger` itself.
/// Otherwise you probably want to use the `NotificationHandler` mixin.
///
/// In order to use this mixin you have to add the `scaffoldMessengerKey` to the MaterialApp widget:
///
/// ```dart
/// MaterialApp(
///   scaffoldMessengerKey: GlobalNotificationHandler.globalKey,
/// )
/// ```
mixin GlobalNotificationHandler<T extends ViewModel> on View<T> {

  static final globalKey = GlobalKey<ScaffoldMessengerState>();

  /// Override this to build a custom prompt widget dialog.

  SnackBar notificationBuilder(BuildContext context, T vm, Notification request) {
    return _defaultNotificationBuilder(context, vm, request);
  }

  @override
  void requestHandler(BuildContext context, T vm, Request request) {
    super.requestHandler(context, vm, request);
    if (request is Notification) {
      final controller = GlobalNotificationHandler.globalKey.currentState!.showSnackBar(
        notificationBuilder(context, vm, request),
      );
      controller.closed.then(request.respond);
    }
  }
}

/// The default builder for notifications dispatched by the [Notifications] mixin.

SnackBar _defaultNotificationBuilder<T>(BuildContext context, T vm, Notification request) {
  return SnackBar(
    content: Text(request.message),
    onVisible: request.onVisible,
    persist: request.persist,
    duration: request.duration,
    action: request.action != null
      ? SnackBarAction(
        label: request.actionLabel,
        onPressed: request.action!,
      )
      : null,
  );
}

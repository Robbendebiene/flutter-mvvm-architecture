import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '/src/base/view.dart';

typedef SnackbarCloseCallback = void Function(SnackBarClosedReason);

class Notification {
  final String message;
  final String actionLabel;
  final VoidCallback? action;
  final VoidCallback? onVisible;
  final SnackbarCloseCallback? onClosed;

  Notification({
    required this.message,
    this.actionLabel = '',
    this.action,
    this.onVisible,
    this.onClosed,
  });
}


/// Mixin that allows the view model to show notifications to the user.
///
/// It exposes a [notificationRequests] observable stream to the view.
/// The view can react to them using the [NotificationHandler].
///
/// Example usage:
/// ```dart
/// class MyViewModel extends ViewModel with NotificationMediator {
///   void myFunction() {
///     // do something ...
///
///     notifyUser("ddd",
///       actionLabel: "my action",
///       action: () => print("action"),
///       onVisible: () => print("visible"),
///       onClosed: (r) => print(r),
///     );
///
///     // do something ...
///   }
/// }
/// ```

mixin NotificationMediator on ViewModel {
  final _streamController = StreamController<Notification>();
  late final _notificationRequests = ObservableStream(_streamController.stream);

  /// Requests input from the view

  void notifyUser(String message, {String actionLabel = '', VoidCallback? action, VoidCallback? onVisible, SnackbarCloseCallback? onClosed}) {
    assert(
      (action == null && actionLabel.isEmpty) || (action != null && actionLabel.isNotEmpty),
      action != null
        ? 'An "action" is defined but no "actionLabel" was provided.'
        : 'An "actionLabel" is defined but no "action" was provided.',
    );

    final request = Notification(
      message: message,
      actionLabel: actionLabel,
      action: action,
      onVisible: onVisible,
      onClosed: onClosed,
    );

    _streamController.add(request);
  }

  @override
  dispose() {
    _streamController.close();
    _notificationRequests.close();
    super.dispose();
  }
}


/// Used to build and display [Notification]s from the [NotificationMediator].
///
/// **Note:** This requires a [ScaffoldMessenger] and [Scaffold] above this [View].
///
/// Example usage:
/// ```dart
/// class MyViewModel extends ViewModel with NotificationMediator {
///   ...
/// }
///
/// class MyView extends View<MyViewModel> with NotificationHandler {
///   const MyView({super.key}) : super(create: MyViewModel.new);
///
///   ...
/// }
/// ```

mixin NotificationHandler<T extends NotificationMediator> on View<T> {

  /// Override this to build a custom prompt widget dialog.

  SnackBar notificationBuilder(BuildContext context, Notification request) {
    return SnackBar(
      content: Text(request.message),
      onVisible: request.onVisible,
      action: request.action != null
        ? SnackBarAction(
          label: request.actionLabel,
          onPressed: request.action!,
        )
        : null,
    );
  }

  @override
  Iterable<ReactionDisposer> hookReactions(BuildContext context, T vm) sync* {
    yield* super.hookReactions(context, vm);

    yield reaction((_) => vm._notificationRequests.value, (result) {
      if (result != null) {
        final messenger = ScaffoldMessenger.of(context);
        final controller = messenger.showSnackBar(
          notificationBuilder(context, result),
        );
        if (result.onClosed != null) {
          controller.closed.then(result.onClosed!);
        }
      }
    });
  }
}

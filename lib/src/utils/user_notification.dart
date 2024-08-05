import 'dart:async';

import 'package:flutter/material.dart' hide View;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '/src/base/view.dart';

typedef SnackbarCloseCallback = void Function(SnackBarClosedReason);

/// Base model used by the `NotificationMediator` and `NotificationHandler` to exchange data.
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

class Notification {
  final String message;
  final String actionLabel;
  final VoidCallback? action;
  final VoidCallback? onVisible;
  final SnackbarCloseCallback? onClosed;

  Notification(this.message, {
    this.actionLabel = '',
    this.action,
    this.onVisible,
    this.onClosed,
  }) :
    assert(
      (action == null && actionLabel.isEmpty) || (action != null && actionLabel.isNotEmpty),
      action != null
        ? 'An "action" is defined but no "actionLabel" was provided.'
        : 'An "actionLabel" is defined but no "action" was provided.',
    );
}


/// Mixin that allows the view model to show notifications to the user.
///
/// The view can react to the notification requests by mixing in the [NotificationHandler].
///
/// Example usage:
/// ```dart
/// class MyViewModel extends ViewModel with NotificationMediator {
///   void myFunction() {
///     // do something ...
///
///     notifyUser(Notification(
///       "ddd",
///       actionLabel: "my action",
///       action: () => print("action"),
///       onVisible: () => print("visible"),
///       onClosed: (r) => print(r),
///     ));
///
///     // do something ...
///   }
/// }
/// ```

mixin NotificationMediator on ViewModel {
  final _streamController = StreamController<Notification>();
  late final _notificationRequests = ObservableStream(_streamController.stream);

  /// Requests the view to display a notification.

  void notifyUser(Notification notification) {
    _streamController.add(notification);
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
/// If your [View] itself provides the [Scaffold] you can alternatively insert and use the [NotificationBuilder] below the [Scaffold].
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
///
/// Override the `notificationBuilder` method in the `View` to customize the notification widget.

mixin NotificationHandler<T extends NotificationMediator> on View<T> {

  /// Override this to build a custom notification snackbar.

  SnackBar notificationBuilder(BuildContext context, Notification request) {
    return _defaultNotificationBuilder(context, request);
  }

  @override
  void hookReactions(BuildContext context, T vm, disposeWithWidget) {
    super.hookReactions(context, vm, disposeWithWidget);
    disposeWithWidget(
      reaction((_) => vm._notificationRequests.value, (Notification? result) {
        if (result != null) {
          final messenger = ScaffoldMessenger.of(context);
          final controller = messenger.showSnackBar(
            notificationBuilder(context, result),
          );
          if (result.onClosed != null) {
            controller.closed.then(result.onClosed!);
          }
        }
      }),
    );
  }
}


typedef NotificationSnackBarBuilder = SnackBar Function(BuildContext context, Notification request);

/// An alternative way to show notifications provided by the [NotificationMediator].
///
/// This must be placed below a [ScaffoldMessenger] and [Scaffold] in order to work.
///
/// ATTENTION: You have to provide the view models type as [T] that provides the notifications.

class NotificationBuilder<T extends NotificationMediator> extends StatefulWidget {
  final Widget child;
  final NotificationSnackBarBuilder builder;

  const NotificationBuilder({
    required this.child,
    this.builder = _defaultNotificationBuilder,
    super.key,
  });

  @override
  NotificationBuilderState createState() => NotificationBuilderState<T>();
}

class NotificationBuilderState<T extends NotificationMediator> extends State<NotificationBuilder> {
  ReactionDisposer? _disposeReaction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final result = context.dependOnInheritedWidgetOfExactType<ViewModelProvider<T>>();
    assert(result != null, 'The NotificationBuilder "$widget" cannot find "$T" in the current context.');
    final viewModel = result!.viewModel;

    _disposeReaction?.call();
    _disposeReaction = _reactionBuilder(viewModel);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _disposeReaction?.call();
    super.dispose();
  }

  ReactionDisposer _reactionBuilder(T viewModel) {
    return reaction((_) => viewModel._notificationRequests.value, (Notification? result) {
      if (result != null) {
        final messenger = ScaffoldMessenger.of(context);
        final controller = messenger.showSnackBar(
          widget.builder(context, result),
        );
        if (result.onClosed != null) {
          controller.closed.then(result.onClosed!);
        }
      }
    });
  }
}


/// The default builder for notifications dispatched by the [NotificationMediator].

SnackBar _defaultNotificationBuilder(BuildContext context, Notification request) {
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

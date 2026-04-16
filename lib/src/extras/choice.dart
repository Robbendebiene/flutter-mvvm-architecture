import 'package:flutter/material.dart' hide View;

import '../../base.dart';


/// A helper [Request] used together with the `ChoiceHandler` to request user choice dialog.
///
/// Returns a future upon request which completes with the users's choice.
///
/// You max extend the class and later access it in the Views `choiceBuilder` like so:
/// ```dart
/// Widget choiceBuilder(BuildContext context, T vm, Choice request) {
///   if (request is CustomChoice1) {
///     ...
///   }
///   else if (request is CustomChoice2) {
///     ...
///   }
/// }
/// ```
/// If you require different fields e.g. because you want to localize the choice text based on the context
/// consider creating your own choice class based on `AsyncRequest` as well as choice handler mixin
/// (take a look at `ChoiceHandler` for an example)

class Choice<R> extends AsyncRequest<R?> {
  final String? title;
  final String message;
  final bool isDismissible;
  final Map<String, R> choices;

  Choice({
    required this.message,
    required this.choices,
    this.title,
    this.isDismissible = false,
  });
}


/// Used to build and display a dialog for `Choice` request.
///
/// Example usage:
/// ```dart
/// class MyViewModel extends ViewModel {
///   void someFunc() {
///     final choice = request(Choice(...));
///   }
/// }
///
/// class MyView extends View<MyViewModel> with ChoiceHandler {
///   ...
/// }
/// ```
///
/// Override the `choiceBuilder` method to customize the dialog widget.

mixin ChoiceHandler<T extends ViewModel> on View<T> {

  /// Override this to build a custom choice widget dialog.

  Widget choiceBuilder(BuildContext context, T vm, Choice request) {
    return AlertDialog(
      title: request.title != null ? Text(request.title!) : null,
      content: Text(request.message),
      actions: request.choices.entries.map(
        (entry) => TextButton(
          onPressed: () => Navigator.of(context).pop(entry.value),
          child: Text(entry.key),
        ),
      ).toList(growable: false),
    );
  }

  @override
  void requestHandler(BuildContext context, T vm, Request request) {
    super.requestHandler(context, vm, request);
    if (request is Choice) {
      showDialog(
        context: context,
        builder: (context) => choiceBuilder(context, vm, request),
        barrierDismissible: request.isDismissible,
      ).then(request.respond);
    }
  }
}

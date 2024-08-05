import 'dart:async';

import 'package:flutter/material.dart' hide View;
import 'package:mobx/mobx.dart';

import '/src/base/view.dart';

/// Base model used by the `PromptMediator` and `PromptHandler` to exchange data.
///
/// You max extend the class and later access it in the `promptBuilder` like so:
///
/// ```dart
/// Widget promptBuilder(BuildContext context, Prompt request) {
///   if (request is CustomPromptClass1) {
///     ...
///   }
///   else if (request is CustomPromptClass2) {
///     ...
///   }
/// }
/// ```

class Prompt<R> {
  final String? title;
  final String message;
  final bool isDismissible;
  final Map<String, R> choices;

  Prompt({
    required this.message,
    required this.choices,
    this.title,
    this.isDismissible = false,
  });

  final _completer = Completer<R?>();

  /// The response may be `null` if [isDismissible] is `true`.

  Future<R?> get response => _completer.future;

  void respond(R? response) => _completer.complete(response);
}


/// Mixin that allows the view model to prompt for user inputs via `promptUserInput()`.
///
/// The view can react to the prompt requests by mixing in the [PromptHandler].
///
/// Example usage:
/// ```dart
/// class MyViewModel extends ViewModel with PromptMediator {
///   void myFunction() async {
///     // do something ...
///
///     final userInput = await promptUserInput(Prompt(
///       message: "Do you want..",
///       choices: {
///         "Yes": true,
///         "No": false,
///         "Cancel": null,
///       },
///     ));
///
///     if (userInput == true) {
///       // do something ...
///     }
///     else {
///       // do something ...
///     }
///   }
/// }
/// ```

mixin PromptMediator on ViewModel {
  final _streamController = StreamController<Prompt>();
  late final _promptRequests = ObservableStream(_streamController.stream);

  /// Requests input from the view.
  ///
  /// Returns the result value. This is the same as `Prompt().response` property.

  Future<R?> promptUserInput<R>(Prompt<R> request) {
    _streamController.add(request);
    return request.response;
  }

  @override
  dispose() {
    _streamController.close();
    _promptRequests.close();
    super.dispose();
  }
}


/// Used to build and display [Prompt]s from the [PromptMediator].
///
/// Example usage:
/// ```dart
/// class MyViewModel extends ViewModel with PromptMediator {
///   ...
/// }
///
/// class MyView extends View<MyViewModel> with PromptHandler {
///   const MyView({super.key}) : super(create: MyViewModel.new);
///
///   ...
/// }
/// ```
///
/// Override the `promptBuilder` method in the `View` to customize the prompt widget.

mixin PromptHandler<T extends PromptMediator> on View<T> {

  /// Override this to build a custom prompt widget dialog.

  Widget promptBuilder(BuildContext context, Prompt request) {
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
  void hookReactions(BuildContext context, T vm, disposeWithWidget) {
    super.hookReactions(context, vm, disposeWithWidget);
    disposeWithWidget(
      reaction((_) => vm._promptRequests.value, (Prompt? result) async {
        if (result != null) {
          final response = await showDialog(
            context: context,
            builder: (context) => promptBuilder(context, result),
            barrierDismissible: result.isDismissible,
          );
          result.respond(response);
        }
      }),
    );
  }
}

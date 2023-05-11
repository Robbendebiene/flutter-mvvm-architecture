import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '/src/base/view.dart';
import '/src/base/view_model.dart';


class Prompt<R> {
  final String message;
  final bool isDismissible;
  final Map<String, R> choices;

  Prompt({
    required this.message,
    required this.choices,
    this.isDismissible = false,
  });

  final _completer = Completer<R?>();

  /// The response may be `null` if [isDismissible] is `true`.

  Future<R?> get response => _completer.future;

  void respond(R? response) => _completer.complete(response);
}


/// Mixin that allows the view model to prompt for user inputs.
///
/// It exposes a [promptRequests] observable stream to the view.
/// The view can react to them using the [PromptHandler].
///
/// Example usage:
/// ```dart
/// class MyViewModel extends ViewModel with PromptMediator {
///   void myHeavyFunction() async {
///     // do something ...
///
///     final userInput = await promptUserInput(
///       message: "Do you want..",
///       choices: {
///         "Yes": true,
///         "No": false,
///         "Cancel": null,
///       },
///     );
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

  /// Requests input from the view

  Future<R?> promptUserInput<R>({required String message, required Map<String, R> choices, bool isDismissible = false}) {
    final request = Prompt(
      message: message,
      choices: choices,
      isDismissible: isDismissible,
    );

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

mixin PromptHandler<T extends PromptMediator> on View<T> {

  /// Override this to build a custom prompt widget dialog.

  Widget promptBuilder(BuildContext context, Prompt request) {
    return AlertDialog(
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
  Iterable<ReactionDisposer> hookReactions(BuildContext context, T vm) sync* {
    yield* super.hookReactions(context, vm);

    yield reaction((_) => vm._promptRequests.value, (result) async {
      if (result != null) {
        final response = await showDialog(
          context: context,
          builder: (context) => promptBuilder(context, result),
          barrierDismissible: result.isDismissible,
        );
        result.respond(response);
      }
    });
  }
}

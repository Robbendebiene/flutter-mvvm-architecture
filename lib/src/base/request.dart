part of 'view.dart';


abstract class Request<Response, Return> {
  Return get _response;

  void respond(Response response);
}

/// Extend this class for custom asynchronous requests.

abstract class AsyncRequest<Response> implements Request<Response, Future<Response>> {
  final _completer = Completer<Response>();

  @override
  Future<Response> get _response => _completer.future;

  @override
  @mustCallSuper
  void respond(Response response) => _completer.complete(response);

  bool get hasBeenResponded => _completer.isCompleted;
}

/// Extend this class for custom synchronous requests.
///
/// The handler has to call `respond` immediately after receiving the request.

abstract class SyncRequest<Response> implements Request<Response, Response> {
  var _gotResponse = false;
  late final Response _pendingResponse;

  @override
  Response get _response {
    if (_gotResponse) {
      return _pendingResponse;
    }
    throw UnimplementedError('The View did not respond to the request. Did you miss adding a request handler mixin or implementing the "requestHandler" method in the View?');
  }

  @override
  @mustCallSuper
  void respond(Response response) {
    if (_gotResponse) {
      throw StateError('This SyncRequest $this has already been responded to.');
    }
    _gotResponse = true;
    _pendingResponse = response;
  }
}

import 'dart:async';
import 'dart:io';

/// Abstraction to check network connectivity.
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool>? get onConnectivityChanged => null;
}

class NetworkInfoImpl implements NetworkInfo {
  final Duration checkInterval;
  StreamController<bool>? _controller;
  Timer? _timer;
  bool? _lastStatus;

  NetworkInfoImpl({this.checkInterval = const Duration(seconds: 15)});

  @override
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    _controller ??= StreamController<bool>.broadcast(
      onListen: () {
        _checkStatus();
        _timer = Timer.periodic(checkInterval, (_) => _checkStatus());
      },
      onCancel: () {
        _timer?.cancel();
        _timer = null;
      },
    );
    return _controller!.stream;
  }

  Future<void> _checkStatus() async {
    final connected = await isConnected;
    if (_lastStatus != connected) {
      _lastStatus = connected;
      if (_controller != null && !_controller!.isClosed) {
        _controller!.add(connected);
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller?.close();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/core/network/network_info.dart';

void main() {
  group('NetworkInfoImpl', () {
    test('isConnected returns a boolean', () async {
      final networkInfo = NetworkInfoImpl();
      final result = await networkInfo.isConnected;
      expect(result, isA<bool>());
    });
  });
}


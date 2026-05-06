import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/repositories/ble_repository.dart';

final bleRepositoryProvider = Provider((ref) => BLERepository());

final bleScanResultsProvider = StreamProvider((ref) {
  return ref.watch(bleRepositoryProvider).scanResults;
});
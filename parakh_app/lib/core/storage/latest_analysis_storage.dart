import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/camera_analysis_result.dart';
import '../models/device_reading.dart';
import '../models/ph_analysis_result.dart';

class LatestAnalysisStorage {
  static const String _nirKey = 'latest_nir_analysis';
  static const String _cameraKey = 'latest_camera_analysis';
  static const String _phKey = 'latest_ph_analysis';
  static const Duration _maximumResultAge = Duration(minutes: 30);

  Future<void> saveNirReading(DeviceReading reading) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _nirKey,
      jsonEncode({
        'feedType': reading.feedType,
        'savedAt': DateTime.now().toIso8601String(),
        'result': reading.toJson(),
      }),
    );
  }

  Future<void> saveCameraResult({
    required CameraAnalysisResult result,
    required String feedType,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _cameraKey,
      jsonEncode({
        'feedType': feedType,
        'savedAt': DateTime.now().toIso8601String(),
        'result': result.toJson(),
      }),
    );
  }

  Future<void> savePhResult(PhAnalysisResult result) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _phKey,
      jsonEncode({
        'feedType': result.feedType,
        'savedAt': DateTime.now().toIso8601String(),
        'result': result.toJson(),
      }),
    );
  }

  Future<DeviceReading?> getNirReading({required String feedType}) async {
    final stored = await _readStoredResult(_nirKey, feedType);

    if (stored == null) return null;

    return DeviceReading.fromJson(stored);
  }

  Future<CameraAnalysisResult?> getCameraResult({
    required String feedType,
  }) async {
    final stored = await _readStoredResult(_cameraKey, feedType);

    if (stored == null) return null;

    return CameraAnalysisResult.fromJson(stored);
  }

  Future<PhAnalysisResult?> getPhResult({required String feedType}) async {
    final stored = await _readStoredResult(_phKey, feedType);

    if (stored == null) return null;

    return PhAnalysisResult.fromJson(stored);
  }

  Future<Map<String, dynamic>?> _readStoredResult(
    String key,
    String feedType,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(key);

    if (encoded == null) return null;

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! Map) return null;

      final storedFeedType = decoded['feedType']?.toString();
      final rawResult = decoded['result'];
      final savedAt = DateTime.tryParse(decoded['savedAt']?.toString() ?? '');

      if (storedFeedType != feedType || rawResult is! Map || savedAt == null) {
        return null;
      }

      final now = DateTime.now();
      final resultAge = now.difference(savedAt);

      final isFromUnexpectedFuture = savedAt.isAfter(
        now.add(const Duration(minutes: 5)),
      );

      if (resultAge > _maximumResultAge || isFromUnexpectedFuture) {
        return null;
      }

      return Map<String, dynamic>.from(rawResult);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPhResult() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_phKey);
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.remove(_nirKey),
      preferences.remove(_cameraKey),
      preferences.remove(_phKey),
    ]);
  }
}

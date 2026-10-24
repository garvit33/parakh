import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calibration_record.dart';

class CalibrationStorage {
  static const String _storageKey = 'parakh_calibration_records';

  Future<List<CalibrationRecord>> getRecords() async {
    final preferences = await SharedPreferences.getInstance();
    final storedRecords = preferences.getStringList(_storageKey) ?? [];
    final records = <CalibrationRecord>[];

    for (final storedRecord in storedRecords) {
      try {
        final decoded = jsonDecode(storedRecord);
        if (decoded is Map) {
          records.add(
            CalibrationRecord.fromJson(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (_) {
        // Ignore damaged entries while keeping valid offline records.
      }
    }

    records.sort(
      (first, second) => second.createdAt.compareTo(first.createdAt),
    );

    return records;
  }

  Future<void> saveRecord(CalibrationRecord record) async {
    final records = await getRecords();

    final existingIndex = records.indexWhere(
      (existing) => existing.id == record.id,
    );

    if (existingIndex == -1) {
      records.add(record);
    } else {
      records[existingIndex] = record;
    }

    records.sort(
      (first, second) => second.createdAt.compareTo(first.createdAt),
    );

    await _writeRecords(records);
  }

  Future<void> deleteRecord(String recordId) async {
    final records = await getRecords();

    records.removeWhere((record) => record.id == recordId);

    await _writeRecords(records);
  }

  Future<void> clearRecords() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  Future<void> _writeRecords(List<CalibrationRecord> records) async {
    final preferences = await SharedPreferences.getInstance();

    final encodedRecords = records
        .map((record) => jsonEncode(record.toJson()))
        .toList();

    await preferences.setStringList(_storageKey, encodedRecords);
  }
}

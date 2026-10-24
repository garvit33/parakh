import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed_test_result.dart';

class TestHistoryStorage {
  static const String _storageKey = 'parakh_test_history';

  Future<List<FeedTestResult>> getResults() async {
    final preferences = await SharedPreferences.getInstance();
    final storedResults = preferences.getStringList(_storageKey) ?? [];

    final results = <FeedTestResult>[];

    for (final storedResult in storedResults) {
      try {
        final decoded = jsonDecode(storedResult) as Map<String, dynamic>;
        results.add(FeedTestResult.fromJson(decoded));
      } catch (_) {
        // Ignore damaged entries so the remaining offline history still loads.
      }
    }

    results.sort(
      (first, second) => second.createdAt.compareTo(first.createdAt),
    );

    return results;
  }

  Future<void> saveResult(FeedTestResult result) async {
    final preferences = await SharedPreferences.getInstance();
    final storedResults = preferences.getStringList(_storageKey) ?? [];

    final updatedResults = [jsonEncode(result.toJson()), ...storedResults];

    await preferences.setStringList(_storageKey, updatedResults);
  }

  Future<void> deleteResult(String resultId) async {
    final preferences = await SharedPreferences.getInstance();
    final storedResults = preferences.getStringList(_storageKey) ?? [];

    final updatedResults = storedResults.where((storedResult) {
      try {
        final decoded = jsonDecode(storedResult) as Map<String, dynamic>;
        return decoded['id'] != resultId;
      } catch (_) {
        return false;
      }
    }).toList();

    await preferences.setStringList(_storageKey, updatedResults);
  }

  Future<void> clearHistory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}

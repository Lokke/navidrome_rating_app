import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app debug logs per session, keeping the last 3 sessions and allowing retrieval/share.
class LoggingService {
  static late LoggingService instance;
  final Directory _logDir;
  final File _currentLog;
  static const _prefsKey = 'app_session_logs';

  LoggingService._(this._logDir, this._currentLog);

  /// Initialize the logging service, creating a new session log.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final docDir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${docDir.path}/logs');
    if (!await logDir.exists()) await logDir.create(recursive: true);
    // Manage session history
    final sessions = prefs.getStringList(_prefsKey) ?? [];
    // Remove oldest if >3
    if (sessions.length >= 3) {
      final toRemove = sessions.sublist(0, sessions.length - 2);
      sessions.removeRange(0, sessions.length - 2);
      for (var name in toRemove) {
        final f = File('${logDir.path}/$name');
        if (await f.exists()) await f.delete();
      }
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final sessionFileName = 'session_$timestamp.log';
    sessions.add(sessionFileName);
    await prefs.setStringList(_prefsKey, sessions);
    final currentLog = File('${logDir.path}/$sessionFileName');
    final service = LoggingService._(logDir, currentLog);
    instance = service;
    await currentLog.writeAsString('--- Session start: $timestamp ---\n');
    // Flutter errors will be captured by runZonedGuarded in main via zoneSpecification for print
  }

  /// Append a message to the current log file.
  Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    await _currentLog.writeAsString(
      '[$timestamp] $message\n',
      mode: FileMode.append,
    );
  }

  /// Log an error and its stack
  Future<void> logError(Object error, StackTrace stack) async {
    await log('ERROR: $error');
    await log(stack.toString());
  }

  /// Retrieve the list of session log file paths (last 3)
  Future<List<String>> getSessionLogPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList(_prefsKey) ?? [];
    return sessions.map((name) => '${_logDir.path}/$name').toList();
  }
}

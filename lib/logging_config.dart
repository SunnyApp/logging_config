library logging_config;

import 'dart:async';
import 'dart:developer' as dev;

import 'package:logging/logging.dart';
import 'package:worker_service/worker_service.dart';

import 'console_interface.dart'
    if (dart.library.io) 'console_io.dart'
    if (dart.library.js) 'console_web.dart';

/// Logging stream consumer
typedef Logging = void Function(LogRecord record);

FutureOr _configureLoggingIsolate(final dynamic p) async {
  if (p is LogConfig) return await configureLogging(p);
}

final StreamController<LogConfig> _configStream = StreamController<LogConfig>();
Stream<LogConfig> get onLogConfigured => _configStream.stream;

/// Configures a single logger - isolate friendly
FutureOr configureLogging(LogConfig config) async {
  hierarchicalLoggingEnabled = true;
  _configStream.add(config);
  print(
      "[$currentIsolateName] Configuring loggers ${config.logLevels.keys.map((name) => name?.isNotEmpty != true ? "root" : name).join(", ")} "
      "to use ${config.handler.runtimeType}");
  RunnerFactory.global.addIsolateInitializer(_configureLoggingIsolate, config);
  config.logLevels.forEach((name, level) {
    final existing = _loggers[name];
    hierarchicalLoggingEnabled = true;
    if (existing == null) {
      _loggers.putIfAbsent(name, () {
        final logger = Logger(name);
        logger.level = level;
        return LoggerState(logger, config.handler);
      });
    } else {
      existing.logger.level = level;
      existing.subscription.cancel();
      _loggers[name] = LoggerState(existing.logger, config.handler);
    }
  });
}

class LogConfig {
  /// For named log levels, provides a log [Level].  The keys represent the logger name, and are hierarchical,
  /// using a dot-separated pattern
  final Map<String, Level> logLevels;

  /// For all logger names specified as keys in [logLevels], determines which [LoggingHandler] is used to output
  /// logs
  final LoggingHandler handler;

  LogConfig.single(
      {String loggerName = "",
      Level level = Level.INFO,
      this.handler = const ConsoleHandler()})
      : logLevels = {loggerName: level};

  LogConfig.root(Level level, {this.handler = const ConsoleHandler()})
      : logLevels = {"": level ?? Level.INFO};

  LogConfig(
      {this.logLevels = const <String, Level>{"": Level.INFO},
      this.handler = const ConsoleHandler()});
}

abstract class LoggingHandler {
  /// Outputs logs to the console, eg stdout
  factory LoggingHandler.console() => const ConsoleHandler();

  /// Outputs logs using [dart:developer] log function
  factory LoggingHandler.dev() => DevLogger();

  const LoggingHandler();
  void log(LogRecord record);

  StreamSubscription<LogRecord> listenTo(Logger logger) {
    return logger.onRecord.listen((record) {
      if (logger.level <= record.level) {
        this.log(record);
      }
    });
  }
}

class LoggerState {
  final Logger logger;
  final LoggingHandler handler;
  final StreamSubscription<LogRecord> subscription;

  LoggerState(this.logger, this.handler)
      : subscription = handler.listenTo(logger);
}

final _loggers = <String, LoggerState>{};

class ConsoleHandler extends LoggingHandler {
  const ConsoleHandler();

  @override
  void log(LogRecord record) {
    logToConsole(record);
  }
}

class DevLogger extends LoggingHandler {
  var _sequence = 0;

  @override
  void log(LogRecord record) {
    _sequence++;
    dev.log(
      record.message,
      time: record.time,
      sequenceNumber: _sequence,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}

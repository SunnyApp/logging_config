library logging_config;

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:isolate';

import 'package:isolate_service/isolate_service.dart';
import 'package:logging/logging.dart';

/// Logging stream consumer
typedef Logging = void Function(LogRecord record);

FutureOr _configureLoggingIsolate(final dynamic p) async {
  if (p is LogConfig) return await configureLogging(p);
}

final StreamController<LogConfig> _configStream = StreamController<LogConfig>();
Stream<LogConfig> get onLogConfigured => _configStream.stream;

/// Configures a single logger - isolate friendly
FutureOr configureLogging(LogConfig config) async {
  _configStream.add(config);
  print("[${Isolate.current.debugName}] Setting logger ${config.name} "
      "to level ${config.level} "
      "using handler: ${config.handler}");
  RunnerFactory.global.addIsolateInitializer(_configureLoggingIsolate, config);

  final existing = _loggers[config.loggerName];
  hierarchicalLoggingEnabled = true;
  if (existing == null) {
    _loggers.putIfAbsent(config.loggerName, () {
      final logger = Logger(config.loggerName);
      logger.level = config.level;
      return LoggerState(logger, config.handler);
    });
  } else {
    existing.logger.level = config.level;
    existing.subscription.cancel();
    _loggers[config.loggerName] = LoggerState(existing.logger, config.handler);
  }
}

class LogConfig {
  final String loggerName;
  final Level level;
  final LoggingHandler handler;

  LogConfig({this.loggerName = "", this.level = Level.INFO, this.handler = const _ConsoleHandler()});

  String get name {
    if (loggerName.isEmpty) return "root";
    return loggerName;
  }
}

abstract class LoggingHandler {
  factory LoggingHandler.console() => const _ConsoleHandler();
  factory LoggingHandler.dev() => _DevLogger();

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

  LoggerState(this.logger, this.handler) : subscription = handler.listenTo(logger);
}

final _loggers = <String, LoggerState>{};

class _ConsoleHandler extends LoggingHandler {
  const _ConsoleHandler();

  @override
  void log(LogRecord record) {
    print(record?.toString());
  }
}

class _DevLogger extends LoggingHandler {
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

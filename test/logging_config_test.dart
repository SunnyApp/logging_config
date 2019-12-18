import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_service/isolate_service.dart';
import 'package:logging/logging.dart';
import 'package:logging_config/logging_config.dart';

void main() {
  setUpAll(() {
    configureLogging(LogConfig(handler: CapturingLogger()));
  });

  test("logs bubble up to root", () async {
    final logger = Logger("bubbles");
    logger.warning("Hey he hey!!");
    logger.info("FOYOINFO");
    logger.config("Configy");

    await Future.delayed(Duration(seconds: 1));

    expect(logs.length, equals(2));
    expect(logs.first.message, equals("Hey he hey!!"));
  });

  test("logs in isolate work", () async {
    configureLogging(LogConfig(loggerName: "bubbles", level: Level.FINER, handler: CapturingLogger()));
    final runner = RunnerFactory.global.create((isolate) => isolate
      ..debugName = "logTest"
      ..poolSize = 3);
    try {
      await runner.run(logInIsolate, LogRecord(Level.WARNING, "I'm rad", "bubbles"));
      await runner.run(logInIsolate, LogRecord(Level.FINER, "Fine should still show up", "bubbles"));
      await runner.run(logInIsolate, LogRecord(Level.FINER, "No fine except bubbles", "unknown"));
    } finally {
      runner.close();
    }
    await Future.delayed(Duration(seconds: 1));

    expect(logs.length, equals(2));
    expect(logs.first.message, equals("Hey he hey!!"));
  });
}

final logs = <LogRecord>[];

class CapturingLogger extends LoggingHandler {
  @override
  void log(LogRecord record) {
    logs.add(record);
    print(record);
  }
}

FutureOr logInIsolate(LogRecord message) {
  final logger = Logger(message.loggerName);
  logger.log(message.level, "[${Isolate.current.debugName}] ${message.message}", message.error, message.stackTrace,
      message.zone);
}

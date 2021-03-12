import 'package:logging_config/logging_config.dart';

/// The environment for logging.  Could be an isolate, web worker, etc.
abstract class LoggingEnvironment {
  /// The name of the environment, isolate name, or web-worker name
  String get envName;

  void onLogConfig(LogConfig logConfig);

  const factory LoggingEnvironment.defaults() = _LoggingEnvironment;
}

class _LoggingEnvironment implements LoggingEnvironment {
  String get envName => "main";

  const _LoggingEnvironment();

  @override
  void onLogConfig(LogConfig logConfig) {
    // do nothing
  }
}

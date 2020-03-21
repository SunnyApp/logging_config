import 'package:logging/logging.dart';

void logToConsole(LogRecord message) {
  print(message?.toString());
  if (message.stackTrace != null) {
    print(message.stackTrace);
  }
}

@JS() // Sets the context, which in this case is `window`
library console_web; // required library declaration called main, or whatever name you wish

import 'package:js/js.dart';
import 'package:logging/logging.dart'; // Pull in our dependency

@JS('console.info') // This marks the annotated function as a call to `console.log`
external void _info(dynamic str);

@JS('console.error') // This marks the annotated function as a call to `console.log`
external void _error(dynamic str);

@JS('console.debug') // This marks the annotated function as a call to `console.log`
external void _debug(dynamic str);

@JS('console.warn') // This marks the annotated function as a call to `console.log`
external void _warn(dynamic str);

typedef LogMethod = void Function(dynamic message);

void logToConsole(LogRecord message) {
  LogMethod method;
  if (message.level >= Level.SEVERE) {
    method = _error;
  } else if (message.level >= Level.WARNING) {
    method = _warn;
  } else if (message.level >= Level.INFO) {
    method = _info;
  } else {
    method = _debug;
  }
  method("$message");
  if (message.stackTrace != null) {
    method(message.stackTrace);
  }
}

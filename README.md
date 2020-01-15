# logging_config

[![pub package](https://img.shields.io/pub/v/logging_config.svg)](https://pub.dartlang.org/packages/logging_config)
[![Coverage Status](https://coveralls.io/repos/github/SunnyApp/logging_config/badge.svg?branch=master)](https://coveralls.io/github/SunnyApp/logging_config?branch=master)


A plugin that helps you configure loggers from the [logger] package, particularly across spawned isolates.  

### Usage

#### Configure the root logger
```
/// Configure the root logger
configureLogging(LogConfig.root(Level.WARN));

/// Configure the log output handler
/// By default, you can use LoggingHandler.console() or LoggingHandler.dev() or
/// you could implement your own that writes logs to an external system
configureLogging(LogConfig(logLevels: {"myLoggerName": Level.INFO}, 
	handler: LoggingHandler.dev()));
```

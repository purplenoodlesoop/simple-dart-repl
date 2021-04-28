abstract class ReplText {
  // MARK: - Commands
  static const exitCommand = 'exit';
  static const helpCommand = 'help';
  static const resetCommand = 'reset';

  // MARK: - Messages
  static const helpMessage = '''

Avaliable commands:
  help – this message
  exit - exit REPL
  reset - discard current session state
    ''';

  static String goodbyeMessage(Duration elapsed) => 'Use time: $elapsed';

  // MARK: - Functions
  static String prettifyIsolateErrorMessage(Object e) {
  final splitted = e.toString().split('data');
  return splitted
      .sublist(1)
      .map((exceptionMessage) {
    final startingIndex = exceptionMessage.indexOf('Error');
    return '⛔️ ' + exceptionMessage.substring(startingIndex);
  }).reduce((value, element) => '$value\n$element');
}
}

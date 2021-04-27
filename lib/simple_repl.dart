import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:simple_repl/expression_types.dart';

/// TODO
// [] Add errors showing
// [] Add clear command
// [] Fix binding name determining
// [] Remove io expressions
// [x] Add reset command
// [x] Improve performance
// [x] Add Windows support
// [x] Add real REPL behaivor

// MARK: - Commands
const _exitCommand = 'exit';
const _helpCommand = 'help';
const _resetCommand = 'reset';

// MARK: - Messages
const _helpMessage = '''

    Avaliable commands:
    help – this message
    exit - exit REPL
    reset - discard current session state
    ''';

String _goodbyeMessage(Duration elapsed) => '\nUse time: $elapsed';

Future<void> runRepl() async {
  final loginTimeStopWatch = Stopwatch()..start();

  print('Simple Dart REPL');
  print(_helpMessage);

  await _runRepl([]);

  print(_goodbyeMessage(loginTimeStopWatch.elapsed));
}

Future<void> _runRepl(List<String> lines) async {
  stdout.write('(${lines.length}) >>> ');
  final expression = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));

  switch (expression) {
    case _exitCommand:
      return;
    case _helpCommand:
      print(_helpMessage);
      return _runRepl(lines);
    case _resetCommand:
      return _runRepl([]);
    default:
      final currentLines = lines..add(expression);
      print(await _evaluate(currentLines));
      return _runRepl(currentLines);
  }
}

Future<dynamic> _evaluate(List<String> lines) async {
  final port = ReceivePort();
  await Isolate.spawnUri(_getCurrentUri(lines), [], port.sendPort);
  return port.first;
}

Uri _getCurrentUri(List<String> lines) {
  return Uri.dataFromString(_getExecutingCode(lines),
      mimeType: 'application/dart');
}

ExpressionTypes _determineExpressionType(String expression) {
  if (expression.contains('print')) return ExpressionTypes.io;
  if (expression.contains('=')) return ExpressionTypes.binding;
  return ExpressionTypes.regular;
}

String _getCurrentExpressionCode(String expression) {
  switch (_determineExpressionType(expression)) {
    case ExpressionTypes.io:
      return '''
      $expression;
      port.send(null);
      ''';
    case ExpressionTypes.binding:
      final bindingName = expression.split(' ').elementAt(1);
      return '''
      $expression;
      port.send($bindingName);
      ''';
    default:
      return '''
      final last = $expression;
      port.send(last);
      ''';
  }
}

String _getExecutingCode(List<String> lines) {
  final code = lines.sublist(0, lines.length - 1).fold<String>(
      '', (accumulator, currenLine) => '$accumulator    $currenLine;\n');
  final currentExpressionCode = _getCurrentExpressionCode(lines.last);
  return '''
  import "dart:isolate";

  void main(_, SendPort port) {
    $code    
    $currentExpressionCode
  }
  ''';
}

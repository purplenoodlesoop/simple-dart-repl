import 'dart:convert';
import 'dart:io';

/// TODO
/// - Add errors showing
/// - Add clear command
/// - Add reset command
/// - Improve performance
/// - Add Windows support
/// - Add real REPL behaivor

// MARK: - Commands
const _exitCommand = 'exit';
const _helpCommand = 'help';

// MARK: - Messages
const _helpMessage =
    'Avaliable commands:\n help – this message\n exit - exit REPL\n';

String _goodbyeMessage(Duration elapsed) => '\nUse time: $elapsed';

Future<void> runRepl() async {
  final loginTimeStopWatch = Stopwatch()..start();

  print('Simple Dart REPL\n');
  print(_helpMessage);

  await _runRepl(0);
  
  print(_goodbyeMessage(loginTimeStopWatch.elapsed));
}

Future<void> _runRepl(int currentLine) async {
  stdout.write('($currentLine) >>> ');
  final expression = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
  if (!await _processInput(expression, currentLine)) {
    await _cleanUpExpressionDirectory(currentLine);
    return;
  }
  await _runRepl(currentLine + 1);
}

Future<bool> _processInput(String input, int currentLine) async {
  switch (input) {
    case _exitCommand:
      return false;
    case _helpCommand:
      print(_helpMessage);
      return true;
    default:
      print(await _evaluate(input, currentLine));
      return true;
  }
}

Future<String> _getCurrentDirectory() async {
  final ls = await Process.run('pwd', []);
  final deletingDirectoryString = ls.stdout.toString();
  return deletingDirectoryString.substring(
      0, deletingDirectoryString.length - 1);
}

Future<void> _cleanUpExpressionDirectory(int currentLine) async {
  final currentDirectory = await _getCurrentDirectory();
  final deletingDirectory =
      currentDirectory + '/expression/expression_${currentLine - 1}.dart';
  await Process.run('rm', ['-f', deletingDirectory]);
}

Future<String> _evaluate(String input, int currentLine) async {
  await _cleanUpExpressionDirectory(currentLine);
  final expressionPath = await _writeExpressionInFile(input, currentLine);
  final result = await _evaluateCurrentExpression(expressionPath);
  return result;
}

String _getFileText(String input) {
  return 'void main(List<String> arguments){print($input);}';
}

Future<String> _writeExpressionInFile(String input, int currentLine) async {
  final currentDirectory = await _getCurrentDirectory();
  final expressionFilePath =
      currentDirectory + '/expression/expression_$currentLine.dart';
  final expressionFile = await File(expressionFilePath).create();
  await expressionFile.writeAsString(_getFileText(input));
  return expressionFilePath;
}

Future<String> _evaluateCurrentExpression(String expressionPath) async {
  final evaluated = await Process.run('dart', [expressionPath]);
  final result = evaluated.stdout.toString();
  if (result == '') {
    return 'Error occured';
  }
  return result.substring(0, result.length - 1);
}

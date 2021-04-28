import 'dart:io';
import 'dart:isolate';

import 'package:simple_repl/models/execution_result.dart';
import 'package:simple_repl/modules/code_generation.dart';
import 'package:simple_repl/modules/repl_text.dart';
import 'package:simple_repl/modules/terminal.dart';

// TODO
// [ ] Add arrows navigation
// [ ] Add not top-level expressions
// [ ] Add dynamic imports

abstract class Repl {
  static Future<void> runRepl() async {
    final loginTimeStopWatch = Stopwatch()..start();

    print('Simple Dart REPL');
    print(ReplText.helpMessage);

    await _runRepl([]);

    print(ReplText.goodbyeMessage(loginTimeStopWatch.elapsed));
    exit(0);
  }

  static Future<void> _runRepl(List<String> lines) async {
    final expression = Terminal.readInput(lines.length);

    switch (expression) {
      case ReplText.exitCommand:
        return;
      case ReplText.helpCommand:
        print(ReplText.helpMessage);
        return _runRepl(lines);
      case ReplText.resetCommand:
        return _runRepl([]);
      case ReplText.clearCommand:
        Terminal.clearScreen();
        return _runRepl(lines);
      default:
        final currentLines = lines + [expression!];
        final evaluation = await _evaluate(currentLines);
        print(evaluation.result);
        if (evaluation.isError) {
          return _runRepl(lines);
        }
        return _runRepl(currentLines);
    }
  }

  static Future<ExecutionResult> _evaluate(List<String> lines) async {
    final port = ReceivePort();
    try {
      await Isolate.spawnUri(_getIsolateUri(lines), [], port.sendPort);
    } catch (e) {
      return ExecutionResult(
          result: ReplText.prettifyIsolateErrorMessage(e), isError: true);
    }
    return ExecutionResult(result: await port.first);
  }

  static Uri _getIsolateUri(List<String> lines) =>
      Uri.dataFromString(CodeGeneration.getExecutingCode(lines),
          mimeType: 'application/dart');
}

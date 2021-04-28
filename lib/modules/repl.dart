import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:simple_repl/models/execution_result.dart';
import 'package:simple_repl/modules/code_generation.dart';
import 'package:simple_repl/modules/repl_text.dart';

// TODO
// [x] Add propper error handling
// [ ] Add arrows navigation
// [x] Add clear command
// [x] Fix binding name determining
// [x] Remove io expressions
// [ ] Add not top-level expressions
// [ ] Add documentation
// [x] Add reset command
// [x] Improve performance
// [x] Add Windows support
// [x] Add real REPL behaivor
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
    stdout.write('(${lines.length}) >>> ');
    final expression =
        stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);

    switch (expression) {
      case ReplText.exitCommand:
        return;
      case ReplText.helpCommand:
        print(ReplText.helpMessage);
        return _runRepl(lines);
      case ReplText.resetCommand:
        return _runRepl([]);
      case ReplText.clearCommand:
        if (Platform.isWindows) {
          print(Process.runSync('cls', [], runInShell: true).stdout);
        } else {
          print(Process.runSync('clear', [], runInShell: true).stdout);
        }
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

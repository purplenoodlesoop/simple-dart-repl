import 'dart:convert';
import 'dart:io';

abstract class Terminal {
  static String? readInput(int lineNumber) {
    stdout.write('($lineNumber) >>> ');
    return stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
  }

  static void clearScreen() {
    if (Platform.isWindows) {
      print(Process.runSync('cls', [], runInShell: true).stdout);
    } else {
      print(Process.runSync('clear', [], runInShell: true).stdout);
    }
  }
}
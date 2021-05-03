import '../enums/expression_types.dart';

abstract class CodeGeneration {
  static ExpressionTypes _determineExpressionType(String expression) {
    if (expression.contains('print')) return ExpressionTypes.io;
    if (expression.contains('=')) return ExpressionTypes.binding;
    return ExpressionTypes.regular;
  }

  static String _getCurrentExpressionCode(String expression) {
    switch (_determineExpressionType(expression)) {
      case ExpressionTypes.io:
        return '''
      $expression;
      port.send("null");
      ''';
      case ExpressionTypes.binding:
        final splittedExpression =
            expression.split(' ').where((element) => element != ' ').toList();
        final bindingName =
            splittedExpression.elementAt(splittedExpression.indexOf('=') - 1);
        return '''
      $expression;
      port.send($bindingName.toString());
      ''';
      default:
        return '''
      final result = $expression;
      port.send(result.toString());
      ''';
    }
  }

  static String getExecutingCode(List<String> lines) {
    final code = lines
        .sublist(0, lines.length - 1)
        .where((expression) =>
            _determineExpressionType(expression) != ExpressionTypes.io)
        .fold<String>(
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
}

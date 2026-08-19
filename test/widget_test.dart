// test/widget_test.dart
// Basic unit tests for JA PyToCy Converter

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_pytocy/modules/logic.dart';

void main() {
  test('CompilerLogic initialization test', () {
    final logic = CompilerLogic();
    expect(logic.queue.isEmpty, true);
    expect(logic.isCompiling, false);
  });
}

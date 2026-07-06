import 'package:baskit/screens/lists/widgets/color_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xFFE53935);
const _green = Color(0xFF43A047);
const _blue = Color(0xFF1E88E5);
const _availableColors = [_red, _green, _blue];

void main() {
  testWidgets('highlights the selected color with a check icon and border', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(selectedColor: _green, onColorSelected: (_) {}),
    );

    expect(find.text('Choose color'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    final colorOptions = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final selectedOption = colorOptions.singleWhere((option) {
      final decoration = option.decoration! as BoxDecoration;
      final border = decoration.border! as Border;

      return border.top.color == _green;
    });
    final selectedDecoration = selectedOption.decoration! as BoxDecoration;
    final selectedBorder = selectedDecoration.border! as Border;

    expect(selectedBorder.top.width, 2);
    expect(selectedDecoration.color, _green.withValues(alpha: 0.14));
  });

  testWidgets('calls onColorSelected with the tapped color', (tester) async {
    Color? selectedColor;

    await tester.pumpWidget(
      _TestApp(
        selectedColor: _red,
        onColorSelected: (color) => selectedColor = color,
      ),
    );

    await tester.tap(find.byType(GestureDetector).at(2));
    await tester.pumpAndSettle();

    expect(selectedColor, _blue);
  });
}

class _TestApp extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _TestApp({required this.selectedColor, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ColorPickerWidget(
          selectedColor: selectedColor,
          availableColors: _availableColors,
          onColorSelected: onColorSelected,
        ),
      ),
    );
  }
}

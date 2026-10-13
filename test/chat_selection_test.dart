import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/ENG/chatSelection.dart';

void main() {
  testWidgets(
      'selection intercepts media taps so tapping selects without opening',
      (tester) async {
    int opened = 0, selected = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SelectableChatMessage(
                selecting: true,
                selected: false,
                onToggle: () => selected++,
                child: TextButton(
                    onPressed: () => opened++, child: const Text('Photo'))))));
    await tester.tap(find.text('Photo'));
    expect(selected, 1);
    expect(opened, 0);
  });
  testWidgets(
      'normal media remains interactive and toolbar cannot delete empty selection',
      (tester) async {
    int opened = 0, deleted = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            appBar: ChatSelectionBar(
                count: 0,
                onClose: () {},
                onSelectAll: () {},
                onDelete: () => deleted++),
            body: SelectableChatMessage(
                selecting: false,
                selected: false,
                onToggle: () {},
                child: TextButton(
                    onPressed: () => opened++, child: const Text('Photo'))))));
    await tester.tap(find.text('Photo'));
    await tester.tap(find.byTooltip('Delete messages'));
    expect(opened, 1);
    expect(deleted, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('coach selection toolbar fits within its existing page column',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SafeArea(
                child: Column(children: [
      ChatSelectionBar(
          count: 2, onClose: () {}, onSelectAll: () {}, onDelete: () {}),
      const Expanded(child: SizedBox())
    ])))));
    expect(find.text('2 selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

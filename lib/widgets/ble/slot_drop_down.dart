import 'package:flutter/material.dart';

class SlotDropdown extends StatefulWidget {
  const SlotDropdown({super.key, required this.onSelection});

  final void Function(int) onSelection;

  @override
  State<StatefulWidget> createState() {
    return _SlotDropdownState();
  }
}

class _SlotDropdownState extends State<SlotDropdown> {
  int dropDownValue = 1;

  final dropDownItems = [1, 2, 3, 4];

  @override
  void initState() {
    super.initState();
    widget.onSelection(dropDownValue);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
        value: dropDownValue,
        items: dropDownItems
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e.toString()),
              ),
            )
            .toList(),
        onChanged: (newValue) {
          widget.onSelection(newValue!);
          setState(() {
            dropDownValue = newValue;
          });
        });
  }
}

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
    return Container(
      height: 40,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(),
          borderRadius: BorderRadius.circular(10)),
      child: DropdownButton(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        value: dropDownValue,
        items: dropDownItems.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Text(e.toString()),
          );
        }).toList(),
        onChanged: (newValue) {
          widget.onSelection(newValue!);
          setState(() {
            dropDownValue = newValue;
          });
        },
        icon: const Icon(Icons.arrow_drop_down),
        underline: const SizedBox(),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';

class PaperForm extends StatelessWidget {
  PaperForm({this.children, this.padding = 2, this.actionButtons});

  final List<Widget> children;
  final List<Widget> actionButtons;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding: EdgeInsets.all(this.padding),
        child: Column(children: [
          ...this.children,
          ..._buildButtons(),
        ]),
      ),
    );
  }

  List<Widget> _buildButtons() {
    if (this.actionButtons == null) return [Container()];

    return [
      const SizedBox(height: 5),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: this.actionButtons,
      )
    ];
  }
}

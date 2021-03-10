import 'package:flutter/cupertino.dart';
import 'package:flutter_wallet_app/src/theme/light_color.dart';

class PaperValidationSummary extends StatelessWidget {
  PaperValidationSummary(this.errors);
  final List<String> errors;
  @override
  Widget build(BuildContext context) {
    if(errors == null)
      return SizedBox( height: 1);
    else
      return Column(
      children:  this.errors.map((error) => Text(error,style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: LightColor.alertRed))).toList(),
    );
  }
}

import 'package:flutter_wallet_app/src/components/copyButton/copy_button.dart';
import 'package:flutter_wallet_app/src/components/form/paper_input.dart';
import 'package:flutter_wallet_app/src/components/form/paper_validation_summary.dart';
import 'package:flutter_wallet_app/src/components/form/paper_form.dart';
import 'package:flutter_wallet_app/src/components/form/paper_radio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../theme/light_color.dart';
import '../../theme/light_color.dart';

class TransferWalletForm extends HookWidget {
  TransferWalletForm({this.onSend,this.errors});
  final Function(String address,String amount) onSend;
  final List<String> errors;


  @override
  Widget build(BuildContext context) {
    var inputController = useTextEditingController();
    var amountController = useTextEditingController();

    startScan() async {
      final result  = await Navigator.of(context).pushNamed(
        "/qrcode_reader",
        arguments: (scannedAddress) async {
          inputController.text = ('qr scam');
        },
      );

      if(result != null ){
        String check = (result);
        if(check.split(':').length > 1){
          inputController.text = (check.split(':')[1]);
        }else{
          inputController.text = (result);
        }
      }
    }

    void transferFunc(){
      this.onSend(inputController.value.text,amountController.value.text);
      amountController.clear();
    }
    return Center(
      child: Container(
        margin: EdgeInsets.all(5),
          child: PaperForm(
            padding: 8,
            actionButtons: <Widget>[
              IconButton(
                  icon: Icon(Icons.camera_alt), onPressed: () => startScan()),
              RaisedButton(
                textColor: LightColor.lightGrey,
                color: LightColor.navyBlue1,
                child: const Text('Send'),
                onPressed: this.onSend != null
                    ? () => transferFunc()
                    : null,
              )
            ],
            children: <Widget>[
              fieldForm(
                  label: 'Transfer Address',
                  hintText: 'Type address to send ',
                  controller: inputController,
                  amountController:amountController),
            ],
          ),
      ),
    );
  }

  Widget fieldForm({
    String label,
    String hintText,
    TextEditingController controller,
    TextEditingController amountController,
  }) {
    return Column(
      children: <Widget>[
        PaperValidationSummary(errors),
        PaperInput(
          labelText: label,
          hintText: hintText,
          maxLines: 3,
          controller: controller,
          keyboardType: TextInputType.text,
        ),
        PaperInput(
          labelText: 'Amount',
          hintText: 'Input amount to send',
          maxLines: 1,
          controller: amountController,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

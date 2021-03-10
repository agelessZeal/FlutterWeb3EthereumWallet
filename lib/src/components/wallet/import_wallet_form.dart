import 'package:flutter_wallet_app/src/components/copyButton/copy_button.dart';
import 'package:flutter_wallet_app/src/components/form/paper_input.dart';
import 'package:flutter_wallet_app/src/components/form/paper_validation_summary.dart';
import 'package:flutter_wallet_app/src/components/form/paper_form.dart';
import 'package:flutter_wallet_app/src/components/form/paper_radio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// import 'package:qrscan/qrscan.dart' as scanner;
import 'package:web3dart/crypto.dart';



class ImportWalletForm extends HookWidget {
  ImportWalletForm({this.onImport, this.errors});

  final Function(String value) onImport;
  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    var inputController = useTextEditingController();
    var qrcodeKey = useState();

    startScan() async {
     final result  = await Navigator.of(context).pushNamed(
        "/qrcode_reader",
        arguments: (scannedAddress) async {
          qrcodeKey.value = scannedAddress.toString();
          inputController.text = ('qr scam');
        },
      );
      qrcodeKey.value = result;
      inputController.text = (result);
    }

    void importStart(){
      inputController.clear();
      this.onImport(qrcodeKey.value);
    }

    return Center(
      child: Container(
        margin: EdgeInsets.all(5),
        child: PaperForm(
          padding: 5,
          actionButtons: <Widget>[
            IconButton(
                icon: Icon(Icons.camera_alt), onPressed: () => startScan()),
            ElevatedButton(
              child: const Text('Import'),
              onPressed: this.onImport != null
                  ? () => importStart()
                  : null,
            )
          ],
          children: <Widget>[
            fieldForm(
                label: 'Private Key',
                hintText: 'Type your private key',
                controller: inputController),
          ],
        ),
      ),
    );
  }

  Widget fieldForm({
    String label,
    String hintText,
    TextEditingController controller,
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
      ],
    );
  }
}

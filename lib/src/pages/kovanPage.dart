import 'package:flutter/material.dart';
import 'package:flutter_wallet_app/src/components/wallet/transfer_wallet_form.dart';
import 'package:flutter_wallet_app/src/theme/light_color.dart';
import 'package:flutter_wallet_app/src/theme/theme.dart';
import 'package:flutter_wallet_app/src/widgets/balance_card.dart';
import 'package:flutter_wallet_app/src/widgets/bottom_navigation_bar.dart';
import 'package:flutter_wallet_app/src/widgets/title_text.dart';
import 'package:flutter_wallet_app/src/components/form/paper_input.dart';
import 'package:flutter_wallet_app/src/components/form/paper_validation_summary.dart';
import 'package:flutter_wallet_app/src/components/wallet/import_wallet_form.dart';

import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet_core/wallet_core.dart';
import 'package:decimal/decimal.dart';
class KovanPage extends StatefulWidget {
  KovanPage({Key key}) : super(key: key);

  @override
  _KovanPageState createState() => _KovanPageState();
}

class _KovanPageState extends State<KovanPage> {
  Client httpClient;
  Web3Client ethClient;

  String lastTransactionHash;

  List<String> errors = [];
  List<String> transferError = [];
  bool loading;
  String currentBalance = "";
  String walletKey ='';
  String gasPrice = '';

  @override
  void initState() {
    super.initState();
    httpClient = new Client();
    ethClient = new Web3Client(
        "https://mainnet.infura.io/v3/da759afeba0c4ff8b95b0b13e9e174e0",
        httpClient);
    errors = [];
  }

  Future<DeployedContract> loadContract() async {
//     // Or generate a new key randomly
//     var rng = new Random.secure();
//     Credentials credentials = EthPrivateKey.createRandom(rng);
//
// // In either way, the library can derive the public key and the address
// // from a private key:
//     var address = await credentials.extractAddress();
//     print(address.hex);

    String abiCode = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0x4fabb145d64652a948d72533023f6e7a623c7c53";

    //BUSD toke contract address in the ether mainnet

    final contract = DeployedContract(ContractAbi.fromJson(abiCode, "MetaCoin"),
        EthereumAddress.fromHex(contractAddress));
    print(contract);
    return contract;
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "33ef6d7ce056743c6b98b08c8e7791d7efca4d505b7f97142f75626cacd4c2e2");

    DeployedContract contract = await loadContract();

    final ethFunction = contract.function(functionName);

    var result = await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: ethFunction,
        parameters: args,
      ),
    );
    return result;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    print('query');
    print(functionName);
    print(contract);
    final ethFunction = contract.function(functionName);
    print(ethFunction);
    final data = await ethClient.call(
        contract: contract, function: ethFunction, params: args);

    print(data);
    return data;
  }

  Future<String> sendCoind(String targetAddressHex, int amount) async {
    EthereumAddress address = EthereumAddress.fromHex(targetAddressHex);
    // uint in smart contract means BigInt for us
    var bigAmount = BigInt.from(amount);
    // sendCoin transaction
    var response = await submit("sendCoin", [address, bigAmount]);
    // hash of the transaction
    return response;
  }

  Future<List<dynamic>> getBalance(String targetAddressHex) async {
    EthereumAddress address = EthereumAddress.fromHex(targetAddressHex);
    print(address);


    List<dynamic> result = await query("getBalance", [address]);
    return result;
  }
  Future<String> onTransfer(String targetAddressHex,String amount) async {
    if(walletKey == ''){
      setState(() {
        transferError = ['Not imported any private key.'];
      });
      return '';
    }

    if(targetAddressHex== null ||(targetAddressHex!=null && targetAddressHex.length< 20)){
      setState(() {
        transferError = ['Invalid Address'];
      });
      return '';
    }

    if(amount == null ||(amount!=null && amount.length == 0)){
      setState(() {
        transferError = ['Amount is empty'];
      });
      return '';
    }
    print(amount);

    if(double.parse(currentBalance) == 0 || double.parse(currentBalance) < double.parse(amount)  ){
      setState(() {
        transferError = ['not sufficient balance.'];
      });
      return '';
    }
    
    try{
      EthereumAddress address = EthereumAddress.fromHex(targetAddressHex);

      var credentials = await ethClient.credentialsFromPrivateKey(walletKey);
      var gas = await ethClient.getGasPrice();

      await ethClient.sendTransaction(
        credentials,
        Transaction(
          to: address,
          gasPrice: gas,
          maxGas: 100000,
          value: EtherAmount.fromUnitAndValue(EtherUnit.ether, double.parse(amount)),
        ),
      );

      setState(() {
        transferError = [];
      });

    }catch(e){
      setState(() {
        errors = [e.toString()];
      });
    }
    return '';
  }

  importWallet(String privateKey) async {
    var gas = await ethClient.getGasPrice();
    if(privateKey== null ||(privateKey!=null && privateKey.length< 20)){
      setState(() {
        errors = ['Invalid key'];
        gasPrice = gas.getValueInUnit(EtherUnit.gwei).toString() + ' gwei';
      });
      return;
    }
    try{
      // a4eee6cee8307a4f81315241fac5f6fb969b04d198e962987fb2362441f192ed
      print('import');
      final private = EthPrivateKey.fromHex(privateKey);
      final address = await private.extractAddress();
      print(address);
      EtherAmount balance = await ethClient.getBalance(address);
      print('balance');
      print(balance.getValueInUnit(EtherUnit.ether));
      setState(() {
        walletKey = privateKey;
        currentBalance = balance.getValueInUnit(EtherUnit.ether).toString();
        errors = null;
        gasPrice = gas.getValueInUnit(EtherUnit.gwei).toString() + ' gwei';
        transferError = [];
      });

    }catch(e){
      setState(() {
        errors = [e.toString()];
        gasPrice = gas.getValueInUnit(EtherUnit.gwei).toString() + ' gwei';
      });
      return;
    }
    // EthPrivateKey credentials = EthPrivateKey.fromHex(
    //     "33ef6d7ce056743c6b98b08c8e7791d7efca4d505b7f97142f75626cacd4c2e2");
  }


  Widget _appBar() {
    return Row(
      children: <Widget>[],
    );
  }

  Widget _operationsWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _icon(Icons.transfer_within_a_station, "Transfer"),
      ],
    );
  }

  Widget _icon(IconData icon, String text) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/transfer');
          },
          child: Container(
            height: 80,
            width: 80,
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      color: Color(0xfff3f3f3),
                      offset: Offset(5, 5),
                      blurRadius: 10)
                ]),
            child: Icon(icon),
          ),
        ),
        Text(text,
            style: GoogleFonts.muli(
                textStyle: Theme.of(context).textTheme.display1,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xff76797e))),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 35),
              _appBar(),
              SizedBox(
                height: 10,
              ),
              TitleText(text: "My wallet"),
              ImportWalletForm(
                  errors: errors,
                  onImport:  (value) async {
                    importWallet(value);
                  }
              ),
              SizedBox(
                height: 20,
              ),
              BalanceCard(balance: currentBalance),
              SizedBox(
                height: 50,
              ),
              TitleText(
                text: "Transfer",
              ),
              Text(
                  'Gas Price: ' + gasPrice,
                  style: GoogleFonts.muli(
                      textStyle: Theme.of(context).textTheme.display1,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff76797e))),
              SizedBox(
                height: 10,
              ),
              TransferWalletForm(
                  errors: transferError,
                  onSend:  (address,amount) async {
                    onTransfer(address,amount);
                  }),
              SizedBox(
                height: 40,
              ),
            ],
          )),
    )));
  }
}

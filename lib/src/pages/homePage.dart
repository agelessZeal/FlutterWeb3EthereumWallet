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

class Network {
  const Network(this.name,this.chainId);
  final String name;
  final int chainId;
}

class Asset {
  const Asset(this.symbol,this.decimal,this.balance);
  final String symbol;
  final int decimal;
  final String balance;
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Client httpClient;
  Web3Client ethClient;

  String lastTransactionHash;

  List<String> errors = [];
  List<String> transferError = [];
  List<Asset> assets = [];
  Asset selectedAsset;

  bool loading;
  String currentBalance = "";
  String walletKey = '';
  EthereumAddress walletAddress;
  String gasPrice = '';
  String tokenBalance;

  DeployedContract gnusContract;

  Network selectedNetwork;
  List<Network> networks = <Network>[
    Network('Mainnet',1),
    Network('Kovan Testnet',42)
  ];

  @override
  void initState() {
    super.initState();
    httpClient = new Client();
    ethClient = new Web3Client(
        "https://mainnet.infura.io/v3/da759afeba0c4ff8b95b0b13e9e174e0",
        httpClient);
    errors = [];
    selectedNetwork = networks.first;
  }

  void changeNetwork(Network network) async {
    print(network.name);
    if(selectedNetwork == null || selectedNetwork.chainId != network.chainId){
      setState(() {
        selectedNetwork = network;
        tokenBalance = null;
        currentBalance = "";
        assets = [];
        selectedAsset = null;
      });
      print(network.chainId);
      if(network.chainId == 1){
        ethClient = new Web3Client(
            "https://mainnet.infura.io/v3/da759afeba0c4ff8b95b0b13e9e174e0",
            httpClient);
        errors = [];
        importWallet(walletKey);
      }else {
        ethClient = new Web3Client(
            "https://kovan.infura.io/v3/da759afeba0c4ff8b95b0b13e9e174e0",
            httpClient);
        errors = [];
        importWallet(walletKey);
      }
    }
  }

  Future<DeployedContract> loadContract() async {

    String abiCode = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0x5a2583a5ac06e742ec79101dba97fab4508fd69c";

    final contract = DeployedContract(ContractAbi.fromJson(abiCode, "GNUS"),
        EthereumAddress.fromHex(contractAddress));
    gnusContract = contract;
    return contract;
  }

  Future<String> submit(String functionName, List<dynamic> args) async {

    EthPrivateKey credentials = EthPrivateKey.fromHex(walletKey);
    DeployedContract contract = await loadContract();

    final ethFunction = contract.function(functionName);

    ethClient = new Web3Client(
        "https://kovan.infura.io/v3/da759afeba0c4ff8b95b0b13e9e174e0",
        httpClient);

    var result = await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: ethFunction,
        parameters: args,
      ),
       chainId: 42,
    );

    return result;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final data = await ethClient.call(
        contract: contract, function: ethFunction, params: args);
    return data;
  }

  Future<String> sendToken(String targetAddressHex, double amount) async {
    EthereumAddress address = EthereumAddress.fromHex(targetAddressHex);
    // uint in smart contract means BigInt for us
    var bigAmount = BigInt.from(amount);
    // sendCoin transaction
    var response = await submit("transfer", [address, bigAmount]);
    await getTokenBalance(walletAddress);
    // hash of the transaction
    return response;
  }

  Future<List<dynamic>> getTokenBalance(EthereumAddress targetAddress) async {

    List<dynamic> result = await query("balanceOf", [targetAddress]);

    String balanceStr =  (result.first / BigInt.from(1000000000000000000)).toString();
    print(balanceStr);
    setState(() {
      tokenBalance  = balanceStr.length > 10 ? balanceStr.substring(0,9):balanceStr;
    });
    // List<dynamic> result1 = await query("symbol", []);
    // print('getTokenBalance symbol query result1');
    return result;
  }

  bool contains(Asset element) {
    for (Asset e in assets) {
      if (e.symbol == element.symbol) return true;
    }
    return false;
  }

  Future<String> onTransfer(String targetAddressHex, String amount) async {

    if (walletKey == '') {
      setState(() {
        transferError = ['Not imported any private key.'];
      });
      return '';
    }

    if (targetAddressHex == null ||
        (targetAddressHex != null && targetAddressHex.length < 20)) {
      setState(() {
        transferError = ['Invalid Address'];
      });
      return '';
    }

    if (amount == null || (amount != null && amount.length == 0)) {
      setState(() {
        transferError = ['Amount is empty'];
      });
      return '';
    }
    print(amount);

    if(selectedAsset != null && selectedAsset.symbol == 'GNUS'){
     await sendToken(targetAddressHex, double.parse(amount)*1000000000000000000);
     return '';
    }

    if (double.parse(currentBalance) == 0 ||
        double.parse(currentBalance) < double.parse(amount)) {
      setState(() {
        transferError = ['not sufficient balance.'];
      });
      return '';
    }

    try {
      EthereumAddress address = EthereumAddress.fromHex(targetAddressHex);

      var credentials = await ethClient.credentialsFromPrivateKey(walletKey);
      var gas = await ethClient.getGasPrice();

      await ethClient.sendTransaction(
        credentials,
        Transaction(
          to: address,
          gasPrice: gas,
          maxGas: 100000,
          value: EtherAmount.fromUnitAndValue(
              EtherUnit.ether, BigInt.from(double.parse(amount))),
        ),
        chainId: selectedNetwork.chainId
      );

      EtherAmount balance = await ethClient.getBalance(walletAddress);

      setState(() {
        currentBalance = balance.getValueInUnit(EtherUnit.ether).toString();
        transferError = [];
      });

    } catch (e) {
      setState(() {
        errors = [e.toString()];
      });
    }
    return '';
  }

  importWallet(String privateKey) async {

    assets = [];

    var gas = await ethClient.getGasPrice();
    if (privateKey == null || (privateKey != null && privateKey.length < 20)) {
      setState(() {
        errors = ['Invalid key'];
        gasPrice = gas.getValueInUnit(EtherUnit.gwei).toString() + ' gwei';
      });
      return;
    }
    try {
      final private = EthPrivateKey.fromHex(privateKey);
      final address = await private.extractAddress();
      EtherAmount balance = await ethClient.getBalance(address);
      Asset asset = new Asset('ETH', 18,  balance.getValueInUnit(EtherUnit.ether).toString());
      setState(() {
        walletKey = privateKey;
        walletAddress = address;
        currentBalance = balance.getValueInUnit(EtherUnit.ether).toString();
        errors = null;
        gasPrice = gas.getValueInUnit(EtherUnit.gwei).toString() + ' gwei';
        transferError = [];
        assets.add(asset);
        selectedAsset = asset;
      });

      if(selectedNetwork != null && selectedNetwork.chainId == 42){
        if(address != null ){
          await this.getTokenBalance(address);
          setState(() {
            assets.add(Asset('GNUS', 18, tokenBalance));
          });
        }
      }
    } catch (e) {
      setState(() {
        errors = [e.toString()];
        gasPrice = gas.getValueInUnit(EtherUnit.gwei).toString() + ' gwei';
      });
      return;
    }
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
              TitleText(text: "My wallet " ),
              DropdownButton<Network>(
                  hint: new Text(selectedNetwork == null ? "Select network" : selectedNetwork.name),
                  value: selectedNetwork,
                  onChanged: (Network newValue) {
                    this.changeNetwork(newValue);
                  },
                  items: networks.map((Network net) {
                    return new DropdownMenuItem<Network>(
                      value: net,
                      child: new Text(
                        net.name,
                        style: new TextStyle(color: Colors.black87),
                      ),
                    );
                  }).toList(),
                ),
              ImportWalletForm(
                  errors: errors,
                  onImport: (value) async {
                    importWallet(value);
                  }),
              SizedBox(
                height: 20,
              ),
              BalanceCard(balance: currentBalance,tokenBalance: tokenBalance),
              SizedBox(
                height: 50,
              ),
              TitleText(
                text: "Transfer",
              ),
              Text('Gas Price: ' + gasPrice,
                  style: GoogleFonts.muli(
                      textStyle: Theme.of(context).textTheme.display1,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff76797e))),
              SizedBox(
                height: 10,
              ),
              DropdownButton<Asset>(
                hint: new Text(selectedAsset == null ? "Select asset" : selectedAsset.symbol),
                value: selectedAsset,
                onChanged: (Asset newValue) {
                  setState(() {
                    selectedAsset = newValue;
                  });
                 },
                items: assets.map((Asset coin) {
                  return new DropdownMenuItem<Asset>(
                    value: coin,
                    child: new Text(
                      coin.symbol,
                      style: new TextStyle(color: Colors.red),
                    ),
                  );
                }).toList(),
              ),
              TransferWalletForm(
                  errors: transferError,
                  onSend: (address, amount) async {
                    onTransfer(address, amount);
                  }),
              SizedBox(
                height: 40,
              ),
            ],
          )),
    )));
  }
}

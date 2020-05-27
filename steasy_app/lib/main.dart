import 'dart:convert' show utf8;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Steasy App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          body: MyBluetoothApp(),
        ));
  }
}

class MyBluetoothApp extends StatefulWidget {
  @override
  MySteasyState createState() => MySteasyState();
}

class MySteasyState extends State<MyBluetoothApp>
    with SingleTickerProviderStateMixin {
  final String serverUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String charUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String steasyDeviceName = "Steasy";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult> scanSubScription;
  List<BluetoothDevice> connectedDevices;
  BluetoothDevice steasyDevice;
  BluetoothCharacteristic steasyCharacteristic;
  String connectionText = "";
  bool isConnected;
  TabController tb;


  @override
  void initState() {
    super.initState();


    FlutterBlue.instance.state.listen((state) {
      if (state == BluetoothState.off) {
        print('----------------------------------');
        print('ALERT THE USER TO TURN ON BLUETOOTH');
        print('DISCONNECT FROM DEVICE AND STOP SCANNING');
        print('----------------------------------');
      } else if (state == BluetoothState.on) {
        print('----------------------------------');
        print('DEVICE-ADAPTER-STATE');
        print(state);
        print('----------------------------------');
        startScan();
      }
    });
  }

  startScan() {
    setState(() {
      connectionText = "---> Start Scanning <---";
      print(connectionText);
    });
    scanSubScription = flutterBlue.scan().listen((scanResult) {
      if (scanResult.device.name.contains(steasyDeviceName)) {
        print('--------------------------');
        print("FOUND DEVICE BY THE NAME");
        print('--------------------------');

        setState(() {
          connectionText = "---> Found target Device <---";
          print(connectionText);
        });

        steasyDevice = scanResult.device;
        steasyDevice.state.listen((deviceState) {
          if (deviceState == BluetoothDeviceState.connected) {
            print("DEVICE IS CONNECTED");
          } else if (deviceState == BluetoothDeviceState.disconnected) {
            print("DEVICE IS DISCONNECTED");
          } else {
            print("DEVICESTATE UNKNOWN");
          }
        });
        connectToDevice();
      }
    }, onDone: () => stopScan());
  }

  stopScan() {
    scanSubScription?.cancel();
    scanSubScription = null;
    print('--------------------------');
    print("STOPPED SCANNING");
    print('--------------------------');
  }

  Future<void> connectToDevice() async {
    if (steasyDevice == null) return;
    print('--------------------------');
    print("FOUNDED DEVICE IS CONNECTING");
    print('--------------------------');
    setState(() {
      connectionText = "---> Device Connecting <---";
      print(connectionText);
    });
    connectedDevices = await flutterBlue.connectedDevices;
    for (BluetoothDevice device in connectedDevices) {
      print(device);
      if (device == steasyDevice) {
        print('ALREADY CONNECTED');
        isConnected = true;
      }
    }
    if (!isConnected) {
      await steasyDevice.connect();
      setState(() {
        connectionText = "---> Device Connected <---";
        isConnected = true;
        print(connectionText);
      });
    }
    discoverServices();
  }

  discoverServices() async {
    if (steasyDevice == null) return;

    List<BluetoothService> services = await steasyDevice.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == serverUUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == charUUID) {
            steasyCharacteristic = characteristic;
            writeData("Hallo, Steasy-Bluetoth-Hardware-Modul");
            setState(() {
              print('--------------------------');
              connectionText = "All Ready with ${steasyDevice.name}";
              print(connectionText);
              print('--------------------------');
            });
          }
        });
      }
    });
  }

  writeData(String data) async {
    if (steasyDevice == null) return;
    print('--------------------------');
    print("MESSAGE SENDED");
    print('--------------------------');

    List<int> bytes = utf8.encode(data);
    await steasyCharacteristic.write(bytes);
  }

  disconnectFromDevice() {
    if (steasyDevice == null) return;

    steasyDevice.disconnect();

    setState(() {
      connectionText = "---> Device Disconnected <---";
      isConnected = false;
      print(connectionText);
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hi, did you already eat today?",
          style: TextStyle(fontSize: 25.0),
        ),
        centerTitle: true,
        bottom: TabBar(
          tabs: <Widget>[Text("NEXT MEAL?"), Text("DEVICECONNECTION")],
          labelPadding: EdgeInsets.only(
            bottom: 15.0,
          ),
          labelStyle: TextStyle(fontSize: 15.0),
          unselectedLabelColor: Colors.white60,
          controller: tb,
        )
      ),
      body: StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (c, snapshot) {
          final state = snapshot.data;
          if (state == BluetoothState.off) {
            return BluetoothIsOff(state: state);
          }
          return TabBarView(
            children: <Widget>[
              timer(context),
              deviceConnector(context),             
            ],
            controller: tb,
          );
        }
      )
    );
  }


    Widget timer(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[

        ],
      ),
    );
  }

  
  Widget deviceConnector(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          
        ],
      ),
    );
  }


}

class BluetoothIsOff extends StatelessWidget {
  const BluetoothIsOff({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            SizedBox(
              height: 30,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
                  style: Theme.of(context).primaryTextTheme.subtitle1.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'To get access to the Steasy-App, please turn on your Bluetooth.',
                  style: Theme.of(context).primaryTextTheme.subtitle1.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

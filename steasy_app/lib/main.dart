import 'dart:convert' show utf8;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(body: MyBluetoothApp(),)
    );
  }
}
class MyBluetoothApp extends StatefulWidget {
  @override
  MySteasyState createState() => MySteasyState();
}

class MySteasyState extends State<MyBluetoothApp> with SingleTickerProviderStateMixin {
  final String serverUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String charUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String targetDeviceName = "Steasy";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult> scanSubScription;
  List<BluetoothDevice> connectedDevices;
  BluetoothDevice steasyDevice;
  BluetoothCharacteristic targetCharacteristic;
  String connectionText = "";
  bool isConnected;


  @override
  void initState() {
    
    super.initState();

    FlutterBlue.instance.state.listen((state) {
      if(state == BluetoothState.off){
        print('----------------------------------');
        print('ALERT THE USER TO TURN ON BLUETOOTH');
        print('DISCONNECT FROM DEVICE AND STOP SCANNING');
        print('----------------------------------');
      }
      else if(state == BluetoothState.on){
        print('----------------------------------');
        print('DEVICE-ADAPTER-STATE');
        print(state);
        print('----------------------------------');
        startScan();
      }
     });
  }

  startScan(){
    setState(() {
      connectionText = "---> Start Scanning <---";
      print(connectionText);
    });
    scanSubScription = flutterBlue.scan().listen((scanResult) {
      if(scanResult.device.name.contains(targetDeviceName)){
        print('--------------------------');
        print("FOUND DEVICE BY THE NAME");
        print('--------------------------');

        setState(() {
          connectionText = "---> Found target Device <---";
          print(connectionText);
        });       

        steasyDevice = scanResult.device;
        steasyDevice.state.listen((deviceState) {
          if(deviceState == BluetoothDeviceState.connected){
            print("DEVICE IS CONNECTED");
          } else if (deviceState == BluetoothDeviceState.disconnected){
            print("DEVICE IS DISCONNECTED");
          } else {
            print("DEVICESTATE UNKNOWN");
          }
         });
         connectToDevice();
      }
     },onDone: () => stopScan());
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
      if(device == steasyDevice){
        print('ALREADY CONNECTED');
        isConnected = true;          
      }
    }
    if (!isConnected){
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
            targetCharacteristic = characteristic;
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
    await targetCharacteristic.write(bytes);
  }




  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("hello"),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

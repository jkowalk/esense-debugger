import 'dart:async';

import 'package:ble_scanner/live_chart.dart';
import 'package:ble_scanner/scan_page.dart';
import 'package:ble_scanner/smoothing_sensor_data.dart';
import 'package:esense_flutter/esense.dart';
import 'package:flutter/material.dart';
import 'package:line_chart/charts/line-chart.widget.dart';
import 'package:line_chart/model/line-chart.model.dart';


import 'models/scanned_device.dart';

class MainPage extends StatefulWidget {
  State<StatefulWidget> createState() => _MainState();
}

class _MainState extends State<MainPage> {
  String selectedDevice = '';
  String selectedDeviceId = '';
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';
  String _button = 'not pressed';
  bool connected = false;

  int _offsetX = 0;
  int _offsetY = 0;
  int _offsetZ = 0;

  int accX = 0;
  int accY = 0;
  int accZ = 0;

  int gyroX = 0;
  int gyroY = 0;
  int gyroZ = 0;


  LiveChart gXchart = LiveChart(100);
  LiveChart gYchart = LiveChart(100);
  LiveChart gZchart = LiveChart(100);
  LiveChart aXchart = LiveChart(100);
  LiveChart aYchart = LiveChart(100);
  LiveChart aZchart = LiveChart(100);


  @override
  void initState() {
    super.initState();
    _listenToESense();
  }

  @override
  void dispose() {
    _pauseListenToSensorEvents();
    ESenseManager.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('eSense Debugger')),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                  child: Text('Connect'),
                  onPressed: () async {
                    _pauseListenToSensorEvents();
                    ESenseManager.disconnect();
                    ScannedDevice device = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ScanPage();
                        },
                      ),
                    );
                    if (selectedDevice == null) selectedDevice = '';
                    else {
                      selectedDevice = device.name;
                      selectedDeviceId = device.id;
                    }
                    if (mounted) {
                      setState(() {});
                    }
                    _connectToESense();
                  }),
              Text(selectedDevice),
              Text(_deviceStatus),
              Text(_button),
              Text('Voltage:        ' + _voltage.toString()),
              Text('Sampling:       ' + sampling.toString()),
              Text('Offset (X,Y,Z): ' + _offsetX.toString() + "   " + _offsetY.toString() + "   " + _offsetZ.toString()),
              RaisedButton(
                  child: Text('Start Sensor'),
                  onPressed: _startListenToSensorEvents
              ),
              RaisedButton(
                  child: Text('Stop Sensor'),
                  onPressed: _pauseListenToSensorEvents
              ),

              // Maybe I have a mistake somewhere,
              // but it seemed like accel and gyro were swapped
              Text('Accel: ' + (gyroX).toString() + "   " + (gyroY).toString() + "   " + (gyroZ).toString()),
              Text('Gyro: ' + (accX).toString() + "   " + (accY).toString() + "   " + (accZ).toString()),
              LineChart(
                width: 390, // Width size of chart
                height: 100, // Height size of chart
                data: gXchart.getData, // The value to the chart
                linePaint: Paint()
                  ..strokeWidth = 3
                  ..style = PaintingStyle.stroke
                  ..color = Colors.black, // Custom paint for the line
                onValuePointer: (LineChartModelCallback x) {
                  print(x.chart.amount);
                },
                showPointer: true,
              ),
              LineChart(
                width: 390, // Width size of chart
                height: 100, // Height size of chart
                data: gYchart.getData, // The value to the chart
                linePaint: Paint()
                  ..strokeWidth = 3
                  ..style = PaintingStyle.stroke
                  ..color = Colors.black, // Custom paint for the line
                onValuePointer: (LineChartModelCallback x) {
                  print(x.chart.amount);
                },
                showPointer: true,
              ),
              LineChart(
                width: 390, // Width size of chart
                height: 100, // Height size of chart
                data: gZchart.getData, // The value to the chart
                linePaint: Paint()
                  ..strokeWidth = 3
                  ..style = PaintingStyle.stroke
                  ..color = Colors.black, // Custom paint for the line
                onValuePointer: (LineChartModelCallback x) {
                  print(x.chart.amount);
                },
                showPointer: true,
              ),
              LineChart(
                width: 390, // Width size of chart
                height: 100, // Height size of chart
                data: aXchart.getData, // The value to the chart
                linePaint: Paint()
                  ..strokeWidth = 3
                  ..style = PaintingStyle.stroke
                  ..color = Colors.black, // Custom paint for the line
                onValuePointer: (LineChartModelCallback x) {
                  print(x.chart.amount);
                },
                showPointer: true,
              ),
              LineChart(
                width: 390, // Width size of chart
                height: 100, // Height size of chart
                data: aYchart.getData, // The value to the chart
                linePaint: Paint()
                  ..strokeWidth = 3
                  ..style = PaintingStyle.stroke
                  ..color = Colors.black, // Custom paint for the line
                onValuePointer: (LineChartModelCallback x) {
                  print(x.chart.amount);
                },
                showPointer: true,
              ),
              LineChart(
                width: 390, // Width size of chart
                height: 100, // Height size of chart
                data: aZchart.getData, // The value to the chart
                linePaint: Paint()
                  ..strokeWidth = 3
                  ..style = PaintingStyle.stroke
                  ..color = Colors.black, // Custom paint for the line
                onValuePointer: (LineChartModelCallback x) {
                  print(x.chart.amount);
                },
                showPointer: true,
              ),
            ],
          ),
        ));
  }

  Future _connectToESense() async {
    print('connecting... connected: $connected');
    print(selectedDevice);
    if (!connected) connected = await ESenseManager.connect(selectedDevice);

    setState(() {
      _deviceStatus = connected ? 'connecting' : 'connection failed';
    });
    _listenToESense();
  }

  Future _listenToESense() async {
    // if you want to get the connection events when connecting,
    // set up the listener BEFORE connecting...
    ESenseManager.connectionEvents.listen((event) {
      print('CONNECTION event: $event');

      // when we're connected to the eSense device, we can start listening to events from it
      if (event.type == ConnectionType.connected) _listenToESenseEvents();

      setState(() {
        connected = false;
        switch (event.type) {
          case ConnectionType.connected:
            _deviceStatus = 'connected';
            connected = true;
            break;
          case ConnectionType.unknown:
            _deviceStatus = 'unknown';
            break;
          case ConnectionType.disconnected:
            _deviceStatus = 'disconnected';
            break;
          case ConnectionType.device_found:
            _deviceStatus = 'device_found';
            break;
          case ConnectionType.device_not_found:
            _deviceStatus = 'device_not_found';
            break;
        }
      });
    });
  }

  void _listenToESenseEvents() async {
    ESenseManager.eSenseEvents.listen((event) {
      print('ESENSE event: $event');

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
            _deviceName = (event as DeviceNameRead).deviceName;
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage;
            break;
          case ButtonEventChanged:
            _button = (event as ButtonEventChanged).pressed
                ? 'pressed'
                : 'not pressed';
            break;
          case AccelerometerOffsetRead:
            _offsetX = (event as AccelerometerOffsetRead).offsetX;
            _offsetY = (event as AccelerometerOffsetRead).offsetY;
            _offsetZ = (event as AccelerometerOffsetRead).offsetZ;
            break;
          case AdvertisementAndConnectionIntervalRead:
            print((event as AdvertisementAndConnectionIntervalRead).toString());
            break;
          case SensorConfigRead:
            print((event as SensorConfigRead).config.toMap().toString());
            break;
          default:
            print(event.type);
        }
      });
    });

    _getESenseProperties();
  }

  void _getESenseProperties() async {
    // get the battery level every 10 secs
    Timer.periodic(
      Duration(seconds: 10),
          (timer) async =>
      (connected) ? await ESenseManager.getBatteryVoltage() : null,
    );

    // wait 2, 3, 4, 5, ... secs before getting the name, offset, etc.
    // it seems like the eSense BTLE interface does NOT like to get called
    // several times in a row -- hence, delays are added in the following calls
    Timer(Duration(seconds: 2),
            () async => await ESenseManager.getDeviceName());
    Timer(Duration(seconds: 3),
            () async => await ESenseManager.getAccelerometerOffset());
    Timer(
        Duration(seconds: 4),
            () async =>
        await ESenseManager.getAdvertisementAndConnectionInterval());
    Timer(Duration(seconds: 5),
            () async => await ESenseManager.getSensorConfig());
  }

  StreamSubscription subscription;
  void _startListenToSensorEvents() async {
    SmoothingSensorData accXSmoothed = SmoothingSensorData(5);
    SmoothingSensorData accYSmoothed = SmoothingSensorData(5);
    SmoothingSensorData accZSmoothed = SmoothingSensorData(5);

    SmoothingSensorData gyroXSmoothed = SmoothingSensorData(5);
    SmoothingSensorData gyroYSmoothed = SmoothingSensorData(5);
    SmoothingSensorData gyroZSmoothed = SmoothingSensorData(5);


    // subscribe to sensor event from the eSense device
    subscription = ESenseManager.sensorEvents.listen((event) {
      //print(event.toString());
      if (this.mounted) {
        //setState(() {

          DateTime now = DateTime.now();

          accXSmoothed.add(event.accel[0]);
          accX = accXSmoothed.getSmoothedValue();
          aXchart.add(now, accX.toDouble());
          accYSmoothed.add(event.accel[1]);
          accY = accYSmoothed.getSmoothedValue();
          aYchart.add(now, accY.toDouble());
          accZSmoothed.add(event.accel[1]);
          accZ = accZSmoothed.getSmoothedValue();
          aZchart.add(now, accZ.toDouble());

          gyroXSmoothed.add(event.gyro[0]);
          gyroX = gyroXSmoothed.getSmoothedValue();
          gXchart.add(now, gyroX.toDouble());
          gyroYSmoothed.add(event.gyro[1]);
          gyroY = gyroYSmoothed.getSmoothedValue();
          gYchart.add(now, gyroY.toDouble());
          gyroZSmoothed.add(event.gyro[2]);
          gyroZ = gyroZSmoothed.getSmoothedValue();
          gZchart.add(now, gyroZ.toDouble());


        setState(() {});

      }
    });
  }

  void _pauseListenToSensorEvents() async {
    subscription.cancel();
    setState(() {
      sampling = false;
    });
  }
}

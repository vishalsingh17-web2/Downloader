import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ReceivePort _port = ReceivePort();
  String status = 'Unknown';
  double progress = 0;

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState(() {
        this.status = status.toString();
        this.progress = progress.toDouble();
      });
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              child: const Text('Download'),
              onPressed: () async {
                final isGranted = await Permission.storage.request();
                if (isGranted == PermissionStatus.granted) {
                  var dir = await getExternalStorageDirectory();
                  var index = dir!.path.indexOf('Android');
                  var path = dir.path.substring(0, index)+"/DCIM";
                  FlutterDownloader.enqueue(
                    url:
                        'https://v.pinimg.com/videos/mc/720p/b1/b2/4d/b1b24d6c301513a527bacf9d627bbab3.mp4',
                    savedDir: path,
                    showNotification: true,
                    fileName: "MyFirstVideo",
                    openFileFromNotification: true,
                  );
                } else {
                  const ScaffoldMessenger(
                    child: SnackBar(content: Text('Permission Denied')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

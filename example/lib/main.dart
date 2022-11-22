import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intel_geti_api/intel_geti_api.dart';
import 'package:intel_geti_ui/intel_geti_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ValueNotifier<bool> appBarOnOffStatus = ValueNotifier(true);
  ValueNotifier<String> modeStatus = ValueNotifier('VIEW');
  StreamController<List<Annotation>> annotationsStatus = StreamController<List<Annotation>>.broadcast();
  StreamController<Annotation> selectedAnnotationStatus = StreamController<Annotation>.broadcast();
  Project project = Project(
    creationTime: DateTime.now(),
    creatorId: '',
    datasets: [Dataset(creationTime: DateTime.now(), id: '', name: '', useForTraining: true)],
    id: '',
    name: '',
    tasks: [TrainableTask(id: '', taskType: 'detection', title: '', labelSchemaId: '', labels: [Label(color: '#ff0000ff', group: '', hotkey: '', id: '', isEmpty: false, name: 'cat')])],
    score: null,
    thumbnail: ''
  );
  late Uint8List imageBytes;


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ByteData>(
      future: NetworkAssetBundle(Uri.parse('https://i.pinimg.com/originals/69/2e/64/692e6421912e29184674dd58ef9f5e18.jpg')).load(''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData){
          return FutureBuilder<ui.Image>(
            future: decodeImageFromList(snapshot.data!.buffer.asUint8List()),
            builder: (context, snapshot1) {
              if (snapshot1.connectionState == ConnectionState.done && snapshot1.hasData){
                Media media = Media(
                  id: '',
                  uploaderId: '',
                  mediaInformation: MediaInformation(displayUrl: '', height: snapshot1.data!.height, width: snapshot1.data!.width),
                  name: '',
                  annotationStatePerTask: {},
                  thumbnail: '',
                  type: 'image',
                  uploadTime: DateTime.now()
                );
                return DetectionAnnotationWidget(
                  imageBytes: snapshot.data!.buffer.asUint8List(),
                  appBarOnOffStatus: appBarOnOffStatus,
                  modeStatus: modeStatus,
                  annotationsStatus: annotationsStatus,
                  selectedAnnotationStatus: selectedAnnotationStatus,
                  project: project,
                  media: media
                );
              }
              return const SizedBox.shrink();
            },
          );
        }
        return const SizedBox.shrink();
      }
    );
  }
}

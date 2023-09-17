import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyHomePage());
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ImagePicker imagePicker;
  File? _image;
  String result = '';

  //TODO ImageLabeler 선언
  dynamic imageLabeler;
  @override
  void initState() {
    // TODO: initState 생성
    super.initState();
    imagePicker = ImagePicker();
    //TODO labeler 초기화
    createLabeler();
  }

  @override
  void dispose() {
    super.dispose();
    imageLabeler.close();
  }

  //TODO 카메라 기능을 사용하여 image capture 기능
  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    _image = File(pickedFile!.path);
    setState(() {
      _image;
      doImageLabeling();
    });
  }

  //TODO gallery 에서 이미지 선택 기능
  _imgFromGallery() async {
    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doImageLabeling();
      });
    }
  }

  //TODO 다운 받은 모델 경로 지정 및 옵션 조절
  createLabeler() async {
    final modelPath = await getModelPath('assets/ml/efficientnet.tflite');
    final options = LocalLabelerOptions(
      confidenceThreshold: 0.1, //분류 정확도 기준치 10%이상 정확도만 나타나게 하는 파라메터
      modelPath: modelPath,
    );
    imageLabeler = ImageLabeler(options: options);
  }

  //모델 파일 경로 및 읽어오는 기능
  Future<String> getModelPath(String asset) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$asset';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  //TODO 이미지 인식 및 라벨링 기능
  doImageLabeling() async {
    result = "";
    final inputImage = InputImage.fromFile(_image!);
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    print(labels);
    for (ImageLabel label in labels) {
      final String text = label.label;
      final int index = label.index;
      final double confidence = label.confidence;
      result += "$text  ${confidence.toStringAsFixed(2)}\n";
    }
    setState(() {
      result;
    });
  }

  //앱 디자인 부분
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('images/SL.jpg'), fit: BoxFit.cover),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  width: 100,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 100),
                  child: Stack(children: <Widget>[
                    Stack(children: <Widget>[
                      Center(
                        child: Image.asset(
                          'images/frame.png',
                          height: 510,
                          width: 500,
                        ),
                      ),
                    ]),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(0, 84, 81, 81),
                            shadowColor: Colors.transparent),
                        onPressed: _imgFromGallery,
                        onLongPress: _imgFromCamera,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: _image != null
                              ? Image.file(
                                  _image!,
                                  width: 335,
                                  height: 495,
                                  fit: BoxFit.fill,
                                )
                              : Container(
                                  width: 340,
                                  height: 330,
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 100,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ]),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Text(
                    result,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

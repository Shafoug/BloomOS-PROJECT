import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DiagnosisRecord {
  final String diagnosis;
  final String recommendation;
  final String imagePath;
  final bool isFileImage;
  final DateTime createdAt;

  DiagnosisRecord({
    required this.diagnosis,
    required this.recommendation,
    required this.imagePath,
    required this.isFileImage,
    required this.createdAt,
  });
}

class ScanScreen extends StatefulWidget {
  final bool isGuest;

  const ScanScreen({super.key, this.isGuest = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  Interpreter? _interpreter;
  List<String> _labels = [];

  bool _modelLoaded = false;
  bool _isAnalyzing = false;

  String _diagnosisResult = 'No diagnosis yet';
  String _diagnosisRecommendation =
      'Choose a leaf image to analyze the plant condition.';

  String? _selectedImagePath;

  static const int inputSize = 224;

  final List<DiagnosisRecord> _history = [];

  bool get _isSignedIn => FirebaseAuth.instance.currentUser != null;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      final labelsData =
      await rootBundle.loadString('assets/models/labels.txt');

      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        _modelLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _diagnosisResult = 'Model failed to load';
        _diagnosisRecommendation = 'Check model.tflite and labels.txt';
      });
    }
  }

  bool _isModelReady() {
    if (!_modelLoaded || _interpreter == null || _labels.isEmpty) {
      setState(() {
        _diagnosisResult = 'Model not ready';
        _diagnosisRecommendation = 'Please wait until the model is loaded.';
      });
      return false;
    }
    return true;
  }

  Future<void> _saveDiagnosisToFirestore({
    required String diagnosis,
    required String recommendation,
    required String imagePath,
    required bool isFileImage,
  }) async {
    if (!_isSignedIn || _uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('diagnoses')
        .add({
      'diagnosis': diagnosis,
      'recommendation': recommendation,
      'imagePath': imagePath,
      'isFileImage': isFileImage,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _pickImageFromCamera() async {
    if (!_isModelReady()) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (picked == null) return;

      setState(() {
        _selectedImagePath = picked.path;
        _isAnalyzing = true;
        _diagnosisResult = 'Analyzing...';
        _diagnosisRecommendation = 'Please wait';
      });

      await _runModelFromFile(
        File(picked.path),
        historyImagePath: picked.path,
        historyIsFileImage: true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _diagnosisResult = 'Camera error';
        _diagnosisRecommendation = 'Use Upload Image instead.';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (!_isModelReady()) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (picked == null) return;

      setState(() {
        _selectedImagePath = picked.path;
        _isAnalyzing = true;
        _diagnosisResult = 'Analyzing...';
        _diagnosisRecommendation = 'Please wait';
      });

      await _runModelFromFile(
        File(picked.path),
        historyImagePath: picked.path,
        historyIsFileImage: true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _diagnosisResult = 'Gallery error';
        _diagnosisRecommendation = 'Please try another image.';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _runModelFromFile(
      File imageFile, {
        required String historyImagePath,
        required bool historyIsFileImage,
      }) async {
    try {
      final input = await _preprocessImage(imageFile);

      final outputShape = _interpreter!.getOutputTensor(0).shape;

      final output = List.generate(
        outputShape[0],
            (_) => List.filled(outputShape[1], 0.0),
      );

      _interpreter!.run(input.reshape([1, inputSize, inputSize, 3]), output);

      final scores = List<double>.from(output[0]);

      final healthyIndex =
      _labels.indexWhere((l) => l.toLowerCase() == 'healthy');

      final diseaseIndex =
      _labels.indexWhere((l) => l.toLowerCase() == 'disease');

      final double healthyScore =
      healthyIndex != -1 ? scores[healthyIndex] : 0;

      final double diseaseScore =
      diseaseIndex != -1 ? scores[diseaseIndex] : 0;

      String diagnosis;
      String recommendation;

      if (diseaseScore > 0.60) {
        diagnosis = 'Possible Disease';
        recommendation =
        'Inspect the leaves, isolate the plant if needed, and apply suitable treatment.';
      } else if (healthyScore > 0.60) {
        diagnosis = 'Healthy';
        recommendation =
        'Plant looks healthy. Continue regular monitoring.';
      } else {
        diagnosis = 'Uncertain';
        recommendation =
        'Unclear result. Try scanning a clearer leaf with good lighting.';
      }

      if (!mounted) return;

      if (historyImagePath.isNotEmpty) {
        _history.insert(
          0,
          DiagnosisRecord(
            diagnosis: diagnosis,
            recommendation: recommendation,
            imagePath: historyImagePath,
            isFileImage: historyIsFileImage,
            createdAt: DateTime.now(),
          ),
        );

        if (_isSignedIn) {
          await _saveDiagnosisToFirestore(
            diagnosis: diagnosis,
            recommendation: recommendation,
            imagePath: historyImagePath,
            isFileImage: historyIsFileImage,
          );
        }
      }

      setState(() {
        _diagnosisResult = diagnosis;
        _diagnosisRecommendation = recommendation;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _diagnosisResult = 'Analysis failed';
        _diagnosisRecommendation =
        'Check image format or model compatibility.';
      });
    }
  }

  Future<Float32List> _preprocessImage(File file) async {
    final Uint8List imageBytes = await file.readAsBytes();
    final img.Image? original = img.decodeImage(imageBytes);

    if (original == null) {
      throw Exception('Could not decode image');
    }

    final img.Image resized = img.copyResize(
      original,
      width: inputSize,
      height: inputSize,
    );

    final Float32List input = Float32List(1 * inputSize * inputSize * 3);

    int index = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);

        input[index++] = pixel.r.toDouble();
        input[index++] = pixel.g.toDouble();
        input[index++] = pixel.b.toDouble();
      }
    }

    return input;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }

  Widget _buildPreviewImage() {
    if (_selectedImagePath == null) {
      return const Icon(
        Icons.document_scanner_outlined,
        size: 55,
        color: Colors.green,
      );
    }

    return ClipOval(
      child: Image.file(
        File(_selectedImagePath!),
        fit: BoxFit.cover,
        width: 150,
        height: 150,
      ),
    );
  }

  Widget _buildHistoryImage(DiagnosisRecord item) {
    return Image.file(
      File(item.imagePath),
      width: 72,
      height: 72,
      fit: BoxFit.cover,
    );
  }

  Widget _dataCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDFF3DA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan Plant',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAF7),
                          shape: BoxShape.circle,
                        ),
                        child: _buildPreviewImage(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _modelLoaded
                            ? 'AI Diagnosis Ready'
                            : 'Loading model...',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isAnalyzing
                                    ? null
                                    : _pickImageFromCamera,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Camera'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isAnalyzing
                                    ? null
                                    : _pickImageFromGallery,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade100,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload Image'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _dataCard('Diagnosis', _diagnosisResult),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommendation',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _diagnosisRecommendation,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isAnalyzing)
                        const Column(
                          children: [
                            CircularProgressIndicator(color: Colors.green),
                            SizedBox(height: 10),
                            Text('Analyzing leaf image...'),
                            SizedBox(height: 16),
                          ],
                        ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'History',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_history.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'No diagnosis history yet 🌿',
                            style: TextStyle(fontSize: 15),
                          ),
                        )
                      else
                        ..._history.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildHistoryImage(item),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.diagnosis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.recommendation,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatDate(item.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
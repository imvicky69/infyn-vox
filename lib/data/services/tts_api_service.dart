import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/tts_request.dart';
import '../models/generation_result.dart';

class TTSApiService {
  String baseUrl;
  String? apiKey;

  TTSApiService({this.baseUrl = "http://127.0.0.1:8808", this.apiKey});

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {"status": "offline"};
  }

  Future<Map<String, dynamic>> getModelStatus() async {
    try {
      final uri = Uri.parse('$baseUrl/v1/models/status');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {"status": "unavailable"};
  }

  Future<GenerationResult> generateSpeech(TTSRequest req, {String? voiceName}) async {
    final uri = Uri.parse('$baseUrl/v1/tts/generate');
    final headers = {
      'Content-Type': 'application/json',
      if (apiKey != null && apiKey!.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(req.toJson()),
    ).timeout(const Duration(minutes: 5));

    if (response.statusCode != 200) {
      throw Exception("Generation failed (Status ${response.statusCode}): ${response.body}");
    }

    final duration = double.tryParse(response.headers['x-audio-duration'] ?? '0') ?? 0.0;
    final inferenceTime = double.tryParse(response.headers['x-inference-time'] ?? '0') ?? 0.0;
    final rtf = double.tryParse(response.headers['x-rtf'] ?? '0') ?? 0.0;
    final sampleRate = int.tryParse(response.headers['x-sample-rate'] ?? '48000') ?? 48000;

    // Save audio bytes to local application directory
    final appDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${appDir.path}/VoxStudio/Outputs');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final fileId = const Uuid().v4();
    final filePath = '${outputDir.path}/vox_$fileId.wav';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return GenerationResult(
      id: fileId,
      audioPath: filePath,
      duration: duration > 0 ? duration : 2.5,
      inferenceTime: inferenceTime,
      rtf: rtf,
      sampleRate: sampleRate,
      text: req.text,
      voiceName: voiceName,
      createdAt: DateTime.now(),
    );
  }

  Future<String> transcribeReferenceAudio(String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/v1/audio/transcribe');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? '';
      }
    } catch (_) {}
    return "";
  }
}

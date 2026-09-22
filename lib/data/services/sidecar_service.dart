import 'dart:async';
import 'dart:io';

enum SidecarStatus { stopped, starting, running, error }

class SidecarService {
  Process? _process;
  SidecarStatus _status = SidecarStatus.stopped;
  String? _lastError;
  final List<String> _logs = [];

  SidecarStatus get status => _status;
  String? get lastError => _lastError;
  List<String> get logs => List.unmodifiable(_logs);

  final _statusController = StreamController<SidecarStatus>.broadcast();
  Stream<SidecarStatus> get onStatusChanged => _statusController.stream;

  Future<void> startLocalServer({String host = "127.0.0.1", int port = 8808}) async {
    if (_status == SidecarStatus.running || _status == SidecarStatus.starting) return;

    // Check if server is already running on the port to avoid socket collision
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 600);
      final req = await client.getUrl(Uri.parse("http://$host:$port/health"));
      final res = await req.close();
      if (res.statusCode == 200) {
        _status = SidecarStatus.running;
        _logs.add("[INFO] Backend server is already running on http://$host:$port");
        _statusController.add(_status);
        return;
      }
    } catch (_) {}

    _status = SidecarStatus.starting;
    _statusController.add(_status);
    _logs.clear();

    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final currentDir = Directory.current.path;

      // Search robustly in installation directories and dev trees
      final possiblePaths = [
        '$exeDir/backend/server.py',
        '$exeDir/server.py',
        '$currentDir/backend/server.py',
        'backend/server.py',
        './backend/server.py',
        'c:/Users/rajvi/Repo/Apps/vox_studio/backend/server.py',
      ];

      File? scriptFile;
      for (final p in possiblePaths) {
        final f = File(p);
        if (await f.exists()) {
          scriptFile = f.absolute;
          break;
        }
      }

      if (scriptFile == null) {
        throw Exception("Could not find server.py script path in application directories.");
      }

      _logs.add("[INFO] Launching Python backend from: ${scriptFile.path}");

      // Explicitly set working directory to backend folder to guarantee write permissions
      final workingDir = scriptFile.parent.path;

      _process = await Process.start(
        'python',
        [scriptFile.path, '--host', host, '--port', port.toString()],
        workingDirectory: workingDir,
        runInShell: true,
      );

      _process!.stdout.transform(const SystemEncoding().decoder).listen((data) {
        _logs.add(data.trim());
        if (_logs.length > 200) _logs.removeAt(0);
      });

      _process!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        _logs.add("[STDERR] ${data.trim()}");
        if (_logs.length > 200) _logs.removeAt(0);
      });

      _process!.exitCode.then((code) {
        _status = SidecarStatus.stopped;
        _statusController.add(_status);
        _process = null;
      });

      // Wait 1.5 seconds for startup verification
      await Future.delayed(const Duration(milliseconds: 1500));
      _status = SidecarStatus.running;
      _statusController.add(_status);
    } catch (e) {
      _status = SidecarStatus.error;
      _lastError = e.toString();
      _statusController.add(_status);
    }
  }

  Future<void> stopLocalServer() async {
    if (_process != null) {
      _process!.kill();
      _process = null;
    }
    _status = SidecarStatus.stopped;
    _statusController.add(_status);
  }

  void dispose() {
    stopLocalServer();
    _statusController.close();
  }
}

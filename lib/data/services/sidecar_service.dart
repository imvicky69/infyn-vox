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

    _status = SidecarStatus.starting;
    _statusController.add(_status);
    _logs.clear();

    try {
      // Find server.py script inside the app's backend directory
      final possiblePaths = [
        'backend/server.py',
        './backend/server.py',
        'c:/Users/rajvi/Repo/Apps/vox_studio/backend/server.py',
        'server.py',
      ];

      String? scriptPath;
      for (final p in possiblePaths) {
        if (await File(p).exists()) {
          scriptPath = p;
          break;
        }
      }

      if (scriptPath == null) {
        throw Exception("Could not find server.py script path.");
      }

      _process = await Process.start(
        'python',
        [scriptPath, '--host', host, '--port', port.toString()],
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

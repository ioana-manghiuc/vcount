import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../utils/csv_converter.dart';
import '../utils/backend_service.dart';

class ResultsViewModel extends ChangeNotifier {
  Map<String, dynamic>? _resultsData;
  bool _isLoading = false;
  String? _error;
  int _selectedVideoIndex = 0;

  double _progressPercent = 0;
  int _framesProcessed = 0;
  int _totalFrames = 0;
  http.Client? _sseClient;

  double get progressPercent => _progressPercent;
  int get framesProcessed => _framesProcessed;
  int get totalFrames => _totalFrames;

  void startProgressStream(String processingId) {
    _progressPercent = 0;
    _framesProcessed = 0;
    _totalFrames = 0;
    _sseClient = http.Client();

    final uri = Uri.parse('${BackendService.backendUrl}/progress/$processingId');

    _sseClient!.send(http.Request('GET', uri)).then((response) async {
      await for (final chunk
          in response.stream.transform(const Utf8Decoder())) {
        for (final line in chunk.split('\n')) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;
          try {
            final json =
                jsonDecode(trimmed.substring(5).trim()) as Map<String, dynamic>;
            _progressPercent = (json['percent'] as num?)?.toDouble() ?? 0;
            _framesProcessed = (json['frames_processed'] as num?)?.toInt() ?? 0;
            _totalFrames = (json['total_frames'] as num?)?.toInt() ?? 0;
            notifyListeners();
          } catch (_) {}
        }
      }
    }).catchError((e) {
      debugPrint('SSE stream ended: $e');
    });
  }

  void stopProgressStream() {
    _sseClient?.close();
    _sseClient = null;
  }

  Map<String, dynamic>? get resultsData => _resultsData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedVideoIndex => _selectedVideoIndex;

  bool get isBulk =>
      _resultsData != null &&
      (_resultsData!['metadata'] as Map<String, dynamic>?)?['bulk'] == true;

  List<Map<String, dynamic>> get perVideoResults {
    if (!isBulk) return [];
    final raw = _resultsData!['per_video_results'] as List<dynamic>? ?? [];
    return raw.cast<Map<String, dynamic>>();
  }

  List<String> get videoDropdownLabels {
    return perVideoResults.map((v) {
      final annotatedPath =
          (v['metadata'] as Map<String, dynamic>?)?['annotated_video']
              as String?;
      if (annotatedPath != null) return annotatedPath.split('/').last;
      return v['video_file'] as String? ?? 'Unknown';
    }).toList();
  }

  Map<String, dynamic>? get activeVideoData {
    if (!isBulk) return _resultsData;
    final list = perVideoResults;
    if (list.isEmpty) return null;
    return list[_selectedVideoIndex.clamp(0, list.length - 1)];
  }

  Map<String, dynamic>? get activeResults =>
      activeVideoData?['results'] as Map<String, dynamic>?;

  Map<String, dynamic>? get activeMetadata {
    if (!isBulk) return _resultsData?['metadata'] as Map<String, dynamic>?;
    final perMeta =
        (activeVideoData?['metadata'] as Map<String, dynamic>?) ?? {};
    final topMeta =
        (_resultsData?['metadata'] as Map<String, dynamic>?) ?? {};
    return {...topMeta, ...perMeta};
  }

  String? get activeAnnotatedVideoUrl =>
      activeMetadata?['annotated_video'] as String?;

  Map<String, dynamic> get _activeVideoPayload => {
        'results': activeResults ?? {},
        'metadata': activeMetadata ?? {},
      };

  void setSelectedVideo(int index) {
    if (index == _selectedVideoIndex) return;
    _selectedVideoIndex = index;
    notifyListeners();
  }

  void setResults(Map<String, dynamic> data) {
    _resultsData = data;
    _selectedVideoIndex = 0;
    _error = null;
    stopProgressStream();
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    _resultsData = null;
    stopProgressStream();
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _resultsData = null;
      _selectedVideoIndex = 0;
    } else {
      stopProgressStream();
    }
    notifyListeners();
  }

  Future<bool> downloadResults() async {
    if (_resultsData == null) return false;
    try {
      final payload = isBulk ? _activeVideoPayload : _resultsData!;
      final label = isBulk
          ? (activeMetadata?['video_file'] as String? ?? 'video')
              .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          : null;
      final timestamp = _timestamp();
      final filename = isBulk
          ? 'results_${label}_$timestamp.json'
          : 'vehicle_counting_results_$timestamp.json';

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Results',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (outputPath == null) return false;
      await File(outputPath).writeAsString(jsonEncode(payload));
      return true;
    } catch (e) {
      _error = 'Failed to download results: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> downloadResultsAsCSV() async {
    if (_resultsData == null) return false;
    try {
      final payload = isBulk ? _activeVideoPayload : _resultsData!;
      final label = isBulk
          ? (activeMetadata?['video_file'] as String? ?? 'video')
              .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          : null;
      final timestamp = _timestamp();
      final filename = isBulk
          ? 'results_${label}_$timestamp.csv'
          : 'vehicle_counting_results_$timestamp.csv';

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Results as CSV',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (outputPath == null) return false;
      await File(outputPath).writeAsString(CSVConverter.convertToCSV(payload));
      return true;
    } catch (e) {
      _error = 'Failed to download CSV: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> downloadAllResults() async {
    if (_resultsData == null) return false;
    try {
      final timestamp = _timestamp();
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save All Results',
        fileName: 'bulk_results_$timestamp.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (outputPath == null) return false;
      await File(outputPath).writeAsString(jsonEncode(_resultsData));
      return true;
    } catch (e) {
      _error = 'Failed to download all results: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> downloadAllResultsAsCSV() async {
    if (_resultsData == null) return false;
    try {
      final timestamp = _timestamp();
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save All Results as CSV',
        fileName: 'bulk_results_$timestamp.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (outputPath == null) return false;
      await File(outputPath)
          .writeAsString(CSVConverter.convertToCSV(_resultsData!));
      return true;
    } catch (e) {
      _error = 'Failed to download all results: $e';
      notifyListeners();
      return false;
    }
  }

  String _timestamp() =>
      DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];

  void reset() {
    _resultsData = null;
    _isLoading = false;
    _error = null;
    _selectedVideoIndex = 0;
    _progressPercent = 0;
    _framesProcessed = 0;
    _totalFrames = 0;
    stopProgressStream();
    notifyListeners();
  }
}
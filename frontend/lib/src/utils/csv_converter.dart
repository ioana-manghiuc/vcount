class CSVConverter {
  static String convertToCSV(Map<String, dynamic> data) {
    final isBulk =
        (data['metadata'] as Map<String, dynamic>?)?['bulk'] == true;

    return isBulk ? _convertBulkToCSV(data) : _convertSingleToCSV(data);
  }


  static String _convertSingleToCSV(Map<String, dynamic> data) {
    final csv = StringBuffer();
    final metadata = data['metadata'] as Map<String, dynamic>?;
    final results = data['results'] as Map<String, dynamic>?;

    _writeMetadataSection(csv, metadata);
    csv.writeln('');
    _writeCountsSection(csv, results);
    csv.writeln('');
    _writeTotalsSection(csv, results);

    return csv.toString();
  }


  static String _convertBulkToCSV(Map<String, dynamic> data) {
    final csv = StringBuffer();
    final topMeta = data['metadata'] as Map<String, dynamic>?;
    final perVideoResults =
        (data['per_video_results'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final aggregatedResults =
        data['results'] as Map<String, dynamic>?;

    csv.writeln('BULK VEHICLE COUNTING RESULTS - GLOBAL METADATA');
    csv.writeln('');
    if (topMeta != null) {
      csv.writeln(
          'Intersection Name,${_escapeCSV(topMeta['intersection_name'] ?? 'N/A')}');
      csv.writeln('Model,${_escapeCSV(topMeta['model'] ?? 'Unknown')}');
      csv.writeln('Total Videos,${topMeta['video_count'] ?? perVideoResults.length}');
      csv.writeln('Directions Count,${topMeta['directions_count'] ?? '0'}');
      csv.writeln('Start Time,${_escapeCSV(topMeta['start_time'] ?? 'N/A')}');
      csv.writeln('End Time,${_escapeCSV(topMeta['end_time'] ?? 'N/A')}');
    }

    for (int i = 0; i < perVideoResults.length; i++) {
      final vr = perVideoResults[i];
      final status = vr['status'] as String? ?? 'unknown';
      final perMeta = vr['metadata'] as Map<String, dynamic>?;
      final mergedMeta = {
        if (topMeta != null) ...topMeta,
        if (perMeta != null) ...perMeta,
      };
      final results = vr['results'] as Map<String, dynamic>?;

      csv.writeln('');
      csv.writeln('');
      csv.writeln('VIDEO ${i + 1} — ${_escapeCSV(perMeta?['video_file'] ?? 'Unknown')}');
      csv.writeln('Status,$status');
      csv.writeln('');

      if (status == 'ok') {
        _writeMetadataSection(csv, mergedMeta);
        csv.writeln('');
        _writeCountsSection(csv, results);
        csv.writeln('');
        _writeTotalsSection(csv, results);
      } else {
        csv.writeln('Error,${_escapeCSV(vr['error'] as String? ?? 'No details')}');
      }
    }

    csv.writeln('');
    csv.writeln('');
    csv.writeln('AGGREGATED TOTALS — ALL VIDEOS');
    csv.writeln('');
    _writeCountsSection(csv, aggregatedResults);
    csv.writeln('');
    _writeTotalsSection(csv, aggregatedResults);

    return csv.toString();
  }


  static void _writeMetadataSection(
      StringBuffer csv, Map<String, dynamic>? metadata) {
    csv.writeln('METADATA');
    if (metadata == null) return;
    csv.writeln(
        'Intersection Name,${_escapeCSV(metadata['intersection_name'] ?? 'N/A')}');
    csv.writeln(
        'Video File,${_escapeCSV(metadata['video_file'] ?? 'Unknown')}');
    csv.writeln('Model,${_escapeCSV(metadata['model'] ?? 'Unknown')}');
    csv.writeln(
        'Processing Time (seconds),${metadata['processing_time_seconds'] ?? '0'}');
    csv.writeln(
        'Total Frames Processed,${metadata['total_frames_processed'] ?? '0'}');
    csv.writeln(
        'Video Dimensions,${metadata['video_dimensions']?['width'] ?? '0'}x${metadata['video_dimensions']?['height'] ?? '0'}');
    csv.writeln('Start Time,${_escapeCSV(metadata['start_time'] ?? 'N/A')}');
    csv.writeln('End Time,${_escapeCSV(metadata['end_time'] ?? 'N/A')}');
    csv.writeln('Input FPS,${metadata['input_fps'] ?? '0'}');
    csv.writeln('Directions Count,${metadata['directions_count'] ?? '0'}');
  }

  static void _writeCountsSection(
      StringBuffer csv, Map<String, dynamic>? results) {
    csv.writeln('VEHICLE COUNTS BY DIRECTION');
    csv.writeln('Direction,Cars,Bikes,Buses,Trucks,Total');
    if (results == null) return;
    results.forEach((directionId, counts) {
      if (counts is Map<String, dynamic>) {
        final cars = counts['cars'] ?? 0;
        final bikes = counts['bikes'] ?? 0;
        final buses = counts['buses'] ?? 0;
        final trucks = counts['trucks'] ?? 0;
        final total = cars + bikes + buses + trucks;
        csv.writeln(
            '="${_escapeCSV(directionId)}",$cars,$bikes,$buses,$trucks,$total');
      }
    });
  }

  static void _writeTotalsSection(
      StringBuffer csv, Map<String, dynamic>? results) {
    int totalCars = 0;
    int totalBikes = 0;
    int totalBuses = 0;
    int totalTrucks = 0;

    results?.forEach((_, counts) {
      if (counts is Map<String, dynamic>) {
        totalCars += (counts['cars'] as num? ?? 0).toInt();
        totalBikes += (counts['bikes'] as num? ?? 0).toInt();
        totalBuses += (counts['buses'] as num? ?? 0).toInt();
        totalTrucks += (counts['trucks'] as num? ?? 0).toInt();
      }
    });

    final totalAll = totalCars + totalBikes + totalBuses + totalTrucks;

    csv.writeln('SUMMARY TOTALS');
    csv.writeln('Metric,Count');
    csv.writeln('Total Cars,$totalCars');
    csv.writeln('Total Bikes,$totalBikes');
    csv.writeln('Total Buses,$totalBuses');
    csv.writeln('Total Trucks,$totalTrucks');
    csv.writeln('TOTAL ALL VEHICLES,$totalAll');
  }


  static String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
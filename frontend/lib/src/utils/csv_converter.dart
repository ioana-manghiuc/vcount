class CSVConverter {
  static String convertToCSV(Map<String, dynamic> data) {
    final csv = StringBuffer();

    csv.writeln('VEHICLE COUNTING RESULTS - METADATA');
    csv.writeln('');

    final metadata = data['metadata'] as Map<String, dynamic>?;
    if (metadata != null) {
      csv.writeln('Intersection Name,${_escapeCSV(metadata['intersection_name'] ?? 'N/A')}');
      csv.writeln('Video File,${_escapeCSV(metadata['video_file'] ?? 'Unknown')}');
      csv.writeln('Model,${_escapeCSV(metadata['model'] ?? 'Unknown')}');
      csv.writeln('Processing Time (seconds),${metadata['processing_time_seconds'] ?? '0'}');
      csv.writeln('Total Frames Processed,${metadata['total_frames_processed'] ?? '0'}');
      csv.writeln('Video Dimensions,${metadata['video_dimensions']?['width'] ?? '0'}x${metadata['video_dimensions']?['height'] ?? '0'}');
      csv.writeln('Start Time,${_escapeCSV(metadata['start_time'] ?? 'N/A')}');
      csv.writeln('End Time,${_escapeCSV(metadata['end_time'] ?? 'N/A')}');
      csv.writeln('Input FPS,${metadata['input_fps'] ?? '0'}');
      csv.writeln('Processed FPS,${metadata['processed_fps'] ?? '0'}');
      csv.writeln('Directions Count,${metadata['directions_count'] ?? '0'}');
    }

    csv.writeln('');
    csv.writeln('VEHICLE COUNTS BY DIRECTION');
    csv.writeln('');

    csv.writeln('Direction,Cars,Bikes,Buses,Trucks,Total');
    final results = data['results'] as Map<String, dynamic>?;
    if (results != null) {
      results.forEach((directionId, counts) {
        if (counts is Map<String, dynamic>) {
          final cars = counts['cars'] ?? 0;
          final bikes = counts['bikes'] ?? 0;
          final buses = counts['buses'] ?? 0;
          final trucks = counts['trucks'] ?? 0;
          final total = cars + bikes + buses + trucks;

          csv.writeln('="${_escapeCSV(directionId)}",$cars,$bikes,$buses,$trucks,$total');
        }
      });
    }
  
    csv.writeln('');
    csv.writeln('');

    if (results != null) {
      int totalCars = 0;
      int totalBikes = 0;
      int totalBuses = 0;
      int totalTrucks = 0;

      results.forEach((_, counts) {
        if (counts is Map<String, dynamic>) {
          totalCars += (counts['cars'] as num? ?? 0).toInt();
          totalBikes += (counts['bikes'] as num? ?? 0).toInt();
          totalBuses += (counts['buses'] as num? ?? 0).toInt();
          totalTrucks += (counts['trucks'] as num? ?? 0).toInt();
        }
      });

      final totalAll = totalCars + totalBikes + totalBuses + totalTrucks;

      csv.writeln('Metric,Count');
      csv.writeln('Total Cars,$totalCars');
      csv.writeln('Total Bikes,$totalBikes');
      csv.writeln('Total Buses,$totalBuses');
      csv.writeln('Total Trucks,$totalTrucks');
      csv.writeln('TOTAL ALL VEHICLES,$totalAll');
    }

    return csv.toString();
  }
  static String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

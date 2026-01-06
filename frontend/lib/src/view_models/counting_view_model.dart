import '../models/count_result_model.dart';

class CountingViewModel {
  List<CountResultModel> parseCsv(String csv) {
    final lines = csv.trim().split('\n');
    final results = <CountResultModel>[];

    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      results.add(
        CountResultModel(
          directionId: parts[0],
          bikes: int.parse(parts[1]),
          cars: int.parse(parts[2]),
          buses: int.parse(parts[3]),
          trucks: int.parse(parts[4]),
        ),
      );
    }

    return results;
  }
}
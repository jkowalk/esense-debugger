

import 'package:line_chart/model/line-chart.model.dart';

class LiveChart {
  int _size;

  LiveChart(this._size);

  List<LineChartModel> _data = List<LineChartModel>();

  void add(DateTime date, double i) {
    _data.add(LineChartModel(date: date, amount: i));
    if (_data.length > _size) {
      _data.removeAt(0);
    }
  }

  List<LineChartModel> get getData => _data;
}
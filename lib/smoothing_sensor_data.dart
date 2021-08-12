
/// Creates Smoothed Data by taking the average of the last values.

class SmoothingSensorData {
  int _window;
  int _sum = 0;
  SmoothingSensorData(this._window);

  List<int> data = List<int>();

  void add(int i) {
    data.add(i);
    _sum += i;
    if (data.length > _window) {
      _sum -= data[0];
      data.removeAt(0);
    }
  }

  int getSmoothedValue() {
    if(data.length == 0)
      return 0;
    return (_sum / data.length).round();
  }
}
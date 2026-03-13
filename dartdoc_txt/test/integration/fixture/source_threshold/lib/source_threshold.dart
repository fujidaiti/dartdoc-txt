/// A library for testing source code threshold behavior.
library source_threshold;

/// A class with methods of varying sizes for threshold testing.
class ThresholdTest {
  /// A tiny method.
  void tiny() {}

  /// A method with exactly 10 lines body (should be inline at threshold=10).
  String medium() {
    var a = 1;
    var b = 2;
    var c = 3;
    var d = 4;
    var e = 5;
    var f = a + b;
    var g = c + d;
    return '$f$g$e';
  }

  /// A method with more than 10 lines (should get detail page).
  String large() {
    var a = 1;
    var b = 2;
    var c = 3;
    var d = 4;
    var e = 5;
    var f = 6;
    var g = 7;
    var h = a + b;
    var i = c + d;
    var j = e + f;
    return '$h$i$j$g';
  }
}

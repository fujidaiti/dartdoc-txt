/// A class with methods of varying sizes for threshold testing.
class ThresholdTest {
  /// A tiny method.
  void tiny() {}

  /// A method with exactly 10 lines body (should be inline at threshold=10).
  String medium() {
    const a = 1;
    const b = 2;
    const c = 3;
    const d = 4;
    const e = 5;
    const f = a + b;
    const g = c + d;
    return '$f$g$e';
  }

  /// A method with more than 10 lines (should get detail page).
  String large() {
    const a = 1;
    const b = 2;
    const c = 3;
    const d = 4;
    const e = 5;
    const f = 6;
    const g = 7;
    const h = a + b;
    const i = c + d;
    const j = e + f;
    return '$h$i$j$g';
  }
}

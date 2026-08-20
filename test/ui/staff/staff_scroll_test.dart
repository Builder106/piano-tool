import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';

void main() {
  const viewport = 580.0;
  const content = 1400.0;
  const anchor = 0.3 * viewport; // 174

  test('does not scroll while the playhead is left of the anchor', () {
    expect(
      staffScrollOffset(
          playheadX: 0, viewportWidth: viewport, contentWidth: content),
      0,
    );
    expect(
      staffScrollOffset(
          playheadX: anchor - 1, viewportWidth: viewport, contentWidth: content),
      0,
    );
  });

  test('pins the playhead at the anchor through the middle', () {
    expect(
      staffScrollOffset(
          playheadX: 500, viewportWidth: viewport, contentWidth: content),
      closeTo(500 - anchor, 1e-9),
    );
  });

  test('stops when the end of the content reaches the right edge', () {
    expect(
      staffScrollOffset(
          playheadX: 1400, viewportWidth: viewport, contentWidth: content),
      closeTo(content - viewport, 1e-9),
    );
  });

  test('never scrolls when the content is narrower than the viewport', () {
    expect(
      staffScrollOffset(
          playheadX: 300, viewportWidth: viewport, contentWidth: 400),
      0,
    );
  });
}

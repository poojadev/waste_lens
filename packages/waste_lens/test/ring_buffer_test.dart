import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens/waste_lens.dart';

void main() {
  group('RingBuffer', () {
    test('rejects non-positive capacity', () {
      expect(() => RingBuffer<int>(0), throwsA(isA<AssertionError>()));
    });

    test('grows up to capacity then reports full', () {
      final buf = RingBuffer<int>(3);
      expect(buf.length, 0);
      expect(buf.isFull, isFalse);
      expect(buf.latest, isNull);

      buf
        ..add(1)
        ..add(2);
      expect(buf.length, 2);
      expect(buf.isFull, isFalse);
      expect(buf.latest, 2);

      buf.add(3);
      expect(buf.isFull, isTrue);
      expect(buf.toList(), [1, 2, 3]);
    });

    test('overwrites oldest once full, preserving order', () {
      final buf = RingBuffer<int>(3)
        ..add(1)
        ..add(2)
        ..add(3)
        ..add(4)
        ..add(5);
      expect(buf.length, 3);
      expect(buf.toList(), [3, 4, 5]);
      expect(buf.latest, 5);
      expect(buf[0], 3);
      expect(buf[2], 5);
    });

    test('indexing out of range throws', () {
      final buf = RingBuffer<int>(2)..add(1);
      expect(() => buf[1], throwsRangeError);
      expect(() => buf[-1], throwsRangeError);
    });

    test('clear resets length but keeps capacity', () {
      final buf = RingBuffer<int>(2)
        ..add(1)
        ..add(2)
        ..clear();
      expect(buf.length, 0);
      expect(buf.latest, isNull);
      buf.add(9);
      expect(buf.toList(), [9]);
    });
  });
}

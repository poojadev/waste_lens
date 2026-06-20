import 'dart:collection';

/// A fixed-capacity FIFO buffer that overwrites its oldest element once full.
///
/// Used for the rolling series behind the overlay sparklines (RSS, waste rate).
/// Reads are O(1) amortised and iteration yields oldest-to-newest.
class RingBuffer<T> with IterableMixin<T> {
  RingBuffer(this.capacity)
      : assert(capacity > 0, 'capacity must be positive'),
        _store = List<T?>.filled(capacity, null, growable: false);

  /// Maximum number of elements retained.
  final int capacity;

  final List<T?> _store;
  int _start = 0;
  int _count = 0;

  @override
  int get length => _count;

  /// `true` once [capacity] elements have been written.
  bool get isFull => _count == capacity;

  /// The most recently added element, or `null` if empty.
  T? get latest =>
      _count == 0 ? null : _store[(_start + _count - 1) % capacity];

  /// Appends [value], discarding the oldest element when at capacity.
  void add(T value) {
    if (_count < capacity) {
      _store[(_start + _count) % capacity] = value;
      _count++;
    } else {
      _store[_start] = value;
      _start = (_start + 1) % capacity;
    }
  }

  /// The element at [index] in oldest-to-newest order.
  T operator [](int index) {
    if (index < 0 || index >= _count) {
      throw RangeError.index(index, this, 'index', null, _count);
    }
    return _store[(_start + index) % capacity] as T;
  }

  /// Removes all elements without releasing capacity.
  void clear() {
    _store.fillRange(0, capacity, null);
    _start = 0;
    _count = 0;
  }

  @override
  Iterator<T> get iterator => _RingIterator<T>(this);
}

class _RingIterator<T> implements Iterator<T> {
  _RingIterator(this._buffer);

  final RingBuffer<T> _buffer;
  int _index = -1;

  @override
  T get current => _buffer[_index];

  @override
  bool moveNext() => ++_index < _buffer.length;
}

// The BAD case is also caught by Flutter's own prefer_const_constructors during
// `flutter analyze`; silence that so the fixture targets only our rule.
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class ConstCandidates extends StatelessWidget {
  const ConstCandidates({super.key});

  @override
  Widget build(BuildContext context) {
    final bool live = DateTime.now().isUtc; // non-const context
    return Column(
      children: [
        if (live) const SizedBox.shrink(),
        Text('static label'), // BAD: const ctor + const args
        const Text('already const'), // GOOD: already const
        Image.network('https://example.com/a.png', cacheWidth: 10), // GOOD
      ],
    );
  }
}

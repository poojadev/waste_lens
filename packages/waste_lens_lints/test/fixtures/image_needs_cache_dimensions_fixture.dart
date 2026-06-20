import 'package:flutter/material.dart';

class Gallery extends StatelessWidget {
  const Gallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.network('https://example.com/photo.jpg'), // BAD
        Image.network(
          'https://example.com/photo.jpg',
          cacheWidth: 200,
          cacheHeight: 200,
        ), // GOOD
      ],
    );
  }
}

import 'package:flutter/material.dart';

class Leaky extends StatefulWidget {
  const Leaky({super.key});

  @override
  State<Leaky> createState() => _LeakyState();
}

class _LeakyState extends State<Leaky> {
  final TextEditingController controller = TextEditingController(); // BAD

  @override
  Widget build(BuildContext context) => TextField(controller: controller);
}

class Tidy extends StatefulWidget {
  const Tidy({super.key});

  @override
  State<Tidy> createState() => _TidyState();
}

class _TidyState extends State<Tidy> {
  final TextEditingController controller = TextEditingController(); // GOOD

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(controller: controller);
}

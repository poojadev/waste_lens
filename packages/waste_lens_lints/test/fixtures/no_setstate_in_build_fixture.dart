import 'package:flutter/material.dart';

class SetStateInBuild extends StatefulWidget {
  const SetStateInBuild({super.key});

  @override
  State<SetStateInBuild> createState() => _SetStateInBuildState();
}

class _SetStateInBuildState extends State<SetStateInBuild> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    setState(() => _count++); // BAD: setState during build

    return GestureDetector(
      onTap: () => setState(() => _count++), // GOOD: deferred callback
      child: Text('$_count'),
    );
  }
}

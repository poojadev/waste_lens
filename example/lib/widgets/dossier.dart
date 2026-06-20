import 'package:flutter/material.dart';

import '../ledger_theme.dart';

/// A "case file" page: forensic eyebrow, title, blurb, and body content.
class DossierScaffold extends StatelessWidget {
  const DossierScaffold({
    super.key,
    required this.exhibit,
    required this.charge,
    required this.title,
    required this.blurb,
    required this.children,
  });

  /// e.g. "EXHIBIT A".
  final String exhibit;

  /// The sin on trial, e.g. "DEAD REBUILD".
  final String charge;

  final String title;
  final String blurb;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('$exhibit · $charge', style: Ledger.eyebrow),
            const SizedBox(height: 10),
            Text(title, style: Ledger.title),
            const SizedBox(height: 10),
            Text(blurb, style: Ledger.body),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A bordered "interaction zone" where the offence is committed.
class OffenceZone extends StatelessWidget {
  const OffenceZone({super.key, required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Ledger.inkRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Ledger.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: Ledger.eyebrow.copyWith(color: Ledger.paper)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// The signature element: a monospace tally that "stamps" each time the count
/// it watches increases. Respects reduced-motion.
class Docket extends StatefulWidget {
  const Docket({
    super.key,
    required this.listenable,
    required this.selector,
    required this.label,
    this.tone = Ledger.charge,
  });

  /// What to listen to (typically the diagnostics aggregates).
  final Listenable listenable;

  /// Reads the current charge count from [listenable].
  final int Function() selector;

  final String label;
  final Color tone;

  @override
  State<Docket> createState() => _DocketState();
}

class _DocketState extends State<Docket> with SingleTickerProviderStateMixin {
  late final AnimationController _stamp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    lowerBound: 0,
    upperBound: 1,
    value: 1,
  );
  late int _last = widget.selector();

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_onChange);
  }

  void _onChange() {
    final next = widget.selector();
    if (next > _last && !_reducedMotion) {
      _stamp
        ..value = 0
        ..forward();
    }
    if (next != _last && mounted) setState(() => _last = next);
  }

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void dispose() {
    widget.listenable.removeListener(_onChange);
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.selector();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Ledger.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Ledger.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label.toUpperCase(),
              style: Ledger.eyebrow.copyWith(color: Ledger.paper),
            ),
          ),
          ScaleTransition(
            scale: Tween<double>(begin: 1.35, end: 1.0).animate(
              CurvedAnimation(parent: _stamp, curve: Curves.easeOutBack),
            ),
            child: Text(
              '$value',
              style: Ledger.data.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: value > 0 ? widget.tone : Ledger.cleared,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A courtroom-plain action button.
class LedgerButton extends StatelessWidget {
  const LedgerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = Ledger.charge,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color tone;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        filled ? tone : Colors.transparent,
      ),
      foregroundColor: WidgetStatePropertyAll(filled ? Ledger.ink : tone),
      side: WidgetStatePropertyAll(BorderSide(color: tone)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      textStyle: WidgetStatePropertyAll(
        Ledger.data.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    return TextButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

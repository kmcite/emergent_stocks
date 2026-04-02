import 'package:flutter/material.dart';
import 'package:signals/signals_core.dart' as core;
import 'package:signals/signals_flutter.dart';

abstract class UI<T extends Widget> extends StatefulWidget {
  const UI({super.key});

  T build(BuildContext context);

  @override
  State<UI<T>> createState() => _UI<T>();

  void init(BuildContext context) {}
  void dispose() {}
}

class _UI<T extends Widget> extends State<UI<T>> with SignalsMixin {
  late final result = createComputed(
    () {
      return widget.build(context);
    },
  );
  bool _init = true;

  @override
  void reassemble() {
    super.reassemble();
    final target = core.SignalsObserver.instance;
    if (target is core.DevToolsSignalsObserver) {
      target.reassemble();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      result.recompute();
      if (mounted) setState(() {});
      result.value;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) {
      // Called on first build (we do not need to rebuild yet)
      _init = false;
      widget.init(context);
      return;
    }
    result.recompute();
  }

  @override
  void didUpdateWidget(covariant UI<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.build != widget.build) {
      result.recompute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return result.value;
  }

  @override
  void dispose() {
    widget.dispose();
    super.dispose();
  }
}

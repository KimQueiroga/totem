import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityTimeout extends StatefulWidget {
  const InactivityTimeout({
    super.key,
    required this.child,
    required this.onTimeout,
    this.timeout = const Duration(seconds: 60),
  });

  final Widget child;
  final VoidCallback onTimeout;
  final Duration timeout;

  @override
  State<InactivityTimeout> createState() => _InactivityTimeoutState();
}

class _InactivityTimeoutState extends State<InactivityTimeout> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant InactivityTimeout oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.timeout != widget.timeout) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  void _registerActivity() {
    _restartTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registerActivity(),
      onPointerMove: (_) => _registerActivity(),
      onPointerSignal: (_) => _registerActivity(),
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent) {
            _registerActivity();
          }

          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }
}

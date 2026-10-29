import 'package:flutter/material.dart';

/// Owns one initialization attempt at a time and exposes a recoverable failure.
class StartupGate<T> extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.initialize,
    required this.builder,
    this.disposeValue,
  });

  final Future<T> Function() initialize;
  final Widget Function(T) builder;
  final Future<void> Function(T)? disposeValue;

  @override
  State<StartupGate<T>> createState() => _StartupGateState<T>();
}

class _StartupGateState<T> extends State<StartupGate<T>> {
  late Future<T> _initialization;
  bool _handedOff = false;
  bool _initializing = false;

  Future<T> _start() {
    _initializing = true;
    return Future<T>.sync(widget.initialize).whenComplete(() {
      _initializing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _initialization = _start();
  }

  @override
  void dispose() {
    final disposeValue = widget.disposeValue;
    if (!_handedOff && disposeValue != null) {
      _initialization.then<void>(
        disposeValue,
        onError: (Object _, StackTrace _) {},
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        _handedOff = true;
        return widget.builder(snapshot.data as T);
      }
      final failed =
          snapshot.connectionState == ConnectionState.done && snapshot.hasError;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: failed
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Aplikasi belum dapat dimulai. Silakan coba lagi.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              if (_initializing) return;
                              final attempt = _start();
                              setState(() {
                                _initialization = attempt;
                              });
                            },
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}

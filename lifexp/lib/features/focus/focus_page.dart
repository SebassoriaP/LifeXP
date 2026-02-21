import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({
    super.key,
    required this.instanceId,
    required this.title,
    this.minutes = 30,
  });

  final String instanceId;
  final String title;
  final int minutes;

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  Timer? _timer;
  int _remaining = 0;
  bool _started = false;
  bool _starting = false;
  bool _finishing = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _remaining = widget.minutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  Future<void> _start() async {
    if (_started || _starting) return;
    setState(() => _starting = true);

    try {
      final sid = await ref
          .read(focusRepoProvider)
          .startSession(
            instanceId: widget.instanceId,
            plannedSeconds: widget.minutes * 60,
          );
      if (!mounted) return;

      setState(() {
        _sessionId = sid;
        _started = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_remaining <= 0) {
          _timer?.cancel();
          _complete();
          return;
        }
        setState(() => _remaining -= 1);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start focus session: $e')),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _complete() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    try {
      final sid = _sessionId;
      if (sid != null) {
        await ref
            .read(focusRepoProvider)
            .endSession(sessionId: sid, result: 'completed');
      }

      // award extra XP + complete mission
      await ref
          .read(instancesRepoProvider)
          .completeInstance(widget.instanceId, xp: 20);

      if (!mounted) return;
      ref.invalidate(playerStatsProvider);
      ref.invalidate(todayInstancesProvider);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not finish session: $e')));
      setState(() => _finishing = false);
    }
  }

  Future<void> _abandon() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Abandon focus?'),
        content: const Text('This will end the session as abandoned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    _timer?.cancel();
    final sid = _sessionId;
    try {
      if (sid != null) {
        await ref
            .read(focusRepoProvider)
            .endSession(sessionId: sid, result: 'abandoned');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not abandon session cleanly: $e')),
        );
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final time = _fmt(_remaining);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Focus'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _abandon,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),

                if (!_started)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _starting ? null : _start,
                      child: Text(
                        _starting
                            ? 'Starting...'
                            : 'Start ${widget.minutes} min',
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _finishing ? null : _complete,
                      child: Text(
                        _finishing
                            ? 'Finishing...'
                            : 'Finish now (only if done)',
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                TextButton(onPressed: _abandon, child: const Text('Abandon')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'main.dart' show kMuted, kRed;
import 'ride4free_api.dart';

/// Critérios de avaliação (PT) — média enviada como classificação global.
const ratingCriteriaLabels = <String, String>{
  'pontualidade': 'Pontualidade',
  'simpatia': 'Simpatia',
  'limpeza_veiculo': 'Limpeza do veículo',
  'comunicacao': 'Comunicação',
};

int averageCriteria(Map<String, int> criteria) {
  if (criteria.isEmpty) return 0;
  final sum = criteria.values.fold<int>(0, (a, b) => a + b);
  return (sum / criteria.length).round().clamp(1, 5);
}

class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    required this.onChanged,
    this.size = 32,
  });

  final int stars;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < stars;
        return IconButton(
          padding: EdgeInsets.zero,
          onPressed: () => onChanged(i + 1),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: kRed,
            size: size,
          ),
        );
      }),
    );
  }
}

class StarDisplay extends StatelessWidget {
  const StarDisplay({super.key, required this.stars, this.size = 16});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? kRed : kMuted,
          )),
    );
  }
}

class _StructuredRatingDialog extends StatefulWidget {
  const _StructuredRatingDialog({
    required this.rideId,
    required this.targetName,
    required this.api,
  });

  final int rideId;
  final String targetName;
  final Ride4FreeApi api;

  @override
  State<_StructuredRatingDialog> createState() => _StructuredRatingDialogState();
}

class _StructuredRatingDialogState extends State<_StructuredRatingDialog> {
  late final Map<String, int> _criteria;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _criteria = {for (final k in ratingCriteriaLabels.keys) k: 5};
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.api.rateRideParticipant(widget.rideId, criteria: _criteria);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overall = averageCriteria(_criteria);
    return AlertDialog(
      title: const Text('Avaliar viagem'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Como foi a experiência com ${widget.targetName}?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Classificação global: $overall ★',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kRed, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 16),
            for (final entry in ratingCriteriaLabels.entries) ...[
              Text(
                entry.value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              StarRow(
                stars: _criteria[entry.key] ?? 5,
                size: 26,
                onChanged: (v) => setState(() => _criteria[entry.key] = v),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'A enviar…' : 'Enviar avaliação'),
        ),
      ],
    );
  }
}

/// Diálogo de avaliação pós-viagem com perguntas estruturadas.
Future<bool> showStructuredRatingDialog(
  BuildContext context, {
  required int rideId,
  required String targetName,
  required Ride4FreeApi api,
}) async {
  final submitted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _StructuredRatingDialog(
      rideId: rideId,
      targetName: targetName,
      api: api,
    ),
  );
  return submitted == true;
}

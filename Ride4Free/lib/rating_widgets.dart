// ignore_for_file: deprecated_member_use

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

// 1. RESTAURADA A CLASSE QUE O MAIN.DART PRECISA
class StarDisplay extends StatelessWidget {
  final int stars;
  final double size;
  const StarDisplay({super.key, required this.stars, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}

// 2. A TUA LINHA DE ESTRELAS INTERATIVA (Mas com design melhorado)
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
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? Colors.amber : Colors.grey[300],
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

// 3. RESTAURADA A FUNÇÃO QUE O ACTIVE_RIDE_FLOW PRECISA
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
  return submitted ?? false;
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
  // A tua lógica original de categorias
  final Map<String, int> _criteria = {
    'pontualidade': 5,
    'simpatia': 5,
    'limpeza_veiculo': 5,
    'comunicacao': 5,
  };

  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final overall = averageCriteria(_criteria);
      
      // 4. RESTAURADA A CHAMADA À API CORRETA (rateRideParticipant)
      await widget.api.rateRideParticipant(
        widget.rideId,
        criteria: Map<String, int>.from(_criteria),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliação enviada! Obrigado.')),
        );
        Navigator.pop(context, true);
      }
    } on Ride4FreeApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 409) {
          Navigator.pop(context, true);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.body.isNotEmpty ? e.body : 'Erro ao enviar avaliação.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar avaliação.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overall = averageCriteria(_criteria);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        // O Scroll evita que o ecrã dê erro quando o teclado abre
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Avalia a viagem',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.8),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Diz-nos como correu com ${widget.targetName}.',
                style: const TextStyle(color: kMuted, fontWeight: FontWeight.w500, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Text(
                'Classificação global: $overall ★',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kRed, fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 20),

              // A tua lógica de várias estrelas (mas desenhadas de forma premium)
              for (final entry in ratingCriteriaLabels.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ),
                StarRow(
                  stars: _criteria[entry.key] ?? 5,
                  size: 32,
                  onChanged: (v) => setState(() => _criteria[entry.key] = v),
                ),
                const SizedBox(height: 16),
              ],

            
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMuted,
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: kRed,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'Enviar',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
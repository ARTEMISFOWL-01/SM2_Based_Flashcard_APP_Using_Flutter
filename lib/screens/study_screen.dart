import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flip_card/flip_card.dart';
import '../main.dart';
import '../models/flashcard.dart';
import '../services/supabase_service.dart';

class StudyScreen extends StatefulWidget {
  final String deckId;
  final String deckName;
  final bool ignoreSchedule;
  const StudyScreen(
      {super.key, required this.deckId, required this.deckName, this.ignoreSchedule = false});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with TickerProviderStateMixin {
  final _service = SupabaseService();
  final _flipKey = GlobalKey<FlipCardState>();

  int _index = 0;
  bool _isFlipped = false;
  bool _submitting = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut));
    _scaleCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
        value: 1.0);
    _scaleAnim =
        Tween<double>(begin: 0.92, end: 1.0).animate(_scaleCtrl);
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _rate(
      List<Map<String, dynamic>> cards, SM2Rating rating) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.lightImpact();

    final card = cards[_index];
    await _service.rateCard(
      cardId: card['id'],
      quality: rating.value,
      currentInterval: (card['interval'] as num? ?? 1).toInt(),
      currentEF: (card['ease_factor'] as num? ?? 2.5).toDouble(),
      currentRepetitions: (card['repetitions'] as num? ?? 0).toInt(),
      currentCorrectCount: (card['correct_count'] as num? ?? 0).toInt(),
    );

    // Slide out
    final toRight = rating.value >= 3;
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(toRight ? 1.4 : -1.4, 0),
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn));
    _slideCtrl.reset();
    await _slideCtrl.forward();

    if (_index < cards.length - 1) {
      // Update card data in-place from supabase response
      final result = applySM2(
        quality: rating.value,
        interval: (card['interval'] as num? ?? 1).toInt(),
        easeFactor: (card['ease_factor'] as num? ?? 2.5).toDouble(),
        repetitions: (card['repetitions'] as num? ?? 0).toInt(),
      );
      cards[_index]['interval'] = result.interval;
      cards[_index]['ease_factor'] = result.easeFactor;
      cards[_index]['repetitions'] = result.repetitions;

      _slideAnim = Tween<Offset>(
        begin: Offset(toRight ? -1.4 : 1.4, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
      _slideCtrl.reset();

      setState(() {
        _index++;
        _isFlipped = false;
        _submitting = false;
      });
      _flipKey.currentState?.toggleCard();
      await _slideCtrl.forward();
    } else {
      _showDoneDialog(cards.length);
    }
  }

  void _showDoneDialog(int total) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentGlow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.accent, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              'Session Complete!',
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'You reviewed $total cards.\nSM-2 has scheduled your next session.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(dialogCtx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Back to Deck',
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.getStudyFlashcards(widget.deckId, ignoreSchedule: widget.ignoreSchedule),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.accent)));
          }

          final cards = snap.data!;

          if (cards.isEmpty) {
            return _NothingDueScreen(deckId: widget.deckId, deckName: widget.deckName);
          }

          if (_index >= cards.length) _index = 0;
          final card = cards[_index];
          final recall =
              (card['recall_probability'] as num? ?? 0.5).toDouble();

          return SafeArea(
            child: Column(
              children: [
                // ── App bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.cardBorder),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textSecondary, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.deckName,
                              style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${_index + 1} of ${cards.length} cards',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      _RecallBadge(recall: recall),
                    ],
                  ),
                ),

                // ── Progress bar ────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_index + 1) / cards.length,
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.accent),
                      minHeight: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Flip card ───────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: SlideTransition(
                      position: _slideAnim,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: FlipCard(
                          key: ValueKey('${card['id']}_$_index'),
                          flipOnTouch: true,
                          onFlipDone: (isBack) =>
                              setState(() => _isFlipped = isBack),
                          front: _CardFace(
                            label: 'QUESTION',
                            text: card['question'],
                            subtext: 'Tap to reveal answer',
                            recall: recall,
                            isFront: true,
                          ),
                          back: _CardFace(
                            label: 'ANSWER',
                            text: card['answer'],
                            subtext: 'How did you do?',
                            recall: recall,
                            isFront: false,
                            imageUrl: card['image_url'],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Rating buttons ──────────────────────────────────────
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isFlipped ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_isFlipped,
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Rate your recall',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5),
                            ),
                          ),
                          Row(
                            children: SM2Rating.values
                                .map((r) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        child: _RatingButton(
                                          rating: r,
                                          onTap: () =>
                                              _rate(cards, r),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          // Next review preview
                          _NextReviewHint(
                              card: card, ratings: SM2Rating.values.toList()),
                        ],
                      ),
                    ),
                  ),
                ),

                if (!_isFlipped)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Tap the card to flip',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Card face ──────────────────────────────────────────────────────────────────
class _CardFace extends StatelessWidget {
  final String label;
  final String text;
  final String subtext;
  final double recall;
  final bool isFront;
  final String? imageUrl;

  const _CardFace({
    required this.label,
    required this.text,
    required this.subtext,
    required this.recall,
    required this.isFront,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFront ? AppColors.cardBorder : AppColors.accent.withValues(alpha: 0.4),
          width: isFront ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Label badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isFront
                    ? AppColors.surface
                    : AppColors.accentGlow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isFront
                        ? AppColors.cardBorder
                        : AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isFront ? AppColors.textMuted : AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Main text
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Optional image on back
            if (!isFront &&
                imageUrl != null &&
                imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl!,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],

            const SizedBox(height: 16),

            Text(
              subtext,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rating button ──────────────────────────────────────────────────────────────
class _RatingButton extends StatefulWidget {
  final SM2Rating rating;
  final VoidCallback onTap;
  const _RatingButton({required this.rating, required this.onTap});

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton> {
  bool _pressed = false;

  Color get _color {
    switch (widget.rating) {
      case SM2Rating.again:
        return AppColors.danger;
      case SM2Rating.hard:
        return const Color(0xFFE8742A);
      case SM2Rating.good:
        return AppColors.info;
      case SM2Rating.easy:
        return AppColors.success;
      case SM2Rating.perfect:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _color.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(widget.rating.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                widget.rating.label,
                style: TextStyle(
                    color: _color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recall badge ───────────────────────────────────────────────────────────────
class _RecallBadge extends StatelessWidget {
  final double recall;
  const _RecallBadge({required this.recall});

  @override
  Widget build(BuildContext context) {
    final color = recall >= 0.7
        ? AppColors.success
        : recall >= 0.4
            ? AppColors.warning
            : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.memory_rounded, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            '${(recall * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ── Next review hint ───────────────────────────────────────────────────────────
class _NextReviewHint extends StatelessWidget {
  final Map<String, dynamic> card;
  final List<SM2Rating> ratings;
  const _NextReviewHint({required this.card, required this.ratings});

  @override
  Widget build(BuildContext context) {
    final curInterval = (card['interval'] as num? ?? 1).toInt();
    final curEF = (card['ease_factor'] as num? ?? 2.5).toDouble();
    final curReps = (card['repetitions'] as num? ?? 0).toInt();

    // Show interval preview for Good (middle option)
    final preview = applySM2(
      quality: SM2Rating.good.value,
      interval: curInterval,
      easeFactor: curEF,
      repetitions: curReps,
    );

    return Row(
      children: [
        const Icon(Icons.schedule_rounded,
            color: AppColors.textMuted, size: 12),
        const SizedBox(width: 4),
        Text(
          'Good → next in ${preview.interval} day${preview.interval == 1 ? '' : 's'}  •  EF ${preview.easeFactor.toStringAsFixed(2)}',
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Nothing due screen ─────────────────────────────────────────────────────────
class _NothingDueScreen extends StatelessWidget {
  final String deckId;
  final String deckName;
  const _NothingDueScreen({required this.deckId, required this.deckName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.done_all_rounded,
                    color: AppColors.success, size: 46),
              ),
              const SizedBox(height: 20),
              Text('All Caught Up!',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'No cards are due in "$deckName" right now.\nSM-2 has scheduled your next review session.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentGlow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),

              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudyScreen(
                        deckId: deckId,
                        deckName: deckName,
                        ignoreSchedule: true,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('Study All Cards Anyway',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back to Deck',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

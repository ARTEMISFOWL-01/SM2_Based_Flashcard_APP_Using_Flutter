import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import 'study_screen.dart';
import '../services/supabase_service.dart';

class DeckScreen extends StatefulWidget {
  final String deckId;
  final String deckName;
  const DeckScreen({super.key, required this.deckId, required this.deckName});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  final _service = SupabaseService();
  int _reloadKey = 0;

  @override
  void initState() {
    super.initState();
  }

  void _reload() {
    setState(() => _reloadKey++);
  }

  Future<void> _addCard() async {
    XFile? selectedImage;
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('New Flashcard',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    prefixIcon: Icon(Icons.help_outline_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    prefixIcon: Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final p = ImagePicker();
                    final img = await p.pickImage(
                        source: ImageSource.gallery, imageQuality: 70);
                    if (img != null) setDS(() => selectedImage = img);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedImage == null
                              ? Icons.image_outlined
                              : Icons.check_circle_outline,
                          color: selectedImage == null
                              ? AppColors.textSecondary
                              : AppColors.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedImage == null
                              ? 'Add Image (optional)'
                              : 'Image selected',
                          style: TextStyle(
                            color: selectedImage == null
                                ? AppColors.textSecondary
                                : AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true &&
        qCtrl.text.trim().isNotEmpty &&
        aCtrl.text.trim().isNotEmpty) {
      String? url;
      if (selectedImage != null) {
        url = await _service.uploadFlashcardImage(selectedImage!);
      }
      await _service.addFlashcard(
        deckId: widget.deckId,
        question: qCtrl.text.trim(),
        answer: aCtrl.text.trim(),
        imageUrl: url,
      );
      _reload();
    }
  }

  Future<void> _deleteCard(String id) async {
    await _service.deleteFlashcard(id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary, size: 18),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudyScreen(
                            deckId: widget.deckId,
                            deckName: widget.deckName),
                      ),
                    );
                    _reload();
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text('Study',
                      style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.bg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0),
                  ),
                ),
              )
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.fromLTRB(56, 0, 120, 14),
              title: Text(
                widget.deckName,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(_reloadKey),
              future: _service.getFlashcards(widget.deckId),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const SliverFillRemaining(
                      child: Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                  AppColors.accent))));
                }
                final cards = snap.data!;
                if (cards.isEmpty) {
                  return const SliverFillRemaining(
                      child: _CardEmptyState());
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _FlashcardTile(
                      card: cards[i],
                      onDelete: () => _deleteCard(cards[i]['id']),
                    ),
                    childCount: cards.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onDelete;
  const _FlashcardTile({required this.card, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final recall = (card['recall_probability'] as num? ?? 0.5).toDouble();
    final recallPct = (recall * 100).toStringAsFixed(0);
    final Color recallColor = recall >= 0.7
        ? AppColors.success
        : recall >= 0.4
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const Border(),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: recallColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$recallPct%',
              style: TextStyle(
                  color: recallColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
        title: Text(
          card['question'] ?? '',
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Interval: ${card['interval'] ?? 1}d  •  EF: ${((card['ease_factor'] ?? 2.5) as num).toStringAsFixed(1)}',
          style:
              const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.textMuted, size: 18),
          onPressed: onDelete,
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: 4),
                const Text('Answer',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const SizedBox(height: 6),
                Text(card['answer'] ?? '',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                if (card['image_url'] != null &&
                    (card['image_url'] as String).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      card['image_url'],
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardEmptyState extends StatelessWidget {
  const _CardEmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.style_rounded,
                color: AppColors.accent, size: 36),
          ),
          const SizedBox(height: 14),
          const Text('No cards yet',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Tap + to add your first flashcard',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

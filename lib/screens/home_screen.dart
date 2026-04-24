import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'deck_screen.dart';
import 'analytics_screen.dart';
import '../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = SupabaseService();
  int _reloadKey = 0;

  @override
  void initState() {
    super.initState();
  }

  void _reload() {
    setState(() => _reloadKey++);
  }

  Future<void> _logout() async {
    await _service.supabase.auth.signOut();
  }

  Future<void> _addDeck() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeckDialog(controller: ctrl),
    );
    if (confirmed == true && ctrl.text.trim().isNotEmpty) {
      await _service.addDeck(ctrl.text.trim());
      _reload();
    }
  }

  Future<void> _deleteDeck(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Deck',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "$title"? This removes all its cards too.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteDeck(id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.bg,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1F2E), AppColors.bg],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.accentGlow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bolt_rounded,
                                      color: AppColors.accent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SmartStudy',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _NavBtn(
                                  icon: Icons.bar_chart_rounded,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AnalyticsScreen()),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _NavBtn(
                                    icon: Icons.logout_rounded,
                                    onTap: _logout),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your Decks',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(_reloadKey),
              future: _service.getDecks(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SliverFillRemaining(
                      child: Center(child: _Loader()));
                }
                final decks = snap.data!;
                if (decks.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyState());
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _DeckCard(
                      deck: decks[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeckScreen(
                              deckId: decks[i]['id'],
                              deckName: decks[i]['title'],
                            ),
                          ),
                        );
                        _reload();
                      },
                      onDelete: () =>
                          _deleteDeck(decks[i]['id'], decks[i]['title']),
                    ),
                    childCount: decks.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDeck,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Deck',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
      ),
    );
  }
}

// ── Deck Card ──────────────────────────────────────────────────────────────────
class _DeckCard extends StatelessWidget {
  final Map<String, dynamic> deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _DeckCard(
      {required this.deck, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accentGlow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.layers_rounded,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck['title'] ?? '',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap to study',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.textMuted, size: 20),
                  onPressed: onDelete,
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── New Deck Dialog ────────────────────────────────────────────────────────────
class _DeckDialog extends StatelessWidget {
  final TextEditingController controller;
  const _DeckDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('New Deck',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Deck name…',
          prefixIcon:
              Icon(Icons.layers_rounded, color: AppColors.textMuted),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Create',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(AppColors.accent));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.layers_rounded,
                color: AppColors.accent, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('No decks yet',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Create your first deck to get started',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

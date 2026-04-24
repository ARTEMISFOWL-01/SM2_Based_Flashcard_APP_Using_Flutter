import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';
import '../services/supabase_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: service.getAllFlashcards(),
        builder: (context, snap) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
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
                title: Text(
                  'Analytics',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (!snap.hasData)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.accent))),
                )
              else if (snap.data!.isEmpty)
                const SliverFillRemaining(child: _EmptyAnalytics())
              else
                _AnalyticsBody(cards: snap.data!),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final List<Map<String, dynamic>> cards;
  const _AnalyticsBody({required this.cards});

  @override
  Widget build(BuildContext context) {
    final totalCards = cards.length;
    final avgRecall = cards
            .map((c) => (c['recall_probability'] ?? 0.5) as num)
            .reduce((a, b) => a + b) /
        totalCards;
    final strongCards =
        cards.where((c) => (c['correct_count'] ?? 0) >= 3).length;
    final weakCards =
        cards.where((c) => (c['correct_count'] ?? 0) <= 1).length;
    final avgEF = cards
            .map((c) => (c['ease_factor'] ?? 2.5) as num)
            .reduce((a, b) => a + b) /
        totalCards;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Quick stat row ────────────────────────────────────────────
          Row(
            children: [
              _QuickStat(
                label: 'Total',
                value: '$totalCards',
                icon: Icons.style_rounded,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              _QuickStat(
                label: 'Strong',
                value: '$strongCards',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              _QuickStat(
                label: 'Weak',
                value: '$weakCards',
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Recall + EF cards ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Avg Recall',
                  value: '${(avgRecall * 100).toStringAsFixed(1)}%',
                  subtitle: 'Across all cards',
                  color: AppColors.accent,
                  icon: Icons.memory_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Avg EF',
                  value: avgEF.toStringAsFixed(2),
                  subtitle: 'Ease factor',
                  color: AppColors.info,
                  icon: Icons.speed_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Recall distribution chart ─────────────────────────────────
          _SectionTitle('Recall Distribution'),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: _RecallPieChart(cards: cards),
          ),

          const SizedBox(height: 20),

          // ── Interval distribution bar chart ───────────────────────────
          _SectionTitle('Study Intervals (days)'),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: _IntervalBarChart(cards: cards),
          ),

          const SizedBox(height: 20),

          // ── SM-2 info ─────────────────────────────────────────────────
          _SectionTitle('About SM-2'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'SM-2 (SuperMemo 2) dynamically adjusts intervals based on your performance rating (Again / Hard / Good / Easy / Perfect). '
              'The Ease Factor (EF) starts at 2.5 and rises when you recall well, shrinks when you struggle. '
              'Cards you find hard come back sooner; easy cards are spaced further apart.',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Pie chart ──────────────────────────────────────────────────────────────────
class _RecallPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> cards;
  const _RecallPieChart({required this.cards});

  @override
  Widget build(BuildContext context) {
    final strong = cards.where((c) =>
        (c['recall_probability'] as num? ?? 0.5) >= 0.7).length;
    final medium = cards.where((c) {
      final r = (c['recall_probability'] as num? ?? 0.5).toDouble();
      return r >= 0.4 && r < 0.7;
    }).length;
    final weak = cards.where((c) =>
        (c['recall_probability'] as num? ?? 0.5) < 0.4).length;
    final total = cards.length.toDouble();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 36,
              sections: [
                if (strong > 0)
                  PieChartSectionData(
                    value: strong / total,
                    color: AppColors.success,
                    radius: 48,
                    title: '$strong',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                if (medium > 0)
                  PieChartSectionData(
                    value: medium / total,
                    color: AppColors.warning,
                    radius: 48,
                    title: '$medium',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                if (weak > 0)
                  PieChartSectionData(
                    value: weak / total,
                    color: AppColors.danger,
                    radius: 48,
                    title: '$weak',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Legend('Strong ≥70%', AppColors.success),
              const SizedBox(height: 8),
              _Legend('Medium 40–70%', AppColors.warning),
              const SizedBox(height: 8),
              _Legend('Weak <40%', AppColors.danger),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

// ── Bar chart ──────────────────────────────────────────────────────────────────
class _IntervalBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> cards;
  const _IntervalBarChart({required this.cards});

  @override
  Widget build(BuildContext context) {
    // Bucket intervals: 1, 2–3, 4–7, 8–14, 15+
    final buckets = <String, int>{
      '1': 0,
      '2-3': 0,
      '4-7': 0,
      '8-14': 0,
      '15+': 0,
    };

    for (final c in cards) {
      final iv = (c['interval'] as num? ?? 1).toInt();
      if (iv == 1) {
        buckets['1'] = buckets['1']! + 1;
      } else if (iv <= 3) {
        buckets['2-3'] = buckets['2-3']! + 1;
      } else if (iv <= 7) {
        buckets['4-7'] = buckets['4-7']! + 1;
      } else if (iv <= 14) {
        buckets['8-14'] = buckets['8-14']! + 1;
      } else {
        buckets['15+'] = buckets['15+']! + 1;
      }
    }

    final entries = buckets.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: (maxY + 1).toDouble(),
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.cardBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    entries[idx].key,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                );
              },
              reservedSize: 26,
            ),
          ),
        ),
        barGroups: List.generate(
          entries.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                width: 22,
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (maxY + 1).toDouble(),
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _QuickStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.title,
      required this.value,
      required this.subtitle,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Study some cards first to see analytics.',
          style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}

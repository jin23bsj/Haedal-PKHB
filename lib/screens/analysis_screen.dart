import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart';
import '../providers/record_provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().fetchGoals();
      context.read<RecordProvider>().fetchRecords();
      context.read<RecordProvider>().fetchSummary();
      _fetchComparison();
    });
  }

  void _fetchComparison() {
    context.read<RecordProvider>().fetchComparison(periodDays: 7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('성장 분석')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGrowthSummary(),
            const SizedBox(height: 24),
            _buildFutureMessageCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('🎯 목표 달성률'),
            const SizedBox(height: 12),
            _buildGoalChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('🔗 목표와 연결된 기록'),
            const SizedBox(height: 12),
            _buildGoalLinkedRecordsCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('📈 감정 변화 (최근 14일)'),
            const SizedBox(height: 12),
            _buildEmotionChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('🔄 과거 vs 현재 비교'),
            const SizedBox(height: 12),
            _buildComparisonCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildGrowthSummary() {
    return Consumer<RecordProvider>(
      builder: (context, provider, _) {
        final summary = provider.summary;
        // 로컬 기록으로 직접 계산 (백엔드 summary보다 정확)
        final streak = provider.streakDays;
        final totalDays = provider.totalRecordDays;
        final topActions = (summary['topActions'] as List?)?.take(3).toList() ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✨ 나의 성장 요약',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatItem('🔥', '$streak일', '연속 기록'),
                  const SizedBox(width: 16),
                  _buildStatItem('📅', '$totalDays일', '총 기록일'),
                ],
              ),
              if (topActions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '자주 한 행동',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: topActions.map((action) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        action.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalChart() {
    return Consumer<GoalProvider>(
      builder: (context, provider, _) {
        final goals = provider.goals;
        if (goals.isEmpty) {
          return _buildEmptyCard('목표를 추가하면 달성률을 볼 수 있어요');
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barGroups: goals.take(5).toList().asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.achievementRate * 100,
                            color: AppColors.primary,
                            width: 18,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < goals.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  goals[idx].title.length > 5
                                      ? '${goals[idx].title.substring(0, 5)}...'
                                      : goals[idx].title,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: AppColors.divider,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmotionChart() {
    return Consumer<RecordProvider>(
      builder: (context, provider, _) {
        final records = provider.records
            .where((r) => r.date.isAfter(DateTime.now().subtract(const Duration(days: 14))))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (records.isEmpty) {
          return _buildEmptyCard('기록을 쌓으면 감정 변화를 볼 수 있어요');
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        const emojis = ['😢', '😴', '😐', '😊', '🤩'];
                        final idx = v.toInt() - 1;
                        if (idx >= 0 && idx < emojis.length) {
                          return Text(emojis[idx], style: const TextStyle(fontSize: 12));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: records.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.emotionScore.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryLight.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonCard() {
    return Consumer<RecordProvider>(
      builder: (context, provider, _) {
        final comp = provider.comparison;
        if (comp.isEmpty) {
          return _buildEmptyCard('30일 이상 기록하면 비교 분석을 볼 수 있어요');
        }

        final insight = comp['insight'] ?? '';
        final pastAvg = (comp['pastAvgScore'] ?? 0).toDouble();
        final currentAvg = (comp['currentAvgScore'] ?? 0).toDouble();
        final diff = currentAvg - pastAvg;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCompareItem('이전 30일', pastAvg.toStringAsFixed(1)),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Icon(
                        diff >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: diff >= 0 ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      Text(
                        '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: diff >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  _buildCompareItem('최근 30일', currentAvg.toStringAsFixed(1)),
                ],
              ),
              if (insight.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡 ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          insight,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompareItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }

  // 💌 미래의 나에게 남긴 한마디 카드
  Widget _buildFutureMessageCard() {
    return Consumer<RecordProvider>(
      builder: (context, provider, _) {
        final recordsWithMessage = provider.records
            .where((r) => r.futureMessage.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (recordsWithMessage.isEmpty) {
          return _buildEmptyCard('기록할 때 미래의 나에게 한마디를 남기면 이곳에 모여요.');
        }

        final latest = recordsWithMessage.first;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💌 미래의 나에게 남긴 최근 한마디',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                '"${latest.futureMessage}"',
                style: const TextStyle(
                  fontSize: 15, height: 1.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${latest.date.month}월 ${latest.date.day}일의 내가 남긴 기록이에요.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔗 목표와 연결된 기록 카드
  Widget _buildGoalLinkedRecordsCard() {
    return Consumer2<RecordProvider, GoalProvider>(
      builder: (context, recordProvider, goalProvider, _) {
        final linkedRecords = recordProvider.records
            .where((r) => r.relatedGoalIds.isNotEmpty)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (linkedRecords.isEmpty) {
          return _buildEmptyCard('오늘 기록에서 목표 점검을 남기면 목표와 기록이 연결돼요.');
        }

        // 가장 많이 연결된 목표 찾기
        final goalCounts = <int, int>{};
        for (final r in linkedRecords) {
          for (final id in r.relatedGoalIds) {
            goalCounts[id] = (goalCounts[id] ?? 0) + 1;
          }
        }
        int? topGoalId;
        int topCount = 0;
        for (final e in goalCounts.entries) {
          if (e.value > topCount) { topGoalId = e.key; topCount = e.value; }
        }
        final topGoal = topGoalId == null ? null : _findGoalById(goalProvider.goals, topGoalId);

        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        final recentCount = linkedRecords.where((r) => r.date.isAfter(sevenDaysAgo)).length;
        final trendMsg = recentCount >= 3
            ? '최근 7일 동안 목표와 연결된 행동이 꾸준히 쌓이고 있어요.'
            : recentCount > 0
                ? '최근 7일 동안 목표와 연결된 기록이 ${recentCount}개 쌓였어요.'
                : '최근 기록은 없지만, 이전에 목표와 연결된 기록이 남아 있어요.';

        final recentRecords = linkedRecords.take(3).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '총 ${linkedRecords.length}개의 기록이 목표와 연결됐어요.',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              if (topGoal != null)
                Text('가장 많이 연결된 목표는 "${topGoal.title}"예요.',
                    style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary))
              else
                const Text('목표와 연결된 기록이 쌓이고 있어요.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text(trendMsg, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              const Text('최근 연결 기록',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              ...recentRecords.map((record) {
                final goalTitles = record.relatedGoalIds.map((id) {
                  final g = _findGoalById(goalProvider.goals, id);
                  return g?.title ?? '연결된 목표';
                }).toList();
                final summary = goalTitles.length > 1
                    ? '${goalTitles.first} 외 ${goalTitles.length - 1}개 목표'
                    : goalTitles.isNotEmpty ? goalTitles.first : '연결된 목표';
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${record.date.month}월 ${record.date.day}일 · $summary',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (linkedRecords.length > 3) ...[
                const SizedBox(height: 6),
                Text('외 ${linkedRecords.length - 3}개의 연결 기록이 더 있어요.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ],
          ),
        );
      },
    );
  }

  Goal? _findGoalById(List<Goal> goals, int goalId) {
    try { return goals.firstWhere((g) => g.id == goalId); } catch (_) { return null; }
  }
}

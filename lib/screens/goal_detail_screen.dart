import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/goal.dart';
import '../models/goal_rate_entry.dart';
import '../providers/goal_provider.dart';

class GoalDetailScreen extends StatelessWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<GoalProvider>(
        builder: (context, provider, _) {
          // goalProvider에 저장된 이 목표의 달성률 변화 기록 (최신순)
          final history = goal.id != null
              ? provider.getHistory(goal.id!)
              : <GoalRateEntry>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 목표 요약 카드
                _buildGoalSummaryCard(provider, goal),
                const SizedBox(height: 28),

                // 기록 목록 헤더
                Row(
                  children: [
                    const Text(
                      '📋 날짜별 기록',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${history.length}개',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 기록이 없을 때
                if (history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Column(
                      children: [
                        Text('📝', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 10),
                        Text(
                          '아직 기록이 없어요\n기록 탭에서 이 목표의 달성률을 업데이트해보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildTimeline(history),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalSummaryCard(GoalProvider provider, Goal goal) {
    // provider에서 최신 goal 상태를 가져옴 (달성률이 실시간 반영되도록)
    final liveGoal = goal.id != null
        ? provider.goals.firstWhere((g) => g.id == goal.id, orElse: () => goal)
        : goal;

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final daysLeft = liveGoal.targetDate != null
        ? DateTime(liveGoal.targetDate!.year, liveGoal.targetDate!.month, liveGoal.targetDate!.day)
            .difference(today).inDays
        : null;
    final percent = (liveGoal.achievementRate * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), AppColors.primaryLight.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 + D-day
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  liveGoal.category ?? '기타',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                liveGoal.isCompleted
                    ? '✅ 완료'
                    : daysLeft == null
                        ? '기한 없음'
                        : daysLeft > 0
                            ? 'D-$daysLeft'
                            : daysLeft == 0
                                ? 'D-Day!'
                                : '기간 초과',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: (daysLeft ?? 1) < 0 && !liveGoal.isCompleted
                      ? Colors.red
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 목표 제목
          Text(
            liveGoal.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if ((liveGoal.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              liveGoal.description!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 달성률 바
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '달성률',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: liveGoal.achievementRate,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),

          // 목표 기한
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                liveGoal.targetDate != null
                    ? '목표 기한: ${DateFormat('yyyy년 M월 d일').format(liveGoal.targetDate!)}'
                    : '목표 기한: 미정',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<GoalRateEntry> history) {
    return Column(
      children: history.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final isLast = i == history.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타임라인 선 + 점
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.primaryLight,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                  ],
                ),
              ),

              // 기록 카드
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 날짜
                      Text(
                        DateFormat('M월 d일 (E)', 'ko').format(item.date),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      // 달성률 변화 (변화가 있을 때만)
                      if (item.hasRateChange) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.totalPercent}%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.increasePercent > 0
                                  ? '+${item.increasePercent}% 증가'
                                  : '${item.increasePercent}% 감소',
                              style: TextStyle(
                                fontSize: 12,
                                color: item.increasePercent > 0
                                    ? AppColors.primary
                                    : Colors.red[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // 메모 (있을 때만)
                      if (item.hasMemo) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.memo,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

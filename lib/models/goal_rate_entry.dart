// 목표별 달성률 변화 기록 (기록 탭에서 저장될 때 생성)
class GoalRateEntry {
  final DateTime date;
  final double prevRate;   // 이전 달성률
  final double newRate;    // 변경 후 달성률
  final String memo;       // 목표별 메모 (없으면 빈 문자열)

  GoalRateEntry({
    required this.date,
    required this.prevRate,
    required this.newRate,
    this.memo = '',
  });

  // 달성률이 실제로 변경됐는지
  bool get hasRateChange => (newRate - prevRate).abs() > 0.001;

  // 메모가 있는지
  bool get hasMemo => memo.trim().isNotEmpty;

  // 이 항목을 목표 상세에 표시할지 여부
  bool get shouldShow => hasRateChange || hasMemo;

  // 증가량 (%)
  int get increasePercent => ((newRate - prevRate) * 100).round();

  // 최종 달성률 (%)
  int get totalPercent => (newRate * 100).round();
}

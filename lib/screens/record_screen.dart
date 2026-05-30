import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/daily_record.dart';
import '../models/goal.dart';
import '../providers/record_provider.dart';
import '../providers/goal_provider.dart';

class RecordScreen extends StatefulWidget {
  final DailyRecord? record; // null이면 새 기록, 아니면 수정 모드

  const RecordScreen({super.key, this.record});

  bool get isEditMode => record != null;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  int _selectedEmotionIndex = 2;
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedActions = [];
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _actionInputController = TextEditingController();
  final TextEditingController _futureMessageController = TextEditingController();
  bool _isLoading = false;

  // 목표별 달성률 & 내용 메모
  final Map<int, double> _goalRates = {};
  final Map<int, TextEditingController> _goalMemos = {};

  final List<String> _suggestedActions = [
    '운동', '독서', '공부', '명상', '산책', '요리',
    '친구 만남', '자기개발', '취미 활동', '휴식',
  ];

  @override
  void initState() {
    super.initState();

    // 수정 모드일 때 기존 데이터 불러오기
    final record = widget.record;
    if (record != null) {
      _selectedDate = record.date;
      final emotionIndex = Emotions.list.indexWhere((e) => e['emoji'] == record.emotion);
      if (emotionIndex != -1) _selectedEmotionIndex = emotionIndex;
      _selectedActions.addAll(record.actions);
      _memoController.text = record.memo;
      _futureMessageController.text = record.futureMessage;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().fetchGoals();
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    _actionInputController.dispose();
    _futureMessageController.dispose();
    for (final c in _goalMemos.values) {
      c.dispose();
    }
    super.dispose();
  }

  // 목표 초기화 (provider에서 목표 불러온 후 슬라이더 초기값 설정)
  void _initGoalControllers(List<Goal> goals) {
    for (final goal in goals) {
      if (goal.id != null && !_goalRates.containsKey(goal.id)) {
        _goalRates[goal.id!] = goal.achievementRate;
        _goalMemos[goal.id!] = TextEditingController(
          text: widget.record?.goalProgressMemos[goal.id!] ?? '',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? '기록 수정' : '오늘 기록'),
        leading: widget.isEditMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 (클릭하면 날짜 선택)
            Center(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('yyyy년 M월 d일 (E)', 'ko').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 감정 선택
            _buildSectionTitle('오늘 감정은 어때요?'),
            const SizedBox(height: 14),
            _buildEmotionSelector(),
            const SizedBox(height: 28),

            // 행동 입력
            _buildSectionTitle('오늘 어떤 일을 했나요?'),
            const SizedBox(height: 12),
            _buildActionInput(),
            const SizedBox(height: 10),
            _buildActionChips(),
            const SizedBox(height: 28),

            // ✅ 목표별 점검 섹션
            _buildSectionTitle('🎯 목표 점검'),
            const SizedBox(height: 4),
            const Text(
              '오늘 각 목표에 얼마나 기여했는지 기록해요',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            _buildGoalSection(),
            const SizedBox(height: 28),

            // 자유 메모
            _buildSectionTitle('한 줄 메모 (선택)'),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '오늘 하루를 돌아보며 한 마디...',
              ),
            ),
            const SizedBox(height: 24),

            // 미래의 나에게 한마디
            _buildSectionTitle('💌 미래의 나에게 한마디 (선택)'),
            const SizedBox(height: 4),
            const Text(
              '분석 탭에서 나중에 다시 볼 수 있어요',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _futureMessageController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: '미래의 나에게 전하고 싶은 말...',
              ),
            ),
            const SizedBox(height: 36),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveRecord,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(widget.isEditMode ? '수정 저장하기' : '기록 저장하기'),
              ),
            ),
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

  Widget _buildEmotionSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(Emotions.list.length, (i) {
        final emotion = Emotions.list[i];
        final selected = _selectedEmotionIndex == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedEmotionIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? Color(emotion['color']).withOpacity(0.3)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? Color(emotion['color']) : AppColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(emotion['emoji'], style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  emotion['label'],
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _actionInputController,
            decoration: const InputDecoration(
              hintText: '직접 입력 (예: 새벽 조깅)',
            ),
            onSubmitted: _addAction,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _addAction(_actionInputController.text),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildActionChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedActions.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedActions.map((action) {
              return Chip(
                label: Text(action),
                backgroundColor: AppColors.primaryLight,
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.primary),
                onDeleted: () => setState(() => _selectedActions.remove(action)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          '추천',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _suggestedActions.map((action) {
            final selected = _selectedActions.contains(action);
            return GestureDetector(
              onTap: () => _toggleAction(action),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  action,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ✅ 목표 점검 섹션
  Widget _buildGoalSection() {
    return Consumer<GoalProvider>(
      builder: (context, provider, _) {
        // 달성률 100% 미만인 진행중 목표만
        final goals = provider.activeGoals
            .where((g) => g.achievementRate < 1.0)
            .toList();

        _initGoalControllers(goals);

        if (goals.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Text(
              '진행 중인 목표가 없어요 🎉\n목표 탭에서 새 목표를 추가해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          );
        }

        return Column(
          children: goals.map((goal) => _buildGoalItem(goal)).toList(),
        );
      },
    );
  }

  Widget _buildGoalItem(Goal goal) {
    final id = goal.id!;
    final rate = _goalRates[id] ?? goal.achievementRate;
    final percent = (rate * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 목표 제목 + 카테고리
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.category ?? '기타',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 달성률 슬라이더
          Row(
            children: [
              const Text(
                '달성률',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: rate,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (val) {
                setState(() => _goalRates[id] = val);
              },
            ),
          ),
          const SizedBox(height: 8),

          // 내용 입력칸
          TextField(
            controller: _goalMemos[id],
            decoration: InputDecoration(
              hintText: '${goal.title}을 위해 오늘 무엇을 했나요?',
              hintStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addAction(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !_selectedActions.contains(trimmed)) {
      setState(() {
        _selectedActions.add(trimmed);
        _actionInputController.clear();
      });
    }
  }

  void _toggleAction(String action) {
    setState(() {
      if (_selectedActions.contains(action)) {
        _selectedActions.remove(action);
      } else {
        _selectedActions.add(action);
      }
    });
  }

  Future<void> _saveRecord() async {
    if (_selectedActions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘 한 행동을 하나 이상 선택해주세요!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. 일일 기록 저장
    final emotion = Emotions.list[_selectedEmotionIndex];
    // 목표별 메모를 goalProgressMemos로 수집
    final goalProgressMemos = <int, String>{};
    for (final entry in _goalMemos.entries) {
      final memo = entry.value.text.trim();
      if (memo.isNotEmpty) goalProgressMemos[entry.key] = memo;
    }
    final record = DailyRecord(
      id: widget.record?.id, // 수정 모드면 기존 id 유지
      date: _selectedDate,
      emotion: emotion['emoji'],
      emotionScore: emotion['score'],
      actions: List.from(_selectedActions),
      memo: _memoController.text.trim(),
      futureMessage: _futureMessageController.text.trim(),
      relatedGoalIds: _goalRates.keys.toList(),
      goalProgressMemos: goalProgressMemos,
    );
    await context.read<RecordProvider>().createRecord(record);

    // 2. 목표별 달성률 업데이트
    final goalProvider = context.read<GoalProvider>();
    for (final entry in _goalRates.entries) {
      final goalId = entry.key;
      final newRate = entry.value;
      final goal = goalProvider.goals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => Goal(
          title: '', description: '', category: '',
          targetDate: DateTime.now(),
        ),
      );
      if (goal.title.isNotEmpty) {
        final prevRate = goal.achievementRate;
        final memo = _goalMemos[goalId]?.text.trim() ?? '';
        // 100% 달성 시 자동으로 완료 처리
        final updatedGoal = newRate >= 1.0
            ? goal.copyWith(achievementRate: 1.0, status: GoalStatus.completed)
            : goal.copyWith(achievementRate: newRate);
        await goalProvider.updateGoal(goalId, updatedGoal);
        goalProvider.addRateEntry(
          goalId: goalId,
          prevRate: prevRate,
          newRate: newRate >= 1.0 ? 1.0 : newRate,
          memo: memo,
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditMode ? '기록이 수정됐어요 ✏️' : '오늘 기록이 저장됐어요 🌱'),
          backgroundColor: AppColors.primary,
        ),
      );
      if (widget.isEditMode) {
        Navigator.pop(context, true); // 수정 모드면 뒤로가기
        return;
      }
      // 새 기록이면 초기화
      setState(() {
        _selectedEmotionIndex = 2;
        _selectedDate = DateTime.now();
        _selectedActions.clear();
        _memoController.clear();
        _futureMessageController.clear();
        for (final c in _goalMemos.values) {
          c.clear();
        }
      });
    }
  }
}

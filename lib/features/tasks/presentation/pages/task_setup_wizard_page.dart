import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';

class TaskSetupWizardPage extends StatefulWidget {
  const TaskSetupWizardPage({super.key});

  @override
  State<TaskSetupWizardPage> createState() => _TaskSetupWizardPageState();
}

class _TaskSetupWizardPageState extends State<TaskSetupWizardPage> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  int _currentPage = 0;
  static const int _totalPages = 6;

  // ── Step 1: Identity ──
  String _taskName = '';

  // ── Step 2: Repetition ──
  String _frequencyType = 'daily'; // 'daily', 'weekly', 'monthly'
  Set<int> _dailyDays = {1, 2, 3, 4, 5, 6, 7}; // 1 = Mon ... 7 = Sun
  int _weeklyDay = 7; // Sunday default
  String _monthlyRuleType = 'start'; // 'start', 'end', 'day_number'
  int _monthlyDayNumber = 15;

  // ── Step 3: Start Time ──
  TimeOfDay? _startTime = const TimeOfDay(hour: 8, minute: 0);

  // ── Step 4: Notification Budget ──
  int _reminderCount = 1; // 0, 1, 2, 3

  // ── Step 5: Grid Color ──
  String _gridColor = '#22C55E';
  static const List<Map<String, String>> _colorPalettes = [
    {'name': 'Emerald', 'hex': '#22C55E'},
    {'name': 'Jade', 'hex': '#10B981'},
    {'name': 'Mint', 'hex': '#86EFAC'},
    {'name': 'Violet', 'hex': '#8B5CF6'},
    {'name': 'Amber', 'hex': '#F59E0B'},
    {'name': 'Cyan', 'hex': '#06B6D4'},
  ];

  // ── Step 6: Morning Review ──
  bool _includeInMorningReview = true;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  List<int> get _computedDaysOfWeek {
    if (_frequencyType == 'weekly') {
      return [_weeklyDay];
    } else if (_frequencyType == 'daily') {
      final list = _dailyDays.toList()..sort();
      return list.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : list;
    }
    return const [1, 2, 3, 4, 5, 6, 7];
  }

  String? get _computedMonthlyRule {
    if (_frequencyType != 'monthly') return null;
    if (_monthlyRuleType == 'start') return 'start';
    if (_monthlyRuleType == 'end') return 'end';
    return _monthlyDayNumber.toString();
  }

  String? get _computedStartTimeString {
    if (_startTime == null) return null;
    final h = _startTime!.hour.toString().padLeft(2, '0');
    final m = _startTime!.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF22C55E);
    }
  }

  void _submitTask() {
    // Single atomic database request dispatched at the very end
    context.read<TasksBloc>().add(
          AddTaskSubmitted(
            name: _taskName.trim(),
            frequencyType: _frequencyType,
            daysOfWeek: _computedDaysOfWeek,
            monthlyRule: _computedMonthlyRule,
            startTime: _computedStartTimeString,
            reminderCount: _reminderCount,
            gridColor: _gridColor,
            includeInMorningReview: _includeInMorningReview,
          ),
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevPage,
        ),
        title: Text(
          'Step ${_currentPage + 1} of $_totalPages',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            color: _parseHexColor(_gridColor),
          ),
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Controlled progression
          onPageChanged: (index) => setState(() => _currentPage = index),
          children: [
            _buildStep1Identity(),
            _buildStep2Repetition(),
            _buildStep3StartTime(),
            _buildStep4Notifications(),
            _buildStep5Color(),
            _buildStep6Review(),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Task Identity ──
  Widget _buildStep1Identity() {
    final presets = ['Read 20 pages', 'Workout', 'Meditate', 'Drink 2L Water', 'Learn Flutter'];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'What habit or goal\nare you committing to?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'e.g. Read 20 pages',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              counterText: '',
            ),
            onChanged: (val) => setState(() => _taskName = val),
          ),
          const SizedBox(height: 16),
          const Text('Or pick a suggested habit:', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((p) {
              return ActionChip(
                label: Text(p),
                onPressed: () {
                  _nameController.text = p;
                  setState(() => _taskName = p);
                },
              );
            }).toList(),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _taskName.trim().isEmpty ? null : _nextPage,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Repetition Cadence ──
  Widget _buildStep2Repetition() {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How often do you want\nto perform this?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 24),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ],
              selected: {_frequencyType},
              onSelectionChanged: (set) {
                setState(() => _frequencyType = set.first);
              },
            ),
            const SizedBox(height: 24),

            // Daily view: multi-day toggle
            if (_frequencyType == 'daily') ...[
              const Text('Active days of the week:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayIndex = i + 1; // 1 = Mon ... 7 = Sun
                  final isSelected = _dailyDays.contains(dayIndex);
                  return FilterChip(
                    label: Text(dayLabels[i]),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _dailyDays.add(dayIndex);
                        } else if (_dailyDays.length > 1) {
                          _dailyDays.remove(dayIndex);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _dailyDays = {1, 2, 3, 4, 5, 6, 7}),
                    child: const Text('Every Day'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _dailyDays = {1, 2, 3, 4, 5}),
                    child: const Text('Weekdays'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _dailyDays = {6, 7}),
                    child: const Text('Weekends'),
                  ),
                ],
              ),
            ],

            // Weekly view: single day picker
            if (_frequencyType == 'weekly') ...[
              const Text('Pick exactly one day each week:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday'
                ].asMap().entries.map((entry) {
                  final dayNum = entry.key + 1;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: _weeklyDay == dayNum,
                    onSelected: (val) {
                      if (val) setState(() => _weeklyDay = dayNum);
                    },
                  );
                }).toList(),
              ),
            ],

            // Monthly view: day number, start, or end
            if (_frequencyType == 'monthly') ...[
              const Text('Monthly schedule rule:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Start of the month (1st)'),
                value: 'start',
                groupValue: _monthlyRuleType,
                onChanged: (val) => setState(() => _monthlyRuleType = val!),
              ),
              RadioListTile<String>(
                title: const Text('End of the month (Last day)'),
                value: 'end',
                groupValue: _monthlyRuleType,
                onChanged: (val) => setState(() => _monthlyRuleType = val!),
              ),
              RadioListTile<String>(
                title: Text('Specific day of the month ($_monthlyDayNumber)'),
                value: 'day_number',
                groupValue: _monthlyRuleType,
                onChanged: (val) => setState(() => _monthlyRuleType = val!),
              ),
              if (_monthlyRuleType == 'day_number')
                Slider(
                  value: _monthlyDayNumber.toDouble(),
                  min: 1,
                  max: 31,
                  divisions: 30,
                  label: 'Day $_monthlyDayNumber',
                  onChanged: (v) => setState(() => _monthlyDayNumber = v.round()),
                ),
            ],

            const SizedBox(height: 40),
            FilledButton(
              onPressed: _nextPage,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Start Time ──
  Widget _buildStep3StartTime() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'When is your ideal\ntime to do this?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.access_time_filled, color: Colors.green),
              title: const Text('Scheduled Start Time'),
              subtitle: Text(
                _startTime != null ? _startTime!.format(context) : 'Anytime (No specific hour)',
              ),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (picked != null) setState(() => _startTime = picked);
                },
                child: const Text('Change'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                label: const Text('Morning (08:00)'),
                onPressed: () => setState(() => _startTime = const TimeOfDay(hour: 8, minute: 0)),
              ),
              ActionChip(
                avatar: const Icon(Icons.wb_cloudy_outlined, size: 16),
                label: const Text('Afternoon (13:00)'),
                onPressed: () => setState(() => _startTime = const TimeOfDay(hour: 13, minute: 0)),
              ),
              ActionChip(
                avatar: const Icon(Icons.nightlight_outlined, size: 16),
                label: const Text('Evening (19:00)'),
                onPressed: () => setState(() => _startTime = const TimeOfDay(hour: 19, minute: 0)),
              ),
            ],
          ),
          const Spacer(),
          FilledButton(
            onPressed: _nextPage,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Notification Budget ──
  Widget _buildStep4Notifications() {
    final tiers = [
      {'count': 0, 'title': '0 — Silent Mode', 'desc': 'No push reminders (self-driven check-in)'},
      {'count': 1, 'title': '1 — Single Reminder', 'desc': 'One notification at your chosen start time'},
      {'count': 2, 'title': '2 — Gentle Follow-up', 'desc': 'Start time reminder + one evening check-in'},
      {'count': 3, 'title': '3 — High Accountability', 'desc': 'Morning kickoff + midday nudge + evening warning'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'How many reminders\ndo you need?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 16),
          ...tiers.map((t) {
            final count = t['count'] as int;
            final isSelected = _reminderCount == count;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? _parseHexColor(_gridColor) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                title: Text(t['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(t['desc'] as String),
                trailing: isSelected ? Icon(Icons.check_circle, color: _parseHexColor(_gridColor)) : null,
                onTap: () => setState(() => _reminderCount = count),
              ),
            );
          }),
          const Spacer(),
          FilledButton(
            onPressed: _nextPage,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Grid Aesthetics ──
  Widget _buildStep5Color() {
    final currentColor = _parseHexColor(_gridColor);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose the color\nfor your grid',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 20),
          // Live interactive grid preview
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_taskName.isEmpty ? 'Habit Preview' : _taskName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Mock 7-column contribution preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final isDone = i % 2 == 0 || i == 6;
                      return Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone ? currentColor : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Select Palette:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorPalettes.map((c) {
              final hex = c['hex']!;
              final color = _parseHexColor(hex);
              final isSelected = _gridColor == hex;

              return InkWell(
                onTap: () => setState(() => _gridColor = hex),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _nextPage,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── Step 6: Review & Final Confirmation ──
  Widget _buildStep6Review() {
    final currentColor = _parseHexColor(_gridColor);

    String freqSummary = 'Daily';
    if (_frequencyType == 'weekly') {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      freqSummary = 'Weekly on ${days[_weeklyDay - 1]}';
    } else if (_frequencyType == 'monthly') {
      if (_monthlyRuleType == 'start') {
        freqSummary = 'Monthly on 1st day';
      } else if (_monthlyRuleType == 'end') {
        freqSummary = 'Monthly on last day';
      } else {
        freqSummary = 'Monthly on day $_monthlyDayNumber';
      }
    } else {
      if (_dailyDays.length == 7) {
        freqSummary = 'Every Day';
      } else if (_dailyDays.length == 5 && !_dailyDays.contains(6) && !_dailyDays.contains(7)) {
        freqSummary = 'Weekdays Only';
      } else {
        freqSummary = 'Daily (${_dailyDays.length} days/week)';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ready to start\nyour new habit?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: currentColor, radius: 14),
                    title: Text(_taskName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(freqSummary),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Start Time:', style: TextStyle(color: Colors.grey)),
                      Text(_startTime != null ? _startTime!.format(context) : 'Anytime'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reminders:', style: TextStyle(color: Colors.grey)),
                      Text('$_reminderCount per day'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Include in Morning Review'),
            subtitle: const Text('Check yesterday completion every morning'),
            value: _includeInMorningReview,
            activeColor: currentColor,
            onChanged: (val) => setState(() => _includeInMorningReview = val),
          ),
          const Spacer(),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: currentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Create Habit & Start Grid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _submitTask,
          ),
        ],
      ),
    );
  }
}


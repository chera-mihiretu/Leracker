import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/error/exceptions.dart';
import '../models/task_entry_model.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks();
  Future<TaskModel> addTask({
    required String name,
    String frequencyType = 'daily',
    List<int> daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    String? monthlyRule,
    String? startTime,
    int reminderCount = 1,
    String gridColor = '#22C55E',
    bool includeInMorningReview = true,
  });
  Future<void> archiveTask(String taskId);

  Future<List<TaskEntryModel>> getTaskEntries(String taskId);
  Future<List<TaskEntryModel>> getAllTaskEntries();
  Future<TaskEntryModel> recordTaskEntry({
    required String taskId,
    required DateTime entryDate,
    required String status,
  });
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final supabase.SupabaseClient supabaseClient;

  TaskRemoteDataSourceImpl({required this.supabaseClient});

  String get _currentUserId {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      throw const ServerException(message: 'User is not authenticated');
    }
    return user.id;
  }

  @override
  Future<List<TaskModel>> getTasks() async {
    try {
      final response = await supabaseClient
          .from('tasks')
          .select()
          .eq('archived', false)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TaskModel> addTask({
    required String name,
    String frequencyType = 'daily',
    List<int> daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    String? monthlyRule,
    String? startTime,
    int reminderCount = 1,
    String gridColor = '#22C55E',
    bool includeInMorningReview = true,
  }) async {
    try {
      final insertData = <String, dynamic>{
        'user_id': _currentUserId,
        'name': name.trim(),
        'frequency_type': frequencyType,
        'frequency': frequencyType,
        'days_of_week': daysOfWeek,
        'reminder_count': reminderCount,
        'grid_color': gridColor,
        'include_in_morning_review': includeInMorningReview,
      };
      if (monthlyRule != null) insertData['monthly_rule'] = monthlyRule;
      if (startTime != null) insertData['start_time'] = startTime;

      try {
        final response = await supabaseClient
            .from('tasks')
            .insert(insertData)
            .select()
            .single();

        return TaskModel.fromJson(response);
      } catch (_) {
        // Fallback for older database schema if custom columns are not yet applied on remote
        final fallbackResponse = await supabaseClient
            .from('tasks')
            .insert({
              'user_id': _currentUserId,
              'name': name.trim(),
              'frequency': frequencyType,
            })
            .select()
            .single();

        return TaskModel.fromJson(fallbackResponse).copyWith(
          frequencyType: frequencyType,
          daysOfWeek: daysOfWeek,
          monthlyRule: monthlyRule,
          startTime: startTime,
          reminderCount: reminderCount,
          gridColor: gridColor,
          includeInMorningReview: includeInMorningReview,
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> archiveTask(String taskId) async {
    try {
      await supabaseClient
          .from('tasks')
          .update({'archived': true})
          .eq('id', taskId);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TaskEntryModel>> getTaskEntries(String taskId) async {
    try {
      final response = await supabaseClient
          .from('task_entries')
          .select()
          .eq('task_id', taskId)
          .order('entry_date', ascending: true);

      return (response as List<dynamic>)
          .map((item) => TaskEntryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TaskEntryModel>> getAllTaskEntries() async {
    try {
      final response = await supabaseClient
          .from('task_entries')
          .select()
          .order('entry_date', ascending: true);

      return (response as List<dynamic>)
          .map((item) => TaskEntryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TaskEntryModel> recordTaskEntry({
    required String taskId,
    required DateTime entryDate,
    required String status,
  }) async {
    try {
      final formattedDate =
          '${entryDate.year.toString().padLeft(4, '0')}-${entryDate.month.toString().padLeft(2, '0')}-${entryDate.day.toString().padLeft(2, '0')}';

      final response = await supabaseClient
          .from('task_entries')
          .upsert(
            {
              'task_id': taskId,
              'user_id': _currentUserId,
              'entry_date': formattedDate,
              'status': status,
              'answered_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'task_id,entry_date',
          )
          .select()
          .single();

      return TaskEntryModel.fromJson(response);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}


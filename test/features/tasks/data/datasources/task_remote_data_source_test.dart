import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/exceptions.dart';
import 'package:progress_tracker/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:progress_tracker/features/tasks/data/models/task_entry_model.dart';
import 'package:progress_tracker/features/tasks/data/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}
class MockUser extends Mock implements supabase.User {}

class RecordedCall {
  final String method;
  final dynamic argument;
  final Map<String, dynamic>? namedArguments;

  RecordedCall(this.method, [this.argument, this.namedArguments]);
}

class FakeFilterBuilder<T> extends Fake
    implements supabase.PostgrestFilterBuilder<T> {
  final Future<dynamic> _future;
  final List<RecordedCall> calls;

  FakeFilterBuilder(this._future, [List<RecordedCall>? calls])
      : calls = calls ?? [];

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return _future.then((v) => onValue(v as T), onError: onError);
  }

  @override
  supabase.PostgrestTransformBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    calls.add(RecordedCall('select', columns));
    return FakeFilterBuilder<List<Map<String, dynamic>>>(_future, calls);
  }

  @override
  supabase.PostgrestFilterBuilder<T> eq(String column, Object value) {
    calls.add(RecordedCall('eq', column, {'value': value}));
    return this;
  }

  @override
  supabase.PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = true,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    calls.add(RecordedCall('order', column, {
      'ascending': ascending,
      'nullsFirst': nullsFirst,
      'referencedTable': referencedTable,
    }));
    return this;
  }

  @override
  supabase.PostgrestTransformBuilder<Map<String, dynamic>> single() {
    calls.add(RecordedCall('single'));
    return FakeFilterBuilder<Map<String, dynamic>>(_future, calls);
  }
}

class FakeQueryBuilder extends Fake implements supabase.SupabaseQueryBuilder {
  final Future<dynamic> Function() _futureFactory;
  final List<RecordedCall> calls = [];

  FakeQueryBuilder(this._futureFactory);

  @override
  supabase.PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    calls.add(RecordedCall('select', columns));
    return FakeFilterBuilder<List<Map<String, dynamic>>>(_futureFactory(), calls);
  }

  @override
  supabase.PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    calls.add(RecordedCall('insert', values));
    return FakeFilterBuilder<dynamic>(_futureFactory(), calls);
  }

  @override
  supabase.PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    calls.add(RecordedCall('upsert', values, {'onConflict': onConflict}));
    return FakeFilterBuilder<dynamic>(_futureFactory(), calls);
  }

  @override
  supabase.PostgrestFilterBuilder<dynamic> update(
    Map values, {
    bool defaultToNull = true,
  }) {
    calls.add(RecordedCall('update', values));
    return FakeFilterBuilder<dynamic>(_futureFactory(), calls);
  }
}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late TaskRemoteDataSourceImpl dataSource;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('user-456');
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

    dataSource = TaskRemoteDataSourceImpl(supabaseClient: mockSupabaseClient);
  });

  group('TaskRemoteDataSourceImpl - addTask (Supabase insert)', () {
    test('successfully inserts full task payload into Supabase tasks table', () async {
      final mockTaskResponse = <String, dynamic>{
        'id': 'remote-task-1',
        'user_id': 'user-456',
        'name': 'Workout',
        'frequency_type': 'daily',
        'frequency': 'daily',
        'days_of_week': [1, 2, 3, 4, 5, 6, 7],
        'monthly_rule': 'start',
        'start_time': '08:00',
        'reminder_count': 2,
        'grid_color': '#22C55E',
        'include_in_morning_review': true,
        'created_at': '2026-11-14T10:00:00.000Z',
        'archived': false,
      };

      late FakeQueryBuilder queryBuilder;
      when(() => mockSupabaseClient.from('tasks')).thenAnswer((_) {
        queryBuilder = FakeQueryBuilder(() => Future.value(mockTaskResponse));
        return queryBuilder;
      });

      final task = await dataSource.addTask(
        name: 'Workout',
        frequencyType: 'daily',
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
        monthlyRule: 'start',
        startTime: '08:00',
        reminderCount: 2,
        gridColor: '#22C55E',
        includeInMorningReview: true,
      );

      expect(task, isA<TaskModel>());
      expect(task.id, 'remote-task-1');
      expect(task.name, 'Workout');
      expect(task.userId, 'user-456');

      // Verify the network call dispatched to Supabase
      verify(() => mockSupabaseClient.from('tasks')).called(1);
      final insertCall = queryBuilder.calls.firstWhere((c) => c.method == 'insert');
      final payload = insertCall.argument as Map<String, dynamic>;
      expect(payload['user_id'], 'user-456');
      expect(payload['name'], 'Workout');
      expect(payload['frequency_type'], 'daily');
      expect(payload['days_of_week'], [1, 2, 3, 4, 5, 6, 7]);
      expect(payload['monthly_rule'], 'start');
      expect(payload['start_time'], '08:00');
      expect(payload['reminder_count'], 2);
      expect(payload['grid_color'], '#22C55E');
      expect(payload['include_in_morning_review'], true);
    });

    test('falls back to legacy schema insert when full schema fails on remote', () async {
      var callCount = 0;
      final fallbackResponse = <String, dynamic>{
        'id': 'fallback-task-1',
        'user_id': 'user-456',
        'name': 'Workout',
        'frequency': 'daily',
        'created_at': '2026-11-14T10:00:00.000Z',
        'archived': false,
      };

      when(() => mockSupabaseClient.from('tasks')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          return FakeQueryBuilder(() => Future.error(Exception('Column does not exist')));
        } else {
          return FakeQueryBuilder(() => Future.value(fallbackResponse));
        }
      });

      final task = await dataSource.addTask(
        name: 'Workout',
        frequencyType: 'daily',
        daysOfWeek: const [1, 2, 3, 4, 5],
        monthlyRule: 'end',
        startTime: '07:30',
        reminderCount: 1,
        gridColor: '#10B981',
        includeInMorningReview: false,
      );

      expect(task.id, 'fallback-task-1');
      expect(task.name, 'Workout');
      expect(task.daysOfWeek, [1, 2, 3, 4, 5]);
      expect(task.monthlyRule, 'end');
      expect(task.gridColor, '#10B981');
      expect(callCount, 2);
    });

    test('throws ServerException when user is not authenticated', () async {
      when(() => mockGoTrueClient.currentUser).thenReturn(null);

      expect(
        () => dataSource.addTask(name: 'Workout'),
        throwsA(isA<ServerException>().having(
          (e) => e.message,
          'message',
          'User is not authenticated',
        )),
      );
    });

    test('throws ServerException on unexpected Supabase error', () async {
      when(() => mockSupabaseClient.from('tasks')).thenThrow(Exception('Supabase DB offline'));

      expect(
        () => dataSource.addTask(name: 'Workout'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('TaskRemoteDataSourceImpl - archiveTask (Supabase update / remove)', () {
    test('updates task record to archived: true where id matches', () async {
      late FakeQueryBuilder queryBuilder;
      when(() => mockSupabaseClient.from('tasks')).thenAnswer((_) {
        queryBuilder = FakeQueryBuilder(() => Future<dynamic>.value(null));
        return queryBuilder;
      });

      await dataSource.archiveTask('task-remove-123');

      verify(() => mockSupabaseClient.from('tasks')).called(1);
      final updateCall = queryBuilder.calls.firstWhere((c) => c.method == 'update');
      expect(updateCall.argument, {'archived': true});

      final eqCall = queryBuilder.calls.firstWhere((c) => c.method == 'eq');
      expect(eqCall.argument, 'id');
      expect(eqCall.namedArguments?['value'], 'task-remove-123');
    });

    test('throws ServerException when archive call fails', () async {
      when(() => mockSupabaseClient.from('tasks')).thenAnswer((_) {
        return FakeQueryBuilder(() => Future.error(Exception('Failed to update')));
      });

      expect(
        () => dataSource.archiveTask('task-123'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('TaskRemoteDataSourceImpl - getTasks', () {
    test('selects unarchived tasks ordered by created_at', () async {
      final mockTasksList = [
        <String, dynamic>{
          'id': 't1',
          'user_id': 'user-456',
          'name': 'Task 1',
          'created_at': '2026-11-14T10:00:00.000Z',
          'archived': false,
        },
        <String, dynamic>{
          'id': 't2',
          'user_id': 'user-456',
          'name': 'Task 2',
          'created_at': '2026-11-14T11:00:00.000Z',
          'archived': false,
        },
      ];

      late FakeQueryBuilder queryBuilder;
      when(() => mockSupabaseClient.from('tasks')).thenAnswer((_) {
        queryBuilder = FakeQueryBuilder(() => Future.value(mockTasksList));
        return queryBuilder;
      });

      final tasks = await dataSource.getTasks();

      expect(tasks.length, 2);
      expect(tasks[0].id, 't1');
      expect(tasks[1].id, 't2');

      verify(() => mockSupabaseClient.from('tasks')).called(1);
      final eqCall = queryBuilder.calls.firstWhere((c) => c.method == 'eq');
      expect(eqCall.argument, 'archived');
      expect(eqCall.namedArguments?['value'], false);

      final orderCall = queryBuilder.calls.firstWhere((c) => c.method == 'order');
      expect(orderCall.argument, 'created_at');
      expect(orderCall.namedArguments?['ascending'], true);
    });

    test('throws ServerException when getTasks query fails', () async {
      when(() => mockSupabaseClient.from('tasks')).thenAnswer((_) {
        return FakeQueryBuilder(() => Future.error(Exception('Query timeout')));
      });

      expect(
        () => dataSource.getTasks(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('TaskRemoteDataSourceImpl - recordTaskEntry (Supabase upsert)', () {
    test('upserts task entry on conflict task_id,entry_date and returns TaskEntryModel', () async {
      final now = DateTime(2026, 11, 14);
      final mockEntryResponse = <String, dynamic>{
        'id': 'entry-1',
        'task_id': 'task-10',
        'user_id': 'user-456',
        'entry_date': '2026-11-14',
        'status': 'done',
        'answered_at': '2026-11-14T12:00:00.000Z',
      };

      late FakeQueryBuilder queryBuilder;
      when(() => mockSupabaseClient.from('task_entries')).thenAnswer((_) {
        queryBuilder = FakeQueryBuilder(() => Future.value(mockEntryResponse));
        return queryBuilder;
      });

      final entry = await dataSource.recordTaskEntry(
        taskId: 'task-10',
        entryDate: now,
        status: 'done',
      );

      expect(entry, isA<TaskEntryModel>());
      expect(entry.id, 'entry-1');
      expect(entry.taskId, 'task-10');
      expect(entry.status, 'done');

      verify(() => mockSupabaseClient.from('task_entries')).called(1);
      final upsertCall = queryBuilder.calls.firstWhere((c) => c.method == 'upsert');
      final payload = upsertCall.argument as Map<String, dynamic>;
      expect(payload['task_id'], 'task-10');
      expect(payload['user_id'], 'user-456');
      expect(payload['entry_date'], '2026-11-14');
      expect(payload['status'], 'done');
      expect(upsertCall.namedArguments?['onConflict'], 'task_id,entry_date');
    });

    test('throws ServerException when recordTaskEntry fails', () async {
      when(() => mockSupabaseClient.from('task_entries')).thenAnswer((_) {
        return FakeQueryBuilder(() => Future.error(Exception('Upsert failed')));
      });

      expect(
        () => dataSource.recordTaskEntry(
          taskId: 't1',
          entryDate: DateTime.now(),
          status: 'done',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('TaskRemoteDataSourceImpl - getTaskEntries & getAllTaskEntries', () {
    test('getTaskEntries filters by task_id and orders by entry_date', () async {
      final mockEntries = [
        <String, dynamic>{
          'id': 'e1',
          'task_id': 'task-1',
          'user_id': 'user-456',
          'entry_date': '2026-11-13',
          'status': 'done',
          'answered_at': '2026-11-13T12:00:00.000Z',
        },
      ];

      late FakeQueryBuilder queryBuilder;
      when(() => mockSupabaseClient.from('task_entries')).thenAnswer((_) {
        queryBuilder = FakeQueryBuilder(() => Future.value(mockEntries));
        return queryBuilder;
      });

      final entries = await dataSource.getTaskEntries('task-1');

      expect(entries.length, 1);
      expect(entries.first.id, 'e1');

      final eqCall = queryBuilder.calls.firstWhere((c) => c.method == 'eq');
      expect(eqCall.argument, 'task_id');
      expect(eqCall.namedArguments?['value'], 'task-1');
    });

    test('getAllTaskEntries selects all entries ordered by entry_date', () async {
      final mockEntries = [
        <String, dynamic>{
          'id': 'e1',
          'task_id': 'task-1',
          'user_id': 'user-456',
          'entry_date': '2026-11-13',
          'status': 'done',
          'answered_at': '2026-11-13T12:00:00.000Z',
        },
        <String, dynamic>{
          'id': 'e2',
          'task_id': 'task-2',
          'user_id': 'user-456',
          'entry_date': '2026-11-14',
          'status': 'missed',
          'answered_at': '2026-11-14T12:00:00.000Z',
        },
      ];

      late FakeQueryBuilder queryBuilder;
      when(() => mockSupabaseClient.from('task_entries')).thenAnswer((_) {
        queryBuilder = FakeQueryBuilder(() => Future.value(mockEntries));
        return queryBuilder;
      });

      final entries = await dataSource.getAllTaskEntries();

      expect(entries.length, 2);
      expect(entries[0].taskId, 'task-1');
      expect(entries[1].taskId, 'task-2');

      final orderCall = queryBuilder.calls.firstWhere((c) => c.method == 'order');
      expect(orderCall.argument, 'entry_date');
      expect(orderCall.namedArguments?['ascending'], true);
    });
  });
}

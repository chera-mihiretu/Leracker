import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:progress_tracker/core/network/network_info.dart';
import 'package:progress_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:progress_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:progress_tracker/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:progress_tracker/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:progress_tracker/features/tasks/domain/repositories/task_repository.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:progress_tracker/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetEnvForTesting();
    await sl.reset();
  });

  tearDown(() async {
    resetEnvForTesting();
    await sl.reset();
  });

  group('getEnv helper', () {
    test('extracts, trims, and unquotes values properly', () {
      dotenv.loadFromString(
        envString: '''
KEY_PLAIN=simple_value
KEY_DOUBLE_QUOTED="double_quoted_value"
KEY_SINGLE_QUOTED='single_quoted_value'
KEY_WITH_SPACES=  spaced_value  
''',
      );

      expect(getEnv('KEY_PLAIN'), 'simple_value');
      expect(getEnv('KEY_DOUBLE_QUOTED'), 'double_quoted_value');
      expect(getEnv('KEY_SINGLE_QUOTED'), 'single_quoted_value');
      expect(getEnv('KEY_WITH_SPACES'), 'spaced_value');
      expect(getEnv('NON_EXISTENT_KEY'), isNull);
    });
  });

  test('initInjection registers all dependencies using dotenv', () async {
    dotenv.loadFromString(
      envString: '''
SUPABASE_URL=https://test.supabase.co
SUPABASE_ANON_KEY=test-anon-key
GOOGLE_WEB_CLIENT_ID=test-web-client-id
GOOGLE_IOS_CLIENT_ID=test-ios-client-id
''',
    );

    await initInjection(envPath: 'assets/keys/.env');

    // Verify external & core
    expect(sl<NetworkInfo>(), isA<NetworkInfo>());
    expect(sl<GoogleSignIn>(), isA<GoogleSignIn>());
    expect(sl<SupabaseClient>(), isA<SupabaseClient>());

    // Verify Auth layer
    expect(sl<AuthRemoteDataSource>(), isA<AuthRemoteDataSource>());
    expect(sl<AuthRepository>(), isA<AuthRepository>());
    expect(sl<AuthBloc>(), isA<AuthBloc>());

    // Verify Tasks layer
    expect(sl<TaskLocalDataSource>(), isA<TaskLocalDataSource>());
    expect(sl<TaskRemoteDataSource>(), isA<TaskRemoteDataSource>());
    expect(sl<TaskRepository>(), isA<TaskRepository>());
    expect(sl<TasksBloc>(), isA<TasksBloc>());
  });
}

import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/network_info.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/sign_in_with_google.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/tasks/data/datasources/task_local_data_source.dart';
import 'features/tasks/data/datasources/task_remote_data_source.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/domain/usecases/add_task.dart';
import 'features/tasks/domain/usecases/get_task_entries.dart';
import 'features/tasks/domain/usecases/get_tasks.dart';
import 'features/tasks/domain/usecases/record_task_entry.dart';
import 'features/tasks/presentation/bloc/tasks_bloc.dart';

final sl = GetIt.instance;

/// Our own env map — independent of flutter_dotenv's isInitialized flag
Map<String, String> _env = {};

/// Visible for testing: clears the cached env map
void resetEnvForTesting() => _env.clear();

/// Helper to safely retrieve environment variables.
/// Checks our own _env map first, then falls back to dotenv.
String? getEnv(String key) {
  // Try our own map first (always works)
  var value = _env[key];
  // Fall back to dotenv if available
  if (value == null && dotenv.isInitialized) {
    value = dotenv.maybeGet(key);
  }
  if (value == null) return null;
  var trimmed = value.trim();
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    trimmed = trimmed.substring(1, trimmed.length - 1).trim();
  }
  return trimmed.isEmpty ? null : trimmed;
}

/// Parse a raw .env string into key-value pairs
Map<String, String> _parseEnvString(String raw) {
  final result = <String, String>{};
  for (final line in raw.replaceAll('\r\n', '\n').split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx < 0) continue;
    final k = trimmed.substring(0, idx).trim();
    final v = trimmed.substring(idx + 1).trim();
    result[k] = v;
  }
  return result;
}

Future<void> initInjection({String envPath = 'assets/keys/.env'}) async {
  // If tests or previous setup already initialized dotenv, sync with _env
  if (dotenv.isInitialized && dotenv.env.isNotEmpty) {
    _env.addAll(dotenv.env);
  }

  // Paths to try in order (including non-dot 'assets/keys/env' for Android asset compatibility)
  final candidatePaths = <String>[
    envPath,
    if (envPath.endsWith('/.env')) envPath.replaceAll('/.env', '/env'),
    'assets/keys/env',
    'assets/keys/.env',
  ];

  if (_env.isEmpty) {
    for (final path in candidatePaths.toSet()) {
      // 1. Try dotenv.load
      try {
        await dotenv.load(fileName: path);
        if (dotenv.isInitialized && dotenv.env.isNotEmpty) {
          _env.addAll(dotenv.env);
          log('[Config] Loaded via dotenv ($path) — keys: ${_env.keys.toList()}');
          break;
        }
      } catch (e) {
        log('[Config] dotenv.load($path) failed: $e');
      }

      // 2. Try rootBundle.loadString + manual parse
      try {
        final raw = await rootBundle.loadString(path);
        log('[Config] rootBundle read OK ($path) — ${raw.length} chars');
        final parsed = _parseEnvString(raw);
        if (parsed.isNotEmpty) {
          _env.addAll(parsed);
          dotenv.env.addAll(parsed);
          log('[Config] Manual parse ($path) — keys: ${_env.keys.toList()}');
          break;
        }
      } catch (e) {
        log('[Config] rootBundle read failed ($path): $e');
      }
    }
  }

  if (_env.isEmpty) {
    log('[Config] WARNING: No env vars loaded! .env is missing or empty.');
  }

  // Initialize Supabase if keys are present in .env
  final supabaseUrl = getEnv('SUPABASE_URL');
  final supabaseAnonKey = getEnv('SUPABASE_ANON_KEY');

  log('Supabase : $supabaseUrl');

  if (supabaseUrl != null &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey != null &&
      supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      // ignore: avoid_print
      log('[Config] Supabase initialized successfully');
    } catch (_) {
      // Supabase may already be initialized (e.g. hot reload or test environment)
    }
  }

  // ── Core & External ──
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  sl.registerLazySingleton<GoogleSignIn>(() {
    final webClientId =
        getEnv('GOOGLE_WEB_CLIENT_ID') ??
        getEnv('WEB_CLIENT_ID') ??
        getEnv('GOOGLE_CLIENT_ID');
    final iosClientId =
        getEnv('GOOGLE_IOS_CLIENT_ID') ?? getEnv('IOS_CLIENT_ID');

    log(
      '[Config] GoogleSignIn serverClientId is ${webClientId != null ? "configured" : "NOT CONFIGURED (null)"}',
    );

    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: (webClientId != null && webClientId.isNotEmpty)
          ? webClientId
          : null,
      clientId: (iosClientId != null && iosClientId.isNotEmpty)
          ? iosClientId
          : null,
    );
  });

  sl.registerLazySingleton<SupabaseClient>(() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      // Fallback when Supabase has not yet been initialized via Supabase.initialize
      final url = getEnv('SUPABASE_URL') ?? 'https://placeholder.supabase.co';
      final anonKey = getEnv('SUPABASE_ANON_KEY') ?? 'placeholder-anon-key';
      return SupabaseClient(
        url,
        anonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    }
  });

  // ── Feature: Auth ──
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl(), googleSignIn: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // BLoC (Factory)
  sl.registerFactory(
    () => AuthBloc(getCurrentUser: sl(), signInWithGoogle: sl(), signOut: sl()),
  );

  // ── Feature: Tasks ──
  // Data sources
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => InMemoryTaskLocalDataSource(),
  );
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetTasks(sl()));
  sl.registerLazySingleton(() => AddTask(sl()));
  sl.registerLazySingleton(() => GetTaskEntries(sl()));
  sl.registerLazySingleton(() => RecordTaskEntry(sl()));

  // BLoC (Factory)
  sl.registerFactory(
    () => TasksBloc(
      getTasks: sl(),
      addTask: sl(),
      getTaskEntries: sl(),
      recordTaskEntry: sl(),
    ),
  );
}

import 'dart:convert';

import 'package:bico_certo/pages/job/job_details_page.dart';
import 'package:bico_certo/services/job_service.dart';
import 'package:flutter/material.dart';
import 'package:bico_certo/services/local_storage_service.dart';
import 'package:bico_certo/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:bico_certo/controllers/chat_rooms_controller.dart';
import 'package:bico_certo/services/chat_api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bico_certo/services/chat_state_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        try {
          final data = jsonDecode(response.payload!);
          final type = data['type'];

          if (type == 'chat') {
            _handleNotificationClick(data['room_id']);
          } else if (type == 'job') {
            _handleJobNotificationClick(data['job_id']);
          }
        } catch (e) {
          // Erro ao processar payload
        }
      }
    },
  );

  const AndroidNotificationChannel jobChannel = AndroidNotificationChannel(
    'job_updates',
    'Atualizações de Jobs',
    description: 'Notificações sobre mudanças de status dos jobs',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(jobChannel);

  const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
    'chat_messages',
    'Mensagens do Chat',
    description: 'Notificações de novas mensagens no chat',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(chatChannel);

  final isFirstTime = await LocalStorageService.getIsFirstTime();
  await dotenv.load(fileName: ".env");
  runApp(MyApp(isFirstTime: isFirstTime));
}

Future<void> _handleJobNotificationClick(String jobId) async {
  try {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    final jobService = JobService();
    final job = await jobService.getJobById(jobId);

    navigatorKey.currentState?.pop();

    if (job != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => JobDetailsPage(job: job),
        ),
      );
    } else {
      throw Exception('Job não encontrado');
    }
  } catch (e) {
    navigatorKey.currentState?.pop();

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Erro')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Erro ao carregar detalhes do job'),
                const SizedBox(height: 8),
                Text(e.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => navigatorKey.currentState?.pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _handleNotificationClick(String roomId) async {
  try {
    final chatApiService = ChatApiService();
    final roomInfo = await chatApiService.getRoomInfo(roomId);

    final jobTitle = roomInfo['job_title'] ?? 'Chat';

    navigatorKey.currentState?.pushNamed(
      '/chat',
      arguments: {
        'roomId': roomId,
        'jobTitle': jobTitle,
      },
    );
  } catch (e) {
    navigatorKey.currentState?.pushNamed(
      '/chat',
      arguments: {
        'roomId': roomId,
        'jobTitle': 'Chat',
      },
    );
  }
}

class MyApp extends StatefulWidget {
  final bool isFirstTime;
  const MyApp({super.key, required this.isFirstTime});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    try {
      NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          try {
            await ChatApiService().updateFcmToken(token);
          } catch (e) {
            // Erro ao salvar token
          }
        }

        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          ChatApiService().updateFcmToken(newToken);
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final type = message.data['type'];

          if (type == 'chat_message') {
            final roomId = message.data['room_id'];

            if (roomId == null) {
              return;
            }

            final chatState = ChatStateService();
            final isInRoom = chatState.isInRoom(roomId);

            if (isInRoom) {
              return;
            }

            if (message.notification != null) {
              flutterLocalNotificationsPlugin.show(
                message.hashCode,
                message.notification!.title,
                message.notification!.body,
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'chat_messages',
                    'Mensagens do Chat',
                    importance: Importance.high,
                    priority: Priority.high,
                    icon: '@mipmap/ic_launcher',
                  ),
                ),
                payload: jsonEncode({'type': 'chat', 'room_id': roomId}),
              );
            }
          } else if (type == 'job_status_change') {
            final jobId = message.data['job_id'];

            if (jobId == null) {
              return;
            }

            if (message.notification != null) {
              flutterLocalNotificationsPlugin.show(
                message.hashCode,
                message.notification!.title,
                message.notification!.body,
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'job_updates',
                    'Atualizações de Jobs',
                    importance: Importance.high,
                    priority: Priority.high,
                    icon: '@mipmap/ic_launcher',
                  ),
                ),
                payload: jsonEncode({'type': 'job', 'job_id': jobId}),
              );
            }
          }
        });

        FirebaseMessaging.instance.getInitialMessage().then((message) {
          if (message != null) {
            Future.delayed(const Duration(seconds: 1), () {
              _handleNotificationPayload(message.data);
            });
          }
        });

        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          _handleNotificationPayload(message.data);
        });
      }
    } catch (e) {
      // Erro ao configurar FCM
    }
  }

  void _handleNotificationPayload(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'chat_message') {
      final roomId = data['room_id'];
      if (roomId != null) {
        _handleNotificationClick(roomId);
      }
    } else if (type == 'job_status_change') {
      final jobId = data['job_id'];
      if (jobId != null) {
        _handleJobNotificationClick(jobId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatRoomsController(ChatApiService())..initialize(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Bico Certo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF156b9a)),
          fontFamily: 'LeagueSpartan',
          useMaterial3: true,
        ),
        initialRoute:
        widget.isFirstTime ? AppRoutes.welcome : AppRoutes.sessionCheck,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
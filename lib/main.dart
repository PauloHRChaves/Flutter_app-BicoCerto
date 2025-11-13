import 'dart:convert';

import 'package:bico_certo/pages/job/job_details_page.dart';
import 'package:bico_certo/pages/wallet/wallet_page.dart';
import 'package:bico_certo/services/job_service.dart';
import 'package:bico_certo/services/job_state_service.dart';
import 'package:bico_certo/services/pending_rating_service.dart';
import 'package:bico_certo/services/wallet_state_service.dart';
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

  final type = message.data['type'];
  if (type == 'rate_client_prompt') {
    await PendingRatingService.savePendingRating(
      jobId: message.data['job_id'] ?? '',
      clientName: message.data['client_name'] ?? 'Cliente',
      jobTitle: message.data['job_title'] ?? 'Trabalho',
    );
  }
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
          } else if (type == 'wallet') {
            _handleWalletNotificationClick();
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

Future<void> showPendingRatingModal(BuildContext context) async {
  final pendingData = await PendingRatingService.getPendingRating();

  if (pendingData == null) return;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => _GlobalRateClientDialog(
      jobId: pendingData['job_id'],
      clientName: pendingData['client_name'],
      jobTitle: pendingData['job_title'] ?? 'Trabalho',
    ),
  );

  await PendingRatingService.clearPendingRating();

  if (result != null) {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Enviar avaliação
    final jobService = JobService();
    try {
      final response = await jobService.rateClient(
        jobId: pendingData['job_id'],
        rating: result['rating'],
        password: result['password'],
      );

      // Fechar loading
      Navigator.pop(context);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Cliente avaliado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erro ao avaliar cliente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fechar loading
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao avaliar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _handleWalletNotificationClick() async {
  try {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => const WalletPage(),
      ),
    );
  } catch (e) {
    print('Erro ao abrir carteira: $e');
  }
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
    // ✅ REMOVIDO: Não verificar aqui, vamos verificar no SessionCheckPage
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

            final jobState = JobStateService();
            final isViewingJob = jobState.isViewingJob(jobId);

            if (isViewingJob) {
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
          } else if (type == 'wallet_transaction') {
            final walletState = WalletStateService();
            final isViewingWallet = walletState.isViewingWallet();

            if (isViewingWallet) {
              return;
            }

            if (message.notification != null) {
              flutterLocalNotificationsPlugin.show(
                message.hashCode,
                message.notification!.title,
                message.notification!.body,
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'wallet_transactions',
                    'Transações da Carteira',
                    importance: Importance.high,
                    priority: Priority.high,
                    icon: '@mipmap/ic_launcher',
                  ),
                ),
                payload: jsonEncode({'type': 'wallet'}),
              );
            }
          }
          // ✅ TRATAR notificação de avaliação de cliente (APP ABERTO)
          else if (type == 'rate_client_prompt') {
            final jobId = message.data['job_id'];
            final clientName = message.data['client_name'] ?? 'Cliente';
            final jobTitle = message.data['job_title'] ?? 'Trabalho'; // ✅ NOVO

            // Salvar avaliação pendente
            PendingRatingService.savePendingRating(
              jobId: jobId,
              clientName: clientName,
              jobTitle: jobTitle, // ✅ NOVO
            );

            // Mostrar modal imediatamente se o contexto estiver disponível
            if (navigatorKey.currentContext != null) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (navigatorKey.currentContext != null) {
                  showPendingRatingModal(navigatorKey.currentContext!);
                }
              });
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
    } else if (type == 'wallet_transaction') {
      _handleWalletNotificationClick();
    }
    // ✅ TRATAR notificação de avaliação (APP FOI ABERTO PELA NOTIFICAÇÃO)
    else if (type == 'rate_client_prompt') {
      if (navigatorKey.currentContext != null) {
        Future.delayed(const Duration(seconds: 1), () {
          if (navigatorKey.currentContext != null) {
            showPendingRatingModal(navigatorKey.currentContext!);
          }
        });
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

class _GlobalRateClientDialog extends StatefulWidget {
  final String jobId;
  final String clientName;
  final String jobTitle;

  const _GlobalRateClientDialog({
    required this.jobId,
    required this.clientName,
    required this.jobTitle,
  });

  @override
  State<_GlobalRateClientDialog> createState() => _GlobalRateClientDialogState();
}

class _GlobalRateClientDialogState extends State<_GlobalRateClientDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int _rating = 3;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ Modal no centro
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber[700]),
              const SizedBox(width: 12),
              const Expanded(child: Text('Avaliar Cliente')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informações do job
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.work, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.jobTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Cliente: ${widget.clientName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'O trabalho foi aprovado! Como foi trabalhar com este cliente?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Rating com estrelas
                const Text(
                  'Sua avaliação:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          size: 40,
                          color: Colors.amber[700],
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ),
                Center(
                  child: Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de senha
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha da Carteira',
                    hintText: 'Digite sua senha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Você pode avaliar o cliente agora ou ignorar e avaliar depois.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),

                // Botão "Avaliar Agora"
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, digite sua senha'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'password': _passwordController.text,
                        'rating': _rating,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Avaliar Agora',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ignorar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muito Ruim';
      case 2:
        return 'Ruim';
      case 3:
        return 'Regular';
      case 4:
        return 'Bom';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
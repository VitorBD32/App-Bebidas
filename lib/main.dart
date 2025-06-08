import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'LoginScreen.dart';
import 'dart:io' show Platform; //detectar qual plataforma ta rodando
import 'package:desktop_window/desktop_window.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Certifique-se de inicializar o Firebase no background handler também
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.notification != null) {
    // Adicionado uma verificação de plataforma para notificação em background
    if (Platform.isAndroid || Platform.isIOS) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pedido_status_channel',
            'Atualizações do Pedido',
            channelDescription: 'Notificações sobre o status dos seus pedidos.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['screen'] ?? 'no_payload',
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    const double initialDesktopWidth = 500.0;
    const double initialDesktopHeight = 900.0;
    await DesktopWindow.setWindowSize(
      const Size(initialDesktopWidth, initialDesktopHeight),
    );
    await DesktopWindow.setMinWindowSize(const Size(900.0, 500.0));
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // **** INÍCIO DA MUDANÇA PARA REMOVER NOTIFICAÇÕES DO WINDOWS ****

  // Condicionando a inicialização do plugin de notificações locais
  // para que só ocorra em Android e iOS
  if (Platform.isAndroid || Platform.isIOS) {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings
    initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      // 'windows' não será mais incluído aqui, pois a inicialização será condicional
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notificação clicada com payload: ${response.payload}');
        if (response.payload == 'acompanhar_pedido' ||
            response.payload?.startsWith('status_update_') == true) {
          print('Tentando navegar para a tela de acompanhamento de pedido.');
        } else if (response.payload == 'compra_finalizada') {
          print('Notificação de compra finalizada clicada.');
        } else if (response.payload?.startsWith('admin_action_confirmed') ==
            true) {
          print('Notificação de ação admin confirmada clicada.');
        }
      },
    );
  }
  // **** FIM DA MUDANÇA ****

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Bebidas',
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
        bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.deepPurple,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.deepPurple,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Colors.deepPurple),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              var begin = const Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.ease;
              var tween = Tween(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.local_drink, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'App Bebidas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

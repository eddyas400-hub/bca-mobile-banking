import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/colors.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/topup_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/pin_verification_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/bill_payment_screen.dart';
import 'services/qr_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'BCA Mobile Banking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primaryBlue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/transfer': (context) {
            final qrData = ModalRoute.of(context)?.settings.arguments as PaymentQRData?;
            return TransferScreen(qrData: qrData);
          },
          '/topup': (context) => const TopUpScreen(),
          '/qr_scanner': (context) => const QRScannerScreen(),
          '/pin': (context) => PinScreen(
            isLogin: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['isLogin'] ?? false,
            isSetup: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['isSetup'] ?? false,
          ),
          '/pin-verification': (context) => const PinVerificationScreen(
            title: 'Verify PIN',
            description: 'Enter your PIN to continue',
          ),
          '/profile': (context) => const ProfileScreen(),
          '/bill_payment': (context) => const BillPaymentScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while initializing
        if (authProvider.state == AuthState.initial || 
            authProvider.state == AuthState.loading) {
          return const Scaffold(
            backgroundColor: AppColors.primaryBlue,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'BCA Mobile Banking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Navigate based on authentication state
        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

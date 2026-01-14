import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:v6_invoice_mobile/repository.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/config/environment.dart';
import 'core/config/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Determine which environment file to load
  // Priority: --dart-define > build flavor > default (.env.dev)
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final envFile = '.env.$flavor';

  // Load environment variables from the appropriate .env file
  await dotenv.load(fileName: envFile);

  // Initialize GetStorage for local storage
  await GetStorage.init();

  // Print environment config in debug mode
  Environment.printConfig();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceRepository(),
      child: GetMaterialApp(
        title: Environment.appName,
        theme: AppTheme.light,
        initialRoute: AppRoutes.LOGIN_PAGE,
        getPages: AppPages.pages,
        debugShowCheckedModeBanner: !Environment.isProduction,
      )
    );
  }
}

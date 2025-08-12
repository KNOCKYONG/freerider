import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/themes/app_theme.dart';
import 'routes/app_router.dart';

class FreeRiderApp extends ConsumerWidget {
  const FreeRiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 Pro 기준
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'FREE RIDER',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerConfig: router,
          builder: (context, widget) {
            // 텍스트 스케일 제한
            final mediaQuery = MediaQuery.of(context);
            final scale = mediaQuery.textScaleFactor.clamp(0.8, 1.2);
            
            return MediaQuery(
              data: mediaQuery.copyWith(textScaleFactor: scale),
              child: widget!,
            );
          },
        );
      },
    );
  }
}
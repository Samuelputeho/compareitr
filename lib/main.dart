import 'package:compareitr/bottom_bar.dart';
import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/core/services/ad_mob_service.dart';
import 'package:compareitr/core/services/user_cache_service.dart';
import 'package:compareitr/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:compareitr/features/card_swiper/presentation/bloc/bloc/card_swiper_bloc.dart';
import 'package:compareitr/features/order/presentation/bloc/order_bloc.dart';
import 'package:compareitr/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:compareitr/features/recently_viewed/presentation/bloc/recent_bloc.dart';
import 'package:compareitr/features/sales/presentation/bloc/salecard_bloc.dart';
import 'package:compareitr/features/sales/presentation/bloc/saleproducts_bloc.dart';
import 'package:compareitr/features/saved/presentation/bloc/saved_bloc.dart';
import 'package:compareitr/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'dart:async';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/theme.dart';
import 'core/theme/cubit/theme_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/cart/presentation/bloc/cart_bloc_bloc.dart';
import 'features/shops/presentation/bloc/all_categories/all_categories_bloc.dart';
import 'features/shops/presentation/bloc/all_products/all_products_bloc.dart';
import 'features/shops/presentation/bloc/all_shops/all_shops_bloc.dart';
import 'core/constants/app_const.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initdependencies();
  
  // Initialize Firebase - Temporarily disabled for debugging
  // await Firebase.initializeApp();
  
  // Request notification permissions - Temporarily disabled
  // final messaging = FirebaseMessaging.instance;
  // await messaging.requestPermission(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );
  
  // Get and print FCM token - Temporarily disabled
  // final token = await messaging.getToken();
  // print('📱 FCM Device Token: $token');
  
  // Store token globally for later use - Temporarily disabled
  // AppConstants.fcmToken = token;
  
  // ADS DISABLED - Commented out to prevent ads from showing
  // final initAdFuture = MobileAds.instance.initialize();
  // final adMobService = AdMobService(initAdFuture);

  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
    ],
  );
  runApp(
    MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => serviceLocator<AppUserCubit>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<ThemeCubit>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<AuthBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<AllCategoriesBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<AllShopsBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<OrderBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<AllProductsBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<CardSwiperBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<CartBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<RecentBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<SavedBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<SalecardBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<SaleProductBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<OrderBloc>(),
          ),
          BlocProvider(
            create: (_) => serviceLocator<NotificationBloc>(),
          ),
        ],
        child: const MyApp(),
      ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription? _authSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthIsUserLoggedIn());
    _initDeepLinks();
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link if app was opened from a deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    // Listen for deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('Error listening to deep links: $err');
      },
    );
  }

  void _listenToAuthChanges() {
    // Listen to Supabase auth state changes
    _authSubscription = serviceLocator.get<SupabaseClient>()
        .auth
        .onAuthStateChange
        .listen((data) {
      final event = data.event;
      final session = data.session;

      print('Auth event: $event');
      
      // Handle sign out event (when refresh token is invalid or user logs out)
      if (event == AuthChangeEvent.signedOut) {
        print('User signed out - clearing local state');
        // Clear the user state when signed out
        context.read<AppUserCubit>().updateUser(null);
      }
      
      // When user clicks password reset link, Supabase triggers PASSWORD_RECOVERY event
      if (event == AuthChangeEvent.passwordRecovery && session != null) {
        print('Password recovery detected! Access token available.');
        
        // Navigate to reset password page
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const ResetPasswordPage(token: ''),
            ),
          );
        });
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    print('Deep link received: $uri');
    print('Path: ${uri.path}');
    print('Fragment: ${uri.fragment}');
    print('Query params: ${uri.queryParameters}');

    // Handle password reset deep link
    // Supabase sends: compareitr://reset-password#access_token=xxx&type=recovery
    // OR: https://.../?code=xxx (email verification code)
    
    // Check for recovery token in fragment
    if (uri.path.contains('reset-password') || uri.fragment.contains('type=recovery')) {
      final fragment = uri.fragment;
      
      // Extract access token from fragment
      final params = Uri.splitQueryString(fragment);
      final accessToken = params['access_token'];
      final type = params['type'];

      print('Access Token: $accessToken');
      print('Type: $type');

      if (type == 'recovery' && accessToken != null) {
        // Navigate to reset password page
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const ResetPasswordPage(token: ''),
          ),
        );
      }
    }
    
    // Also check for 'code' parameter (email verification)
    if (uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'];
      print('Verification code detected: $code');
      // The code will be automatically handled by Supabase auth
      // Just need to ensure the session is refreshed
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'CompareItg',
          theme: AppTheme.lightThemeMode,
          darkTheme: AppTheme.darkThemeMode,
          themeMode: themeState.themeMode,
          home: BlocSelector<AppUserCubit, AppUserState, bool>(
        selector: (state) {
          return state is AppUserLoggedIn;
        },
        builder: (context, isLoggedIn) {
          if (isLoggedIn) {
            // Wait for the user to be logged in before dispatching cart actions
            final cartId = (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
            
            print('🚀 App started - User logged in: $cartId');
            // Note: ConnectionChecker check would go here if needed
            print('🌐 App startup complete - loading cached data');
            
            // Debug: Check what's stored in cache
            UserCacheService.debugCacheContents();

            // Only dispatch GetCartItems if cartId is available and valid
            if (cartId.isNotEmpty) {
              context.read<CartBloc>().add(GetCartItems(cartId: cartId));
            }
            
            // Refresh user data to ensure location is up to date
            // This will use cached data if offline
            context.read<AuthBloc>().add(AuthIsUserLoggedIn());
            
            // Dispatch other events - these will now check cache first
            // Card swiper will load cached images immediately if available
            context.read<CardSwiperBloc>().add(GetAllCardSwiperPicturesEvent());
            
            // Shops will use cached data if offline
            context.read<AllShopsBloc>().add(GetAllShopsEvent());
            
            // Recently viewed will use cached data if offline
            context.read<RecentBloc>().add(GetRecentItems(recentId: cartId));
            
            // Always dispatch these events - they will handle offline scenarios internally
            context.read<AllCategoriesBloc>().add(GetAllCategoriesEvent());
            context.read<AllProductsBloc>().add(GetAllProductsEvent());
            context.read<SavedBloc>().add(GetSavedItems(savedId: cartId));
            context.read<SalecardBloc>().add(GetAllSaleCardEvent());
            context.read<SaleProductBloc>().add(GetAllSaleProductsEvent());
            context.read<OrderBloc>().add(GetUserOrdersEvent(cartId));
            context.read<NotificationBloc>().add(GetNotificationsEvent(userId: cartId));
            
            // Save device token for push notifications
            if (AppConstants.fcmToken != null) {
              print('📱 Saving FCM token for user: $cartId');
              context.read<NotificationBloc>().add(SaveDeviceTokenEvent(
                userId: cartId,
                token: AppConstants.fcmToken!,
                platform: Platform.isAndroid ? 'android' : 'ios',
              ));
            }
            
            return const MainNavigationPage();
          }
          // When the user is not logged in, navigate to Login page
          context.read<AllCategoriesBloc>().add(GetAllCategoriesEvent());
          context.read<AuthBloc>();
          return const LoginPage();
        },
      ),
    );
      },
    );
  }
}
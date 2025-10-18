import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/core/theme/cubit/theme_cubit.dart';
import 'package:compareitr/core/common/network/network_connection.dart';
import 'package:compareitr/core/services/user_cache_service.dart';
import 'package:compareitr/core/services/image_cache_service.dart';
import 'package:compareitr/core/services/offline_queue_service.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:compareitr/core/services/order_number_service.dart';
import 'package:compareitr/features/delivery_config/data/datasources/delivery_config_remote_data_source.dart';
import 'package:compareitr/features/delivery_config/data/repositories/delivery_config_repository_impl.dart';
import 'package:compareitr/features/delivery_config/domain/repositories/delivery_config_repository.dart';
import 'package:compareitr/features/delivery_config/domain/usecases/get_delivery_config.dart';
import 'package:compareitr/features/delivery_config/presentation/bloc/delivery_config_bloc.dart';
import 'package:compareitr/features/auth/data/datasourses/auth_remote_data_source.dart';
import 'package:compareitr/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:compareitr/features/auth/domain/repository/auth_repository.dart';
import 'package:compareitr/features/auth/domain/usecases/current_user.dart';
import 'package:compareitr/features/auth/domain/usecases/reset_password.dart';
import 'package:compareitr/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:compareitr/features/auth/domain/usecases/send_password_reset_otp.dart';
import 'package:compareitr/features/auth/domain/usecases/verify_otp_and_reset_password.dart';
import 'package:compareitr/features/auth/domain/usecases/update_user.dart';
import 'package:compareitr/features/auth/domain/usecases/user_login.dart';
import 'package:compareitr/features/auth/domain/usecases/user_sign_up.dart';
import 'package:compareitr/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:compareitr/features/card_swiper/data/datasources/card_swiper_remote_data_source.dart';
import 'package:compareitr/features/card_swiper/data/repository/card_swiper_repository_impl.dart';
import 'package:compareitr/features/card_swiper/domain/repository/card_swiper_repository.dart';
import 'package:compareitr/features/cart/domain/repository/cart_repository.dart';
import 'package:compareitr/features/cart/domain/usecases/update_cart_item_usecase.dart';
import 'package:compareitr/features/order/data/datasources/order_remote_data_source.dart';
import 'package:compareitr/features/order/data/repository/order_repository_impl.dart';
import 'package:compareitr/features/order/domain/repositories/order_repository.dart';
import 'package:compareitr/features/order/domain/usecases/cancel_oder.dart';
import 'package:compareitr/features/order/domain/usecases/create_order.dart';
import 'package:compareitr/features/order/domain/usecases/get_order_by_id.dart';
import 'package:compareitr/features/order/domain/usecases/get_user_order.dart';
import 'package:compareitr/features/order/domain/usecases/update_order_status.dart';
import 'package:compareitr/features/order/presentation/bloc/order_bloc.dart';
import 'package:compareitr/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:compareitr/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:compareitr/features/notifications/domain/repositories/notification_repository.dart';
import 'package:compareitr/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/delete_notification_usecase.dart';
import 'package:compareitr/features/notifications/domain/usecases/save_device_token_usecase.dart';
import 'package:compareitr/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:compareitr/features/recently_viewed/data/datasource/recently_viewed_local_datasource.dart';
import 'package:compareitr/features/recently_viewed/data/datasource/recently_viewed_remote_data_source.dart';
import 'package:compareitr/features/recently_viewed/data/repository/recent_repo_impl.dart';
import 'package:compareitr/features/recently_viewed/domain/repository/recent_repo.dart';
import 'package:compareitr/features/recently_viewed/domain/usecases/add_recent_item_usecase.dart';
import 'package:compareitr/features/recently_viewed/domain/usecases/get_recent_items_usecase.dart';
import 'package:compareitr/features/recently_viewed/domain/usecases/remove_recent_item_usecase.dart';
import 'package:compareitr/features/recently_viewed/presentation/bloc/recent_bloc.dart';
import 'package:compareitr/features/sales/data/datasources/sale_card_remote_data_source.dart';
import 'package:compareitr/features/sales/data/datasources/sale_products_data_source.dart';
import 'package:compareitr/features/sales/data/repository/sale_card_repository_impl.dart';
import 'package:compareitr/features/sales/data/repository/sale_product_repository_impl.dart';
import 'package:compareitr/features/sales/domain/repository/sale_card_repository.dart';
import 'package:compareitr/features/sales/domain/repository/sale_product_repository.dart';
import 'package:compareitr/features/sales/domain/usecases/get_all_sale_card_usecase.dart';
import 'package:compareitr/features/sales/domain/usecases/get_all_sale_products_usecase.dart';
import 'package:compareitr/features/sales/presentation/bloc/salecard_bloc.dart';
import 'package:compareitr/features/sales/presentation/bloc/saleproducts_bloc.dart';
import 'package:compareitr/features/shops/data/datasources/shops_local_datasource.dart';
import 'package:compareitr/features/shops/domain/usecase/get_categories.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/secrets/app_secrets.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/card_swiper/domain/usecase/card_swiper.dart';
import 'features/card_swiper/presentation/bloc/bloc/card_swiper_bloc.dart';
import 'features/cart/data/datasources/cart_remote_data_source.dart';
import 'features/cart/data/repository/cart_repository_impl.dart';
import 'features/cart/domain/usecases/add_cart_item_usecase.dart';
import 'features/cart/domain/usecases/get_cart_items_usecase.dart';
import 'features/cart/domain/usecases/remove_cart_item_usecase.dart';
import 'features/cart/presentation/bloc/cart_bloc_bloc.dart';
import 'features/shops/data/datasources/shops_remote_datasource.dart';
import 'features/shops/data/repository/repo_impl.dart';
import 'features/shops/domain/repository/repo.dart';
import 'features/shops/domain/usecase/get_all_products.dart';
import 'features/shops/domain/usecase/get_all_shops.dart';
import 'features/shops/domain/usecase/get_branches_by_shop.dart';
import 'features/shops/presentation/bloc/all_categories/all_categories_bloc.dart';
import 'features/shops/presentation/bloc/all_products/all_products_bloc.dart';
import 'features/shops/presentation/bloc/all_shops/all_shops_bloc.dart';
import 'features/shops/presentation/bloc/branches/branches_bloc.dart';
import 'package:compareitr/features/saved/data/datasources/saved_remote_data_source.dart';
import 'package:compareitr/features/saved/data/repository/saved_repository_impl.dart';
import 'package:compareitr/features/saved/domain/repository/saved_repository.dart';
import 'package:compareitr/features/saved/domain/usecases/add_saved_item_usecase.dart';
import 'package:compareitr/features/saved/domain/usecases/get_saved_items_usecase.dart';
import 'package:compareitr/features/saved/domain/usecases/remove_saved_item_usecase.dart';
import 'package:compareitr/features/saved/presentation/bloc/saved_bloc.dart';
import 'package:compareitr/core/services/app_settings_service.dart';

final serviceLocator = GetIt.instance;

Future<void> initdependencies() async {
  // Initialize Supabase first
  final supabase = await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseKey,
  );

  // Initialize Hive BEFORE registering dependencies that use it
  final directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  print('✅ Hive initialized at: ${directory.path}');

  await Hive.openBox('shops');
  await Hive.openBox('recently_viewed');
  print('✅ Hive boxes opened: shops, recently_viewed');
  
  // Initialize UserCacheService BEFORE registering dependencies
  await UserCacheService.init();
  
  // Initialize CacheManager (network monitoring)
  await CacheManager.init();
  
  // Initialize ImageCacheService
  await ImageCacheService.init();
  
  // Initialize OfflineQueueService
  await OfflineQueueService.init();

  // Register basic services first
  serviceLocator.registerLazySingleton(() => supabase.client);
  serviceLocator.registerLazySingleton(() => AppUserCubit());
  serviceLocator.registerLazySingleton(() => ThemeCubit());
  serviceLocator.registerFactory(() => InternetConnection());
  serviceLocator.registerFactory<ConnectionChecker>(() => ConnectionCheckerImpl(serviceLocator()));
  
  // Register OrderNumberService
  serviceLocator.registerLazySingleton(() => OrderNumberService(serviceLocator()));
  
  // Register AppSettingsService
  serviceLocator.registerLazySingleton(() => AppSettingsService(supabaseClient: serviceLocator()));

  // NOW register dependencies that use Hive boxes
  _initAuth();
  _initShops();
  _initCardSwiper();
  _initCart();
  _initRecentlyViewed();
  _initSaved();
  _initSalecard();
  _initSaleProduct();
  _initOrder();
  _initNotifications();

  // Register DeliveryConfig dependencies
  serviceLocator.registerLazySingleton<DeliveryConfigRemoteDataSource>(
    () => DeliveryConfigRemoteDataSourceImpl(supabaseClient: serviceLocator()),
  );
  
  serviceLocator.registerLazySingleton<DeliveryConfigRepository>(
    () => DeliveryConfigRepositoryImpl(remoteDataSource: serviceLocator()),
  );
  
  serviceLocator.registerLazySingleton(() => GetDeliveryConfig(serviceLocator()));
  
  serviceLocator.registerFactory(() => DeliveryConfigBloc(getDeliveryConfig: serviceLocator()));
}

void _initShops() {
  serviceLocator
    ..registerFactory<ShopsRemoteDataSource>(
      () => ShopsRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<ShopsLocalDataSource>(
      () => ShopsLocalDataSourceImpl(
        Hive.box('shops'),
      ),
    )
    ..registerFactory<ShopsRepository>(
      () => ShopsRepositoryImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<GetAllShopsUsecase>(
      () => GetAllShopsUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<GetCategoriesUsecase>(
      () => GetCategoriesUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<AllShopsBloc>(
      () => AllShopsBloc(
        getAllShopsUsecase: serviceLocator(),
      ),
    )
    ..registerFactory<GetAllProductsUseCase>(
      () => GetAllProductsUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory<AllProductsBloc>(
      () => AllProductsBloc(
        getAllProductsUseCase: serviceLocator(),
      ),
    )
    ..registerFactory<AllCategoriesBloc>(
      () => AllCategoriesBloc(
        getCategoriesUsecase: serviceLocator(),
      ),
    )
    ..registerFactory<GetBranchesByShopUsecase>(
      () => GetBranchesByShopUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<BranchesBloc>(
      () => BranchesBloc(
        getBranchesByShopUsecase: serviceLocator(),
      ),
    );
  // Debugging: Check if dependencies are correctly registered
}

void _initCardSwiper() {
  serviceLocator
    ..registerFactory<CardSwiperRemoteDataSource>(
      () => CardSwiperRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<CardSwiperRepository>(
      () => CardSwiperRepositoryImpl(
        remoteDataSource: serviceLocator(),
      ),
    )
    ..registerFactory<GetAllCardSwiperPicturesUseCase>(
      () => GetAllCardSwiperPicturesUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory<CardSwiperBloc>(
      () => CardSwiperBloc(
        getAllCardSwiperPicturesUseCase: serviceLocator(),
      ),
    );
}

void _initAuth() {
  serviceLocator
    ..registerFactory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(
        serviceLocator(),
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserSignUp(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserLogin(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => CurrentUser(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => LogoutUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UpdateUserProfile(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => SendPasswordResetEmail(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => ResetPassword(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => SendPasswordResetOTP(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => VerifyOTPAndResetPassword(
        serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => AuthBloc(
          userSignUp: serviceLocator(),
          userLogin: serviceLocator(),
          currentUser: serviceLocator(),
          appUserCubit: serviceLocator(),
          logoutUsecase: serviceLocator(),
          updateUserProfile: serviceLocator(),
          sendPasswordResetEmail: serviceLocator(),
          resetPassword: serviceLocator(),
          sendPasswordResetOTP: serviceLocator(),
          verifyOTPAndResetPassword: serviceLocator(),
          ),
    );
}

void _initCart() {
  serviceLocator
    ..registerFactory<CartRemoteDataSource>(
      // Register the data source
      () => CartRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<CartRepository>(
      // Register the repository
      () => CartRepositoryImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<AddCartItemUsecase>(
      // Register the use case for adding an item to the cart
      () => AddCartItemUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<RemoveCartItemUsecase>(
      // Register the use case for removing an item from the cart
      () => RemoveCartItemUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<GetCartItemsUsecase>(
      // Register the use case for getting all cart items
      () => GetCartItemsUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<UpdateCartItemUsecase>(
      // Register the use case for getting all cart items
      () => UpdateCartItemUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<CartBloc>(
      // Register the CartBloc
      () => CartBloc(
        addCartItemUsecase: serviceLocator(),
        removeCartItemUsecase: serviceLocator(),
        getCartItemsUsecase: serviceLocator(),
        updateCartItemUsecase: serviceLocator(),
      ),
    );
}

void _initRecentlyViewed() {
  serviceLocator
    ..registerFactory<RecentlyViewedRemoteDataSource>(
      () => RecentlyViewedRemoteDataSourceImpl(
        serviceLocator(), // Assuming you have a SupabaseClient registered
      ),
    )
    ..registerFactory<RecentlyViewedLocalDataSource>(
      () => RecentlyViewedLocalDataSourceImpl(
        Hive.box('recently_viewed'),
      ),
    )
    ..registerFactory<RecentRepository>(
      () => RecentRepoImpl(
        serviceLocator(),
        
      ),
    )
    ..registerFactory<AddRecentItemUsecase>(
      () => AddRecentItemUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<GetRecentItemsUsecase>(
      () => GetRecentItemsUsecase(
        serviceLocator(),
      ),
    )

    ..registerFactory<RemoveRecentItemUsecase>(
      () => RemoveRecentItemUsecase(
        serviceLocator(),
      ),
    )

    ..registerFactory<RecentBloc>(
      () => RecentBloc(
        getRecentItemsUsecase: serviceLocator(),
        addRecentItemUsecase: serviceLocator(),
        removeRecentItemUsecase: serviceLocator(),
      ),
    );
}

void _initSaved() {
  serviceLocator
    ..registerFactory<SavedRemoteDataSource>(
      () => SavedRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<SavedRepository>(
      () => SavedRepositoryImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<AddSavedItemUsecase>(
      () => AddSavedItemUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<RemoveSavedItemUsecase>(
      () => RemoveSavedItemUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<GetSavedItemsUsecase>(
      () => GetSavedItemsUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<SavedBloc>(
      () => SavedBloc(
        addSavedItemUsecase: serviceLocator(),
        removeSavedItemUsecase: serviceLocator(),
        getSavedItemsUsecase: serviceLocator(),
      ),
    );
}

void _initSalecard() {
  serviceLocator
    ..registerFactory<SaleCardRemoteDataSource>(
      () => SaleCardRemoteDataSourceImpl(
        serviceLocator(), // Assuming you use a SupabaseClient
      ),
    )
    ..registerFactory<SaleCardRepository>(
      () => SaleCardRepositoryImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<GetSaleCardAllUsecase>(
      () => GetSaleCardAllUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<SalecardBloc>(
      () => SalecardBloc(
        getSaleCardAllUsecase: serviceLocator(),
      ),
    );
}

void _initSaleProduct() {
  serviceLocator
    ..registerFactory<SaleProductRemoteDataSource>(
      () => SaleProductRemoteDataSourceImpl(
        serviceLocator(), // Assuming you use a SupabaseClient
      ),
    )
    ..registerFactory<SaleProductRepository>(
      () => SaleProductRepositoryImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<GetAllSaleProductsUsecase>(
      () => GetAllSaleProductsUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory<SaleProductBloc>(
      () => SaleProductBloc(
        getAllProductsUseCase: serviceLocator(),
      ),
    );
}

void _initOrder() {
  serviceLocator
    ..registerFactory<OrderRemoteDataSource>( 
      () => OrderRemoteDataSourceImpl(
        serviceLocator(), // Assuming you have a SupabaseClient registered
      ),
    )
    ..registerFactory<OrderRepository>(
      () => OrderRepositoryImpl(
        serviceLocator(),
        serviceLocator(),
      ),
    )
    ..registerFactory<CreateOrder>(
      () => CreateOrder(
        serviceLocator(),
      ),
    )
    ..registerFactory<GetUserOrders>(
      () => GetUserOrders(
        serviceLocator(),
      ),
    )
    ..registerFactory<GetOrderById>(
      () => GetOrderById(
        serviceLocator(),
      ),
    )
    ..registerFactory<CancelOrder>(
      () => CancelOrder(
        serviceLocator(),
      ),
    )
    
    ..registerFactory<UpdateOrderStatus>(
      () => UpdateOrderStatus(
        serviceLocator(),
      ),
    )
    ..registerFactory<OrderBloc>(
      () => OrderBloc(
        createOrder: serviceLocator(),
        getUserOrders: serviceLocator(),
        getOrderById: serviceLocator(),
        cancelOrder: serviceLocator(),
        updateOrderStatus: serviceLocator(),
      ),
    );
}

void _initNotifications() {
  serviceLocator
    // Data Source
    ..registerFactory<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    // Repository
    ..registerFactory<NotificationRepository>(
      () => NotificationRepositoryImpl(
        serviceLocator(),
      ),
    )
    // Use Cases
    ..registerFactory(
      () => GetNotificationsUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetUnreadCountUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => MarkAsReadUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => MarkAllAsReadUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => DeleteNotificationUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => SaveDeviceTokenUseCase(
        serviceLocator(),
      ),
    )
    // Bloc
    ..registerLazySingleton(
      () => NotificationBloc(
        getNotificationsUseCase: serviceLocator(),
        getUnreadCountUseCase: serviceLocator(),
        markAsReadUseCase: serviceLocator(),
        markAllAsReadUseCase: serviceLocator(),
        deleteNotificationUseCase: serviceLocator(),
        saveDeviceTokenUseCase: serviceLocator(),
        notificationRepository: serviceLocator(),
      ),
    );
}
// ... existing code ...

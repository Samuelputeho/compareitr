import 'package:compareitr/core/theme/app_pallete.dart';
import 'package:compareitr/core/widgets/offline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/likes/presentation/pages/like_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/shops/presentation/pages/home_page.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const WalletPage(), // You can keep or replace this one too
    const NotificationsPage(), // Notifications on 3rd icon
    const LikePage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  IconData _getIconData(int index, bool isSelected) {
    switch (index) {
      case 0:
        return isSelected ? IconlyBold.home : IconlyLight.home;
      case 1:
        return isSelected ? IconlyBold.wallet : IconlyLight.wallet;
      case 2:
        return isSelected ? IconlyBold.bag : IconlyLight.notification;
      case 3:
        return isSelected ? IconlyBold.heart : IconlyLight.heart;
      case 4:
        return isSelected ? IconlyBold.profile : IconlyLight.profile;
      default:
        return IconlyLight.home; // Default icon
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfflineIndicator(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        elevation: 0,
        items: List.generate(5, (index) {
          // Special handling for notifications icon (index 2) with badge
          if (index == 2) {
            return BottomNavigationBarItem(
              icon: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  int unreadCount = 0;
                  if (state is NotificationsLoaded) {
                    unreadCount = state.unreadCount;
                  }
                  return Badge(
                    label: Text('$unreadCount'),
                    isLabelVisible: unreadCount > 0,
                    child: Icon(
                      _getIconData(index, index == _selectedIndex),
                      size: 25,
                      color: index == _selectedIndex 
                          ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor 
                          : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                    ),
                  );
                },
              ),
              label: '',
            );
          }
          
          return BottomNavigationBarItem(
            icon: Icon(
              _getIconData(index, index == _selectedIndex),
              size: 25, // Adjust the icon size as needed
              color: index == _selectedIndex 
                  ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor 
                  : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
            ),
            label: '',
          );
        }),
        currentIndex: _selectedIndex,
        selectedItemColor: AppPallete.primaryColor,
        unselectedItemColor: AppPallete.secondaryColor,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

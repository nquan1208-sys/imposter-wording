import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/base/rx/obs_builder.dart';
import 'package:untitled/features/root/enums/navigation_bottom_tab_enum.dart';

class AppBottomNavigationBar extends ConsumerWidget {
  const AppBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStore = ref.watch(StoreProvider.app);
    return ObsBuilder(
      streams: [appStore.selectedBottomTabSubject],
      builder: (ctx) => BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: NavigationBottomTabExtension.toIndex(
          appStore.selectedBottomTabSubject.value,
        ),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          appStore.onBottomTabChange(
            NavigationBottomTabExtension.fromIndex(index),
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

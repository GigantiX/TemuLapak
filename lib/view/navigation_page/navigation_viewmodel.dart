
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/utils/logger.dart';

final navigationViewModelProvider =
    StateNotifierProvider<NavigationViewModel, int>((ref) {
  return NavigationViewModel();
});

class NavigationViewModel extends StateNotifier<int> {
  NavigationViewModel() : super(0);

  void setIndex(int index) {
    state = index;
    Logger.log("Current Tab Index: $index");
  }

  int get currentTab => state;
}
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/model/state/app_state.dart';

part 'listmerchant_viewmodel.g.dart';

enum MerchantCategory { nearest, drinks, food, snacks }

extension MerchantCategoryExtension on MerchantCategory {
  String get displayName {
    switch (this) {
      case MerchantCategory.nearest:
        return "Terdekat";
      case MerchantCategory.drinks:
        return "Minuman";
      case MerchantCategory.food:
        return "Makanan";
      case MerchantCategory.snacks:
        return "Cemilan";
    }
  }
}

@riverpod
class ListMerchantViewModel extends _$ListMerchantViewModel {
  @override
  AppState<String, Exception> build() {
    return AppState.idle();
  }
}

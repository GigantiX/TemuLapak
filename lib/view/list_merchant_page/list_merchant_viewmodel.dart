import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/location/location_services.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';

part 'list_merchant_viewmodel.g.dart';

enum MerchantCategory { nearest, drinks, food, snacks }

enum MerchantFilter { all, open, closed }

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

  String get firebaseCategory {
    switch (this) {
      case MerchantCategory.nearest:
        return ""; // Special case, not used for Firebase query
      case MerchantCategory.drinks:
        return "Minuman";
      case MerchantCategory.food:
        return "Makanan";
      case MerchantCategory.snacks:
        return "Cemilan";
    }
  }
}

extension MerchantFilterExtension on MerchantFilter {
  String get displayName {
    switch (this) {
      case MerchantFilter.all:
        return "Semua";
      case MerchantFilter.open:
        return "Buka";
      case MerchantFilter.closed:
        return "Tutup";
    }
  }
}

// Provider for MerchantService
@riverpod
MerchantService merchantService(ref) {
  return MerchantService();
}

// Provider for LocationServices
@riverpod
LocationServices locationServices(ref) {
  return LocationServices.instance;
}

@riverpod
class ListMerchantViewModel extends _$ListMerchantViewModel {
  List<MerchantModel> _originalMerchants = [];
  
  @override
  AppState<List<MerchantModel>, Exception> build() {
    return AppState.idle();
  }

  /// Fetch merchants based on category
  Future<void> fetchMerchants(MerchantCategory category) async {
    _updateState(AppState.loading());
    
    try {
      Logger.log("LISTVM - Fetching merchants for category: ${category.displayName}");
      
      List<MerchantModel> merchants;
      
      switch (category) {
        case MerchantCategory.nearest:
          merchants = await _fetchNearestMerchants();
          break;
        case MerchantCategory.drinks:
        case MerchantCategory.food:
        case MerchantCategory.snacks:
          merchants = await _fetchMerchantsByCategory(category.firebaseCategory);
          break;
      }
      
      // Store original data for filtering
      _originalMerchants = merchants;
      
      Logger.log("LISTVM - Successfully fetched ${merchants.length} merchants");
      _updateState(AppState.success(merchants));
      
    } catch (e) {
      Logger.error("LISTVM - Error fetching merchants", error: e);
      _updateState(AppState.error(
        Exception(e.toString()),
        message: 'Failed to load merchants'
      ));
    }
  }

  /// Apply filter to current merchants
  void applyFilter(MerchantFilter filter) {
    if (_originalMerchants.isEmpty) {
      Logger.log("LISTVM - Cannot apply filter, no merchants loaded");
      return;
    }
    
    List<MerchantModel> filteredMerchants;
    
    switch (filter) {
      case MerchantFilter.all:
        filteredMerchants = _originalMerchants;
        break;
      case MerchantFilter.open:
        filteredMerchants = _originalMerchants.where((m) => m.merchantStatus == true).toList();
        break;
      case MerchantFilter.closed:
        filteredMerchants = _originalMerchants.where((m) => m.merchantStatus == false).toList();
        break;
    }
    
    Logger.log("LISTVM - Applied filter ${filter.displayName}, ${filteredMerchants.length} merchants");
    _updateState(AppState.success(filteredMerchants));
  }

  /// Refresh merchants data
  Future<void> refreshMerchants(MerchantCategory category) async {
    Logger.log("LISTVM - Refreshing merchants for category: ${category.displayName}");
    await fetchMerchants(category);
  }

  /// Private method to update state safely
  void _updateState(AppState<List<MerchantModel>, Exception> newState) {
    state = newState;
  }

  /// Fetch nearest merchants
  Future<List<MerchantModel>> _fetchNearestMerchants() async {
    final locationService = ref.read(locationServicesProvider);
    final position = await locationService.getCurrentLocation();
    
    if (position == null) {
      throw Exception('Location not available. Please enable GPS.');
    }
    
    final merchantService = ref.read(merchantServiceProvider);
    return await merchantService.getNearbyMerchants(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusInKm: 20.0, // 20km radius for list page
      limit: 50, // Higher limit for list page
    );
  }

  /// Fetch merchants by category
  Future<List<MerchantModel>> _fetchMerchantsByCategory(String category) async {
    final merchantService = ref.read(merchantServiceProvider);
    return await merchantService.getMerchantsByCategory(category);
  }
}

// Provider for current filter state
@riverpod
class MerchantFilterState extends _$MerchantFilterState {
  @override
  MerchantFilter build() {
    return MerchantFilter.all;
  }

  void setFilter(MerchantFilter filter) {
    Logger.log("Filter changed to: ${filter.displayName}");
    state = filter;
  }
}
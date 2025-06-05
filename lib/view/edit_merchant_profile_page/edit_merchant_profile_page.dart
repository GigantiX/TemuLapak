import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/edit_merchant_profile_page/edit_merchant_profile_viewmodel.dart';

class EditMerchantProfilePage extends ConsumerStatefulWidget {
  const EditMerchantProfilePage({super.key});

  @override
  ConsumerState<EditMerchantProfilePage> createState() =>
      _EditMerchantProfilePageState();
}

class _EditMerchantProfilePageState
    extends ConsumerState<EditMerchantProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _categories = ["Makanan", "Minuman", "Cemilan"];
  final List<ProductField> _productFields = [];

  List<String> _selectedCategories = [];
  bool _isInitialized = false;
  bool _hasChanges = false;
  ProviderSubscription<AppState<String, Exception>>? _subscription;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // To track original data for comparison
  MerchantModel? _originalMerchant;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  void _initializeData() {
    ref.read(editMerchantDataViewModelProvider.notifier).loadMerchantData();
    _subscription = ref.listenManual(
        editMerchantProfileViewModelProvider, _handleStateChanges);
  }

  @override
  void dispose() {
    _subscription?.close();
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _descController.dispose();

    for (var field in _productFields) {
      field.nameController.dispose();
      field.priceController.dispose();
    }

    super.dispose();
  }

  void _handleStateChanges(AppState<String, Exception>? previous,
      AppState<String, Exception> current) {
    current.when(
      idle: () {},
      loading: () {
        Loading.show(context);
      },
      success: (message) {
        Logger.log("SUCCESS STATE TRIGGERED: $message");

        if (mounted) {
          Loading.hide();
          
          // Show success animation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 2),
            ),
          );

          Future.delayed(Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop(true);
          });
        }
      },
      error: (error, message) {
        Logger.error("ERROR STATE TRIGGERED: $message");
        Loading.hide();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(message ??
                        "Gagal memperbarui profil penjual. Silakan coba lagi."),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  void _populateFields(MerchantModel merchant) {
    Logger.log("Populating fields with merchant data");

    _originalMerchant = merchant;

    _nameController.text = merchant.merchantName ?? '';
    _descController.text = merchant.merchantDesc ?? '';
    _selectedCategories = List<String>.from(merchant.merchantCategory ?? []);

    // Clear existing product fields
    for (var field in _productFields) {
      field.nameController.dispose();
      field.priceController.dispose();
    }
    _productFields.clear();

    // Add product fields based on existing products
    if (merchant.products != null && merchant.products!.isNotEmpty) {
      for (var product in merchant.products!) {
        final nameController =
            TextEditingController(text: product.productName ?? '');
        final priceController =
            TextEditingController(text: product.productPrice ?? '');
        _productFields.add(ProductField(
          nameController: nameController,
          priceController: priceController,
        ));
      }
    } else {
      _addProductField();
    }

    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _descController.addListener(_onFieldChanged);

    setState(() {
      _isInitialized = true;
    });

    Logger.log("Fields populated successfully");
  }

  void _onFieldChanged() {
    if (_originalMerchant != null) {
      setState(() {
        _hasChanges = _hasDataChanged();
      });
    }
  }

  bool _hasDataChanged() {
    if (_originalMerchant == null) return true;

    // Check if image changed
    final imageState = ref.read(editPickImageViewModelProvider);
    final hasImageChanged = imageState.maybeWhen(
      success: (file) => file != null,
      orElse: () => false,
    );

    if (hasImageChanged) return true;

    // Check basic fields
    if (_nameController.text != (_originalMerchant!.merchantName ?? '')) {
      return true;
    }
    if (_descController.text != (_originalMerchant!.merchantDesc ?? '')) {
      return true;
    }

    // Check categories
    final originalCategories =
        Set<String>.from(_originalMerchant!.merchantCategory ?? []);
    final currentCategories = Set<String>.from(_selectedCategories);
    if (originalCategories.difference(currentCategories).isNotEmpty ||
        currentCategories.difference(originalCategories).isNotEmpty) {
      return true;
    }

    // Check products
    final originalProducts = _originalMerchant!.products ?? [];
    if (originalProducts.length != _productFields.length) return true;

    for (int i = 0;
        i < _productFields.length && i < originalProducts.length;
        i++) {
      final currentName = _productFields[i].nameController.text;
      final currentPrice = _productFields[i].priceController.text;
      final originalName = originalProducts[i].productName ?? '';
      final originalPrice = originalProducts[i].productPrice ?? '';

      if (currentName != originalName || currentPrice != originalPrice) {
        return true;
      }
    }

    return false;
  }

  void _addProductField() {
    Logger.log("Adding new product field");
    setState(() {
      final nameController = TextEditingController();
      final priceController = TextEditingController();
      
      nameController.addListener(_onFieldChanged);
      priceController.addListener(_onFieldChanged);
      
      _productFields.add(ProductField(
        nameController: nameController,
        priceController: priceController,
      ));
    });
  }

  void _removeProductField() {
    Logger.log("Removing last product field");
    if (_productFields.length > 1) {
      setState(() {
        final field = _productFields.removeLast();
        field.nameController.dispose();
        field.priceController.dispose();
        _hasChanges = _hasDataChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantState = ref.watch(editMerchantDataViewModelProvider);
    final imageState = ref.watch(editPickImageViewModelProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      body: merchantState.when(
        idle: () => _buildLoadingState(isTablet),
        loading: () => _buildLoadingState(isTablet),
        success: (merchant) {
          if (!_isInitialized) {
            _populateFields(merchant);
          }

          return !_isInitialized
              ? _buildLoadingState(isTablet)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildMainContent(merchant, imageState, isTablet),
                  ),
                );
        },
        error: (error, message) => _buildErrorState(message, isTablet),
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet) {
    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      appBar: AppBar(
        title: Text('Edit Profil Penjual'),
        backgroundColor: MyColor.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MyColor.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: MyColor.orange,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Memuat data profil...',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? message, bool isTablet) {
    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      appBar: AppBar(
        title: Text('Edit Profil Penjual'),
        backgroundColor: MyColor.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 40 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: isTablet ? 72 : 64,
                  color: Colors.red[400],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Gagal Memuat Data',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  color: MyColor.blackPlain,
                ),
              ),
              SizedBox(height: 12),
              Text(
                message ?? "Terjadi kesalahan saat memuat data merchant",
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(editMerchantDataViewModelProvider.notifier)
                      .loadMerchantData();
                },
                icon: Icon(Icons.refresh),
                label: Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColor.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 24,
                    vertical: isTablet ? 16 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(MerchantModel merchant, AppState<File?, Exception> imageState, bool isTablet) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Simple App Bar
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: MyColor.orange,
          foregroundColor: Colors.white,
          title: Text(
            'Edit Profil Penjual',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: isTablet ? 24 : 20,
            ),
          ),
        ),

        // Form Content
        SliverToBoxAdapter(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 20,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Information Section
                  _buildSectionCard(
                    title: "Informasi Toko",
                    icon: Icons.store_outlined,
                    isTablet: isTablet,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: "Nama Toko / Dagangan",
                          hint: "Contoh: Warung Makan Bu Sari",
                          icon: Icons.storefront,
                          isTablet: isTablet,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama toko tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        _buildImageSection(imageState, merchant, isTablet),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Description Section
                  _buildSectionCard(
                    title: "Deskripsi",
                    icon: Icons.description_outlined,
                    isTablet: isTablet,
                    child: _buildTextField(
                      controller: _descController,
                      label: "Deskripsi Toko / Dagangan",
                      hint: "Ceritakan tentang toko dan produk Anda...",
                      icon: Icons.edit_note,
                      maxLines: 4,
                      isTablet: isTablet,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),

                  SizedBox(height: 24),

                  // Categories Section
                  _buildSectionCard(
                    title: "Kategori Produk",
                    subtitle: "Pilih minimal 1 kategori",
                    icon: Icons.category_outlined,
                    isTablet: isTablet,
                    child: _buildCategoryChips(isTablet),
                  ),

                  SizedBox(height: 24),

                  // Products Section
                  _buildSectionCard(
                    title: "Produk yang Dijual",
                    subtitle: "Kelola produk yang Anda jual",
                    icon: Icons.inventory_2_outlined,
                    isTablet: isTablet,
                    child: _buildProductFields(isTablet),
                  ),

                  SizedBox(height: 40),

                  // Save Button
                  _buildSaveButton(isTablet),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 28 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  decoration: BoxDecoration(
                    color: MyColor.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: MyColor.orange,
                    size: isTablet ? 28 : 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: MyColor.blackPlain,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: MyColor.blackPlain,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: MyColor.blackPlain,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: isTablet ? 18 : 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: MyColor.orange, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: maxLines > 1 ? 20 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(AppState<File?, Exception> imageState, MerchantModel merchant, bool isTablet) {
    final aspectRatio = isTablet ? 2.5 : 16 / 9;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Foto Toko / Dagangan",
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: MyColor.blackPlain,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: imageState.maybeWhen(
                  success: (file) => file != null ? Colors.amber.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  orElse: () => Colors.grey.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                imageState.maybeWhen(
                  success: (file) => file != null ? 'Akan diperbarui' : 'Tetap sama',
                  orElse: () => 'Tetap sama',
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: imageState.maybeWhen(
                    success: (file) => file != null ? Colors.amber[700] : Colors.grey[600],
                    orElse: () => Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageState.when(
                idle: () => _buildCurrentImage(merchant, isTablet),
                loading: () => Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: MyColor.orange,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Memuat gambar...',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                success: (file) => file != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            file,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: Colors.amber[400],
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Baru',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildCurrentImage(merchant, isTablet),
                error: (error, message) => Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: isTablet ? 48 : 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          message ?? 'Terjadi kesalahan',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: isTablet ? 14 : 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildImageButton(
                icon: Icons.camera_alt_outlined,
                label: "Kamera",
                isTablet: isTablet,
                onPressed: () {
                  ref
                      .read(editPickImageViewModelProvider.notifier)
                      .pickImage(ImageSource.camera);
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildImageButton(
                icon: Icons.photo_library_outlined,
                label: "Galeri",
                isTablet: isTablet,
                onPressed: () {
                  ref
                      .read(editPickImageViewModelProvider.notifier)
                      .pickImage(ImageSource.gallery);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentImage(MerchantModel merchant, bool isTablet) {
    if (merchant.merchantImgUrl != null && merchant.merchantImgUrl!.isNotEmpty) {
      return Image.network(
        merchant.merchantImgUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[100]!,
                  Colors.grey[50]!,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: isTablet ? 48 : 40,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gambar tidak dapat dimuat',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                color: MyColor.orange,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[100]!,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                color: MyColor.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: isTablet ? 48 : 40,
                color: MyColor.orange,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Belum Ada Foto',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: MyColor.blackPlain,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tambahkan foto untuk menarik pelanggan',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyColor.orange.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: MyColor.orange,
                  size: isTablet ? 22 : 20,
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: MyColor.orange,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isTablet) {
    return Wrap(
      spacing: isTablet ? 16 : 12,
      runSpacing: 12,
      children: _categories.map((category) {
        final isSelected = _selectedCategories.contains(category);
        return FilterChip(
          label: Text(
            category,
            style: TextStyle(
              color: isSelected ? Colors.white : MyColor.orange,
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
          selected: isSelected,
          selectedColor: MyColor.orange,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(
              color: isSelected ? MyColor.orange : Colors.grey[300]!,
              width: 2,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 12 : 10,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(category);
              } else {
                _selectedCategories.remove(category);
              }
              _hasChanges = _hasDataChanged();
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildProductFields(bool isTablet) {
    return Column(
      children: [
        ..._productFields.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          
          return Container(
            margin: EdgeInsets.only(bottom: 20),
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 10 : 8),
                      decoration: BoxDecoration(
                        color: MyColor.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: MyColor.orange,
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Produk ${index + 1}',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: MyColor.blackPlain,
                        ),
                      ),
                    ),
                    if (_productFields.length > 1)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _productFields.removeAt(index);
                              product.nameController.dispose();
                              product.priceController.dispose();
                              _hasChanges = _hasDataChanged();
                            });
                          },
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red[400],
                            size: isTablet ? 24 : 20,
                          ),
                          tooltip: 'Hapus produk',
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Column(
                  children: [
                    _buildProductTextField(
                      controller: product.nameController,
                      label: "Nama Produk",
                      hint: "Contoh: Nasi Gudeg",
                      icon: Icons.fastfood_outlined,
                      isTablet: isTablet,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Wajib diisi";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildProductTextField(
                      controller: product.priceController,
                      label: "Harga",
                      hint: "15000",
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      prefix: "Rp ",
                      isTablet: isTablet,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Wajib diisi";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        
        // Add Product Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MyColor.orange.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _addProductField,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 24 : 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 10 : 8),
                      decoration: BoxDecoration(
                        color: MyColor.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: MyColor.orange,
                        size: isTablet ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Tambah Produk',
                      style: TextStyle(
                        color: MyColor.orange,
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefix,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: MyColor.blackPlain,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: MyColor.blackPlain,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: MyColor.blackPlain,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: isTablet ? 16 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: MyColor.orange, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isTablet ? 16 : 12,
            ),
            errorStyle: TextStyle(fontSize: isTablet ? 13 : 11),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isTablet) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: double.infinity,
      height: isTablet ? 60 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _hasChanges 
              ? [MyColor.orange, MyColor.orange.withValues(alpha: 0.8)]
              : [Colors.grey[400]!, Colors.grey[500]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _hasChanges ? [
          BoxShadow(
            color: MyColor.orange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _hasChanges ? () async {
            Logger.log("Save Profile Button Pressed");

            if (_formKey.currentState!.validate()) {
              if (_selectedCategories.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Silakan pilih minimal satu kategori"),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                return;
              }

              try {
                List<Product> products = [];
                for (var field in _productFields) {
                  products.add(Product(
                    productName: field.nameController.text,
                    productPrice: field.priceController.text,
                  ));
                }

                final imageState = ref.read(editPickImageViewModelProvider);
                final File? imageFile = imageState.maybeWhen(
                  success: (file) => file,
                  orElse: () => null,
                );

                await ref
                    .read(editMerchantProfileViewModelProvider.notifier)
                    .updateMerchantProfile(
                      merchantName: _nameController.text,
                      merchantDesc: _descController.text,
                      merchantCategory: _selectedCategories,
                      products: products,
                      imageFile: imageFile != null ? XFile(imageFile.path) : null,
                    );
              } catch (e) {
                Logger.error("Unexpected error during merchant profile update: $e");
                Loading.hide();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Terjadi kesalahan: ${e.toString()}"),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text("Mohon lengkapi semua data yang diperlukan"),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          } : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Row(
                key: ValueKey(_hasChanges),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _hasChanges ? Icons.save : Icons.check_circle,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    _hasChanges ? 'Simpan Perubahan' : 'Tidak Ada Perubahan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber,
                color: Colors.amber[700],
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Perubahan Belum Disimpan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar tanpa menyimpan?',
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Keluar Tanpa Simpan',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Trigger save
              if (_formKey.currentState!.validate() && _selectedCategories.isNotEmpty) {
                // Auto-save logic here if needed
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Simpan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
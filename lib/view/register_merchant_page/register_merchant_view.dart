import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/utils/network_checker.dart';
import 'package:temulapak_app/view/register_merchant_page/register_merchant_viewmodel.dart';
import 'package:temulapak_app/view/widget/map_picker/map_picker_dialog.dart';

class RegisterMerchantPage extends ConsumerStatefulWidget {
  const RegisterMerchantPage({super.key});

  @override
  ConsumerState<RegisterMerchantPage> createState() =>
      _RegisterMerchantPageState();
}

class _RegisterMerchantPageState extends ConsumerState<RegisterMerchantPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _categories = ["Makanan", "Minuman", "Cemilan"];
  final _locationController = TextEditingController(text: "Pilih lokasi");
  final List<ProductField> _productFields = [];

  final List<String> _selectedCategories = [];
  LatLng? _selectedLocation;
  bool _isInitialized = false;
  ProviderSubscription<AppState<String, Exception>>? _subscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          _initializeData();
        } catch (e) {
          Logger.error("RegisterMerchant - Error in initialization", error: e);
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error initializing page: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  void _initializeData() {
    Logger.log("RegisterMerchant - Starting initialization");

    try {
      setState(() {
        if (_productFields.isEmpty) {
          _addProductField();
        }
        _isInitialized = true;
      });

      if (mounted) {
        _subscription = ref.listenManual(
          registerMerchantViewModelProvider,
          _handleStateChanges,
        );
        Logger.log("RegisterMerchant - Initialization completed successfully");
      }
    } catch (e) {
      Logger.error("RegisterMerchant - Error in _initializeData", error: e);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    _scrollController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();

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
        Loading.hide();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ));

          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              ref.read(registerMerchantViewModelProvider.notifier)
                  .navigateToProfile(context);
            }
          });
        }
      },
      error: (error, message) {
        Logger.error("ERROR STATE TRIGGERED: $message");
        Loading.hide();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message ??
                "Gagal mendaftar sebagai penjual. Silakan coba lagi."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
    );
  }

  void _addProductField() {
    Logger.log("Adding new product field");
    setState(() {
      _productFields.add(ProductField(
        nameController: TextEditingController(),
        priceController: TextEditingController(),
      ));
    });
  }

  Widget _buildRegisterButton(bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 60 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MyColor.orange, MyColor.orange.withValues(alpha: 0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MyColor.orange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Logger.log("Register Merchant Button Pressed");

            if (_formKey.currentState!.validate()) {
              await NetworkChecker.instance.run(
              context: context,
              action: () async {
                final imageState = ref.read(pickImageViewModelProvider);
                final File? imageFile = imageState.maybeWhen(
                  success: (file) => file,
                  orElse: () => null,
                );

                await ref
                    .read(registerMerchantViewModelProvider.notifier)
                    .registerMerchant(
                      name: _nameController.text,
                      description: _descController.text,
                      categories: _selectedCategories,
                      productFields: _productFields,
                      location: _selectedLocation,
                      imageFile: imageFile != null ? XFile(imageFile.path) : null,
                    );
                return true;
              },
            );
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
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Daftar Sebagai Penjual',
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
    );
  }

  // --- Other build methods remain the same ---
  // (No changes needed for the rest of the file)
  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(pickImageViewModelProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      body: !_isInitialized
          ? Center(child: CircularProgressIndicator(color: MyColor.orange))
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Simple App Bar
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: MyColor.orange,
                  foregroundColor: Colors.white,
                  title: Text(
                    'Daftar Penjual',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
                          // Progress Indicator
                          _buildProgressIndicator(),
                          SizedBox(height: 32),

                          // Store Name Section
                          _buildSectionCard(
                            title: "Informasi Toko",
                            icon: Icons.store_outlined,
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _nameController,
                                  label: "Nama Toko / Dagangan",
                                  hint: "Contoh: Warung Makan Bu Sari",
                                  icon: Icons.storefront,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Nama toko tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 24),
                                _buildImageSection(imageState, isTablet),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Description Section
                          _buildSectionCard(
                            title: "Deskripsi",
                            icon: Icons.description_outlined,
                            child: _buildTextField(
                              controller: _descController,
                              label: "Deskripsi Toko / Dagangan",
                              hint:
                                  "Ceritakan tentang toko dan produk Anda...",
                              icon: Icons.edit_note,
                              maxLines: 4,
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
                            child: _buildCategoryChips(isTablet),
                          ),

                          SizedBox(height: 24),

                          // Location Section
                          _buildSectionCard(
                            title: "Lokasi Toko",
                            subtitle:
                                "Tentukan lokasi awal untuk memulai berjualan",
                            icon: Icons.location_on_outlined,
                            child: _buildLocationPicker(isTablet),
                          ),

                          SizedBox(height: 24),

                          // Products Section
                          _buildSectionCard(
                            title: "Produk yang Dijual",
                            subtitle: "Tambahkan produk yang akan Anda jual",
                            icon: Icons.inventory_2_outlined,
                            child: _buildProductFields(isTablet),
                          ),

                          SizedBox(height: 40),

                          // Register Button
                          _buildRegisterButton(isTablet),

                          SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MyColor.orange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MyColor.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.how_to_reg,
              color: MyColor.orange,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Langkah 1 dari 1',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Lengkapi Profil Penjual',
                  style: TextStyle(
                    fontSize: 16,
                    color: MyColor.blackPlain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
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
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MyColor.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: MyColor.orange,
                    size: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyColor.blackPlain,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
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
            fontSize: 16,
            color: MyColor.blackPlain,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
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

  Widget _buildImageSection(
      AppState<File?, Exception> imageState, bool isTablet) {
    final aspectRatio = isTablet ? 2.5 : 16 / 9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Foto Toko / Dagangan",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MyColor.blackPlain,
          ),
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
                idle: () => Container(
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
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: MyColor.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 30,
                          color: MyColor.orange,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Pilih Foto Toko',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: MyColor.blackPlain,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Foto yang menarik meningkatkan kepercayaan pelanggan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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
                            fontSize: 14,
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
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green[400],
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
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
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          message ?? 'Terjadi kesalahan',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 12,
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
                onPressed: () {
                  try {
                    ref
                        .read(pickImageViewModelProvider.notifier)
                        .pickImage(ImageSource.camera);
                  } catch (e) {
                    Logger.error("Error opening camera", error: e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tidak dapat membuka kamera'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildImageButton(
                icon: Icons.photo_library_outlined,
                label: "Galeri",
                onPressed: () {
                  try {
                    ref
                        .read(pickImageViewModelProvider.notifier)
                        .pickImage(ImageSource.gallery);
                  } catch (e) {
                    Logger.error("Error opening gallery", error: e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tidak dapat membuka galeri'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
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
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: MyColor.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: MyColor.orange,
                    fontSize: 14,
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
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLocationPicker(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                Logger.log("Maps button pressed");
                final locationState =
                    ref.read(locationPickerViewModelProvider);
                final initialLocation = locationState.maybeWhen(
                  success: (location) => location,
                  orElse: () => null,
                );

                Loading.show(context);
                await Future.delayed(Duration(milliseconds: 100));

                if (!mounted) return;

                final result = await showDialog<LatLng>(
                  context: context,
                  builder: (context) => MapPickerDialog(
                    initialLocation: _selectedLocation ?? initialLocation,
                  ),
                );

                if (!mounted) return;

                if (result != null) {
                  setState(() {
                    _selectedLocation = result;
                    _locationController.text = "Lokasi telah dipilih";
                  });
                }
                Logger.log("Selected location: $_selectedLocation");
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedLocation != null
                            ? Colors.green.withValues(alpha: 0.1)
                            : MyColor.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedLocation != null
                            ? Icons.location_on
                            : Icons.location_on_outlined,
                        color: _selectedLocation != null
                            ? Colors.green[600]
                            : MyColor.orange,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedLocation != null
                                ? 'Lokasi Dipilih'
                                : 'Pilih Lokasi Toko',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: MyColor.blackPlain,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedLocation != null
                                ? 'Lokasi berhasil ditentukan'
                                : 'Ketuk untuk membuka peta',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_selectedLocation == null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '* Lokasi wajib dipilih',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[400],
              ),
            ),
          ),
      ],
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
            padding: EdgeInsets.all(20),
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MyColor.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: MyColor.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Produk ${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: MyColor.blackPlain,
                        ),
                      ),
                    ),
                    if (_productFields.length > 1)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _productFields.removeAt(index);
                            product.nameController.dispose();
                            product.priceController.dispose();
                          });
                        },
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red[400],
                        ),
                        tooltip: 'Hapus produk',
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      prefix: "Rp ",
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
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MyColor.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: MyColor.orange,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Tambah Produk',
                      style: TextStyle(
                        color: MyColor.orange,
                        fontSize: 16,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
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
            fontSize: 14,
            color: MyColor.blackPlain,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: MyColor.blackPlain,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
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
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorStyle: TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
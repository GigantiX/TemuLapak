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
    extends ConsumerState<EditMerchantProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _categories = ["Makanan", "Minuman", "Cemilan"];
  final List<ProductField> _productFields = [];

  List<String> _selectedCategories = [];
  bool _isInitialized = false;
  ProviderSubscription<AppState<String, Exception>>? _subscription;

  // To track original data for comparison
  MerchantModel? _originalMerchant;
  File? _originalImageFile;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  void _initializeData() {
    // Load merchant data first
    ref.read(editMerchantDataViewModelProvider.notifier).loadMerchantData();

    _subscription = ref.listenManual(
        editMerchantProfileViewModelProvider, _handleStateChanges);
  }

  @override
  void dispose() {
    _subscription?.close();
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ));

          Future.delayed(Duration(seconds: 2), () {
            Loading.hide();
            if (mounted)
              Navigator.of(context)
                  .pop(true); // Return true to indicate success
          });
        }
      },
      error: (error, message) {
        Logger.error("ERROR STATE TRIGGERED: $message");
        Loading.hide();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message ??
                "Gagal memperbarui profil penjual. Silakan coba lagi."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ));
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
      // Add at least one empty product field
      _addProductField();
    }

    setState(() {
      _isInitialized = true;
    });

    Logger.log("Fields populated successfully");
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _categories.map((category) {
        final isSelected = _selectedCategories.contains(category);
        return FilterChip(
          label: Text(
            category,
            style: TextStyle(
              color: isSelected ? MyColor.white : MyColor.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: isSelected,
          selectedColor: MyColor.orange,
          backgroundColor: MyColor.white,
          shape: StadiumBorder(
            side: BorderSide(
              color: MyColor.orange,
              width: 1.0,
            ),
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

  void _addProductField() {
    Logger.log("Adding new product field");
    setState(() {
      _productFields.add(ProductField(
        nameController: TextEditingController(),
        priceController: TextEditingController(),
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
      });
    }
  }

  List<Widget> _buildProductFields() {
    List<Widget> fields = [];

    for (int i = 0; i < _productFields.length; i++) {
      final product = _productFields[i];

      if (_productFields.length > 1) {
        fields.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            "Produk ${i + 1}",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ));
      }

      fields.add(Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: product.nameController,
                cursorColor: MyColor.orange,
                decoration: InputDecoration(
                  fillColor: MyColor.white,
                  filled: true,
                  labelText: "Nama Produk",
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                    color: MyColor.orange,
                  )),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                    color: MyColor.orange,
                  )),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Nama produk tidak boleh kosong";
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: product.priceController,
                cursorColor: MyColor.orange,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  fillColor: MyColor.white,
                  filled: true,
                  labelText: "Harga Produk",
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                    color: MyColor.orange,
                  )),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                    color: MyColor.orange,
                  )),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Harga tidak boleh kosong";
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ));
    }
    return fields;
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

  @override
  Widget build(BuildContext context) {
    final merchantState = ref.watch(editMerchantDataViewModelProvider);
    final imageState = ref.watch(editPickImageViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil Penjual'),
        backgroundColor: MyColor.white,
      ),
      backgroundColor: MyColor.whitePlain,
      body: merchantState.when(
        idle: () =>
            Center(child: CircularProgressIndicator(color: MyColor.orange)),
        loading: () =>
            Center(child: CircularProgressIndicator(color: MyColor.orange)),
        success: (merchant) {
          if (!_isInitialized) {
            _populateFields(merchant);
          }

          return !_isInitialized
              ? Center(child: CircularProgressIndicator(color: MyColor.orange))
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nama Toko / Dagangan",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _nameController,
                              cursorColor: MyColor.orange,
                              decoration: InputDecoration(
                                fillColor: MyColor.white,
                                filled: true,
                                hintText: "Nama Toko",
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                  color: MyColor.orange,
                                )),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: MyColor.orange,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nama Toko tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Foto Toko / Dagangan",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 5),
                            Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: imageState.when(
                                      idle: () => _buildCurrentImage(merchant),
                                      loading: () => Container(
                                        color: Colors.grey[300],
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      ),
                                      success: (file) => file != null
                                          ? Image.file(
                                              file,
                                              fit: BoxFit.cover,
                                            )
                                          : _buildCurrentImage(merchant),
                                      error: (_, message) => Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _buildCurrentImage(merchant),
                                          Container(
                                            color: Colors.black
                                                .withValues(alpha: 0.5),
                                            child: Center(
                                              child: Text(
                                                message ??
                                                    "Error loading image",
                                                style: TextStyle(
                                                    color: Colors.white),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(editPickImageViewModelProvider
                                            .notifier)
                                        .pickImage(ImageSource.camera);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: MyColor.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      iconColor: MyColor.white,
                                      foregroundColor: MyColor.white),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt),
                                      SizedBox(width: 5),
                                      Text("Camera"),
                                    ],
                                  ),
                                )),
                                SizedBox(width: 10),
                                Expanded(
                                    child: ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(editPickImageViewModelProvider
                                            .notifier)
                                        .pickImage(ImageSource.gallery);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: MyColor.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      iconColor: MyColor.white,
                                      foregroundColor: MyColor.white),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo_library),
                                      SizedBox(width: 5),
                                      Text("Gallery"),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Deskripsi Toko / Dagangan",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 5),
                            TextFormField(
                              controller: _descController,
                              cursorColor: MyColor.orange,
                              maxLines: 7,
                              minLines: 3,
                              decoration: InputDecoration(
                                fillColor: MyColor.white,
                                filled: true,
                                hintText: "Deskripsi Toko",
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                  color: MyColor.orange,
                                )),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: MyColor.orange,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Deskripsi tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Kategori Produk (min. 1)",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 5),
                            _buildCategoryChips(),
                            SizedBox(height: 20),
                            Text(
                              "Produk yang dijual",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            ..._buildProductFields(),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                if (_productFields.length > 1)
                                  Expanded(
                                    child: ElevatedButton(
                                        onPressed: _removeProductField,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: MyColor.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                            iconColor: MyColor.white,
                                            foregroundColor: MyColor.white),
                                        child: Text("Kurangi Produk")),
                                  ),
                                SizedBox(width: 10),
                                if (_productFields.length <= 1)
                                  Expanded(
                                    child: SizedBox(),
                                  ),
                                Expanded(
                                  child: ElevatedButton(
                                      onPressed: _addProductField,
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: MyColor.orange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                          iconColor: MyColor.white,
                                          foregroundColor: MyColor.white),
                                      child: Text("Tambah Produk")),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () async {
                                  Logger.log("Save Profile Button Pressed");

                                  // Check if there are any changes
                                  if (!_hasDataChanged()) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                          Text("Tidak ada perubahan profil"),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ));
                                    return;
                                  }

                                  // Step 1: Validate all form fields
                                  if (_formKey.currentState!.validate()) {
                                    if (_selectedCategories.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "Silakan pilih minimal satu kategori"),
                                        backgroundColor: Colors.red,
                                      ));
                                      return;
                                    }

                                    Logger.log(
                                        "Selected categories: $_selectedCategories");

                                    try {
                                      Logger.log(
                                          "All form fields validated successfully");

                                      // Step 2: Collect product data
                                      List<Product> products = [];
                                      for (var field in _productFields) {
                                        products.add(Product(
                                          productName:
                                              field.nameController.text,
                                          productPrice:
                                              field.priceController.text,
                                        ));
                                      }
                                      Logger.log(
                                          "Products collected: ${products.length} items");

                                      final imageState = ref
                                          .read(editPickImageViewModelProvider);
                                      final File? imageFile =
                                          imageState.maybeWhen(
                                        success: (file) => file,
                                        orElse: () => null,
                                      );

                                      await ref
                                          .read(
                                              editMerchantProfileViewModelProvider
                                                  .notifier)
                                          .updateMerchantProfile(
                                            merchantName: _nameController.text,
                                            merchantDesc: _descController.text,
                                            merchantCategory:
                                                _selectedCategories,
                                            products: products,
                                            imageFile: imageFile != null
                                                ? XFile(imageFile.path)
                                                : null,
                                          );
                                    } catch (e) {
                                      Logger.error(
                                          "Unexpected error during merchant profile update: $e");
                                      Loading.hide();

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "Terjadi kesalahan: ${e.toString()}"),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  } else {
                                    Logger.error(
                                        "Form validation failed, some fields are invalid");
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          "Mohon lengkapi semua data yang diperlukan"),
                                      backgroundColor: Colors.red,
                                    ));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: MyColor.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    iconColor: MyColor.white,
                                    foregroundColor: MyColor.white),
                                child: Text("Simpan"),
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      )),
                );
        },
        error: (error, message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading merchant data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                message ?? error.toString(),
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(editMerchantDataViewModelProvider.notifier)
                      .loadMerchantData();
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: MyColor.orange),
                child: Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentImage(MerchantModel merchant) {
    if (merchant.merchantImgUrl != null &&
        merchant.merchantImgUrl!.isNotEmpty) {
      return Image.network(
        merchant.merchantImgUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            "lib/assets/images/UploadImage.jpg",
            fit: BoxFit.cover,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[300],
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );
    } else {
      return Image.asset(
        "lib/assets/images/UploadImage.jpg",
        fit: BoxFit.cover,
      );
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/utils/logger.dart';
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

    // FIXED: Add null check before listening
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
        _isInitialized = true; // Allow UI to show even on error
      });
    }
    rethrow;
  }
  }

  @override
  void dispose() {
    _subscription?.close();
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

          Future.delayed(Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
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
          ));
        }
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(pickImageViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar menjadi Penjual'),
        backgroundColor: MyColor.white,
      ),
      backgroundColor: MyColor.whitePlain,
      body: !_isInitialized
          ? Center(child: CircularProgressIndicator(color: MyColor.orange))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        _buildImageSection(imageState),
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
                          "Lokasi Toko / Dagangan",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Atur lokasi sesuai dengan lokasi toko anda atau lokasi awal anda untuk memulai berjualan secara keliling.",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _locationController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    fillColor: MyColor.white,
                                    filled: true,
                                    hintText: "Pilih Lokasi",
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: MyColor.orange),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: MyColor.orange),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 1,
                                      horizontal: 10,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_selectedLocation == null) {
                                      return "Lokasi tidak boleh kosong";
                                    }
                                    return null;
                                  },
                                )),
                            SizedBox(width: 10),
                            Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Logger.log("Maps button pressed");
                                    //Show pop up maps
                                    final locationState = ref
                                        .read(locationPickerViewModelProvider);
                                    final initalLocation =
                                        locationState.maybeWhen(
                                      success: (location) => location,
                                      orElse: () => null,
                                    );

                                    Loading.show(context);

                                    await Future.delayed(
                                        Duration(milliseconds: 100));

                                    if (!mounted) return;

                                    final result = await showDialog<LatLng>(
                                      context: context,
                                      builder: (context) => MapPickerDialog(
                                        initialLocation:
                                            _selectedLocation ?? initalLocation,
                                      ),
                                    );

                                    if (!mounted) return;

                                    if (result != null) {
                                      setState(() {
                                        _selectedLocation = result;
                                        _locationController.text =
                                            "Lokasi telah dipilih";
                                      });
                                    }
                                    Logger.log(
                                        "Selected location: $_selectedLocation");
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
                                      Icon(Icons.share_location),
                                      SizedBox(width: 5),
                                      Text("Maps"),
                                    ],
                                  ),
                                ))
                          ],
                        ),
                        ref.watch(locationPickerViewModelProvider).maybeWhen(
                              error: (e, msg) => Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                    "Terjadi kesalahan saat pemilihan lokasi"),
                              ),
                              orElse: () => SizedBox.shrink(),
                            ),
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
                                        borderRadius: BorderRadius.circular(7),
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
                              Logger.log("Register Merchant Button Pressed");
                              // Step 1: Validate all form fields
                              if (_formKey.currentState!.validate()) {
                                // Step 2: Check image selection
                                final imageState =
                                    ref.read(pickImageViewModelProvider);
                                final File? imageFile = imageState.maybeWhen(
                                  success: (file) => file,
                                  orElse: () => null,
                                );

                                if (imageFile == null) {
                                  Logger.error(
                                      "No image selected for merchant");
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "Silakan pilih foto toko/dagangan terlebih dahulu"),
                                    backgroundColor: Colors.red,
                                  ));
                                  return;
                                }

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
                                  // Step 3: Collect product data
                                  List<Product> products = [];
                                  for (var field in _productFields) {
                                    products.add(Product(
                                      productName: field.nameController.text,
                                      productPrice: field.priceController.text,
                                    ));
                                  }
                                  Logger.log(
                                      "Products collected: ${products.length} items");

                                  final merchant = MerchantModel(
                                    uid: '',
                                    merchantStatus: true,
                                    merchantName: _nameController.text,
                                    merchantDesc: _descController.text,
                                    merchantLocLat: _selectedLocation!.latitude,
                                    merchantLocLong:
                                        _selectedLocation!.longitude,
                                    merchantImgUrl: null,
                                    merchantPopularity: 0,
                                    merchantCategory: _selectedCategories,
                                    products: products,
                                  );
                                  Logger.log(
                                      "Merchant model created: ${merchant.toMap()}");

                                  await ref
                                      .read(registerMerchantViewModelProvider
                                          .notifier)
                                      .registerMerchant(
                                        data: merchant,
                                        imageFile: XFile(imageFile.path),
                                      );
                                } catch (e) {
                                  Logger.error(
                                      "Unexpected error during merchant registration: $e");
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
                            child: Text("Daftar"),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ))),
    );
  }

  Widget _buildImageSection(AppState<File?, Exception> imageState) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
                idle: () => Image.asset(
                  "lib/assets/images/UploadImage.jpg",
                  fit: BoxFit.cover,
                ),
                loading: () => Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: MyColor.orange,
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Memuat gambar...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                success: (file) => file != null
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        "lib/assets/images/UploadImage.jpg",
                        fit: BoxFit.cover,
                      ),
                error: (error, message) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      "lib/assets/images/UploadImage.jpg",
                      fit: BoxFit.cover,
                    ),
                    Container(
                      color: Colors.red.withValues(alpha: 0.7),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              message ?? "Error loading image",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                // FIXED: Clear error state
                                ref.read(pickImageViewModelProvider.notifier).clearError();
                              },
                              child: Text(
                                'Tutup',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
                // FIXED: Add try-catch for image picking
                try {
                  ref
                      .read(pickImageViewModelProvider.notifier)
                      .pickImage(ImageSource.camera);
                } catch (e) {
                  Logger.error("Error opening camera", error: e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tidak dapat membuka kamera: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColor.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                iconColor: MyColor.white,
                foregroundColor: MyColor.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 5),
                  Text("Camera"),
                ],
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // FIXED: Add try-catch for image picking
                try {
                  ref
                      .read(pickImageViewModelProvider.notifier)
                      .pickImage(ImageSource.gallery);
                } catch (e) {
                  Logger.error("Error opening gallery", error: e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tidak dapat membuka galeri: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColor.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                iconColor: MyColor.white,
                foregroundColor: MyColor.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 5),
                  Text("Gallery"),
                ],
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 20),
    ],
  );
}
}

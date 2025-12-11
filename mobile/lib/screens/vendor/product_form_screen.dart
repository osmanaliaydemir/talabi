import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/currency.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/services/logger_service.dart';

class VendorProductFormScreen extends StatefulWidget {
  const VendorProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<VendorProductFormScreen> createState() =>
      _VendorProductFormScreenState();
}

class _VendorProductFormScreenState extends State<VendorProductFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  // late TextEditingController _categoryController; // Replaced by dropdown
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _preparationTimeController;

  bool _isAvailable = true;
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;
  bool _isUploading = false;

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = false;
  Currency _selectedCurrency = Currency.try_;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    // _categoryController = TextEditingController(
    //   text: widget.product?.category ?? '',
    // );
    // Initialize selected category if editing (need to map category name to ID if ID is not available in product)
    // Ideally Product model should have categoryId. For now we might need to rely on name matching or update Product model.
    // Assuming Product model will be updated or we just start fresh.
    // Actually, I should fetch categories first then set selected ID.
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stock?.toString() ?? '',
    );
    _preparationTimeController = TextEditingController(
      text: widget.product?.preparationTime?.toString() ?? '',
    );
    _isAvailable = widget.product?.isAvailable ?? true;
    _imageUrl = widget.product?.imageUrl;
    _selectedCurrency = widget.product?.currency ?? Currency.try_;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final categories = await _apiService.getCategories(
        language: AppLocalizations.of(context)?.localeName,
      );
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;

        // Try to match existing category
        if (widget.product?.categoryId != null) {
          _selectedCategoryId = widget.product!.categoryId;
        } else if (widget.product?.category != null) {
          final existing = categories.firstWhere(
            (c) => c['name'] == widget.product!.category,
            orElse: () => {},
          );
          if (existing.isNotEmpty) {
            _selectedCategoryId = existing['id'].toString();
          }
        }
      });
    } catch (e) {
      LoggerService().error(
        'Kategoriler yüklenemedi: $e',
        e,
        StackTrace.current,
      );
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    // _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isUploading = true;
        });

        // Upload image
        final imageUrl = await _apiService.uploadProductImage(
          await MultipartFile.fromFile(pickedFile.path),
        );

        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.vendorProductFormImageUploaded),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.vendorProductFormImageUploadError(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(localizations.vendorProductFormSourceCamera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(localizations.vendorProductFormSourceGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final localizations = AppLocalizations.of(context)!;

    try {
      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'categoryId': _selectedCategoryId,
        // 'category': _categoryController.text.isEmpty ? null : _categoryController.text, // Deprecated
        'price': double.parse(_priceController.text),
        'currency': _selectedCurrency.toInt(),
        'imageUrl': _imageUrl,
        'isAvailable': _isAvailable,
        'stock': _stockController.text.isEmpty
            ? null
            : int.parse(_stockController.text),
        'preparationTime': _preparationTimeController.text.isEmpty
            ? null
            : int.parse(_preparationTimeController.text),
      };

      if (widget.product == null) {
        // Create new product
        await _apiService.createProduct(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.vendorProductFormCreateSuccess),
            ),
          );
        }
      } else {
        // Update existing product
        await _apiService.updateProduct(widget.product!.id, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.vendorProductFormUpdateSuccess),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.vendorProductFormError(e.toString())),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEdit
              ? localizations.vendorProductFormEditTitle
              : localizations.vendorProductFormNewTitle,
        ),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            GestureDetector(
              onTap: _isUploading ? null : _showImageSourceDialog,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _isUploading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepPurple,
                        ),
                      )
                    : _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : _imageUrl != null
                    ? CachedNetworkImageWidget(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.cover,
                        maxWidth: 600,
                        maxHeight: 600,
                        borderRadius: BorderRadius.circular(12),
                        errorWidget: _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: localizations.vendorProductFormNameLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.fastfood),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.vendorProductFormNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: localizations.vendorProductFormDescriptionLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: localizations.vendorProductFormCategoryLabel,
                border: const OutlineInputBorder(),
                prefixIcon: _isLoadingCategories
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.category),
              ),
              items: _isLoadingCategories
                  ? []
                  : _categories.map((category) {
                      return DropdownMenuItem(
                        value: category['id'].toString(),
                        child: Text(category['name'] as String),
                      );
                    }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Kategori seçimi zorunludur';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Currency
            DropdownButtonFormField<Currency>(
              initialValue: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Para Birimi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              items: Currency.values.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text('${currency.symbol} ${currency.code}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: localizations.vendorProductFormPriceLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.vendorProductFormPriceRequired;
                }
                if (double.tryParse(value) == null) {
                  return localizations.vendorProductFormPriceInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Stock
            TextFormField(
              controller: _stockController,
              decoration: InputDecoration(
                labelText: localizations.vendorProductFormStockLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory),
                hintText: localizations.optional,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    int.tryParse(value) == null) {
                  return localizations.vendorProductFormInvalidNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Preparation time
            TextFormField(
              controller: _preparationTimeController,
              decoration: InputDecoration(
                labelText: localizations.vendorProductFormPreparationTimeLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.timer),
                hintText: localizations.optional,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    int.tryParse(value) == null) {
                  return localizations.vendorProductFormInvalidNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Availability switch
            SwitchListTile(
              title: Text(localizations.vendorProductFormInStockLabel),
              subtitle: Text(
                _isAvailable
                    ? localizations.vendorProductFormInStockDescription
                    : localizations.vendorProductFormOutOfStockDescription,
              ),
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
              },
              activeThumbColor: Colors.green,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEdit
                          ? localizations.updateButton
                          : localizations.createButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          localizations.vendorProductFormAddImage,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

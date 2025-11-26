import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/navigation_logger.dart';

class VendorProductFormScreen extends StatefulWidget {
  final Product? product;

  const VendorProductFormScreen({super.key, this.product});

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
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _preparationTimeController;

  bool _isAvailable = true;
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.product?.category ?? '',
    );
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Resim yüklendi')));
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Resim yüklenemedi: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
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

    try {
      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'category': _categoryController.text.isEmpty
            ? null
            : _categoryController.text,
        'price': double.parse(_priceController.text),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ürün oluşturuldu')));
        }
      } else {
        // Update existing product
        await _apiService.updateProduct(widget.product!.id, data);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ürün güncellendi')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEdit ? 'Ürün Düzenle' : 'Yeni Ürün'),
        backgroundColor: Colors.orange,
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
                    ? const Center(child: CircularProgressIndicator())
                    : _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : _imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                        ),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ürün Adı *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fastfood),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ürün adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Fiyat *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Fiyat gerekli';
                }
                if (double.tryParse(value) == null) {
                  return 'Geçerli bir fiyat girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Stock
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Stok Miktarı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
                hintText: 'Opsiyonel',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    int.tryParse(value) == null) {
                  return 'Geçerli bir sayı girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Preparation time
            TextFormField(
              controller: _preparationTimeController,
              decoration: const InputDecoration(
                labelText: 'Hazırlık Süresi (dakika)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
                hintText: 'Opsiyonel',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    int.tryParse(value) == null) {
                  return 'Geçerli bir sayı girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Availability switch
            SwitchListTile(
              title: const Text('Stokta'),
              subtitle: Text(
                _isAvailable
                    ? 'Ürün müşterilere gösterilecek'
                    : 'Ürün stok dışı olarak işaretlenecek',
              ),
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
              },
              activeColor: Colors.green,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
                      isEdit ? 'Güncelle' : 'Oluştur',
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text('Resim Ekle', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}

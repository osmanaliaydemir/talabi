import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';

class DeliveryProofScreen extends StatefulWidget {
  final int orderId;

  const DeliveryProofScreen({super.key, required this.orderId});

  @override
  State<DeliveryProofScreen> createState() => _DeliveryProofScreenState();
}

class _DeliveryProofScreenState extends State<DeliveryProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _notesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    print('DeliveryProofScreen: Taking photo - OrderId: ${widget.orderId}');
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      print('DeliveryProofScreen: Photo taken - Path: ${photo.path}');
      setState(() {
        _image = File(photo.path);
      });
    }
  }

  Future<void> _submitProof() async {
    print('DeliveryProofScreen: Submitting proof - OrderId: ${widget.orderId}');
    if (!_formKey.currentState!.validate()) {
      print('DeliveryProofScreen: Form validation failed');
      return;
    }
    if (_image == null) {
      print('DeliveryProofScreen: No image provided');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo of the delivery')),
      );
      return;
    }

    if (_signatureController.isEmpty) {
      print('DeliveryProofScreen: No signature provided');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please obtain a signature')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final courierService = CourierService();

      // Upload image
      print('DeliveryProofScreen: Uploading image...');
      String photoUrl = await courierService.uploadImage(_image!);
      print('DeliveryProofScreen: Image uploaded - URL: $photoUrl');

      // Process and upload signature
      String? signatureUrl;
      if (_signatureController.isNotEmpty) {
        print('DeliveryProofScreen: Processing signature...');
        final Uint8List? data = await _signatureController.toPngBytes();
        if (data != null) {
          final tempDir = await getTemporaryDirectory();
          final file = await File(
            '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
          ).create();
          await file.writeAsBytes(data);
          signatureUrl = await courierService.uploadImage(file);
          print('DeliveryProofScreen: Signature uploaded - URL: $signatureUrl');
        }
      }

      print('DeliveryProofScreen: Submitting proof to backend...');
      await courierService.submitProof(
        widget.orderId,
        photoUrl,
        signatureUrl,
        _notesController.text.isEmpty ? null : _notesController.text,
      );

      print(
        'DeliveryProofScreen: Proof submitted successfully - OrderId: ${widget.orderId}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery proof submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e, stackTrace) {
      print('DeliveryProofScreen: ERROR submitting proof - $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Failed to')
                  ? e.toString()
                  : (AppLocalizations.of(context)?.failedToSubmitProof ??
                        'Error: ${e.toString()}'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print('DeliveryProofScreen: Back button pressed');
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Delivery Proof'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '1. Take Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _image != null
                      ? Image.file(_image!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text('Tap to take photo'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                '2. Signature',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Signature(
                      controller: _signatureController,
                      height: 200,
                      backgroundColor: Colors.white,
                    ),
                    Container(
                      color: Colors.grey[200],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _signatureController.clear(),
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                '3. Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Left at front door, etc.',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProof,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.teal)
                    : const Text('Submit Proof & Complete Delivery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

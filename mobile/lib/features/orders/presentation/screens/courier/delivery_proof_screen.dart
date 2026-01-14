import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';

class DeliveryProofScreen extends StatefulWidget {
  const DeliveryProofScreen({super.key, required this.orderId});
  final String orderId;

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
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
    }
  }

  Future<void> _submitProof() async {
    if (!_formKey.currentState!.validate()) {
      LoggerService().warning('DeliveryProofScreen: Form validation failed');
      return;
    }
    if (_image == null) {
      LoggerService().warning('DeliveryProofScreen: No image provided');
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.pleaseTakePhoto ??
                'Please take a photo of the delivery',
          ),
        ),
      );
      return;
    }

    if (_signatureController.isEmpty) {
      LoggerService().warning('DeliveryProofScreen: No signature provided');
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.pleaseObtainSignature ?? 'Please obtain a signature',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final courierService = CourierService();

      // Upload image
      final String photoUrl = await courierService.uploadImage(_image!);

      // Process and upload signature
      String? signatureUrl;
      if (_signatureController.isNotEmpty) {
        final Uint8List? data = await _signatureController.toPngBytes();
        if (data != null) {
          final tempDir = await getTemporaryDirectory();
          final file = await File(
            '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
          ).create();
          await file.writeAsBytes(data);
          signatureUrl = await courierService.uploadImage(file);
        }
      }

      await courierService.submitProof(
        widget.orderId,
        photoUrl,
        signatureUrl,
        _notesController.text.isEmpty ? null : _notesController.text,
      );
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.deliveryProofSubmittedSuccessfully ??
                  'Delivery proof submitted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'DeliveryProofScreen: ERROR submitting proof',
        e,
        stackTrace,
      );
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
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(localizations?.deliveryProof ?? 'Delivery Proof'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '1. ${localizations?.takePhoto ?? 'Take Photo'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                          children: [
                            const Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localizations?.takePhoto ?? 'Tap to take photo',
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                '2. ${localizations?.signature ?? 'Signature'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                            label: Text(localizations?.clear ?? 'Clear'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                '3. ${localizations?.notes ?? 'Notes'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: localizations?.notesOptional ?? 'Notes (Optional)',
                  border: const OutlineInputBorder(),
                  hintText:
                      localizations?.leftAtFrontDoor ??
                      'Left at front door, etc.',
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
                    ? const CircularProgressIndicator(color: Colors.teal)
                    : Text(
                        localizations?.submitProofAndCompleteDelivery ??
                            'Submit Proof & Complete Delivery',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

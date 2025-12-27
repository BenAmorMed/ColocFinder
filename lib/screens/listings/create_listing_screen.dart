import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../models/listing_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedRoomType = AppConstants.roomTypes[0];
  final Map<String, bool> _amenities = {
    for (var amenity in AppConstants.availableAmenities) amenity: false
  };
  
  final List<File> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _handleCreate() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFiles.isEmpty) {
        Helpers.showSnackBar(context, 'Please add at least one image', isError: true);
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final listingProvider = Provider.of<ListingProvider>(context, listen: false);
      
      if (authProvider.userModel == null) return;

      final newListing = ListingModel(
        id: '', // Will be set by Firestore
        userId: authProvider.userModel!.id,
        userName: authProvider.userModel!.name,
        userPhoto: authProvider.userModel!.photoUrl,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        roomType: _selectedRoomType,
        images: [], // Will be uploaded and updated
        amenities: _amenities,
        availableFrom: DateTime.now(),
        createdAt: DateTime.now(),
        isActive: true,
      );

      final success = await listingProvider.createListingWithImages(newListing, _imageFiles);

      if (!mounted) return;

      if (success) {
        Helpers.showSnackBar(context, 'Listing created successfully!');
        Navigator.pop(context);
      } else {
        Helpers.showSnackBar(
          context,
          listingProvider.errorMessage ?? 'Failed to create listing',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photos Section
              _buildSectionTitle('Photos'),
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _titleController,
                label: 'Title',
                hintText: 'e.g., Cozy Private Room in Downtown',
                prefixIcon: Icons.title_rounded,
                validator: (v) => Validators.validateRequired(v, 'Title'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hintText: 'Describe the room, the apartment, and the roommates...',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
                validator: (v) => Validators.validateRequired(v, 'Description'),
              ),
              
              const SizedBox(height: 24),
              
              // Details Section
              _buildSectionTitle('Listing Details'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'Price (TND/month)',
                      hintText: '0',
                      prefixIcon: Icons.money_rounded,
                      keyboardType: TextInputType.number,
                      validator: Validators.validatePrice,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoomTypeDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _locationController,
                label: 'Location',
                hintText: 'e.g., Tunis, Ariana, Sousse...',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => Validators.validateRequired(v, 'Location'),
              ),
              
              const SizedBox(height: 24),
              
              // Amenities Section
              _buildSectionTitle('Amenities'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.availableAmenities.map((amenity) {
                  final isSelected = _amenities[amenity] ?? false;
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _amenities[amenity] = selected;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 40),
              
              Consumer<ListingProvider>(
                builder: (context, listingProvider, _) {
                  return CustomButton(
                    text: 'Create Listing',
                    onPressed: _handleCreate,
                    isLoading: listingProvider.isLoading,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imageFiles.length + 1,
            itemBuilder: (context, index) {
              if (index == _imageFiles.length) {
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                  ),
                );
              }

              return Stack(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_imageFiles[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_imageFiles.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Add at least one photo of the room',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildRoomTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRoomType,
      decoration: InputDecoration(
        labelText: 'Room Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: AppConstants.roomTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRoomType = value;
          });
        }
      },
    );
  }
}

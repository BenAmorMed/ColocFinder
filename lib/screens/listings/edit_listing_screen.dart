import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/listing_provider.dart';
import '../../utils/image_helper.dart';
import '../../models/listing_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';


class EditListingScreen extends StatefulWidget {
  final ListingModel listing;

  const EditListingScreen({
    super.key,
    required this.listing,
  });

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  
  late String _selectedRoomType;
  late Map<String, bool> _amenities;
  
  final List<File> _newImageFiles = [];
  late List<String> _existingImages;
  final List<String> _removedImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing.title);
    _descriptionController = TextEditingController(text: widget.listing.description);
    _priceController = TextEditingController(text: widget.listing.price.toStringAsFixed(0));
    _locationController = TextEditingController(text: widget.listing.location);
    final roomType = widget.listing.roomType;
    _selectedRoomType = AppConstants.roomTypes.contains(roomType)
        ? roomType
        : AppConstants.roomTypes[0];
    _existingImages = List.from(widget.listing.images);
    
    _amenities = {
      for (var amenity in AppConstants.availableAmenities)
        amenity: widget.listing.amenities[amenity] ?? false
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _removedImageUrls.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      if (_existingImages.isEmpty && _newImageFiles.isEmpty) {
        Helpers.showSnackBar(context, 'Please keep at least one image', isError: true);
        return;
      }

      final listingProvider = Provider.of<ListingProvider>(context, listen: false);
      
      final updatedListing = widget.listing.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        roomType: _selectedRoomType,
        images: _existingImages, // Existing ones that were kept
        amenities: _amenities,
      );

      final success = await listingProvider.updateListing(
        updatedListing,
        newImageFiles: _newImageFiles,
        removedImageUrls: _removedImageUrls,
      );

      if (!mounted) return;

      if (success) {
        Helpers.showSnackBar(context, 'Listing updated successfully!');
        Navigator.pop(context);
      } else {
        Helpers.showSnackBar(
          context,
          listingProvider.errorMessage ?? 'Failed to update listing',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
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
              _buildImagePreview(),
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
                    text: 'Save Changes',
                    onPressed: _handleUpdate,
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

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _existingImages.length + _newImageFiles.length + 1,
            itemBuilder: (context, index) {
              if (index == _existingImages.length + _newImageFiles.length) {
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

              // Existing images
              if (index < _existingImages.length) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: ImageHelper.getSafeImageProvider(_existingImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _removeExistingImage(index),
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
              }

              // New picked images
              final fileIndex = index - _existingImages.length;
              return Stack(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_newImageFiles[fileIndex]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _removeNewImage(fileIndex),
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
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              );
            },
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

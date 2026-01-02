import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../utils/image_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _schoolController;
  late TextEditingController _workController;
  
  String _selectedGender = AppConstants.genderOptions[0];
  Map<String, String> _lifestylePreferences = {};
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _schoolController = TextEditingController(text: user?.school ?? '');
    _workController = TextEditingController(text: user?.work ?? '');
    _selectedGender = AppConstants.genderOptions.contains(user?.gender)
        ? user!.gender!
        : AppConstants.genderOptions[0];
    _lifestylePreferences = Map<String, String>.from(user?.lifestylePreferences ?? {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _schoolController.dispose();
    _workController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 500,
      maxHeight: 500,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        gender: _selectedGender,
        school: _schoolController.text.trim(),
        work: _workController.text.trim(),
        lifestylePreferences: _lifestylePreferences,
        photoFile: _imageFile,
      );

      if (!mounted) return;

      if (success) {
        Helpers.showSnackBar(context, 'Profile updated successfully');
        Navigator.pop(context);
      } else {
        Helpers.showSnackBar(
          context,
          authProvider.errorMessage ?? 'Failed to update profile',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading && authProvider.userModel == null) {
            return const LoadingIndicator();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (authProvider.userModel?.photoUrl != null
                                    ? (ImageHelper.isBase64(authProvider.userModel!.photoUrl!)
                                        ? MemoryImage(ImageHelper.decodeBase64(authProvider.userModel!.photoUrl!))
                                        : NetworkImage(authProvider.userModel!.photoUrl!))
                                    : null) as ImageProvider?,
                            child: _imageFile == null && authProvider.userModel?.photoUrl == null
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  CustomTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person_outline,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _bioController,
                    label: 'Bio',
                    hintText: 'Tell others about yourself',
                    prefixIcon: Icons.info_outline,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildGenderDropdown(),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _schoolController,
                    label: 'School / University',
                    hintText: 'e.g., FST, ENIT, MSB...',
                    prefixIcon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _workController,
                    label: 'Work / Occupation',
                    hintText: 'e.g., Student, Engineer, Designer...',
                    prefixIcon: Icons.work_outline,
                  ),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Lifestyle Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Matching with other roommates is based on these preferences.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  
                  ..._buildLifestylePreferences(),
                  const SizedBox(height: 32),
                  
                  CustomButton(
                    text: 'Save Changes',
                    onPressed: _handleSave,
                    isLoading: authProvider.isLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.people_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: AppConstants.genderOptions.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedGender = value;
          });
        }
      },
    );
  }

  List<Widget> _buildLifestylePreferences() {
    return AppConstants.lifestylePreferences.entries.map((entry) {
      final category = entry.key;
      final options = entry.value;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          initialValue: _lifestylePreferences[category] ?? options[0],
          decoration: InputDecoration(
            labelText: category,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _lifestylePreferences[category] = value;
              });
            }
          },
        ),
      );
    }).toList();
  }
}

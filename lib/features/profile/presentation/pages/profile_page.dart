import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:compareitr/core/common/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:compareitr/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:compareitr/core/theme/cubit/theme_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:compareitr/core/services/app_settings_service.dart';
import 'package:compareitr/init_dependencies.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Open email client for support
  Future<void> _openSupportEmail(BuildContext context) async {
    // Fetch support email from database
    final appSettingsService = serviceLocator<AppSettingsService>();
    final supportEmail = await appSettingsService.getSupportEmail();
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=CompareItr Support Request&body=Hello CompareItr Team,%0D%0A%0D%0AI need help with:%0D%0A%0D%0A',
    );

    try {
      final canLaunch = await canLaunchUrl(emailUri);
      
      if (canLaunch) {
        await launchUrl(emailUri);
      } else {
        // Show support dialog instead
        if (context.mounted) {
          _showSupportDialog(context);
        }
      }
    } catch (e) {
      // Show support dialog as fallback
      if (context.mounted) {
        _showSupportDialog(context);
      }
    }
  }

  // Show support dialog with contact information
  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: serviceLocator<AppSettingsService>().getSupportEmail(),
        builder: (context, snapshot) {
          final supportEmail = snapshot.data ?? 'support@compareitr.com';
          return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.teal),
            SizedBox(width: 8),
            Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help or have a complaint?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email us at:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      supportEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We\'ll respond to your inquiry as soon as possible!',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
        if (state is AuthLoading) {
          return Center(child: CircularProgressIndicator(color: Colors.green));
        } else if (state is AuthFailure) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is AuthSuccess) {
          final user = state.user;
          
          // Debug: Print user profile picture URL
          print('Profile Picture URL: "${user.proPic}"');
          print('Is empty: ${user.proPic.isEmpty}');
          print('Is null string: ${user.proPic == 'null'}');

          return SingleChildScrollView(
            child: Column(
              children: [
                // User Profile Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                                width: 3,
                              ),
                            ),
                            child: Builder(
                              builder: (context) {
                                // Check if we have a valid image URL
                                final hasValidImage = user.proPic.isNotEmpty && 
                                    user.proPic != 'null' && 
                                    user.proPic.startsWith('http');
                                
                                print('Has valid image: $hasValidImage');
                                
                                if (hasValidImage) {
                                  return CachedNetworkImage(
                                    imageUrl: user.proPic,
                                    imageBuilder: (context, imageProvider) => CircleAvatar(
                                      radius: 47,
                                      backgroundImage: imageProvider,
                                      backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey.shade300,
                                    ),
                                    placeholder: (context, url) => CircleAvatar(
                                      radius: 47,
                                      backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey.shade300,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.green,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      print('❌ Error loading profile image: $error');
                                      return CircleAvatar(
                                        radius: 47,
                                        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey.shade300,
                                        child: Text(
                                          user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.grey[300] : Colors.grey.shade700,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  return CircleAvatar(
                                    radius: 47,
                                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey.shade300,
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.grey[300] : Colors.grey.shade700,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileUpdateForm(user: user),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[300] : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      if (user.phoneNumber != 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '+264 ${user.phoneNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Menu Items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildMenuCard(
                        context: context,
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        subtitle: 'Update your information',
                        iconColor: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileUpdateForm(user: user),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<ThemeCubit, ThemeState>(
                        builder: (context, themeState) {
                          return _buildThemeCard(
                            context: context,
                            isDarkMode: themeState.isDarkMode,
                            onChanged: (value) {
                              context.read<ThemeCubit>().toggleTheme();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context: context,
                        icon: Icons.support_agent,
                        title: 'Support',
                        subtitle: 'Contact us for help or complaints',
                        iconColor: Colors.teal,
                        onTap: () => _openSupportEmail(context),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context: context,
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        iconColor: Colors.red,
                        onTap: () {
                          context.read<AuthBloc>().add(AuthLogout());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logged out')),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text('No user data available.'));
        }
      }),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required bool isDarkMode,
    required ValueChanged<bool> onChanged,
  }) {
    final currentIsDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentIsDarkMode ? Colors.grey[850] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.indigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDarkMode,
            onChanged: onChanged,
            activeColor: Colors.grey.shade700,
          ),
        ],
      ),
    );
  }
}

// Profile Update Form
class ProfileUpdateForm extends StatefulWidget {
  final UserEntity user;

  const ProfileUpdateForm({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileUpdateFormState createState() => _ProfileUpdateFormState();
}

class _ProfileUpdateFormState extends State<ProfileUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _streetController;
  late TextEditingController _locationController;
  late TextEditingController _phoneNumberController;
  File? _imageFile;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _streetController = TextEditingController(text: widget.user.street);
    _locationController = TextEditingController(text: widget.user.location);
    _phoneNumberController = TextEditingController(
      text: widget.user.phoneNumber != 0 ? widget.user.phoneNumber.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _locationController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    // Show image source selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isUpdating = true;
      });

      // Trigger the profile update
      // Only pass imagePath if user selected a new image (otherwise null = keep existing)
      context.read<AuthBloc>().add(AuthUpdateProfile(
            userId: widget.user.id,
            name: _nameController.text.trim(),
            street: _streetController.text.trim(),
            location: _locationController.text.trim(),
            phoneNumber: int.parse(_phoneNumberController.text.trim()),
            imagePath: _imageFile, // null if no new image selected = keep existing picture
            email: widget.user.email,
          ));

      // Show success and pop
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Picture Section
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green,
                          width: 3,
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          // Show selected image or existing profile picture
                          if (_imageFile != null) {
                            return CircleAvatar(
                              radius: 60,
                              backgroundImage: FileImage(_imageFile!),
                            );
                          } else if (widget.user.proPic.isNotEmpty &&
                              widget.user.proPic != 'null' &&
                              widget.user.proPic.startsWith('http')) {
                            return CachedNetworkImage(
                              imageUrl: widget.user.proPic,
                              imageBuilder: (context, imageProvider) => CircleAvatar(
                                radius: 60,
                                backgroundImage: imageProvider,
                              ),
                              placeholder: (context, url) => CircleAvatar(
                                radius: 60,
                                backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                child: CircularProgressIndicator(color: Colors.green),
                              ),
                              errorWidget: (context, url, error) => CircleAvatar(
                                radius: 60,
                                backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                child: Text(
                                  widget.user.name.isNotEmpty
                                      ? widget.user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return CircleAvatar(
                              radius: 60,
                              backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                              child: Text(
                                widget.user.name.isNotEmpty
                                    ? widget.user.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Tap camera icon to change photo (optional)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email Field (Read-only)
                TextFormField(
                  initialValue: widget.user.email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  ),
                  enabled: false,
                ),

                const SizedBox(height: 16),

                // Phone Number Field
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '81234567',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefixText: '+264 ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.trim().length < 8) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Street Field
                TextFormField(
                  controller: _streetController,
                  decoration: InputDecoration(
                    labelText: 'Street Address',
                    hintText: 'e.g., Independence Avenue',
                    prefixIcon: const Icon(Icons.streetview),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your street address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Location/Suburb Field
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Suburb/Area',
                    hintText: 'e.g., Klein Windhoek',
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your suburb/area';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.green,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Update Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isUpdating ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

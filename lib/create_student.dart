import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateStudent extends StatefulWidget {
  const CreateStudent({super.key});

  @override
  State<CreateStudent> createState() => _CreateStudentState();
}

class _CreateStudentState extends State<CreateStudent> {
  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _programController = TextEditingController();
  final _emailController = TextEditingController();

  File? _profileImage;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      await supabase.storage.from('student_profiles').upload(fileName, imageFile);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $error')),
      );
      return null;
    }

    final publicUrl = supabase.storage.from('student_profiles').getPublicUrl(fileName);
    return publicUrl;
  }

  Future<void> createStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    String? profileUrl;
    if (_profileImage != null) {
      profileUrl = await uploadProfileImage(_profileImage!);
      if (profileUrl == null) {
        setState(() => _isUploading = false);
        return;
      }
    }

    try {
      await supabase.from('Students').insert({
        'Firstname': _firstnameController.text.trim(),
        'Surname': _surnameController.text.trim(),
        'Program': _programController.text.trim(),
        'Email': _emailController.text.trim(),
        'Profile_url': profileUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student created successfully')),
      );

      Navigator.pop(context);

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating student: $error')),
      );
    }

    setState(() => _isUploading = false);
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _surnameController.dispose();
    _programController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Student'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.camera_alt, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstnameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter first name' : null,
                    ),
                    TextFormField(
                      controller: _surnameController,
                      decoration: const InputDecoration(labelText: 'Surname'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter surname' : null,
                    ),
                    TextFormField(
                      controller: _programController,
                      decoration: const InputDecoration(labelText: 'Program'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter program' : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter email';
                        }
                        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: createStudent,
                      child: const Text('Create Student'),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}

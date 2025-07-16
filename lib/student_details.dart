import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDetails extends StatefulWidget {
  final int studentId;
  const StudentDetails({super.key, required this.studentId});

  @override
  State<StudentDetails> createState() => _StudentDetailsState();
}

class _StudentDetailsState extends State<StudentDetails> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool isLoading = true;
  Map<String, dynamic>? student;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstnameController;
  late TextEditingController _surnameController;
  late TextEditingController _programController;
  late TextEditingController _emailController;

  File? _profileImage;
  bool _isUploadingImage = false;
  bool _isUpdating = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchStudent();
  }

  Future<void> fetchStudent() async {
    try {
      final data = await supabase
          .from('Students')
          .select()
          .eq('id', widget.studentId)
          .single();

      student = data as Map<String, dynamic>;

      _firstnameController = TextEditingController(text: student!['Firstname']);
      _surnameController = TextEditingController(text: student!['Surname']);
      _programController = TextEditingController(text: student!['Program']);
      _emailController = TextEditingController(text: student!['Email']);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load student: $error')),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    setState(() => _isUploadingImage = true);

    final fileName = 'profile_${widget.studentId}_${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      await supabase.storage.from('student_profiles').upload(fileName, imageFile);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $error')),
      );
      setState(() => _isUploadingImage = false);
      return null;
    }

    final publicUrl = supabase.storage.from('student_profiles').getPublicUrl(fileName);

    setState(() => _isUploadingImage = false);

    return publicUrl;
  }

  Future<void> updateProfilePicture() async {
    if (_profileImage == null) return;

    final url = await uploadProfileImage(_profileImage!);

    if (url != null) {
      setState(() => _isUpdating = true);

      try {
        await supabase
            .from('Students')
            .update({'Profile_url': url})
            .eq('id', widget.studentId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );

        fetchStudent();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $error')),
        );
      }

      setState(() => _isUpdating = false);
    }
  }

  Future<void> deleteProfilePicture() async {
    setState(() => _isUpdating = true);

    try {
      await supabase
          .from('Students')
          .update({'Profile_url': null})
          .eq('id', widget.studentId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture deleted')),
      );

      fetchStudent();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }

    setState(() => _isUpdating = false);
  }

  Future<void> updateStudentInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      await supabase.from('Students').update({
        'Firstname': _firstnameController.text.trim(),
        'Surname': _surnameController.text.trim(),
        'Program': _programController.text.trim(),
        'Email': _emailController.text.trim(),
      }).eq('id', widget.studentId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student info updated')),
      );

      fetchStudent();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    }

    setState(() => _isUpdating = false);
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isUploadingImage || _isUpdating
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (student!['Profile_url'] != null
                                ? NetworkImage(student!['Profile_url'])
                                : null) as ImageProvider<Object>?,
                        child: (_profileImage == null && student!['Profile_url'] == null)
                            ? const Icon(Icons.camera_alt, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: updateProfilePicture,
                          child: const Text('Update Profile Picture'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: deleteProfilePicture,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete Picture'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                        if (value == null || value.isEmpty) return 'Enter email';
                        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) return 'Enter valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: updateStudentInfo,
                      child: const Text('Update Student Info'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

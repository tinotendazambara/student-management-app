import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnrolledStudents extends StatefulWidget {
  const EnrolledStudents({super.key});

  @override
  State<EnrolledStudents> createState() => _EnrolledStudentsState();
}

class _EnrolledStudentsState extends State<EnrolledStudents> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool isLoading = true;
  List<dynamic> students = [];

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('Students')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        students = response;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> confirmAndDeleteStudent(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await deleteStudent(id);
  }

  Future<void> deleteStudent(int id) async {
    try {
      await supabase.from('Students').delete().eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted')),
      );

      fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enrolled Students')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text('No students enrolled.'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: student['Profile_url'] != null
                            ? NetworkImage(student['Profile_url'])
                            : null,
                        child: student['Profile_url'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text('${student['Firstname']} ${student['Surname']}'),
                      subtitle: Text(student['Program']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmAndDeleteStudent(student['id']),
                      ),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_student.dart';
import 'student_details.dart';

class EnrolledStudents extends StatefulWidget {
  const EnrolledStudents({super.key});

  @override
  State<EnrolledStudents> createState() => _EnrolledStudentsState();
}

class _EnrolledStudentsState extends State<EnrolledStudents> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> students = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() => isLoading = true);

    final response = await supabase
        .from('Students')
        .select()
        .order('created_at', ascending: false);

    if (response.isEmpty) {
      setState(() {
        students = [];
        isLoading = false;
      });
    } else {
      setState(() {
        students = response;
        isLoading = false;
      });
    }
  }

  Future<void> deleteStudent(int id) async {
    final response = await supabase
        .from('Students')
        .delete()
        .eq('id', id);

    // Supabase 1.5.x returns empty response on success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student deleted')),
    );

    fetchStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrolled Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateStudent()),
              ).then((_) => fetchStudents());
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text('No students enrolled yet.'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      leading: student['Profile_url'] != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(student['Profile_url']),
                            )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('${student['Firstname']} ${student['Surname']}'),
                      subtitle: Text(student['Program'] ?? 'No program'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentDetails(studentId: student['id']),
                          ),
                        ).then((_) => fetchStudents());
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteStudent(student['id']),
                      ),
                    );
                  },
                ),
    );
  }
}

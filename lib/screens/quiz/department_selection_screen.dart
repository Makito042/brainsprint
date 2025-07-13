import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../repositories/quiz_repository.dart';
import 'course_selection_screen.dart';

class DepartmentSelectionScreen extends StatelessWidget {
  const DepartmentSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
      ),
      body: StreamBuilder<List<Department>>(
        stream: QuizRepository().getDepartments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error loading departments',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }

          final departments = snapshot.data ?? [];

          if (departments.isEmpty) {
            return const Center(
              child: Text(
                'No departments available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final department = departments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    department.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    department.description,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseSelectionScreen(department: department),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

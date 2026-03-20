import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Models & Providers
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reviewer_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';

// Screens & Widgets
import 'student_task_detail_screen.dart';
import 'login_screen.dart';
import 'package:phys_ed/widgets/pdf_viewer_widget.dart';
import 'package:phys_ed/widgets/download_button.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  // LNU Identity Colors
  static const Color lnuNavy = Color(0xFF002147);
  static const Color academicGray = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: academicGray,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          toolbarHeight: 115,
          automaticallyImplyLeading: false,
          title: userAsync.when(
            data: (user) => _buildHeader(context, user),
            loading: () => const LinearProgressIndicator(color: lnuNavy),
            error: (_, __) => const Text("Error loading profile"),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded, color: lnuNavy),
                onPressed: () => _showLogoutConfirmation(context, ref),
              ),
            ),
          ],
          bottom: const TabBar(
            labelColor: lnuNavy,
            unselectedLabelColor: Colors.blueGrey,
            indicatorColor: lnuNavy,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "Courses"),
              Tab(text: "Tasks"),
              Tab(text: "Reviewers"),
              Tab(text: "Grades"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCourseList(ref),
            _buildTaskList(ref),
            _buildReviewerList(ref),
            _buildGradesList(ref),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(BuildContext context, AppUser? user) {
    return GestureDetector(
      onTap: () => _showProfileModal(context, user),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: lnuNavy.withOpacity(0.1),
            backgroundImage: (user?.avatarUrl?.isNotEmpty ?? false)
                ? NetworkImage(user!.avatarUrl)
                : null,
            child: (user?.avatarUrl?.isEmpty ?? true)
                ? const Icon(Icons.person, color: lnuNavy)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.fullName?.toUpperCase() ?? "STUDENT",
                  style: const TextStyle(
                    color: lnuNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Section ${user?.section ?? 'N/A'} • Year ${user?.yearLevel ?? 'N/A'}",
                  style: TextStyle(
                    color: lnuNavy.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.black12),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(sub, style: const TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }

  // --- TAB CONTENT BUILDERS ---

  Widget _buildCourseList(WidgetRef ref) {
    // UPDATED: Now watches allCoursesProvider to ensure content displays
    final coursesAsync = ref.watch(allCoursesProvider);

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return _buildEmptyState(Icons.auto_stories, "No courses available", "Modules will appear once assigned.");
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: academicGray,
                  child: Icon(Icons.fitness_center, color: lnuNavy, size: 20),
                ),
                title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(course.description ?? "Tap to view lessons"),
                trailing: const Icon(Icons.chevron_right, color: Colors.black26),
                onTap: () {
                  // TODO: Navigate to CourseDetailScreen(course: course)
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: lnuNavy)),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildTaskList(WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _buildEmptyState(Icons.task_alt, "No tasks assigned", "Enjoy your free time!");
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
              child: ListTile(
                title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Due: ${task.deadline.month}/${task.deadline.day}"),
                trailing: const Icon(Icons.chevron_right, color: lnuNavy),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentTaskDetailScreen(task: task))),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: lnuNavy)),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildReviewerList(WidgetRef ref) {
    final reviewersAsync = ref.watch(allReviewersProvider);
    return reviewersAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return _buildEmptyState(Icons.picture_as_pdf, "No reviewers yet", "Study materials will be posted here.");
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
              child: ListTile(
                leading: const Icon(Icons.description_outlined, color: lnuNavy),
                title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: DownloadButton(
                  materialId: doc.id,
                  title: doc.title,
                  url: doc.fileUrl,
                  fileExtension: '.pdf',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerWidget(
                        title: doc.title,
                        urlOrPath: doc.fileUrl,
                        isOffline: false,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: lnuNavy)),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildGradesList(WidgetRef ref) {
    final mySubsAsync = ref.watch(mySubmissionsProvider);
    final allTasksAsync = ref.watch(allTasksProvider);

    return mySubsAsync.when(
      data: (subs) {
        if (subs.isEmpty) {
          return _buildEmptyState(Icons.grade_outlined, "No grades yet", "Submit a task to see your performance.");
        }
        return allTasksAsync.when(
          data: (tasks) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final sub = subs[index];
                final matchingTask = tasks.firstWhere(
                      (t) => t.id == sub.taskId,
                  orElse: () => TaskModel(id: '', title: 'Deleted Task', description: '', maxScore: 0, deadline: DateTime.now()),
                );
                final isGraded = sub.grade != null && sub.grade!.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                  child: ListTile(
                    leading: Icon(Icons.star, color: isGraded ? Colors.amber : Colors.grey.shade300),
                    title: Text(matchingTask.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Submitted: ${sub.submittedAt.month}/${sub.submittedAt.day}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGraded ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGraded ? "${sub.grade}/${matchingTask.maxScore}" : "Pending",
                        style: TextStyle(color: isGraded ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: lnuNavy)),
          error: (e, _) => Center(child: Text("Error matching tasks")),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: lnuNavy)),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  // --- MODALS ---

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout", style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        content: const Text("Ready to leave the student portal?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lnuNavy),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            child: const Text("YES, LOGOUT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProfileModal(BuildContext context, AppUser? user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("STUDENT PROFILE", style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Divider(height: 30),
              CircleAvatar(
                radius: 45,
                backgroundColor: academicGray,
                backgroundImage: (user?.avatarUrl?.isNotEmpty ?? false) ? NetworkImage(user!.avatarUrl) : null,
                child: (user?.avatarUrl?.isEmpty ?? true) ? const Icon(Icons.person, size: 40, color: lnuNavy) : null,
              ),
              const SizedBox(height: 20),
              _profileRow(Icons.person_outline, "Name", user?.fullName ?? "N/A"),
              _profileRow(Icons.email_outlined, "Email", user?.email ?? "N/A"),
              _profileRow(Icons.class_outlined, "Section", user?.section ?? "N/A"),
              _profileRow(Icons.trending_up, "Year", "${user?.yearLevel ?? 'N/A'} Year"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE", style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: lnuNavy.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
          Expanded(child: Text(value, style: const TextStyle(color: lnuNavy, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
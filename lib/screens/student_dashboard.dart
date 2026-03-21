import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

// Import existing screens
import 'course_screen.dart';
import 'lesson_screen.dart';
import 'class_screen.dart';
import 'reviewer_screen.dart';
import 'submission_screen.dart';
import 'login_screen.dart';
import 'tasklist_screen.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  // LNU Identity Colors
  static const Color lnuNavy = Color(0xFF002147);
  static const Color academicGray = Color(0xFFF8FAFC);

  bool _isLogoutHovered = false;

  final List<Map<String, dynamic>> _allModules = [
    {
      'title': 'Courses',
      'icon': Icons.menu_book_rounded,
      'screen': const CourseScreen(),
    },
    {
      'title': 'Tasks & Quizzes',
      'icon': Icons.task_alt_rounded,
      'screen': const TaskListScreen(),
    },
    {
      'title': 'Lessons',
      'icon': Icons.play_lesson_rounded,
      'screen': const LessonScreen(),
    },
    {
      'title': 'Classes',
      'icon': Icons.groups_rounded,
      'screen': const ClassScreen(),
    },
    {
      'title': 'Reviewers',
      'icon': Icons.picture_as_pdf_rounded,
      'screen': const ReviewerScreen(),
    },
    {
      'title': 'Grades',
      'icon': Icons.assignment_turned_in_rounded,
      'screen': const SubmissionScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: lnuNavy,
      appBar: AppBar(
        backgroundColor: lnuNavy,
        elevation: 0,
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
        title: userAsync.when(
          data: (user) => _buildProfileHeader(context, user),
          loading: () => const LinearProgressIndicator(color: Colors.white),
          error: (_, _) => const Text(
            "Error loading profile",
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'All Modules',
            onPressed: () => _showMenuModal(context),
          ),
          const SizedBox(width: 8),
          _buildLogoutButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "QUICK ACCESS",
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.1,
                ),
                itemCount: _allModules.length,
                itemBuilder: (context, index) {
                  return _buildMenuCard(context, _allModules[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "ALL MODULES",
                style: TextStyle(
                  color: lnuNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: _allModules
                    .map((module) => _buildModalMenuIcon(context, module))
                    .toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lnuNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "CLOSE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, Map<String, dynamic> module) {
    return InkWell(
      onTap: () {
        if (module['screen'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => module['screen']),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: academicGray,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(module['icon'], color: lnuNavy, size: 38),
            const SizedBox(height: 16),
            Text(
              module['title'],
              style: const TextStyle(
                color: lnuNavy,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalMenuIcon(
    BuildContext context,
    Map<String, dynamic> module,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (module['screen'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => module['screen']),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: academicGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(module['icon'], color: lnuNavy, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              module['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: lnuNavy,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppUser? user) {
    return GestureDetector(
      onTap: () => _showProfileModal(context, user),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/lnu.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) =>
                    const Icon(Icons.school, color: lnuNavy, size: 28),
              ),
            ),
            const SizedBox(width: 12),

            // --- FIXED: WEB SAFE PROFILE IMAGE ---
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  (user?.avatarUrl != null &&
                      user!.avatarUrl.trim().isNotEmpty &&
                      user.avatarUrl != 'null')
                  ? Image.network(
                      user.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: Colors.white),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),

            // -------------------------------------
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user?.fullName?.toUpperCase() ??
                        user?.email.split('@')[0].toUpperCase() ??
                        "STUDENT",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Section ${user?.section ?? 'N/A'} • Year ${user?.yearLevel ?? 'N/A'}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Center(
        child: MouseRegion(
          onEnter: (_) => setState(() => _isLogoutHovered = true),
          onExit: (_) => setState(() => _isLogoutHovered = false),
          child: InkWell(
            onTap: () => _showLogoutConfirmation(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isLogoutHovered ? Colors.redAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isLogoutHovered ? Colors.redAccent : Colors.white54,
                  width: 1.5,
                ),
              ),
              child: const Text(
                "LOGOUT",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Logout",
          style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold),
        ),
        content: const Text("Ready to leave the student portal?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authControllerProvider).signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "YES, LOGOUT",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileModal(BuildContext context, AppUser? user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360, minHeight: 450),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "STUDENT PORTAL",
                style: TextStyle(
                  color: lnuNavy,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),

              // --- FIXED: WEB SAFE MODAL IMAGE ---
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: academicGray,
                  shape: BoxShape.circle,
                  border: Border.all(color: lnuNavy.withOpacity(0.2), width: 4),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    (user?.avatarUrl != null &&
                        user!.avatarUrl.trim().isNotEmpty &&
                        user.avatarUrl != 'null')
                    ? Image.network(
                        user.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 50, color: lnuNavy),
                      )
                    : const Icon(Icons.person, size: 50, color: lnuNavy),
              ),

              // -----------------------------------
              const SizedBox(height: 24),
              _profileRow(
                Icons.person_outline,
                "Name",
                user?.fullName ?? "Not Set",
              ),
              const Divider(),
              _profileRow(
                Icons.email_outlined,
                "Email",
                user?.email ?? "Not Set",
              ),
              const Divider(),
              _profileRow(
                Icons.class_outlined,
                "Section",
                user?.section ?? "Not Set",
              ),
              const Divider(),
              _profileRow(
                Icons.trending_up,
                "Year Level",
                "${user?.yearLevel ?? 'Not Set'} Year",
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lnuNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "CLOSE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
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
          Icon(icon, size: 22, color: lnuNavy.withOpacity(0.7)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.black45,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: lnuNavy,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

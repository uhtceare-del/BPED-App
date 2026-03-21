import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart'; // ← new import

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrlAsync = ref.watch(avatarUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: avatarUrlAsync.when(
                data: (url) {
                  if (url == null || url.isEmpty) {
                    return const Icon(Icons.person, color: Colors.white);
                  }
                  return ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(strokeWidth: 2),
                error: (_, _) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome! You are logged in."),
            const SizedBox(height: 40),

            // Bigger preview so you can easily verify it works
            avatarUrlAsync.when(
              data: (url) {
                if (url == null || url.isEmpty) {
                  return const Text("No profile picture set yet");
                }
                return Column(
                  children: [
                    const Text("Your profile picture:"),
                    const SizedBox(height: 16),
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, st) => Text("Error: $err"),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ref.read(authControllerProvider).signOut();
              },
              child: const Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}

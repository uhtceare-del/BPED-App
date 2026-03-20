import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_material_model.dart';
import '../providers/offline_provider.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/pdf_viewer_widget.dart';

class OfflineDownloadsScreen extends ConsumerWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We grab the Hive box we opened in main.dart
    final box = Hive.box('downloadsBox');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offline Files'),
      ),
      // ValueListenableBuilder automatically rebuilds the UI whenever the box changes
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box currentBox, _) {
          if (currentBox.isEmpty) {
            return const Center(
              child: Text(
                'No materials downloaded yet.\nGo to your classes to save some!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Convert the raw Hive data back into our OfflineMaterial model
          final materials = currentBox.values.cast<OfflineMaterial>().toList();

          return ListView.builder(
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];

              // Check if it's a video or a document to show the right icon
              final isVideo = material.localFilePath.endsWith('.mp4');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isVideo ? Colors.blue.shade100 : Colors.red.shade100,
                    child: Icon(
                      isVideo ? Icons.play_circle_fill : Icons.picture_as_pdf,
                      color: isVideo ? Colors.blue : Colors.red,
                    ),
                  ),
                  title: Text(
                    material.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Available Offline'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Remove from device',
                    onPressed: () {
                      // Use our provider to delete the file from storage and Hive
                      ref.read(offlineStorageProvider).deleteFile(material.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${material.title} removed.')),
                      );
                    },
                  ),
                  onTap: () {
                    if (isVideo) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerWidget(
                            title: material.title,
                            urlOrPath: material.localFilePath,
                            isOffline: true,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerWidget(
                            title: material.title,
                            urlOrPath: material.localFilePath,
                            isOffline: true,
                          ),
                        ),
                      );
                    }
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
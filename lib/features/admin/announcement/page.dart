import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/admin/announcement/services/announcement_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    final data = await AnnouncementService().fetchAnnouncements();
    setState(() {
      _announcements = data;
    });
}

  void _openAddAnnouncement() {
    _openAnnouncementForm();
  }

  void _openEditAnnouncement(Map<String, dynamic> data) {
    _openAnnouncementForm(existing: data);
  }

  void _openAnnouncementForm({Map<String, dynamic>? existing}) {
    final titleController = TextEditingController(text: existing?['title'] ?? '');
    final descriptionController = TextEditingController(text: existing?['description'] ?? '');
    bool isCritical = existing?['isCritical'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(existing == null ? "New Announcement" : "Edit Announcement"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Critical Announcement"),
                      Switch(
                        value: isCritical,
                        onChanged: (v) {
                          setStateDialog(() {
                            isCritical = v;
                          });
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (existing == null) {
                    await AnnouncementService().createAnnouncement({
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'isCritical': isCritical,
                    });
                  } else {
                    await AnnouncementService().updateAnnouncement(
                      existing['id'],
                      {
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'isCritical': isCritical,
                      },
                    );
                  }

                  Navigator.pop(context);
                  await loadAnnouncements();
                },
                child: const Text("Save"),
              )
            ],
          );
        });
      },
    );
  }

  void _deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Announcement"),
        content: const Text("Are you sure you want to delete this announcement?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    await AnnouncementService().deleteAnnouncement(id);
    await loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddAnnouncement,
          )
        ],
      ),
      body: _announcements.isEmpty
          ? const Center(child: Text("No announcements found"))
          : ListView.builder(
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                final item = _announcements[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(item['title']),
                    subtitle: Text(item['description']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item['isCritical'])
                          const Icon(Icons.warning, color: Colors.red),

                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openEditAnnouncement(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteAnnouncement(item['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

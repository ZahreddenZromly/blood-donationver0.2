import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AdminNewsPostScreen extends StatefulWidget {
  const AdminNewsPostScreen({super.key});

  @override
  State<AdminNewsPostScreen> createState() => _AdminNewsPostScreenState();
}

class _AdminNewsPostScreenState extends State<AdminNewsPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  String? _editingDocId;
  bool _isLoading = false;

  final user = FirebaseAuth.instance.currentUser;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _convertImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64String = base64Encode(bytes);
    final mimeType = 'image/${imageFile.path.split('.').last}';
    return 'data:$mimeType;base64,$base64String';
  }

  Future<void> _postNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageBase64 = '';

      if (_selectedImage != null) {
        imageBase64 = await _convertImageToBase64(_selectedImage!);
      }

      final newsData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageBase64': imageBase64,
        'timestamp': Timestamp.now(),
        'likes': [],
      };

      if (_editingDocId == null) {
        await FirebaseFirestore.instance.collection('news').add(newsData);
        _showSnackBar("News posted!");
      } else {
        await FirebaseFirestore.instance.collection('news').doc(_editingDocId).update(newsData);
        _showSnackBar("News updated!");
      }

      _clearForm();
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    _titleController.clear();
    _descriptionController.clear();
    _selectedImage = null;
    _editingDocId = null;
    setState(() {});
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteNews(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete News"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('news').doc(docId).delete();
      _showSnackBar("News deleted.");
    }
  }

  Future<void> _toggleLike(String docId, List likes) async {
    final uid = user?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('news').doc(docId);

    if (likes.contains(uid)) {
      // If user has already liked, remove the like
      await docRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      // If user hasn't liked yet, add the like
      await docRef.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }


  Future<void> _showLikedUsersDialog(List likes) async {
    if (likes.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Liked By"),
          content: const Text("No users have liked this post yet."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    List<String> likedUserNames = [];

    for (String uid in likes) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          likedUserNames.add(userData['name'] ?? 'Unknown');
        } else {
          likedUserNames.add('Unknown User');
        }
      } catch (e) {
        likedUserNames.add('Error loading user');
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Liked By"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: likedUserNames.map((name) => ListTile(title: Text(name))).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _buildNewsCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final base64 = data['imageBase64'] ?? '';
    final hasImage = base64.isNotEmpty;
    final List likes = data['likes'] ?? [];

    Widget imageWidget = const Icon(Icons.image_not_supported);
    if (hasImage) {
      try {
        final decodedBytes = base64.split(',').last;
        final bytes = base64Decode(decodedBytes);
        imageWidget = Image.memory(bytes, width: 50, height: 50, fit: BoxFit.cover);
      } catch (_) {
        imageWidget = const Icon(Icons.broken_image);
      }
    }

    final isLiked = user != null && likes.contains(user!.uid);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: imageWidget,
        title: Text(data['title'] ?? ''),
        subtitle: Text(
          '${DateFormat('yyyy-MM-dd – HH:mm').format(timestamp)}\n${data['description'] ?? ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 0,
          runSpacing: -8,
          direction: Axis.vertical,
          children: [
            IconButton(
              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey),
              onPressed: () => _toggleLike(doc.id, likes),
              iconSize: 20,
              padding: EdgeInsets.zero,
            ),
            // Display the number of likes (size of the list)
            Text('${likes.length}', style: const TextStyle(fontSize: 12)),
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              onPressed: () => _showLikedUsersDialog(likes),
              iconSize: 20,
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteNews(doc.id),
              iconSize: 20,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        onTap: () {
          _editingDocId = doc.id;
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _selectedImage = null;
          setState(() {});
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin News", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (val) => val == null || val.isEmpty ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (val) => val == null || val.isEmpty ? 'Enter a description' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text("Choose Image"),
                      ),
                      const SizedBox(width: 10),
                      if (_selectedImage != null)
                        Image.file(_selectedImage!, width: 50, height: 50, fit: BoxFit.cover)
                      else
                        const Text("No image selected"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _postNews,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_editingDocId == null ? "Post News" : "Update News"),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            const Text("Your News Posts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('news')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No news posts available.");
                }

                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: snapshot.data!.docs.map(_buildNewsCard).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/note.dart';

class AddNoteScreen extends StatefulWidget {
  final Note? note;

  const AddNoteScreen({super.key, this.note});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode(); // Manage focus for the title
  final FocusNode _contentFocusNode = FocusNode(); // Manage focus for the content

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  void _saveNote() {
    final String title = _titleController.text.trim();
    final String content = _contentController.text.trim();
    if (title.isNotEmpty && content.isNotEmpty) {
      final note = Note(
        title: title,
        content: content,
        dateTime: DateTime.now(),
      );
      Navigator.pop(context, note); // Pass the new note back to the previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Add Note' : 'Edit Note'),
        actions: [
          // Save or update button
          IconButton(
            icon: Icon(widget.note == null ? Icons.save : Icons.update),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside text fields
          _titleFocusNode.unfocus();
          _contentFocusNode.unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title text field with manual focus
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: InputDecoration(
                  hintText: 'Enter Note Title',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Content text field with manual focus
              Expanded(
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Write your note here...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  maxLines: null, // Allows multiple lines of text
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose(); // Dispose of focus nodes
    _contentFocusNode.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:share/share.dart'; // Share functionality package
import 'package:intl/intl.dart'; // For date formatting
import 'add_note_screen.dart';
import '../models/note.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme; // Callback to toggle theme
  final bool isDarkMode; // Current theme state

  const HomeScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Note> _notes = [];
  Note? _lastDeletedNote; // To store the last deleted note
  int? _lastDeletedNoteIndex; // To store the index of the last deleted note

  void _addNote() async {
    final newNote = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddNoteScreen(),
      ),
    );
    if (newNote != null) {
      setState(() {
        _notes.add(newNote as Note);
      });
    }
  }

  void _editNote(int index) async {
    final editedNote = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNoteScreen(note: _notes[index]),
      ),
    );
    if (editedNote != null) {
      setState(() {
        _notes[index] = editedNote as Note;
      });
    }
  }

  void _deleteNoteWithUndo(int index) {
    setState(() {
      _lastDeletedNote = _notes[index];
      _lastDeletedNoteIndex = index;
      _notes.removeAt(index);
    });

    // Show Snackbar with undo option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              if (_lastDeletedNote != null && _lastDeletedNoteIndex != null) {
                _notes.insert(_lastDeletedNoteIndex!, _lastDeletedNote!);
                _lastDeletedNote = null; // Clear last deleted note
                _lastDeletedNoteIndex = null; // Clear index
              }
            });
          },
        ),
        duration: const Duration(seconds: 3), // Show Snackbar for 3 seconds
      ),
    );
  }

  void _shareNote(Note note) {
    Share.share('Title: ${note.title}\n\nContent: ${note.content}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          // Toggle theme button with dynamic color based on the current theme
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: widget.isDarkMode ? Colors.yellow : Colors.black,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          final formattedDate = DateFormat('MMM d, yyyy - hh:mm a').format(note.dateTime);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                note.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: $formattedDate',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    color: Colors.green,
                    onPressed: () => _shareNote(note),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () => _deleteNoteWithUndo(index),
                  ),
                ],
              ),
              onTap: () => _editNote(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}

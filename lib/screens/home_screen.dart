import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino icons
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
  List<Note> _filteredNotes = [];
  String _searchQuery = ''; // Current search query
  bool _isSearchActive = false; // Flag to check if search bar is active
  bool _isSortedByDate = true; // Flag for sorting by date (newest to oldest)

  @override
  void initState() {
    super.initState();
    _filteredNotes = _notes; // Initialize filtered notes with all notes
  }

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
        _filteredNotes = _notes; // Update filtered notes
      });
    }
  }

  void _editNote(int index) async {
    final editedNote = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNoteScreen(note: _filteredNotes[index]),
      ),
    );
    if (editedNote != null) {
      setState(() {
        final editedNoteObj = editedNote as Note;
        _notes[_notes.indexOf(_filteredNotes[index])] = editedNoteObj;
        _filteredNotes = _notes;
        _isSearchActive = false;
        _searchQuery = '';
      });
    }
  }

  void _deleteNoteWithUndo(int index) {
    // Use the note from the filtered list to ensure correct deletion
    final Note deletedNote = _filteredNotes[index];

    setState(() {
      _notes.remove(deletedNote); // Remove the note from the main list
      _filteredNotes = _notes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList(); // Update filtered notes
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              // Restore the deleted note
              _notes.add(deletedNote);
              _filteredNotes = _notes.where((note) {
                return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    note.content.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList(); // Update filtered notes
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _shareNote(Note note) {
    Share.share('Title: ${note.title}\n\nContent:\n${note.content}\n\n${DateFormat('d MMM, yyyy - hh:mm a').format(note.dateTime)}');
  }

  void _searchNotes(String query) {
    setState(() {
      _searchQuery = query;
      _filteredNotes = _notes.where((note) {
        return note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _sortNotes() {
    setState(() {
      if (_isSortedByDate) {
        _notes.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Sort by newest to oldest
      } else {
        _notes.sort((a, b) => a.dateTime.compareTo(b.dateTime)); // Sort by oldest to newest
      }
      _filteredNotes = _notes; // Update filtered notes after sorting
    });
  }

  Future<bool> _onWillPop() async {
    if (_isSearchActive) {
      setState(() {
        _isSearchActive = false;
        _searchQuery = '';
        _filteredNotes = _notes; // Reset to the full list
      });
      return false; // Prevent the app from closing
    }
    return true; // Allow the app to close
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Notes'),
          actions: [
            IconButton(
              icon: Icon(_isSearchActive ? Icons.close : Icons.search),
              color: widget.isDarkMode ? Colors.white : Colors.black,
              onPressed: () {
                setState(() {
                  if (_isSearchActive) {
                    _isSearchActive = false;
                    _searchQuery = '';
                    _filteredNotes = _notes;
                  } else {
                    _isSearchActive = true;
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(
                _isSortedByDate ? CupertinoIcons.sort_down : CupertinoIcons.sort_up, // Cupertino icons for sorting
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _isSortedByDate = !_isSortedByDate;
                  _sortNotes();
                });
              },
            ),
            IconButton(
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: widget.isDarkMode ? Colors.yellow : Colors.black,
              ),
              onPressed: widget.toggleTheme,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isSearchActive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Search notes...',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: _searchNotes,
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = _filteredNotes[index];
                  final formattedDate = DateFormat('d MMM, yyyy - hh:mm a').format(note.dateTime);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      title: Text(
                        note.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$formattedDate',
                            style: const TextStyle(fontSize: 12, color: Colors.white38),
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
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNote,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

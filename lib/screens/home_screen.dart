import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino icons
import 'package:share/share.dart'; // Share functionality package
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart'; // For persistent storage
import 'dart:convert'; // For JSON serialization
import 'add_note_screen.dart';
import '../models/note.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // Global theme state

  @override
  void initState() {
    super.initState();
    _loadDarkMode(); // Load saved dark mode preference
  }

  // Load dark mode preference from SharedPreferences
  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default to light mode if not set
    });
  }

  // Toggle dark mode and save preference
  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode; // Toggle dark mode state
      prefs.setBool('isDarkMode', _isDarkMode); // Save updated dark mode state
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      theme: _isDarkMode
          ? ThemeData.dark() // Dark theme
          : ThemeData.light(), // Light theme
      home: HomeScreen(
        toggleTheme: _toggleDarkMode,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}

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
  bool _isSortedByDate = false; // Flag for sorting by date (newest to oldest)

  @override
  void initState() {
    super.initState();
    _loadNotes(); // Load saved notes
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = jsonEncode(_notes.map((note) => note.toJson()).toList());
    await prefs.setString('notes', notesJson);
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('notes');
    if (notesJson != null) {
      final List decodedList = jsonDecode(notesJson);
      setState(() {
        _notes.addAll(decodedList.map((data) => Note.fromJson(data)));
        _filteredNotes = _notes;
      });
    }
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
      _saveNotes(); // Save notes after adding
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
      _saveNotes(); // Save notes after editing
    }
  }

  void _deleteNoteWithUndo(int index) {
    final Note deletedNote = _filteredNotes[index];
    final originalIndex = _notes.indexOf(deletedNote);

    setState(() {
      _filteredNotes.removeAt(index);
      _notes.remove(deletedNote);
    });
    _saveNotes(); // Save notes after deletion

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _notes.insert(originalIndex, deletedNote);
              _filteredNotes = _notes;
            });
            _saveNotes(); // Save notes after undo
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _shareNote(Note note) {
    Share.share(
        'Title: ${note.title}\n\nContent:\n${note.content}\n\n${DateFormat('d MMM, yyyy - hh:mm a').format(note.dateTime)}');
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
                _isSortedByDate
                    ? CupertinoIcons.sort_down
                    : CupertinoIcons.sort_up, // Cupertino icons for sorting
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
                  final formattedDate =
                  DateFormat('d MMM, yyyy - hh:mm a').format(note.dateTime);

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

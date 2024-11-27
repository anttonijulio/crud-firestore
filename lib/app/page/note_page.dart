import 'package:animated_loading_bar/animated_loading_bar.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../app.dart';
import '../helper/helper.dart';
import '../model/note.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late FocusNode _noteFNode;
  late TextEditingController _noteTextController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _noteFNode = FocusNode();
    _noteTextController = TextEditingController();
    _listenConnection();
  }

  @override
  void dispose() {
    _noteFNode.dispose();
    _noteTextController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await FirebaseFirestore.instance.collection(collectionId).get();
  }

  void _listenConnection() async {
    Helper.listenConnection().listen((event) {
      if (event.contains(ConnectivityResult.none)) {
        _showFlushbar(
            'Koneksi terputus, kamu tidak bisa menambah catatan sekarang');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Ku')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(collectionId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                itemCount: snapshot.data?.docs.length ?? 3,
                itemBuilder: (_, __) {
                  return Shimmer.fromColors(
                    baseColor: Theme.of(context).primaryColor,
                    highlightColor: Colors.grey.shade800,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      title: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      subtitle: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  );
                },
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Catatan kamu kosong nih',
                  textAlign: TextAlign.center,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('error - ${snapshot.error}'));
            } else {
              return ListView.separated(
                itemCount: snapshot.data!.docs.length,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final snapshotData = snapshot.data!.docs[index].data();
                  final note = Note.fromFirestore(snapshotData);

                  return ListTile(
                    leading: CircleAvatar(
                        child: Text(note.content[0].toUpperCase())),
                    title: Text(note.content),
                    subtitle: Text('ID ${note.id}'),
                    // delete note
                    trailing: IconButton(
                      onPressed: () => _deleteNote(note),
                      icon: const Icon(Icons.delete),
                    ),
                    // edit note
                    onTap: () {
                      // set current content to TextField
                      setState(() => _noteTextController.text = note.content);
                      _openTextField(
                        onSubmitted: (newValue) {
                          final currentNote = Note(
                            id: note.id,
                            content: newValue,
                            timestamp: note.timestamp,
                          );
                          _editNote(currentNote);
                        },
                      );
                    },
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTextField(
          onSubmitted: (value) {
            final id = Helper.generateID(value);
            final now = DateTime.now().toString();
            _addNote(Note(id: id, content: value, timestamp: now));
          },
        ),
        child: const Icon(Icons.edit_note),
      ),
    );
  }

  void _openTextField({
    required void Function(String value) onSubmitted,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                AnimatedLoadingBar(
                  height: 2,
                  colors: [Theme.of(context).primaryColorLight],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Material(
                      borderRadius: BorderRadius.circular(100),
                      color: Theme.of(context).primaryColor,
                      child: TextField(
                        autofocus: true,
                        focusNode: _noteFNode,
                        onSubmitted: onSubmitted,
                        controller: _noteTextController,
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Tulis catatan kamu disini',
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _unfocus,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNote(Note newNote) async {
    if (_noteTextController.text.isEmpty) {
      _unfocus();
      _showFlushbar('note tidak boleh kosong');
    } else if (_noteTextController.text.length <= 5) {
      _unfocus();
      _showFlushbar('Panjang note harus lebih dari 5 karakter');
    } else {
      if (await Helper.availableConnection()) {
        try {
          setState(() => _isLoading = true);

          await FirebaseFirestore.instance
              .collection(collectionId)
              .doc(newNote.id)
              .set(newNote.toFirestore());

          setState(() => _isLoading = false);

          _unfocus();
        } catch (e) {
          _noteFNode.unfocus();
          await _showErrorDialog(e);
        }
      } else {
        _unfocus(clearText: false);
        _showFlushbar('Koneksi terputus');
      }
    }
  }

  void _editNote(Note currentNote) async {
    if (_noteTextController.text.isEmpty) {
      _unfocus();
      _showFlushbar('note tidak boleh kosong');
    } else if (_noteTextController.text.length <= 5) {
      _unfocus();
      _showFlushbar('Panjang note harus lebih dari 5 karakter');
    } else {
      // check connection
      if (await Helper.availableConnection()) {
        try {
          setState(() => _isLoading = true);

          await FirebaseFirestore.instance
              .collection(collectionId)
              .doc(currentNote.id)
              .update(currentNote.toFirestore());

          setState(() => _isLoading = false);

          _unfocus();
          _showFlushbar('Catatan berhasil diupdate');
        } catch (e) {
          _noteFNode.unfocus();
          await _showErrorDialog(e);
        }
      } else {
        _unfocus();
        _showFlushbar('Koneksi terputus');
      }
    }
  }

  void _deleteNote(Note currentNote) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Catatan'),
          content: Text.rich(
            TextSpan(
              text: 'Kamu yakin ingin menghapus ',
              children: [
                TextSpan(
                  text: currentNote.content,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' ?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                if (await Helper.availableConnection()) {
                  try {
                    await FirebaseFirestore.instance
                        .collection(collectionId)
                        .doc(currentNote.id)
                        .delete();
                    if (context.mounted) {
                      Navigator.of(dialogContext).pop(); // tutup dialog
                    }
                    _showFlushbar('Catatan dihapus');
                  } catch (e) {
                    _showFlushbar('Terjadi kesalahan saat menghapus catatan');
                  }
                } else {
                  _unfocus();
                  _showFlushbar('Koneksi terputus');
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> _showErrorDialog(Object? error) {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                FocusScope.of(context).requestFocus(_noteFNode);
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        );
      },
    );
  }

  void _unfocus({bool clearText = true}) {
    _noteFNode.unfocus();
    if (clearText) _noteTextController.clear();
    Navigator.of(context).pop(); // close dialog
  }

  void _showFlushbar(String message, {bool isDismissible = true}) async {
    await Flushbar(
      message: message,
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      duration: const Duration(seconds: 3),
      isDismissible: isDismissible,
    ).show(context);
  }
}

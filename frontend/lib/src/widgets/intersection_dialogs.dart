import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart'; // <--- needed
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/directions_provider.dart';
import '../models/direction_line.dart';

Future<void> saveIntersectionToFile(
    BuildContext context, DirectionsProvider provider, Size canvasSize) async {
  final nameController = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Save Intersection'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Intersection name',
          hintText: 'e.g. Baker St – Melcombe St',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) return;

            String? filePath = await FilePicker.platform.saveFile(
              dialogTitle: 'Save Intersection as JSON',
              fileName: '$name.json',
              type: FileType.custom,
              allowedExtensions: ['json'],
            );

            if (filePath != null) {
              final data = provider.serializeIntersection(name, canvasSize);
              final file = File(filePath);
              await file.writeAsString(jsonEncode(data));
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> showLoadIntersectionDialog(BuildContext context) async {
  final provider = context.read<DirectionsProvider>();

  String? filePath = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select Intersection JSON',
    type: FileType.custom,
    allowedExtensions: ['json'],
  ).then((result) => result != null ? result.files.single.path : null);

  if (filePath == null) return;

  final file = File(filePath);
  final jsonString = await file.readAsString();
  final data = jsonDecode(jsonString);

  provider.loadIntersectionFromData(data);
}


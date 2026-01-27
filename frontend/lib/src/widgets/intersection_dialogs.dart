import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/src/localization/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../view_models/directions_view_model.dart';
import '../models/intersection_model.dart';

Future<void> showSaveIntersectionDialog(
  BuildContext context,
  DirectionsViewModel provider,
  Size canvasSize,
  AppLocalizations localizations,
) async {
  final nameController = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(localizations.saveIntersection),
        content: TextField(
          controller: nameController,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: localizations.intersectionName,
            hintText: localizations.intersectionNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: nameController.text.trim().isEmpty ? null : () async {
              final name = nameController.text.trim();

              final dir = await getApplicationDocumentsDirectory();
              final intersectionsDir = Directory(p.join(dir.path, 'intersections'));

              if (!intersectionsDir.existsSync()) {
                intersectionsDir.createSync(recursive: true);
              }

              final filePath = p.join(intersectionsDir.path, '$name.json');
              final data = provider.serializeIntersection(name, canvasSize);
              final file = File(filePath);
              await file.writeAsString(jsonEncode(data));

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.intersectionSaved(name))),
              );
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    ),
  );
}

Future<void> showLoadIntersectionDialog(
  BuildContext context,
  DirectionsViewModel provider,
  AppLocalizations localizations,
) async {

  Future<void> _handlePickFile({bool shouldPopDialog = true}) async {
    final result = await provider.pickIntersectionFile();
    if (result == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.invalidFileContent)),
      );
      return;
    }

    if (!context.mounted) return;
    if (shouldPopDialog && Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.intersectionLoaded(result.name))),
    );
  }

  final dir = await getApplicationDocumentsDirectory();
  final intersectionsDir = Directory(p.join(dir.path, 'intersections'));

  if (!intersectionsDir.existsSync()) {
    await _handlePickFile(shouldPopDialog: false);
    return;
  }

  final files = intersectionsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  if (files.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.noSavedIntersectionsFound)),
    );
    return;
  }

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(localizations.loadIntersection),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (_, index) {
              final file = files[index];
              final name = file.uri.pathSegments.last.replaceAll('.json', '');
              return ListTile(
                title: Text(name),
                subtitle: Text(file.path),
                leading: Icon(Icons.alt_route, color: Theme.of(context).colorScheme.onSurface),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
                  tooltip: localizations.delete,
                  onPressed: () async {
                    await provider.deleteIntersection(file.path);
                    files.removeAt(index);
                    if (context.mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(localizations.intersectionDeleted(name))),
                      );
                    }
                  },
                ),
                onTap: () async {
                  final jsonString = await file.readAsString();
                  final data = jsonDecode(jsonString);
                  provider.file = IntersectionModel.fromJson(data);
                  provider.loadIntersectionFromData(data);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.intersectionLoaded(name))),
                    );
                  }
                  
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _handlePickFile(),
            child: Text(localizations.loadFromDisk),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    ),
  );
}
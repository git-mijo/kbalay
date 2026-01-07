import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';

class CsvUploadWidget extends StatefulWidget {
  const CsvUploadWidget({super.key});

  @override
  State<CsvUploadWidget> createState() => _CsvUploadWidgetState();
}

class _CsvUploadWidgetState extends State<CsvUploadWidget> {
  bool isUploading = false;
  String? uploadedFileName;
  int uploadedCount = 0;
  String? errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _uploadCsv() async {
    setState(() {
      isUploading = true;
      errorMessage = null;
      uploadedCount = 0;
      uploadedFileName = null;
    });

    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) {
        setState(() => isUploading = false);
        return;
      }

      // Read CSV contents
      String csvString;
      if (result.files.single.bytes != null) {
        csvString = utf8.decode(result.files.single.bytes!);
      } else if (result.files.single.path != null) {
        csvString = await File(result.files.single.path!).readAsString();
      } else {
        throw 'Cannot read CSV file.';
      }

      // Parse CSV
      final csvConverter = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
        fieldDelimiter: ',',
        textDelimiter: '"',
      );
      final rows = csvConverter.convert(csvString);

      final nonEmptyRows =
          rows.where((r) => r.any((c) => c.toString().trim().isNotEmpty)).toList();
      if (nonEmptyRows.isEmpty) throw 'CSV file is empty';

      // Headers
      final headersRaw = nonEmptyRows.first;
      final headers = headersRaw.map((h) => h.toString().trim()).toList();
      final requiredColumns = ['lotId', 'firstName', 'lastName', 'fullAddress'];
      for (var col in requiredColumns) {
        if (!headers.contains(col)) throw 'Missing required column: $col';
      }

      // Map rows
      final csvData = <Map<String, String>>[];
      for (int i = 1; i < nonEmptyRows.length; i++) {
        final row = nonEmptyRows[i];
        final map = <String, String>{};
        for (int j = 0; j < headers.length; j++) {
          map[headers[j]] = j < row.length ? row[j].toString().trim() : '';
        }
        csvData.add(map);
      }

      // --- OPTIMIZED EXISTING LOT CHECK ---
      final lotIds = csvData.map((r) => r['lotId']!).toList();
      final existingDocs = <DocumentSnapshot<Object?>>[];

      const batchSize = 10; // Firestore whereIn limit
      for (var i = 0; i < lotIds.length; i += batchSize) {
        final chunk = lotIds.sublist(i, (i + batchSize).clamp(0, lotIds.length));
        final querySnapshot = await _firestore
            .collection('master_residents')
            .where('lotId', whereIn: chunk)
            .get();
        existingDocs.addAll(querySnapshot.docs);
      }

      final newResidents = <Map<String, String>>[];
      final toUpdateDocs = <Map<String, dynamic>>[];

      for (var resident in csvData) {
        final lotId = resident['lotId']!;
        // null-safe way to find existing doc
        DocumentSnapshot<Object?>? existingDoc;
        for (final doc in existingDocs) {
          if (doc['lotId'] == lotId) {
            existingDoc = doc;
            break;
          }
        }

        if (existingDoc == null) {
          // New resident → add to batch insert
          newResidents.add({
            ...resident,
            'userId': '', // empty userId
          });
        } else {
          final existingUserId = existingDoc['userId'] as String?;
          if (existingUserId == null || existingUserId.isEmpty) {
            // Existing resident with empty userId → update data
            toUpdateDocs.add({
              'docRef': existingDoc.reference,
              'data': {
                'firstName': resident['firstName'],
                'lastName': resident['lastName'],
                'fullAddress': resident['fullAddress'],
              },
            });
          }
          // Else: existing resident with userId → skip
        }
      }

      if (newResidents.isEmpty && toUpdateDocs.isEmpty) {
        setState(() {
          errorMessage = 'No new residents to upload or update.';
          isUploading = false;
        });
        return;
      }

      // Confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final displayList = [
            ...newResidents.map((r) => {...r, 'type': 'new'}),
            ...toUpdateDocs.map((u) => {...u['data'], 'type': 'update'}),
          ];
          return AlertDialog(
            title: const Text('Confirm Upload'),
            content: SizedBox(
              width: double.maxFinite,
              height: 40.h,
              child: ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final r = displayList[index];
                  final type = r['type'] as String;
                  return ListTile(
                    leading: Icon(type == 'new' ? Icons.person_add : Icons.edit),
                    title: Text('${r['firstName']} ${r['lastName']}'),
                    subtitle: Text(r['fullAddress']!),
                    trailing: Text(type == 'new' ? 'New' : 'Update'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Upload'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        setState(() => isUploading = false);
        return;
      }

      // Batch upload and update
      final batch = _firestore.batch();
      for (var r in newResidents) {
        final doc = _firestore.collection('master_residents').doc();
        batch.set(doc, {
          ...r,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      for (var u in toUpdateDocs) {
        batch.update(u['docRef'], u['data']);
      }
      await batch.commit();

      setState(() {
        uploadedFileName = result.files.single.name;
        uploadedCount = newResidents.length + toUpdateDocs.length;
      });

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded/Updated $uploadedCount residents'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorMessage != null
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withAlpha(77),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            uploadedFileName != null ? Icons.check_circle : Icons.upload_file,
            size: 32.sp,
            color: uploadedFileName != null
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            uploadedFileName ?? 'Upload Resident Data (CSV)',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            uploadedFileName != null
                ? '$uploadedCount residents uploaded successfully'
                : 'Required columns: lotId, firstName, lastName, fullAddress',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (errorMessage != null) ...[
            SizedBox(height: 1.h),
            Text(
              errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUploading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _uploadCsv();
                    },
              icon: isUploading
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.file_upload),
              label: Text(isUploading ? 'Uploading...' : 'Select CSV File'),
            ),
          ),
        ],
      ),
    );
  }
}

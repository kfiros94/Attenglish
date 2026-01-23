import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:typed_data';
import '../models/class_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/widgets/cross_platform_drop_zone.dart';

/// Student data parsed from Excel file
class StudentImportData {
  final String fullName;
  final String userName;
  final String email;
  final String password;
  final String parentFullName;
  final String parentPhone;
  final String? parentEmail;
  bool isValid;
  String? errorMessage;

  StudentImportData({
    required this.fullName,
    required this.userName,
    required this.email,
    required this.password,
    required this.parentFullName,
    required this.parentPhone,
    this.parentEmail,
    this.isValid = true,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'userName': userName,
    'email': email,
    'password': password,
    'parentFullName': parentFullName,
    'parentPhone': parentPhone,
    if (parentEmail != null && parentEmail!.isNotEmpty) 'parentEmail': parentEmail,
  };
}

/// Dialog for importing students from Excel file
class ExcelStudentImportDialog extends StatefulWidget {
  final ClassModel classroom;

  const ExcelStudentImportDialog({
    super.key,
    required this.classroom,
  });

  @override
  State<ExcelStudentImportDialog> createState() => _ExcelStudentImportDialogState();
}

class _ExcelStudentImportDialogState extends State<ExcelStudentImportDialog> {
  List<StudentImportData> _students = [];
  bool _isLoading = false;
  bool _isImporting = false;
  bool _isDragging = false;
  String? _fileName;
  String? _errorMessage;
  int _successCount = 0;
  int _failedCount = 0;

  /// Handle file from drag & drop or file picker
  Future<void> _handleFile(String fileName, Uint8List bytes) async {
    setState(() {
      _fileName = fileName;
      _isLoading = true;
      _errorMessage = null;
      _students = [];
    });

    // Check file extension
    final extension = fileName.split('.').last.toLowerCase();
    if (!['xlsx', 'xls', 'ods'].contains(extension)) {
      setState(() {
        _errorMessage = LocalizationService.instance.isRTL
            ? 'סוג קובץ לא נתמך. השתמש ב-.xlsx, .xls או .ods'
            : 'Unsupported file type. Use .xlsx, .xls, or .ods';
        _isLoading = false;
      });
      return;
    }

    _parseExcel(bytes);
  }

  /// Pick and parse Excel file
  Future<void> _pickExcelFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _students = [];
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'ods'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final file = result.files.first;

      if (file.bytes == null) {
        setState(() {
          _errorMessage = LocalizationService.instance.isRTL
              ? 'לא ניתן לקרוא את הקובץ'
              : 'Could not read file';
          _isLoading = false;
        });
        return;
      }

      await _handleFile(file.name, file.bytes!);
    } catch (e) {
      setState(() {
        _errorMessage = LocalizationService.instance.isRTL
            ? 'שגיאה בבחירת קובץ: $e'
            : 'Error picking file: $e';
        _isLoading = false;
      });
    }
  }

  /// Parse Excel file and extract student data using spreadsheet_decoder
  void _parseExcel(Uint8List bytes) {
    try {
      debugPrint('Starting Excel parsing, bytes length: ${bytes.length}');

      // Use spreadsheet_decoder to parse the file
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);
      final students = <StudentImportData>[];

      debugPrint('Excel decoded. Tables: ${decoder.tables.keys.toList()}');

      // Check if there are any sheets
      if (decoder.tables.isEmpty) {
        setState(() {
          _errorMessage = LocalizationService.instance.isRTL
              ? 'לא נמצאו גיליונות בקובץ'
              : 'No sheets found in file';
          _isLoading = false;
        });
        return;
      }

      // Get the first sheet
      final sheetName = decoder.tables.keys.first;
      final sheet = decoder.tables[sheetName];

      debugPrint('Using sheet: $sheetName');

      if (sheet == null) {
        setState(() {
          _errorMessage = LocalizationService.instance.isRTL
              ? 'לא ניתן לקרוא את הגיליון'
              : 'Could not read sheet';
          _isLoading = false;
        });
        return;
      }

      debugPrint('Sheet rows: ${sheet.rows.length}');

      if (sheet.rows.isEmpty) {
        setState(() {
          _errorMessage = LocalizationService.instance.isRTL
              ? 'הקובץ ריק'
              : 'File is empty';
          _isLoading = false;
        });
        return;
      }

      // Debug: print first row to verify structure
      if (sheet.rows.isNotEmpty) {
        debugPrint('First row (headers): ${sheet.rows.first}');
      }

      // Expected columns: fullName, userName, email, password, parentFullName, parentPhone, parentEmail (optional)
      // Skip header row (first row)
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
          continue;
        }

        debugPrint('Processing row $i: $row');

        final fullName = _getCellValue(row, 0);
        final userName = _getCellValue(row, 1);
        final email = _getCellValue(row, 2);
        final password = _getCellValue(row, 3);
        final parentFullName = _getCellValue(row, 4);
        final parentPhone = _getCellValue(row, 5);
        final parentEmail = row.length > 6 ? _getCellValue(row, 6) : null;

        final student = StudentImportData(
          fullName: fullName,
          userName: userName,
          email: email,
          password: password,
          parentFullName: parentFullName,
          parentPhone: parentPhone,
          parentEmail: parentEmail,
        );

        // Validate student data
        _validateStudent(student);
        students.add(student);
      }

      if (students.isEmpty) {
        setState(() {
          _errorMessage = LocalizationService.instance.isRTL
              ? 'לא נמצאו תלמידים בקובץ'
              : 'No students found in file';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Excel parsing error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = LocalizationService.instance.isRTL
            ? 'שגיאה בפענוח קובץ: $e'
            : 'Error parsing file: $e';
        _isLoading = false;
      });
    }
  }

  /// Get cell value as string
  String _getCellValue(List<dynamic> row, int index) {
    if (index >= row.length || row[index] == null) {
      return '';
    }
    return row[index].toString().trim();
  }

  /// Validate student data
  void _validateStudent(StudentImportData student) {
    final isRTL = LocalizationService.instance.isRTL;
    final errors = <String>[];

    if (student.fullName.isEmpty) {
      errors.add(isRTL ? 'שם מלא חסר' : 'Full name missing');
    }
    if (student.userName.isEmpty) {
      errors.add(isRTL ? 'שם משתמש חסר' : 'Username missing');
    } else if (student.userName.contains(' ')) {
      errors.add(isRTL ? 'שם משתמש לא יכול להכיל רווחים' : 'Username cannot contain spaces');
    }
    if (student.email.isEmpty) {
      errors.add(isRTL ? 'אימייל חסר' : 'Email missing');
    } else if (!student.email.contains('@')) {
      errors.add(isRTL ? 'אימייל לא תקין' : 'Invalid email');
    }
    if (student.password.isEmpty) {
      errors.add(isRTL ? 'סיסמה חסרה' : 'Password missing');
    } else if (student.password.length < 6) {
      errors.add(isRTL ? 'סיסמה קצרה מדי (מינימום 6)' : 'Password too short (min 6)');
    }
    if (student.parentFullName.isEmpty) {
      errors.add(isRTL ? 'שם הורה חסר' : 'Parent name missing');
    }
    if (student.parentPhone.isEmpty) {
      errors.add(isRTL ? 'טלפון הורה חסר' : 'Parent phone missing');
    }
    if (student.parentEmail != null && student.parentEmail!.isNotEmpty && !student.parentEmail!.contains('@')) {
      errors.add(isRTL ? 'אימייל הורה לא תקין' : 'Invalid parent email');
    }

    if (errors.isNotEmpty) {
      student.isValid = false;
      student.errorMessage = errors.join(', ');
    }
  }

  /// Import students using Cloud Function
  Future<void> _importStudents() async {
    final validStudents = _students.where((s) => s.isValid).toList();

    if (validStudents.isEmpty) {
      final isRTL = LocalizationService.instance.isRTL;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRTL ? 'אין תלמידים תקינים לייבוא' : 'No valid students to import'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('bulkCreateStudents');

      final result = await callable.call({
        'classId': widget.classroom.id,
        'students': validStudents.map((s) => s.toJson()).toList(),
      });

      final data = result.data as Map<String, dynamic>;
      _successCount = data['created'] as int? ?? 0;
      _failedCount = data['failed'] as int? ?? 0;

      if (mounted) {
        Navigator.of(context).pop(true);

        final isRTL = LocalizationService.instance.isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL
                  ? '$_successCount תלמידים נוספו בהצלחה${_failedCount > 0 ? ', $_failedCount נכשלו' : ''}'
                  : '$_successCount students added successfully${_failedCount > 0 ? ', $_failedCount failed' : ''}',
            ),
            backgroundColor: _failedCount > 0 ? AppColors.warning : AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final isRTL = LocalizationService.instance.isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL ? 'שגיאה בייבוא תלמידים: $e' : 'Error importing students: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;
    final validCount = _students.where((s) => s.isValid).length;
    final invalidCount = _students.where((s) => !s.isValid).length;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.upload_file,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRTL ? 'ייבוא תלמידים מאקסל' : 'Import Students from Excel',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${widget.classroom.name} - ${isRTL ? 'כיתה' : 'Grade'} ${widget.classroom.grade}',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isRTL ? 'פורמט קובץ נדרש:' : 'Required file format:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRTL
                          ? 'עמודות נדרשות (בסדר הזה):\n'
                            '1. שם מלא\n'
                            '2. שם משתמש\n'
                            '3. אימייל\n'
                            '4. סיסמה\n'
                            '5. שם הורה\n'
                            '6. טלפון הורה\n'
                            '7. אימייל הורה (אופציונלי)'
                          : 'Required columns (in this order):\n'
                            '1. Full Name\n'
                            '2. Username\n'
                            '3. Email\n'
                            '4. Password\n'
                            '5. Parent Name\n'
                            '6. Parent Phone\n'
                            '7. Parent Email (optional)',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRTL
                          ? 'השורה הראשונה צריכה להיות כותרות (תידלג)'
                          : 'First row should be headers (will be skipped)',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Drag & Drop zone with smooth animations (cross-platform)
              CrossPlatformDropZone(
                enabled: !_isLoading && !_isImporting,
                onDragStateChanged: (isDragging) => setState(() => _isDragging = isDragging),
                onFileDrop: (fileName, bytes) async {
                  await _handleFile(fileName, bytes);
                },
                child: GestureDetector(
                  onTap: _isLoading || _isImporting ? null : _pickExcelFile,
                  child: MouseRegion(
                    cursor: _isLoading || _isImporting
                        ? SystemMouseCursors.forbidden
                        : SystemMouseCursors.click,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: _isDragging ? 1.02 : 1.0),
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutCubic,
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        decoration: BoxDecoration(
                          color: _isDragging
                              ? AppColors.primary.withOpacity(0.08)
                              : (_fileName != null
                                  ? AppColors.success.withOpacity(0.05)
                                  : AppColors.background),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: _isDragging
                                ? AppColors.primary
                                : (_fileName != null
                                    ? AppColors.success
                                    : AppColors.textTertiary),
                            width: _isDragging ? 2.5 : 1,
                          ),
                          boxShadow: _isDragging
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoading)
                              const CircularProgressIndicator()
                            else if (_fileName != null)
                              const Icon(
                                Icons.check_circle,
                                size: 48,
                                color: AppColors.success,
                              )
                            else
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: _isDragging ? -8.0 : 0.0),
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                builder: (context, offset, child) => Transform.translate(
                                  offset: Offset(0, offset),
                                  child: Icon(
                                    _isDragging ? Icons.file_download : Icons.cloud_upload_outlined,
                                    size: 48,
                                    color: _isDragging ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppTheme.spacingSmall),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: _isDragging ? AppTheme.fontSizeMedium + 1 : AppTheme.fontSizeMedium,
                                color: _fileName != null
                                    ? AppColors.success
                                    : (_isDragging ? AppColors.primary : AppColors.textSecondary),
                                fontWeight: _fileName != null || _isDragging ? FontWeight.w600 : FontWeight.normal,
                              ),
                              child: Text(
                                _isDragging
                                    ? (isRTL ? 'שחרר כאן!' : 'Drop file here!')
                                    : (_fileName ?? (isRTL
                                        ? 'גרור קובץ אקסל לכאן או לחץ לבחירה'
                                        : 'Drag Excel file here or click to browse')),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _isDragging ? 0.0 : 1.0,
                              child: Column(
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    isRTL ? 'פורמטים נתמכים: .xlsx, .xls, .ods' : 'Supported: .xlsx, .xls, .ods',
                                    style: const TextStyle(
                                      fontSize: AppTheme.fontSizeSmall,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: AppTheme.spacingMedium),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Student preview list
              if (_students.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMedium),

                // Summary
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: validCount > 0
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${_students.length}',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isRTL ? 'סה"כ' : 'Total',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$validCount',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            isRTL ? 'תקינים' : 'Valid',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      if (invalidCount > 0)
                        Column(
                          children: [
                            Text(
                              '$invalidCount',
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            Text(
                              isRTL ? 'שגויים' : 'Invalid',
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSmall),

                // Student list
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      return Card(
                        color: student.isValid
                            ? null
                            : AppColors.error.withOpacity(0.05),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: student.isValid
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.error.withOpacity(0.2),
                            child: Icon(
                              student.isValid ? Icons.check : Icons.error,
                              color: student.isValid ? AppColors.success : AppColors.error,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            student.fullName.isNotEmpty ? student.fullName : (isRTL ? 'שם חסר' : 'Missing name'),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: student.isValid ? AppColors.textPrimary : AppColors.error,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.email.isNotEmpty ? student.email : (isRTL ? 'אימייל חסר' : 'Missing email'),
                                style: const TextStyle(fontSize: AppTheme.fontSizeSmall),
                              ),
                              if (!student.isValid && student.errorMessage != null)
                                Text(
                                  student.errorMessage!,
                                  style: const TextStyle(
                                    fontSize: AppTheme.fontSizeSmall,
                                    color: AppColors.error,
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: !student.isValid,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.of(context).pop(false),
          child: Text(
            isRTL ? 'ביטול' : 'Cancel',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        if (_students.isNotEmpty && validCount > 0)
          ElevatedButton.icon(
            onPressed: _isImporting ? null : _importStudents,
            icon: _isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload),
            label: Text(
              isRTL ? 'ייבא $validCount תלמידים' : 'Import $validCount Students',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
          ),
      ],
    );
  }
}

/// Show Excel student import dialog
Future<bool?> showExcelStudentImportDialog(
  BuildContext context,
  ClassModel classroom,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ExcelStudentImportDialog(classroom: classroom),
  );
}

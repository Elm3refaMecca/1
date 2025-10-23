// test_selection_page.dart (MODIFIED)

import 'dart:async'; // <-- إضافة مهمة للتعامل مع StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// --- MODIFIED: Direct import for GradeEntryPage ---
import 'package:almarefamecca/grade_entry_page.dart';


class TestItem {
  final String testFieldKey;
  final String name;
  final String term;

  TestItem({
    required this.testFieldKey,
    required this.name,
    required this.term,
  });
}

// --- REMOVED: _GradeEntryLoader widget is no longer needed ---

class TestSelectionPage extends StatelessWidget {
  final String stage;
  final String grade;
  final String className;
  final String subject;
  final String professionKey; // Note: This might not be directly used for Nafes anymore
  final bool isBehaviorMode;
  final bool isAdmin;

  const TestSelectionPage({
    super.key,
    required this.stage,
    required this.grade,
    required this.className,
    required this.subject,
    required this.professionKey, // Keep for non-Nafes subjects
    required this.isBehaviorMode,
    required this.isAdmin,
  });

  // --- ✅✅✅ START OF MODIFICATION ✅✅✅ ---
  // Helper map to convert subject name to a shortcode for the key
  static const Map<String, String> _subjectShortcodes = {
    'رياضيات': 'math',
    'لغتي': 'lughati',
    'علوم': 'science',
    // Add other subjects if Nafes expands to them in the future
  };

  List<TestItem> _getTestsForSubject() {
    final List<TestItem> allTests = [];
    final bool isNafesSubject = ['رياضيات', 'لغتي', 'علوم'].contains(subject);
    final String currentSubjectShortcode = _subjectShortcodes[subject] ?? '';

    // Add standard tests only if the subject is NOT Nafes OR if it IS a Nafes subject
    // (This avoids adding standard math tests when selecting Nafes-Math)
    // We use the passed `professionKey` for standard tests.
    if (!isNafesSubject || professionKey != 'profession13') {
      allTests.addAll([
        TestItem(testFieldKey: 'e1$professionKey', name: 'الاختبار الاول (دوري)', term: 'الترم الأول'),
        TestItem(testFieldKey: 'e2$professionKey', name: 'الاختبار الثاني (دوري)', term: 'الترم الأول'),
        TestItem(testFieldKey: 'e3$professionKey', name: 'الاختبار الثالث (دوري)', term: 'الترم الأول'),
        TestItem(testFieldKey: 'e14$professionKey', name: 'اختبار قبلي', term: 'اختبارات إضافية'),
        TestItem(testFieldKey: 'e15$professionKey', name: 'اختبار بعدي', term: 'اختبارات إضافية'),
        TestItem(testFieldKey: 'e16$professionKey', name: 'اختبار احتياطي', term: 'اختبارات إضافية'),
      ]);
    }


    // Conditionally add Nafes tests with subject-specific keys
    final bool isGrade6 = grade == 'الصف السادس';
    final bool isGrade3 = grade == 'الصف الثالث';
    final bool isScienceMathsLughati = ['علوم', 'رياضيات', 'لغتي'].contains(subject);
    final bool isMathsLughati = ['رياضيات', 'لغتي'].contains(subject);

    // Check if Nafes tests should be shown for the current grade and subject combination
    if (currentSubjectShortcode.isNotEmpty && ((isGrade6 && isScienceMathsLughati) || (isGrade3 && isMathsLughati))) {
      // Use 'profession13' as the base key part for Nafes
      const String nafesBaseKey = 'profession13';
      allTests.addAll([
        TestItem(testFieldKey: 'e1${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الأول أساسي', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e2${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الثاني أساسي', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e3${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الاول ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e4${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الثاني ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e5${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الثالث ف نافس', term: 'اختبارات نافس'), // Corrected typo
        TestItem(testFieldKey: 'e6${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الرابع ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e7${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الخامس ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e8${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار السادس ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e9${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار السابع ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e10${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الثامن ف نافس', term: 'اختبارات نافس'), // Corrected typo
        TestItem(testFieldKey: 'e11${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار التاسع ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e12${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار العاشر ف نافس', term: 'اختبارات نافس'),
      ]);
    }
    // --- ✅✅✅ END OF MODIFICATION ✅✅✅ ---

    return allTests;
  }

  @override
  Widget build(BuildContext context) {
    // --- MODIFIED: Navigate directly to GradeEntryPage ---
    if (isBehaviorMode) {
      // For behavior mode, navigate directly to the page.
      // No changes needed here as it doesn't involve testFieldKey for grading
      return GradeEntryPage(
        stage: stage,
        grade: grade,
        className: className,
        subject: subject,
        testFieldKey: 'behavior_mode', // A special key for behavior mode
        testName: 'تقييم سلوك الطلاب',
        isBehaviorMode: true,
      );
    }


    final allTests = _getTestsForSubject();
    // Group tests by term for display
    final term1Tests = allTests.where((t) => t.term == 'الترم الأول').toList();
    final additionalTests = allTests.where((t) => t.term == 'اختبارات إضافية').toList();
    final nafsTests = allTests.where((t) => t.term == 'اختبارات نافس').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('اختر الاختبار - $subject'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (term1Tests.isNotEmpty)
            _buildTermSection(context, 'الاختبارات الدورية', term1Tests),

          if (term1Tests.isNotEmpty && (additionalTests.isNotEmpty || nafsTests.isNotEmpty))
            const SizedBox(height: 24),

          if (additionalTests.isNotEmpty)
            _buildTermSection(context, 'اختبارات إضافية', additionalTests),

          if (additionalTests.isNotEmpty && nafsTests.isNotEmpty)
            const SizedBox(height: 24),

          // Display Nafes tests only if they exist for the selected context
          if (nafsTests.isNotEmpty)
            _buildTermSection(context, 'اختبارات نافس', nafsTests),
        ],
      ),
    );
  }

  Widget _buildTermSection(BuildContext context, String title, List<TestItem> termTests) {
    // Ensure the section is only built if there are tests for it
    if (termTests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Divider(),
        ...termTests.map((test) {
          return _TestTile(
            test: test,
            isAdmin: isAdmin,
            // --- MODIFIED: onTap now navigates directly ---
            onTap: (isLocked) {
              if (isLocked && !isAdmin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('هذا الاختبار مغلق حالياً من قبل الإدارة.')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GradeEntryPage(
                      stage: stage,
                      grade: grade,
                      className: className,
                      subject: subject, // Pass the actual subject name
                      testFieldKey: test.testFieldKey, // Pass the potentially modified key
                      testName: test.name,
                      isBehaviorMode: isBehaviorMode, // Should be false here
                    ),
                  ),
                );
              }
            },
          );
        }).toList(),
      ],
    );
  }
}

// -- (الحل) تم تعديل الويدجت بالكامل ليعمل بشكل لحظي --
class _TestTile extends StatefulWidget {
  final TestItem test;
  final bool isAdmin;
  final Function(bool isLocked) onTap;

  const _TestTile({
    required this.test,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  __TestTileState createState() => __TestTileState();
}

class __TestTileState extends State<_TestTile> {
  bool? _isLocked; // null indicates loading state
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _lockStatusSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLockStatus();
  }

  @override
  void dispose() {
    // إلغاء المتابعة عند حذف الويدجت لمنع تسرب الذاكرة
    _lockStatusSubscription?.cancel();
    super.dispose();
  }

  /// Establishes a real-time listener for changes to the test's lock status.
  void _listenToLockStatus() {
    _lockStatusSubscription = _firestore
        .collection('test_status')
        .doc(widget.test.testFieldKey) // Listen using the potentially modified key
        .snapshots()
        .listen((doc) {
      if (mounted) {
        setState(() {
          // If the document exists, read 'isLocked', otherwise default to false (unlocked).
          _isLocked = doc.exists ? (doc.data()?['isLocked'] ?? false) : false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        // --- Added error handling ---
        debugPrint("Error listening to lock status for ${widget.test.testFieldKey}: $error");
        setState(() {
          // On error (e.g., permission denied), default to locked for safety.
          _isLocked = true;
        });
      }
    });
  }

  Future<void> _toggleLockStatus() async {
    if (_isLocked == null) return; // Don't allow toggle if status is not loaded
    final newStatus = !_isLocked!;

    // Optimistic UI update for instant feedback
    setState(() {
      _isLocked = newStatus;
    });

    try {
      // Set the new status in Firestore. This will create the document if it doesn't exist.
      await _firestore.collection('test_status').doc(widget.test.testFieldKey).set({
        'isLocked': newStatus,
        'testName': widget.test.name, // Good practice to store test name too
      });
    } catch (e) {
      // If the Firestore update fails, revert the UI change and show an error.
      debugPrint("Error toggling lock status for ${widget.test.testFieldKey}: $e");
      setState(() {
        _isLocked = !newStatus; // Revert optimistic update
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث حالة الاختبار: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle the initial loading state (_isLocked is null)
    if (_isLocked == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const ListTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('جارِ تحميل حالة الاختبار...'),
        ),
      );
    }

    // Use the determined lock status
    final bool isEffectivelyLocked = _isLocked!;
    final Color iconColor = isEffectivelyLocked ? Colors.grey : Theme.of(context).primaryColor;
    final Color textColor = isEffectivelyLocked ? Colors.grey : Colors.black;
    final bool canTap = !isEffectivelyLocked || widget.isAdmin; // Admin can always tap

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(
          isEffectivelyLocked ? Icons.lock_outline : Icons.edit_note,
          color: iconColor,
        ),
        title: Text(
          widget.test.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        trailing: widget.isAdmin
            ? IconButton(
          icon: Icon(isEffectivelyLocked ? Icons.lock : Icons.lock_open, color: iconColor),
          tooltip: isEffectivelyLocked ? 'فتح الاختبار للمعلمين' : 'قفل الاختبار على المعلمين',
          onPressed: _toggleLockStatus, // Always allow admin to toggle
        )
            : (isEffectivelyLocked ? null : const Icon(Icons.arrow_forward_ios, size: 16)), // Show arrow only if unlocked for non-admin
        onTap: canTap ? () => widget.onTap(isEffectivelyLocked) : null, // Disable tap if locked for non-admin
      ),
    );
  }
}
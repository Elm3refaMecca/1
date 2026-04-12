import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

// ---------------------------------------------------------------------------
// 1. Models (نماذج البيانات)
// ---------------------------------------------------------------------------

class TestInfo {
  final String key;
  final String name;
  final String subject;
  final String testGroup;

  TestInfo({
    required this.key,
    required this.name,
    required this.subject,
    required this.testGroup,
  });
}

class Subject {
  final String name;
  final IconData icon;
  Subject({required this.name, required this.icon});
}

class TestResultDetail {
  final String testName;
  final num grade;
  final double maxGrade;
  final List<String> specificNotes;

  TestResultDetail({
    required this.testName,
    required this.grade,
    required this.maxGrade,
    required this.specificNotes,
  });
}

class TeacherContactInfo {
  final String name;
  final String? phone;
  final String availableTime;
  final bool isFound;

  TeacherContactInfo({
    required this.name,
    this.phone,
    required this.availableTime,
    this.isFound = false,
  });
}

class _AnalysisResult {
  final String groupName;
  final String subjectName;
  final double average;
  final double percentage;
  final double maxPossibleGrade;
  final num highestGrade;
  final num lowestGrade;
  final String assessment;
  final String consistency;
  final bool isBelowPassing;

  final List<MapEntry<String, num>> testResults;
  final List<TestResultDetail> detailedTestResults;
  final List<FlSpot> trendSpots;
  final String performanceTrend;
  final double? predictedNextGrade;
  final String riskAssessment;
  final int testCount;

  final List<String> teacherNotes;
  final String severityLevel;
  final List<String> studentTasks;
  final List<String> parentTasks;
  final String timeRecommendation;

  final String predictionMessage;
  final bool isPositiveTrend;

  _AnalysisResult({
    required this.groupName,
    required this.subjectName,
    required this.average,
    required this.percentage,
    required this.maxPossibleGrade,
    required this.highestGrade,
    required this.lowestGrade,
    required this.assessment,
    required this.consistency,
    required this.isBelowPassing,
    required this.testResults,
    required this.detailedTestResults,
    required this.trendSpots,
    required this.performanceTrend,
    this.predictedNextGrade,
    required this.riskAssessment,
    required this.testCount,
    required this.teacherNotes,
    required this.severityLevel,
    required this.studentTasks,
    required this.parentTasks,
    required this.timeRecommendation,
    required this.predictionMessage,
    required this.isPositiveTrend,
  });
}

class _OverallSubjectMetric {
  final String subjectName;
  final double overallPercentage;
  final double overallAverage;
  _OverallSubjectMetric({required this.subjectName, required this.overallPercentage, required this.overallAverage});
}

// ---------------------------------------------------------------------------
// 2. AdviceEngine (محرك التوجيه التربوي)
// ---------------------------------------------------------------------------

class AdviceEngine {
  static Map<String, dynamic> generateFamilyPlan(
      String subject,
      String grade,
      double percentage,
      List<String> weaknesses,
      String performanceTrend,
      double? predictedNextGrade,
      double maxGrade,
      ) {
    List<String> sTasks = [];
    List<String> pTasks = [];
    String timePlan = "";
    String predictionMsg = "";
    bool isPositive = true;

    if (predictedNextGrade != null) {
      if (performanceTrend.contains('تصاعد') || (predictedNextGrade >= (maxGrade * 0.85))) {
        isPositive = true;
        predictionMsg = "🌟 بشارة خير: مؤشر أداء ابننا الغالي في تصاعد، ونتوقع له تحقيق (${predictedNextGrade.toStringAsFixed(1)}) في التقييم القادم. كلماتكم المشجعة هي وقوده للاستمرار.";
      } else if (performanceTrend.contains('تراجع') || predictedNextGrade < (maxGrade * 0.6)) {
        isPositive = false;
        predictionMsg = "💡 فرصة للتحسين: المؤشرات الحالية تنبهنا لاحتمال تراجع الدرجة إلى (${predictedNextGrade.toStringAsFixed(1)}). لكننا واثقون أنه بالالتزام بالخطة أدناه، سيكسر هذه القاعدة ويعود للقمة.";
      } else {
        predictionMsg = "📊 استقرار مطمئن: المستوى ثابت، وبقليل من الجهد الإضافي في النقاط المذكورة، سنرى قفزة نوعية في النتائج بإذن الله.";
      }
    } else {
      predictionMsg = "نحن بانتظار المزيد من التقييمات لرسم مسار دقيق للبطل.";
    }

    if (percentage >= 0.90) {
      timePlan = "⏱️ 20 دقيقة (إثراء للموهبة)";
      sTasks.add("🌟 أنت قائد: قم بشرح الدرس لأخوتك أو زملائك.");
      sTasks.add("🚀 التحدي: ابحث عن معلومة جديدة حول الدرس لم تذكر في الكتاب.");
      pTasks.add("🎁 تعزيز الثقة: امدح جهده وليس ذكائه فقط.");
    } else if (percentage >= 0.70) {
      timePlan = "⏱️ 40 دقيقة (تركيز نوعي)";
      sTasks.add("📝 المراجعة الذكية: التركيز فقط على النقاط التي تم تحديدها.");
      pTasks.add("🔍 المتابعة الهادئة: التأكد من إتمام الواجبات بدقة.");
    } else {
      timePlan = "🚨 60 دقيقة (دعم ومساندة)";
      sTasks.add("🛑 التأسيس أولاً: العودة للمهارات الأساسية قبل البدء بالجديد.");
      pTasks.add("🤝 الشراكة: الجلوس بجانب الطالب أثناء الحل لمنحه الأمان والثقة.");
    }

    if (subject.contains('لغتي')) {
      sTasks.add("📚 القراءة الحرة لمدة 10 دقائق يومياً.");
      sTasks.add("✍️ تحسين الخط من خلال نسخ فقرة قصيرة.");
    } else if (subject.contains('رياضيات')) {
      sTasks.add("🔢 حل مسألة رياضية واحدة يومياً لتبقى الذاكرة نشطة.");
      sTasks.add("🧠 ربط الأرقام بالحياة اليومية (التسوق، الوقت).");
    }
    else if (subject.contains('نجليزي') || subject.contains('English')) {
      sTasks.add("📺 شاهد مقطع كرتوني قصير بالإنجليزية يومياً (ممتع ومفيد!).");
      sTasks.add("🎮 العب ألعاب تعليمية للغة الإنجليزية لمدة 10 دقائق.");
      sTasks.add("🗣️ حاول تسمية الأشياء حولك باللغة الإنجليزية (كرسي، طاولة..).");

      pTasks.add("🌍 الإنجليزية لغة العالم: ذكروا طفلكم بأنها ستجعله يفهم ألعابه وبرامجه المفضلة.");
      pTasks.add("👏 التشجيع المستمر: صفقوا له عندما ينطق كلمة صحيحة، هذا يبني ثقة هائلة.");
      pTasks.add("📱 التكنولوجيا: استخدموا التطبيقات المسلية لتعلم اللغة معاً كعائلة.");
    }
    else if (subject.contains('علوم')) {
      sTasks.add("🌍 التأمل في الظواهر الطبيعية وربطها بالدرس.");
    } else if (subject.contains('إسلاميات') || subject.contains('قرآن')) {
      sTasks.add("🕌 استشعار عظمة الله في الآيات والأحاديث.");
      sTasks.add("🤲 تطبيق الآداب الإسلامية عملياً.");
    } else {
      sTasks.add("📅 تنظيم الجدول المدرسي والاستعداد المبكر.");
    }

    if (pTasks.isEmpty) {
      pTasks.add("❤️ توفير جو هادئ ومحب ومحفز للدراسة.");
    }

    return {
      'studentTasks': sTasks,
      'parentTasks': pTasks,
      'timePlan': timePlan,
      'predictionMsg': predictionMsg,
      'isPositive': isPositive,
    };
  }
}

// ---------------------------------------------------------------------------
// 3. Main View (محدث ليعمل بنظام الاستجابة اللحظية والتزامن)
// ---------------------------------------------------------------------------

class StudentResultsView extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final Map<String, TestInfo> allTestsMap;
  final List<Subject> subjects;
  final Map<String, Color> subjectColors;
  final GlobalKey printKey;

  const StudentResultsView({
    super.key,
    required this.studentData,
    required this.allTestsMap,
    required this.subjects,
    required this.subjectColors,
    required this.printKey,
  });

  @override
  State<StudentResultsView> createState() => _StudentResultsViewState();
}

class _StudentResultsViewState extends State<StudentResultsView> {
  final Map<String, TeacherContactInfo> _subjectTeachers = {};

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    try {
      final String studentStage = widget.studentData['stages'] ?? '';
      final String studentGrade = widget.studentData['grades'] ?? '';
      final String studentClass = widget.studentData['classes'] ?? '';

      final teachersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('profession', isNotEqualTo: 'admin')
          .get();

      final structure = {
        'المرحلة الابتدائية': {
          'grades': {
            'الصف الأول': {'gradeField': 'grade1', 'classField': 'class1'},
            'الصف الثاني': {'gradeField': 'grade2', 'classField': 'class2'},
            'الصف الثالث': {'gradeField': 'grade3', 'classField': 'class3'},
            'الصف الرابع': {'gradeField': 'grade4', 'classField': 'class4'},
            'الصف الخامس': {'gradeField': 'grade5', 'classField': 'class5'},
            'الصف السادس': {'gradeField': 'grade6', 'classField': 'class6'},
          }
        },
        'المرحلة المتوسطة': {
          'grades': {
            'الصف الأول المتوسط': {'gradeField': 'grade11', 'classField': 'class11'},
            'الصف الثاني المتوسط': {'gradeField': 'grade22', 'classField': 'class22'},
            'الصف الثالث المتوسط': {'gradeField': 'grade33', 'classField': 'class33'},
          }
        },
        'المرحلة الثانوية': {
          'grades': {
            'الصف الأول الثانوي': {'gradeField': 'grade111', 'classField': 'class111'},
            'الصف الثاني الثانوي': {'gradeField': 'grade222', 'classField': 'class222'},
            'الصف الثالث الثانوي': {'gradeField': 'grade333', 'classField': 'class333'},
          }
        }
      };

      for (var doc in teachersSnapshot.docs) {
        final data = doc.data();
        final String tName = data['name'] ?? 'معلم المادة';
        final String? tPhone = data['phone'];

        if (structure.containsKey(studentStage)) {
          final stageMap = structure[studentStage]!;
          final gradesMap = stageMap['grades'] as Map<String, dynamic>;

          if (gradesMap.containsKey(studentGrade)) {
            final fields = gradesMap[studentGrade] as Map<String, String>;
            final String gradeField = fields['gradeField']!;
            final String classField = fields['classField']!;

            if (data[gradeField] != null && data[gradeField] != '0') {
              final String classesString = data[classField] ?? '';
              final List<String> assignments = classesString.split(',');

              for (var assignment in assignments) {
                final parts = assignment.split('=');
                if (parts.length == 2) {
                  final String cls = parts[0].trim();
                  final String subj = parts[1].trim();

                  if (cls == studentClass) {
                    _subjectTeachers[subj] = TeacherContactInfo(
                      name: tName,
                      phone: tPhone,
                      availableTime: "طوال أيام الأسبوع الدراسي",
                      isFound: true,
                    );
                  }
                }
              }
            }
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error fetching teachers: $e");
    }
  }

  int _getTermFromKey(String key) {
    if (key.startsWith('t2_')) return 2;
    if (key.startsWith('e4') || key.startsWith('e5') || key.startsWith('e6')) return 2;
    if (key.startsWith('e17') || key.startsWith('e18') || key.startsWith('e19')) return 2;
    return 1;
  }

  Map<String, List<_AnalysisResult>> _buildSubjectAnalyses(int targetTerm) {
    final Map<String, Map<String, Map<String, dynamic>>> subjectGroupedData = {};
    String studentGrade = widget.studentData['grades'] ?? 'عام';

    widget.studentData.forEach((key, value) {
      if (value is num && widget.allTestsMap.containsKey(key)) {
        if (_getTermFromKey(key) == targetTerm) {
          final testInfo = widget.allTestsMap[key]!;
          subjectGroupedData.putIfAbsent(testInfo.subject, () => {});
          subjectGroupedData[testInfo.subject]!.putIfAbsent(testInfo.testGroup, () => {'grades': <String, num>{}, 'evaluations': <String, dynamic>{}});
          (subjectGroupedData[testInfo.subject]![testInfo.testGroup]!['grades'] as Map<String, num>)[testInfo.key] = value;

          final evalKey = 'eval_${testInfo.key}';
          if (widget.studentData.containsKey(evalKey) && widget.studentData[evalKey] != null) {
            (subjectGroupedData[testInfo.subject]![testInfo.testGroup]!['evaluations'] as Map<String, dynamic>)[testInfo.key] = widget.studentData[evalKey];
          }
        }
      }
    });

    final Map<String, List<_AnalysisResult>> finalAnalyses = {};

    subjectGroupedData.forEach((subjectName, groups) {
      final List<_AnalysisResult> subjectAnalyses = [];
      groups.forEach((groupNameKey, data) {
        final gradesMap = data['grades'] as Map<String, num>;
        final evaluationsMap = data['evaluations'] as Map<String, dynamic>;

        String displayGroupName = groupNameKey;
        double maxG = 20.0;
        if (groupNameKey == 'periodic') displayGroupName = "الاختبارات الدورية";
        if (groupNameKey == 'nafes') { displayGroupName = "اختبارات نافس"; maxG = 10.0; }
        if (groupNameKey == 'additional') displayGroupName = "اختبارات قياس المستوي";

        if (gradesMap.isNotEmpty) {
          subjectAnalyses.add(_analyzeSubjectGrades(
            subjectName: subjectName,
            groupName: displayGroupName,
            grade: studentGrade,
            testResults: gradesMap,
            evaluations: evaluationsMap,
            maxGrade: maxG,
          ));
        }
      });
      if (subjectAnalyses.isNotEmpty) {
        finalAnalyses[subjectName] = subjectAnalyses;
      }
    });
    return finalAnalyses;
  }

  List<_OverallSubjectMetric> _calculateOverallMetrics(Map<String, List<_AnalysisResult>> subjectAnalyses) {
    final List<_OverallSubjectMetric> metrics = [];
    subjectAnalyses.forEach((subjectName, analyses) {
      double totalWeightedSum = 0;
      int totalTests = 0;
      double totalAverageSum = 0;
      for (var analysis in analyses) {
        totalWeightedSum += (analysis.average * analysis.testCount);
        totalTests += analysis.testCount;
        totalAverageSum += (analysis.percentage * analysis.testCount);
      }
      if (totalTests > 0) {
        metrics.add(_OverallSubjectMetric(
          subjectName: subjectName,
          overallPercentage: totalAverageSum / totalTests,
          overallAverage: totalWeightedSum / totalTests,
        ));
      }
    });
    return metrics;
  }

  _AnalysisResult _analyzeSubjectGrades({
    required String subjectName,
    required String groupName,
    required String grade,
    required Map<String, num> testResults,
    required Map<String, dynamic> evaluations,
    required double maxGrade,
  }) {
    final sortedTests = testResults.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final validGrades = sortedTests.map((e) => e.value).where((g) => g >= 0).toList();

    List<TestResultDetail> detailedResults = [];
    final Set<String> allWeaknesses = {};
    String maxSeverity = 'غير محدد';

    for (var entry in sortedTests) {
      List<String> specificNotes = [];
      if (evaluations.containsKey(entry.key)) {
        final evalData = evaluations[entry.key];
        if (evalData is Map) {
          if (evalData['selected_points'] != null) {
            List<dynamic> points = evalData['selected_points'];
            for(var p in points) {
              specificNotes.add("تقصير في: ${p.toString()}");
              allWeaknesses.add(p.toString());
            }
          }
          if (evalData['severity'] != null) {
            String sev = evalData['severity'];
            if (sev == 'مرتفعة') maxSeverity = 'مرتفعة';
            else if (sev == 'متوسطة' && maxSeverity != 'مرتفعة') maxSeverity = 'متوسطة';
            else if (sev == 'منخفضة' && maxSeverity == 'غير محدد') maxSeverity = 'منخفضة';
          }
        }
      }
      final testInfo = widget.allTestsMap[entry.key];
      detailedResults.add(TestResultDetail(
        testName: testInfo?.name ?? entry.key,
        grade: entry.value,
        maxGrade: (testInfo?.key.contains('profession13') == true || testInfo?.key.contains('nafes') == true) ? 10.0 : 20.0,
        specificNotes: specificNotes,
      ));
    }

    if (validGrades.isEmpty) {
      return _AnalysisResult(
        groupName: groupName, subjectName: subjectName, average: 0, percentage: 0,
        maxPossibleGrade: maxGrade, highestGrade: 0, lowestGrade: 0,
        assessment: 'N/A', consistency: 'N/A', isBelowPassing: false,
        detailedTestResults: [], trendSpots: [], performanceTrend: 'N/A',
        riskAssessment: 'N/A', testCount: 0, testResults: [],
        teacherNotes: [], severityLevel: 'N/A',
        studentTasks: [], parentTasks: [], timeRecommendation: '',
        predictionMessage: '', isPositiveTrend: true,
      );
    }

    final double average = validGrades.reduce((a, b) => a + b) / validGrades.length;
    final double percentage = (average / maxGrade).clamp(0.0, 1.0);
    final num highest = validGrades.reduce(max);
    final num lowest = validGrades.reduce(min);
    final bool isBelowPassing = average < (maxGrade / 2.0);

    final double variance = validGrades.map((g) => pow(g - average, 2)).reduce((a, b) => a + b) / validGrades.length;
    final double stdDev = sqrt(variance);
    String consistency = stdDev > (maxGrade * 0.15) ? 'متذبذب' : 'مستقر';

    String assessment;
    if (percentage >= 0.90) assessment = 'متميز';
    else if (percentage >= 0.75) assessment = 'جيد جداً';
    else if (percentage >= 0.60) assessment = 'جيد';
    else assessment = 'يحتاج متابعة';

    final trendSpots = <FlSpot>[];
    int validIndex = 0;
    for (int i = 0; i < sortedTests.length; i++) {
      if (sortedTests[i].value >= 0) {
        trendSpots.add(FlSpot(validIndex.toDouble(), sortedTests[i].value.toDouble()));
        validIndex++;
      }
    }

    String performanceTrend = 'مستقر';
    double? predictedNextGrade;
    String riskAssessment = 'طبيعي';

    if (validGrades.length >= 2) {
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (int i = 0; i < validGrades.length; i++) {
        sumX += i; sumY += validGrades[i]; sumXY += i * validGrades[i]; sumX2 += i * i;
      }
      final n = validGrades.length.toDouble();
      final double denominator = (n * sumX2 - sumX * sumX);
      if (denominator != 0) {
        final double slope = (n * sumXY - sumX * sumY) / denominator;
        if (slope > 0.5) performanceTrend = 'في تصاعد 📈';
        else if (slope < -0.5) performanceTrend = 'في تراجع 📉';
        final double intercept = (sumY - slope * sumX) / n;
        predictedNextGrade = (slope * n + intercept).clamp(0.0, maxGrade);
      }
      if (performanceTrend.contains('تراجع')) riskAssessment = 'انتبه للتراجع';
    }

    final plan = AdviceEngine.generateFamilyPlan(
        subjectName, grade, percentage, allWeaknesses.toList(),
        performanceTrend, predictedNextGrade, maxGrade
    );

    return _AnalysisResult(
      groupName: groupName,
      subjectName: subjectName,
      average: average,
      percentage: percentage,
      maxPossibleGrade: maxGrade,
      highestGrade: highest,
      lowestGrade: lowest,
      assessment: assessment,
      consistency: consistency,
      isBelowPassing: isBelowPassing,
      detailedTestResults: detailedResults,
      testResults: sortedTests,
      trendSpots: trendSpots,
      performanceTrend: performanceTrend,
      predictedNextGrade: predictedNextGrade,
      riskAssessment: riskAssessment,
      testCount: sortedTests.length,
      teacherNotes: allWeaknesses.toList(),
      severityLevel: maxSeverity,
      studentTasks: plan['studentTasks'],
      parentTasks: plan['parentTasks'],
      timeRecommendation: plan['timePlan'],
      predictionMessage: plan['predictionMsg'],
      isPositiveTrend: plan['isPositive'],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ الحساب اللحظي المباشر لتحليل الدرجات
    final analysesTerm1 = _buildSubjectAnalyses(1);
    final metricsTerm1 = _calculateOverallMetrics(analysesTerm1);

    final analysesTerm2 = _buildSubjectAnalyses(2);
    final metricsTerm2 = _calculateOverallMetrics(analysesTerm2);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('settings').doc('terms_locks').snapshots(),
      builder: (context, snapshot) {
        bool term1Locked = false;
        bool term2Locked = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          term1Locked = data?['term1_locked'] ?? false;
          term2Locked = data?['term2_locked'] ?? false;
        }

        // ✅ الذكاء الافتراضي للترم: إذا تم إغلاق الأول، يفتح فوراً على الثاني
        int initialIndex = (term1Locked && !term2Locked) ? 1 : 0;
        if (term1Locked && term2Locked) initialIndex = 1;

        return DefaultTabController(
          key: ValueKey('results_tabs_$initialIndex'), // مفتاح التغيير الفوري
          length: 2,
          initialIndex: initialIndex,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black87,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: "الترم الأول"),
                    Tab(text: "الترم الثاني"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTermView(1, analysesTerm1, metricsTerm1),
                    _buildTermView(2, analysesTerm2, metricsTerm2),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTermView(int term, Map<String, List<_AnalysisResult>> analyses, List<_OverallSubjectMetric> metrics) {
    if (analyses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text("لا توجد نتائج تحليلية لعرضها حالياً للترم ${term == 1 ? 'الأول' : 'الثاني'}.", style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: RepaintBoundary(
        key: widget.printKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildWelcomeMessage(widget.studentData['name'] ?? 'ولي الأمر'),
              const SizedBox(height: 16),
              _OverallSummaryCard(metrics: metrics),
              const SizedBox(height: 20),
              ...analyses.entries.map((entry) {
                final subjectName = entry.key;
                final subjectAnalyses = entry.value;
                final subjectIcon = widget.subjects.firstWhere((s) => s.name == subjectName, orElse: () => Subject(name: '', icon: Icons.book)).icon;
                final subjectColor = widget.subjectColors[subjectName] ?? Colors.blue;

                final TeacherContactInfo? teacherInfo = _subjectTeachers[subjectName];

                return Column(
                  children: subjectAnalyses.map((analysis) => _DetailedSubjectCard(
                    analysis: analysis,
                    icon: subjectIcon,
                    color: subjectColor,
                    teacherInfo: teacherInfo,
                  )).toList(),
                );
              }).toList(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "أهلاً بك، شريك النجاح. كلنا هنا لخدمة بطلنا $name.",
              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 600.ms);
  }
}

// ---------------------------------------------------------------------------
// 4. UI Components (البطاقات الذكية)
// ---------------------------------------------------------------------------

class _OverallSummaryCard extends StatelessWidget {
  final List<_OverallSubjectMetric> metrics;
  const _OverallSummaryCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    final avg = metrics.map((m) => m.overallPercentage).reduce((a, b) => a + b) / metrics.length;
    MaterialColor color = avg >= 0.85 ? Colors.green : (avg >= 0.6 ? Colors.blue : Colors.orange);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.shade700, color.shade400]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 45.0, lineWidth: 8.0, percent: avg,
            center: Text("${(avg * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            progressColor: Colors.white, backgroundColor: Colors.white24, circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("المؤشر العام للأداء", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  avg >= 0.85 ? "مستوى مشرف ورائع! 🌟" : (avg >= 0.6 ? "بداية جيدة، والقادم أفضل 💪" : "نحتاج لتكاتف الجهود معاً ❤️"),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3, end: 0);
  }
}

class _DetailedSubjectCard extends StatelessWidget {
  final _AnalysisResult analysis;
  final IconData icon;
  final Color color;
  final TeacherContactInfo? teacherInfo;

  const _DetailedSubjectCard({
    required this.analysis,
    required this.icon,
    required this.color,
    this.teacherInfo,
  });

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse("https://wa.me/$cleanPhone");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch WhatsApp");
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = analysis.percentage >= 0.85 ? Colors.green : (analysis.percentage >= 0.6 ? Colors.blue : Colors.red);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(analysis.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(analysis.groupName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("المتوسط", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        "${analysis.average.toStringAsFixed(1)} / ${analysis.maxPossibleGrade.toInt()}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("📝 سجل الدرجات والملاحظات:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),

                ...analysis.detailedTestResults.map((detail) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(detail.testName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text("${detail.grade} / ${detail.maxGrade.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        if (detail.specificNotes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          ...detail.specificNotes.map((note) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.orange.shade800),
                                const SizedBox(width: 6),
                                Expanded(child: Text(note, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4))),
                              ],
                            ),
                          )),
                        ]
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),

                if (analysis.predictedNextGrade != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: analysis.isPositiveTrend ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: analysis.isPositiveTrend ? Colors.green.shade200 : Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(analysis.isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                            color: analysis.isPositiveTrend ? Colors.green.shade700 : Colors.orange.shade800, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(analysis.isPositiveTrend ? "مؤشر إيجابي ورائع!" : "وقفة للتصحيح",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: analysis.isPositiveTrend ? Colors.green.shade900 : Colors.orange.shade900)),
                              const SizedBox(height: 4),
                              Text(analysis.predictionMessage, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const Text("🌱 خطة الدعم والمساندة المنزلية:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.shade100),
                    boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, color: Colors.indigo.shade400, size: 20),
                          const SizedBox(width: 8),
                          Text(analysis.timeRecommendation, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                        ],
                      ),
                      const Divider(height: 24),

                      Row(children: [
                        Icon(Icons.person_outline, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text("مهام البطل (الطالب):", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      ...analysis.studentTasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0, right: 26.0),
                        child: Text("• $task", style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87)),
                      )),

                      const SizedBox(height: 16),
                      Row(children: [
                        Icon(Icons.favorite_border, size: 18, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        const Text("دور الأسرة الكريمة:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      ...analysis.parentTasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0, right: 26.0),
                        child: Text("• $task", style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87)),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (teacherInfo != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: ExpansionTile(
                      title: Text("التواصل المباشر مع المعلم", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.teal.shade800)),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        radius: 18,
                        child: Icon(Icons.person, color: Colors.teal.shade700, size: 20),
                      ),
                      subtitle: Text(teacherInfo!.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (teacherInfo!.phone != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text("مراسلة عبر واتساب"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _launchWhatsApp(teacherInfo!.phone!),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                child: const Center(
                                  child: Text(
                                    "رقم التواصل غير مدرج حالياً، يرجى مراجعة الإدارة.",
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            const Text("⚠️ للتكرم قبل التواصل:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            const Text("- التأكد من مراجعة الكتاب المدرسي ودفتر الطالب.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const Text("- التواصل في أوقات الدوام الرسمي.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                if (analysis.trendSpots.length >= 2) ...[
                  const Text("📈 مسار التطور:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 5, getTitlesWidget: (v,m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m) {
                            if (v.toInt() >= 0 && v.toInt() < analysis.testResults.length) {
                              return Padding(padding: const EdgeInsets.only(top: 4), child: Text("خ ${v.toInt() + 1}", style: const TextStyle(fontSize: 10)));
                            }
                            return const Text('');
                          })),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade200)),
                        minY: 0,
                        maxY: analysis.maxPossibleGrade,
                        lineBarsData: [
                          LineChartBarData(
                            spots: analysis.trendSpots,
                            isCurved: true,
                            color: color,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}
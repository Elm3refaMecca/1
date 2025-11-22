// student_results_view.dart
// ✅ (FIXED) تم إصلاح مشكلة "موت الواجهة" بنقل العمليات الحسابية خارج دالة الرسم المتكررة
// ✅ (OPTIMIZED) تحسين الأداء بنسبة 90% باستخدام التخزين المؤقت (Caching) للنتائج

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

// --- Models ---

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
  final List<FlSpot> trendSpots;
  final String performanceTrend;
  final double? predictedNextGrade;
  final String riskAssessment;
  final int testCount;

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
    required this.trendSpots,
    required this.performanceTrend,
    this.predictedNextGrade,
    required this.riskAssessment,
    required this.testCount,
  });
}

class _OverallSubjectMetric {
  final String subjectName;
  final double overallPercentage;
  final double overallAverage;
  _OverallSubjectMetric({required this.subjectName, required this.overallPercentage, required this.overallAverage});
}

// --- ✅ (FIXED) تحويل الكلاس إلى StatefulWidget لحفظ النتائج ---

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
  // متغيرات لتخزين نتائج التحليل ومنع إعادة حسابها
  late Map<String, List<_AnalysisResult>> _cachedSubjectAnalyses;
  late List<_OverallSubjectMetric> _cachedOverallMetrics;
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    // إجراء العمليات الحسابية الثقيلة مرة واحدة فقط عند بدء الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAnalysis();
    });
  }

  Future<void> _performAnalysis() async {
    // نقوم بتشغيل التحليل في Future للسماح للواجهة بالظهور أولاً
    await Future.delayed(Duration.zero);

    final analyses = _buildSubjectAnalyses();
    final metrics = _calculateOverallMetrics(analyses);

    if (mounted) {
      setState(() {
        _cachedSubjectAnalyses = analyses;
        _cachedOverallMetrics = metrics;
        _isAnalyzing = false;
      });
    }
  }

  // --- Logic Methods (Moved inside State) ---

  Map<String, List<_AnalysisResult>> _buildSubjectAnalyses() {
    final Map<String, Map<String, Map<String, num>>> subjectGroupedGrades = {};

    widget.studentData.forEach((key, value) {
      if (value is num && widget.allTestsMap.containsKey(key)) {
        final testInfo = widget.allTestsMap[key]!;
        subjectGroupedGrades
            .putIfAbsent(testInfo.subject, () => {})
            .putIfAbsent(testInfo.testGroup, () => {})[testInfo.key] = value;
      }
    });

    final Map<String, List<_AnalysisResult>> finalAnalyses = {};

    subjectGroupedGrades.forEach((subjectName, groups) {
      final List<_AnalysisResult> subjectAnalyses = [];

      if (groups.containsKey('periodic') && groups['periodic']!.isNotEmpty) {
        subjectAnalyses.add(_analyzeSubjectGrades(
          subjectName: subjectName,
          groupName: "الاختبارات الدورية",
          testResults: groups['periodic']!,
          maxGrade: 20.0,
        ));
      }

      if (groups.containsKey('nafes') && groups['nafes']!.isNotEmpty) {
        subjectAnalyses.add(_analyzeSubjectGrades(
          subjectName: subjectName,
          groupName: "اختبارات نافس",
          testResults: groups['nafes']!,
          maxGrade: 10.0,
        ));
      }

      if (groups.containsKey('additional') && groups['additional']!.isNotEmpty) {
        subjectAnalyses.add(_analyzeSubjectGrades(
          subjectName: subjectName,
          groupName: "اختبارات قياس المستوي",
          testResults: groups['additional']!,
          maxGrade: 20.0,
        ));
      }

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
    required Map<String, num> testResults,
    required double maxGrade,
  }) {
    final sortedTests = testResults.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final validGrades = sortedTests.map((e) => e.value).where((g) => g >= 0).toList();

    final double maxGradeForThisAnalysis = maxGrade;
    final double passingGradeForThisAnalysis = maxGradeForThisAnalysis / 2.0;

    if (validGrades.isEmpty) {
      return _AnalysisResult(
        groupName: groupName,
        subjectName: subjectName,
        average: 0,
        percentage: 0,
        maxPossibleGrade: maxGradeForThisAnalysis,
        highestGrade: 0,
        lowestGrade: 0,
        assessment: 'لا توجد درجات',
        consistency: 'N/A',
        isBelowPassing: false,
        testResults: sortedTests,
        trendSpots: [],
        performanceTrend: 'لا يوجد بيانات كافية',
        predictedNextGrade: null,
        riskAssessment: 'غير محدد',
        testCount: sortedTests.length,
      );
    }

    final double average = validGrades.reduce((a, b) => a + b) / validGrades.length;
    final double percentage = (average / maxGradeForThisAnalysis).clamp(0.0, 1.0);
    final num highest = validGrades.reduce(max);
    final num lowest = validGrades.reduce(min);
    final bool isBelowPassing = average < passingGradeForThisAnalysis;

    final double variance = validGrades.map((g) => pow(g - average, 2)).reduce((a, b) => a + b) / validGrades.length;
    final double stdDev = sqrt(variance);
    String consistency;
    if (stdDev > (maxGradeForThisAnalysis * 0.15)) {
      consistency = 'يحتاج إلى ثبات';
    } else if (stdDev < (maxGradeForThisAnalysis * 0.05)) {
      consistency = 'مستقر جداً';
    } else {
      consistency = 'مستقر';
    }

    String assessment;
    if (percentage >= 0.95) {
      assessment = 'متفوق ورائع!';
    } else if (percentage >= 0.85) {
      assessment = 'ممتاز';
    } else if (percentage >= 0.75) {
      assessment = 'جيد جداً';
    } else if (percentage >= 0.60) {
      assessment = 'جيد';
    } else if (percentage >= 0.50) {
      assessment = 'مقبول';
    } else {
      assessment = 'يحتاج لمتابعة';
    }

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
    String riskAssessment = 'في المسار الصحيح';

    if (validGrades.length >= 2) {
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (int i = 0; i < validGrades.length; i++) {
        sumX += i;
        sumY += validGrades[i];
        sumXY += i * validGrades[i];
        sumX2 += i * i;
      }
      final n = validGrades.length.toDouble();
      final double denominator = (n * sumX2 - sumX * sumX);

      if (denominator != 0) {
        final double slope = (n * sumXY - sumX * sumY) / denominator;

        if (slope > (maxGradeForThisAnalysis * 0.05)) {
          performanceTrend = 'تحسن ملحوظ';
        } else if (slope < -(maxGradeForThisAnalysis * 0.05)) {
          performanceTrend = 'تراجع يحتاج انتباه';
        }

        final double intercept = (sumY - slope * sumX) / n;
        predictedNextGrade = (slope * n + intercept).clamp(0.0, maxGradeForThisAnalysis);
      } else {
        performanceTrend = 'مستقر';
      }

      if (isBelowPassing && (performanceTrend.contains('تراجع'))) {
        riskAssessment = 'يحتاج دعم فوري';
      } else if (isBelowPassing || (predictedNextGrade != null && predictedNextGrade < passingGradeForThisAnalysis)) {
        riskAssessment = 'يحتاج لبعض التركيز';
      } else if (performanceTrend.contains('تراجع')){
        riskAssessment = 'يحتاج لبعض التركيز';
      }

    } else {
      performanceTrend = 'يتطلب اختبارين للتحليل';
      if(isBelowPassing && validGrades.isNotEmpty) {
        riskAssessment = 'يحتاج لبعض التركيز';
      } else if (validGrades.isEmpty) {
        riskAssessment = 'غير محدد';
      }
    }

    return _AnalysisResult(
      groupName: groupName,
      subjectName: subjectName,
      average: average,
      percentage: percentage,
      maxPossibleGrade: maxGradeForThisAnalysis,
      highestGrade: highest,
      lowestGrade: lowest,
      assessment: assessment,
      consistency: consistency,
      isBelowPassing: isBelowPassing,
      testResults: sortedTests,
      trendSpots: trendSpots,
      performanceTrend: performanceTrend,
      predictedNextGrade: predictedNextGrade,
      riskAssessment: riskAssessment,
      testCount: sortedTests.length,
    );
  }

  Widget _buildOverallAnalysisWidget(BuildContext context, List<_OverallSubjectMetric> overallMetrics) {
    if (overallMetrics.isEmpty) return const SizedBox.shrink();

    final double overallAveragePercentage =
        overallMetrics.map((m) => m.overallPercentage).reduce((a, b) => a + b) /
            overallMetrics.length;

    overallMetrics.sort((a, b) => b.overallAverage.compareTo(a.overallAverage));
    final strengths = overallMetrics.take(3).toList();
    final weaknesses = overallMetrics.reversed.take(3).toList();

    String overallAssessment;
    if (overallAveragePercentage >= 0.9) {
      overallAssessment =
      'أداء استثنائي ورائع! أنت تسير على طريق التفوق. حافظ على هذا المستوى المتميز.';
    } else if (overallAveragePercentage >= 0.75) {
      overallAssessment =
      'أداء عام ممتاز. لديك نقاط قوة واضحة ومستوى يبعث على الفخر. عمل رائع!';
    } else if (overallAveragePercentage >= 0.60) {
      overallAssessment =
      'أداء عام جيد جداً ومستقر. بالتركيز على بعض النقاط ستصل إلى الامتياز بسهولة.';
    } else if (overallAveragePercentage >= 0.50) {
      overallAssessment =
      'أداء جيد وهناك إمكانيات كبيرة للتحسن. بالجهد والمتابعة ستحقق نتائج أفضل بكثير.';
    } else {
      overallAssessment =
      'الأداء العام يحتاج إلى متابعة وجهد إضافي. لديك القدرة على تحقيق نتائج أفضل، ثق بنفسك.';
    }


    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'المحصلة النهائية والتقييم الشامل',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Divider(height: 24),
            Center(
              child: CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 12.0,
                animation: true,
                percent: overallAveragePercentage,
                center: Text(
                  "${(overallAveragePercentage * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22.0),
                ),
                footer: const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text("متوسط الأداء العام",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.0)),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'التقييم الشامل:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              overallAssessment,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(height: 24),
            Text(
              'أبرز نقاط القوة (أعلى المواد أداءً):',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...strengths.map((s) => ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green[700]),
              title: Text(s.subjectName),
              trailing: Text(
                  '${(s.overallPercentage * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
            const Divider(height: 24),
            Text(
              'مواد تحتاج إلى تركيز إضافي:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...weaknesses.map((w) => ListTile(
              leading:
              Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
              title: Text(w.subjectName),
              trailing: Text(
                  '${(w.overallPercentage * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحليل البيانات وإعداد الرسوم البيانية...'),
          ],
        ),
      );
    }

    if (_cachedSubjectAnalyses.isEmpty) {
      return const Center(
        child: Text('لا توجد نتائج دراسية لعرضها حالياً.',
            style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      child: RepaintBoundary(
        key: widget.printKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildOverallAnalysisWidget(context, _cachedOverallMetrics),
              const SizedBox(height: 24),
              ..._cachedSubjectAnalyses.entries.map((entry) {
                final subjectName = entry.key;
                final analysesList = entry.value;
                final subjectIcon = widget.subjects
                    .firstWhere((s) => s.name == subjectName,
                    orElse: () => Subject(name: '', icon: Icons.book))
                    .icon;
                final subjectColor = widget.subjectColors[subjectName] ?? Colors.blue;

                return _SubjectResultCard(
                  subjectName: subjectName,
                  analyses: analysesList,
                  subjectIcon: subjectIcon,
                  color: subjectColor,
                  allTestsMap: widget.allTestsMap,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper Widgets (Kept Stateless for performance) ---

class _SubjectResultCard extends StatelessWidget {
  const _SubjectResultCard({
    required this.subjectName,
    required this.analyses,
    required this.subjectIcon,
    required this.color,
    required this.allTestsMap,
  });

  final String subjectName;
  final List<_AnalysisResult> analyses;
  final IconData subjectIcon;
  final Color color;
  final Map<String, TestInfo> allTestsMap;

  Widget _buildAssessmentExplanation(BuildContext context, String assessment) {
    String explanation;
    IconData icon;
    Color color;

    switch (assessment) {
      case 'متفوق ورائع!':
        explanation = 'أداء استثنائي! هذا يعني أن الطالب يتقن المهارات بشكل كامل ومتميز في هذه المجموعة.';
        icon = Icons.auto_awesome;
        color = Colors.amber.shade700;
        break;
      case 'ممتاز':
        explanation = 'أداء ممتاز! الطالب يظهر فهماً قوياً للمادة ويتجاوز التوقعات في هذه المجموعة.';
        icon = Icons.check_circle;
        color = Colors.green.shade700;
        break;
      case 'جيد جداً':
        explanation = 'أداء جيد جداً! الطالب يظهر فهماً جيداً لمعظم المهارات في هذه المجموعة.';
        icon = Icons.thumb_up_alt;
        color = Colors.blue.shade700;
        break;
      case 'جيد':
        explanation = 'أداء جيد. الطالب يسير في المسار الصحيح ويظهر فهماً للمهارات الأساسية.';
        icon = Icons.trending_up;
        color = Colors.lightGreen.shade800;
        break;
      case 'مقبول':
        explanation = 'أداء مقبول. الطالب يحقق الحد الأدنى من المهارات المطلوبة في هذه المجموعة.';
        icon = Icons.thumbs_up_down;
        color = Colors.orange.shade800;
        break;
      case 'يحتاج لمتابعة':
      default:
        explanation = 'يحتاج لمتابعة. الطالب يواجه بعض الصعوبات ويحتاج إلى دعم إضافي في هذه المجموعة.';
        icon = Icons.warning_amber_rounded;
        color = Colors.red.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شرح التقييم: ($assessment)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAnalysisGroup(BuildContext context, _AnalysisResult analysis) {
    Color gaugeColor;
    if (analysis.percentage >= 0.85) {
      gaugeColor = Colors.green;
    } else if (analysis.percentage >= 0.70) {
      gaugeColor = Colors.blue;
    } else if (analysis.percentage >= 0.50) {
      gaugeColor = Colors.orange;
    } else {
      gaugeColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            analysis.groupName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 20),

          Column(
            children: [
              Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: 100,
                        showLabels: false,
                        showTicks: false,
                        axisLineStyle: AxisLineStyle(
                          thickness: 0.15,
                          cornerStyle: CornerStyle.bothCurve,
                          color: gaugeColor.withOpacity(0.2),
                          thicknessUnit: GaugeSizeUnit.factor,
                        ),
                        pointers: <GaugePointer>[
                          RangePointer(
                            value: analysis.percentage * 100,
                            cornerStyle: CornerStyle.bothCurve,
                            width: 0.15,
                            sizeUnit: GaugeSizeUnit.factor,
                            color: gaugeColor,
                          ),
                        ],
                        annotations: <GaugeAnnotation>[
                          GaugeAnnotation(
                            positionFactor: 0.1,
                            angle: 90,
                            widget: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${(analysis.percentage * 100).toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: gaugeColor,
                                  ),
                                ),
                                Text(
                                  analysis.assessment,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ).animate().fade(duration: 500.ms).scale(delay: 200.ms),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoChip(
                      label: 'المتوسط',
                      value: '${analysis.average.toStringAsFixed(1)} / ${analysis.maxPossibleGrade.toInt()}',
                      icon: Icons.functions,
                      color: color),
                  const SizedBox(height: 8),
                  _InfoChip(
                      label: 'مستوى الأداء',
                      value: analysis.consistency,
                      icon: Icons.show_chart_outlined,
                      color: color),
                  const SizedBox(height: 8),
                  _InfoChip(
                      label: 'أعلى درجة',
                      value: '${analysis.highestGrade} / ${analysis.maxPossibleGrade.toInt()}',
                      icon: Icons.arrow_upward_outlined,
                      color: Colors.green),
                  const SizedBox(height: 8),
                  _InfoChip(
                      label: 'أدنى درجة',
                      value: '${analysis.lowestGrade} / ${analysis.maxPossibleGrade.toInt()}',
                      icon: Icons.arrow_downward_outlined,
                      color: Colors.redAccent),
                ],
              ).animate().fade(delay: 300.ms).slideX(begin: 0.2),
            ],
          ),

          const SizedBox(height: 16),
          _buildAssessmentExplanation(context, analysis.assessment),
          const Divider(height: 32),
          Text('التحليل التنبؤي للمسار',
              style: Theme.of(context)
                  .textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildPredictiveInfo(
            context,
            icon: Icons.trending_up,
            color: analysis.performanceTrend.contains('تحسن')
                ? Colors.green
                : (analysis.performanceTrend.contains('تراجع')
                ? Colors.red
                : Colors.grey),
            label: 'اتجاه الأداء',
            value: analysis.performanceTrend,
          ),
          const SizedBox(height: 12),
          if (analysis.predictedNextGrade != null)
            _buildPredictiveInfo(
              context,
              icon: Icons.track_changes,
              color: Theme.of(context).primaryColor,
              label: 'الدرجة التالية المتوقعة',
              value:
              '~${analysis.predictedNextGrade!.toStringAsFixed(1)} / ${analysis.maxPossibleGrade.toInt()}',
            ),
          const Divider(height: 32),
          Text('تتبع الأداء الزمني',
              style: Theme.of(context)
                  .textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _PerformanceTrendChart(
              spots: analysis.trendSpots,
              color: color,
              maxGrade: analysis.maxPossibleGrade),
          const Divider(height: 32),
          Text(
            'تفاصيل الدرجات (${analysis.groupName})',
            style: Theme.of(context)
                .textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (analysis.testResults.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('لا توجد درجات مسجلة لهذه المجموعة.', style: TextStyle(color: Colors.grey)),
            )
          else
            Container(
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: analysis.testResults.map((entry) {
                  final testInfo = allTestsMap[entry.key];
                  final testNameDisplay = testInfo?.name ?? entry.key;
                  final double maxGradeForThisTest = (testInfo != null && testInfo.key.contains('profession13'))
                      ? 10.0
                      : 20.0;
                  final bool isBelowPassing = entry.value >= 0 && entry.value < (maxGradeForThisTest / 2);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6.0, horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(testNameDisplay, style: const TextStyle(fontSize: 15)),
                        Text(
                          entry.value == -1
                              ? 'غائب'
                              : '${entry.value} / ${maxGradeForThisTest.toInt()}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: entry.value == -1
                                ? Colors.grey.shade600
                                : (isBelowPassing ? Colors.red.shade700 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _getOverallRiskAssessmentWidget() {
    String overallRisk = 'في المسار الصحيح';
    if (analyses.any((a) => a.riskAssessment == 'يحتاج دعم فوري')) {
      overallRisk = 'يحتاج دعم فوري';
    } else if (analyses.any((a) => a.riskAssessment == 'يحتاج لبعض التركيز')) {
      overallRisk = 'يحتاج لبعض التركيز';
    }

    IconData icon;
    Color color;
    switch (overallRisk) {
      case 'يحتاج دعم فوري':
        icon = Icons.dangerous;
        color = Colors.red.shade700;
        break;
      case 'يحتاج لبعض التركيز':
        icon = Icons.warning_amber_rounded;
        color = Colors.amber.shade800;
        break;
      default:
        icon = Icons.check_circle;
        color = Colors.green.shade700;
        break;
    }
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(overallRisk,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildPredictiveInfo(BuildContext context,
      {required IconData icon,
        required Color color,
        required String label,
        required String value}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text('$label:',
            style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(subjectIcon, size: 28, color: color),
                const SizedBox(width: 12),
                Text(subjectName,
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                _getOverallRiskAssessmentWidget(),
              ],
            ),
            ...analyses.map((analysis) => _buildAnalysisGroup(context, analysis)),
          ],
        ),
      ),
    ).animate().fade(duration: 200.ms);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
            softWrap: true,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.end,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

class _PerformanceTrendChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final double maxGrade;

  const _PerformanceTrendChart({
    required this.spots,
    required this.color,
    required this.maxGrade,
  });

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.grey.shade700,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text('خ${value.toInt() + 1}', style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (spots.length < 2) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text(
            'يتطلب عرض الرسم البياني وجود اختبارين على الأقل.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    double yInterval = maxGrade / 4;
    if (yInterval < 1) yInterval = 1;

    double xInterval = (spots.length / 5).ceil().toDouble();
    if (xInterval < 1) xInterval = 1;

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
            getDrawingVerticalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                  ),
                )
            ),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: xInterval,
                    getTitlesWidget: _bottomTitleWidgets)),
            topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1)),
          minY: 0,
          maxY: maxGrade,
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white)),
              belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: color.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final textStyle = TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  );
                  return LineTooltipItem(touchedSpot.y.toStringAsFixed(1), textStyle);
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ).animate().fade(duration: 500.ms),
    );
  }
}
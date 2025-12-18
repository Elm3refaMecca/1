import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class ExcellenceCriterion {
  final String title;
  final double maxPoints;
  double obtainedPoints;

  ExcellenceCriterion({required this.title, required this.maxPoints, this.obtainedPoints = 0.0});

  Map<String, dynamic> toMap() {
    return {'title': title, 'maxPoints': maxPoints, 'obtainedPoints': obtainedPoints};
  }
}

class ExcellenceDomain {
  final String title;
  final double weight; // النسبة المئوية للوزن
  final List<ExcellenceCriterion> criteria;

  ExcellenceDomain({required this.title, required this.weight, required this.criteria});

  double get totalObtained => criteria.fold(0, (sum, item) => sum + item.obtainedPoints);
  double get totalPossible => criteria.fold(0, (sum, item) => sum + item.maxPoints);

  // حساب الدرجة الموزونة لهذا المجال
  double get weightedScore {
    if (totalPossible == 0) return 0;
    return (totalObtained / totalPossible) * weight;
  }
}

// ---------------------------------------------------------------------------
// DATA PROVIDER (المعايير من الملف المرفق)
// ---------------------------------------------------------------------------

List<ExcellenceDomain> getStandardDomains() {
  return [
    ExcellenceDomain(
      title: 'المجال الأول: الكفاءة المهنية والأكاديمية',
      weight: 25,
      criteria: [
        ExcellenceCriterion(title: 'عمق المعرفة بالمحتوى الأكاديمي', maxPoints: 5),
        ExcellenceCriterion(title: 'القدرة على ربط المفاهيم بالتطبيقات الحياتية', maxPoints: 5),
        ExcellenceCriterion(title: 'التحديث المستمر للمعلومات والمعارف', maxPoints: 5),
        ExcellenceCriterion(title: 'الإلمام بالمستجدات في المجال التخصصي', maxPoints: 5),
        ExcellenceCriterion(title: 'استخدام استراتيجيات تدريس متنوعة وفعالة', maxPoints: 5),
        ExcellenceCriterion(title: 'تطبيق التعلم النشط والتفاعلي', maxPoints: 5),
        ExcellenceCriterion(title: 'توظيف التقنية بفاعلية في التدريس', maxPoints: 5),
        ExcellenceCriterion(title: 'التمايز في التعليم وفق احتياجات الطلاب', maxPoints: 5),
      ],
    ),
    ExcellenceDomain(
      title: 'المجال الثاني: التأثير والفاعلية',
      weight: 20,
      criteria: [
        ExcellenceCriterion(title: 'تحسن ملموس في تحصيل الطلاب', maxPoints: 8),
        ExcellenceCriterion(title: 'تطور مهارات التفكير العليا لدى الطلاب', maxPoints: 5),
        ExcellenceCriterion(title: 'تنمية اتجاهات إيجابية نحو المادة', maxPoints: 4),
        ExcellenceCriterion(title: 'خلق بيئة صفية آمنة ومحفزة', maxPoints: 5),
        ExcellenceCriterion(title: 'الإدارة الفعالة للوقت والموارد', maxPoints: 5),
        ExcellenceCriterion(title: 'بناء علاقات إيجابية مع الطلاب', maxPoints: 5),
      ],
    ),
    ExcellenceDomain(
      title: 'المجال الثالث: الإبداع والابتكار',
      weight: 15,
      criteria: [
        ExcellenceCriterion(title: 'تطوير مشاريع أو برامج تعليمية مبتكرة', maxPoints: 8),
        ExcellenceCriterion(title: 'ابتكار وسائل وأدوات تعليمية جديدة', maxPoints: 6),
        ExcellenceCriterion(title: 'إجراء بحوث إجرائية في الصف', maxPoints: 6),
        ExcellenceCriterion(title: 'استخدام تطبيقات ومنصات رقمية متقدمة', maxPoints: 5),
        ExcellenceCriterion(title: 'تصميم محتوى رقمي تفاعلي', maxPoints: 5),
      ],
    ),
    ExcellenceDomain(
      title: 'المجال الرابع: التطوير المهني والقيادة',
      weight: 15,
      criteria: [
        ExcellenceCriterion(title: 'المشاركة في دورات تدريبية متخصصة', maxPoints: 5),
        ExcellenceCriterion(title: 'الحصول على شهادات مهنية إضافية', maxPoints: 5),
        ExcellenceCriterion(title: 'قيادة فرق عمل أو مشاريع تربوية', maxPoints: 6),
        ExcellenceCriterion(title: 'الإرشاد والتوجيه للمعلمين الجدد', maxPoints: 5),
        ExcellenceCriterion(title: 'المشاركة الفاعلة في اللجان المدرسية', maxPoints: 5),
      ],
    ),
    ExcellenceDomain(
      title: 'المجال الخامس: الاحترافية والأخلاقيات',
      weight: 10,
      criteria: [
        ExcellenceCriterion(title: 'الالتزام بأخلاقيات مهنة التعليم', maxPoints: 5),
        ExcellenceCriterion(title: 'النزاهة والعدالة في التعامل', maxPoints: 5),
        ExcellenceCriterion(title: 'الالتزام بالمواعيد والحضور', maxPoints: 4),
        ExcellenceCriterion(title: 'تنفيذ المهام بإتقان ودقة', maxPoints: 4),
        ExcellenceCriterion(title: 'اللياقة في المظهر والهندام', maxPoints: 3),
      ],
    ),
    ExcellenceDomain(
      title: 'المجال السادس: التواصل والشراكة',
      weight: 10,
      criteria: [
        ExcellenceCriterion(title: 'فعالية التواصل المنتظم مع الأسر', maxPoints: 5),
        ExcellenceCriterion(title: 'بناء علاقات إيجابية مع أولياء الأمور', maxPoints: 4),
        ExcellenceCriterion(title: 'التعاون الفعال مع الزملاء', maxPoints: 4),
        ExcellenceCriterion(title: 'مشاركة الخبرات وأفضل الممارسات', maxPoints: 4),
        ExcellenceCriterion(title: 'بناء شراكات مع مؤسسات خارجية', maxPoints: 3),
      ],
    ),
    ExcellenceDomain(
      title: 'المجال السابع: الإنجازات والجوائز',
      weight: 5,
      criteria: [
        ExcellenceCriterion(title: 'الحصول على جوائز محلية أو دولية', maxPoints: 8),
        ExcellenceCriterion(title: 'شهادات تقدير رسمية من جهات معتبرة', maxPoints: 5),
        ExcellenceCriterion(title: 'نشر مواد تعليمية يستفيد منها الآخرون', maxPoints: 5),
        ExcellenceCriterion(title: 'إنجازات طلابية متميزة بإشراف المعلم', maxPoints: 5),
      ],
    ),
  ];
}

// ---------------------------------------------------------------------------
// 1. MAIN HUB (لوحة التحكم الرئيسية للجائزة)
// ---------------------------------------------------------------------------

class ExcellenceHubPage extends StatelessWidget {
  const ExcellenceHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("جائزة المعرفة للتميز"),
        backgroundColor: const Color(0xFF1A237E), // أزرق داكن فخم
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users')
                  .where('profession', isNotEqualTo: 'admin')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا يوجد معلمين مسجلين"));
                }

                final teachers = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final data = teachers[index].data() as Map<String, dynamic>;
                    final teacherId = teachers[index].id;
                    final name = data['name'] ?? 'معلم';
                    final photo = data['photo'];

                    return _buildTeacherCard(context, teacherId, name, photo);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A237E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Image.asset('assets/m4.png', height: 80, color: Colors.white.withOpacity(0.9), errorBuilder: (c,e,s) => const Icon(Icons.verified, size: 80, color: Colors.amber)), // شعار المدرسة
          const SizedBox(height: 16),
          const Text(
            "الدورة الأولى ٢٠٢٦",
            style: TextStyle(color: Colors.amberAccent, fontSize: 14, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          const Text(
            "فئة المعلم المتميز",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(BuildContext context, String id, String name, String? photoUrl) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('excellence_awards')
          .doc('cycle_2026')
          .collection('evaluations')
          .doc(id)
          .snapshots(),
      builder: (context, snapshot) {
        final bool isEvaluated = snapshot.hasData && snapshot.data!.exists;
        final double? totalScore = isEvaluated ? (snapshot.data!.data() as Map<String, dynamic>)['totalScore'] : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              backgroundColor: Colors.grey.shade200,
              child: photoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(isEvaluated ? "تم التقييم" : "بانتظار التقييم",
                style: TextStyle(color: isEvaluated ? Colors.green : Colors.orange, fontSize: 12)),
            trailing: isEvaluated
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(20)),
              child: Text("${totalScore?.toStringAsFixed(1)}%", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
            )
                : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherEvaluationPage(teacherId: id, teacherName: name),
                ),
              );
            },
          ),
        ).animate().fadeIn().slideX();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 2. EVALUATION PAGE (صفحة التقييم التفصيلي)
// ---------------------------------------------------------------------------

class TeacherEvaluationPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherEvaluationPage({super.key, required this.teacherId, required this.teacherName});

  @override
  State<TeacherEvaluationPage> createState() => _TeacherEvaluationPageState();
}

class _TeacherEvaluationPageState extends State<TeacherEvaluationPage> {
  List<ExcellenceDomain> domains = getStandardDomains();
  int _currentStep = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // يمكن هنا تحميل التقييم السابق إذا وجد
  }

  double get _calculateTotalScore {
    double total = 0;
    for (var domain in domains) {
      total += domain.weightedScore;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("تقييم: ${widget.teacherName}"),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              physics: const ScrollPhysics(),
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < domains.length - 1) {
                  setState(() => _currentStep += 1);
                } else {
                  _submitEvaluation();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(_currentStep == domains.length - 1 ? 'اعتماد التقييم' : 'التالي'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('السابق', style: TextStyle(color: Colors.grey)),
                        ),
                    ],
                  ),
                );
              },
              steps: domains.map((domain) {
                return Step(
                  title: Text(domain.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("الوزن: ${domain.weight}%"),
                  isActive: _currentStep == domains.indexOf(domain),
                  state: _currentStep > domains.indexOf(domain) ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: domain.criteria.map((criterion) {
                      return _buildCriterionSlider(criterion);
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("النتيجة الحالية:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${_calculateTotalScore.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: (_calculateTotalScore / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            progressColor: _calculateTotalScore >= 90 ? Colors.amber : Colors.blue,
            barRadius: const Radius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionSlider(ExcellenceCriterion criterion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(criterion.title, style: const TextStyle(fontSize: 14)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: criterion.obtainedPoints,
                    min: 0,
                    max: criterion.maxPoints,
                    divisions: criterion.maxPoints.toInt(),
                    label: criterion.obtainedPoints.round().toString(),
                    activeColor: const Color(0xFF1A237E),
                    onChanged: (val) {
                      setState(() {
                        criterion.obtainedPoints = val;
                      });
                    },
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5)),
                  child: Text("${criterion.obtainedPoints.toInt()}/${criterion.maxPoints.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitEvaluation() async {
    setState(() => _isSaving = true);

    final double finalScore = _calculateTotalScore;
    String classification;
    if (finalScore >= 90) classification = "متميز بامتياز";
    else if (finalScore >= 80) classification = "متميز";
    else if (finalScore >= 70) classification = "جيد جداً";
    else classification = "غير مؤهل للتميز";

    final Map<String, dynamic> evaluationData = {
      'teacherName': widget.teacherName,
      'timestamp': FieldValue.serverTimestamp(),
      'totalScore': finalScore,
      'classification': classification,
      'domains': domains.map((d) => {
        'title': d.title,
        'score': d.weightedScore,
        'details': d.criteria.map((c) => c.toMap()).toList()
      }).toList(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('excellence_awards')
          .doc('cycle_2026')
          .collection('evaluations')
          .doc(widget.teacherId)
          .set(evaluationData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultSummaryPage(
            teacherName: widget.teacherName,
            score: finalScore,
            classification: classification,
          )),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
        setState(() => _isSaving = false);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 3. RESULT PAGE (صفحة النتيجة النهائية)
// ---------------------------------------------------------------------------

class ResultSummaryPage extends StatelessWidget {
  final String teacherName;
  final double score;
  final String classification;

  const ResultSummaryPage({super.key, required this.teacherName, required this.score, required this.classification});

  @override
  Widget build(BuildContext context) {
    Color statusColor = score >= 90 ? Colors.amber : (score >= 80 ? Colors.green : Colors.blueGrey);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified, size: 100, color: Color(0xFF1A237E)).animate().scale(duration: 500.ms),
              const SizedBox(height: 24),
              const Text("تم اعتماد التقييم بنجاح", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  children: [
                    Text(teacherName, style: const TextStyle(fontSize: 18)),
                    const Divider(height: 30),
                    const Text("النتيجة النهائية", style: TextStyle(color: Colors.grey)),
                    Text("${score.toStringAsFixed(1)}%", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: statusColor)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(classification, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text("العودة للقائمة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:js' as js;
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, debugPrint;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'package:almarefamecca/firebase_options.dart';
import 'package:almarefamecca/secondary_pages.dart';
import 'package:almarefamecca/add.dart';
import 'package:almarefamecca/student_view.dart';

// ===========================================================================
// CONSTANTS & ICONS
// ===========================================================================
const String waIconSvgGlobal = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51a12.8 12.8 0 0 0-.57-.01c-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413Z"/></svg>''';
const String _xIconSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 22.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>''';
const String _instaIconSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058 1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>''';
const String _snapIconSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12.08 2c-.17 0-.58.05-1.12.18-.75.19-1.39.49-1.89.88a4.93 4.93 0 00-1.87 3.52c-.04.42-.05 1.13-.02 1.95.03.74.07 1.25.1 1.49l.06.35c-.1.02-.27.05-.49.07-.3.03-.68.04-1.09.02-.27-.01-.58-.04-.89-.11-.29-.07-.51-.17-.61-.31-.05-.08-.07-.18-.04-.32a1.35 1.35 0 01.14-.38l.06-.1c.07-.12.11-.26.11-.42 0-.25-.09-.48-.25-.66a.8.8 0 00-.6-.28c-.28 0-.55.13-.75.36-.2.24-.31.54-.31.86 0 .5.24 1.05.69 1.54.44.47 1 .84 1.63 1.08.52.19 1.14.33 1.83.4.15.02.26.04.3.06.05.03.07.09.07.19v.15c0 .32-.01.59-.03.79l-.02.16c0 .04-.01.07-.01.08 0 .15-.22.42-.64.76-.36.29-.8.56-1.31.78-.49.2-.97.35-1.42.42a1 1 0 00-.73.49c-.14.24-.16.51-.06.77.1.25.32.44.59.5.38.1.84.14 1.35.14 1 0 2.1-.19 3.2-.55.22-.07.41-.12.55-.16.11-.03.18-.04.18-.04.1-.03.22-.05.34-.05.36 0 .7.18.96.53l.02.04c.14.23.36.36.64.36s.5-.13.65-.37l.03-.04c.26-.35.6-.53.95-.53.12 0 .24.02.34.05 0 0 .07.02.17.04.14.04.34.09.56.16 1.08.36 2.18.55 3.17.55.5 0 .96-.04 1.35-.14.27-.06.49-.25.59-.5.1-.26.08-.53-.06-.77a1 1 0 00-.73-.49c-.45-.07-.93-.22-1.41-.42-.51-.22-.95-.49-1.32-.78-.41-.34-.63-.61-.63-.76v-.08l-.02-.16c-.02-.2-.03-.47-.03-.79v-.15c0-.1.02-.16.07-.19.04-.02.15-.04.3-.06.69-.07 1.31-.21 1.83-.4.63-.24 1.19-.61 1.63-1.08.45-.49.69-1.04.69-1.54 0-.32-.11-.62-.31-.86-.2-.23-.47-.36-.75-.36-.26 0-.5.1-.6.28a.98.98 0 00-.25.66c0 .16.04.3.11.42l.06.1c.07.13.12.26.14.38.03.14.01.24-.04.32-.1.14-.32.24-.61.31-.31.07-.62.1-.89.11-.4.02-.79.01-1.09-.02a5.55 5.55 0 01-.49-.07l.06-.35c.03-.24.07-.75.1-1.49.03-.82.02-1.53-.02-1.95a4.93 4.93 0 00-1.87-3.52c-.5-.39-1.14-.69-1.89-.88-.54-.13-.95-.18-1.12-.18z"/></svg>''';
const String _tiktokIconSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12.53.02C13.84 0 15.14.01 16.44 0c.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 2.78-1.15 5.54-3.33 7.37-1.84 1.54-4.29 2.12-6.6 1.71-2.8-.46-5.22-2.31-6.26-4.98-.8-2.07-.63-4.5.47-6.42 1.19-2.06 3.42-3.4 5.76-3.69 2.05-.24 4.19.16 5.86 1.34v4.35c-1.74-.92-3.95-.94-5.63-.09-1.48.75-2.4 2.34-2.31 4.02.07 1.48.91 2.87 2.22 3.55 1.5.78 3.39.63 4.75-.43 1.25-.97 1.94-2.55 1.95-4.13.03-5.2.01-10.41.02-15.61z"/></svg>''';

// ===========================================================================
// MODELS & DATA PROVIDERS
// ===========================================================================

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

class AnalysisResult {
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

  AnalysisResult({
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

class OverallSubjectMetric {
  final String subjectName;
  final double overallPercentage;
  final double overallAverage;
  OverallSubjectMetric({required this.subjectName, required this.overallPercentage, required this.overallAverage});
}

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
  final double weight;
  final List<ExcellenceCriterion> criteria;

  ExcellenceDomain({required this.title, required this.weight, required this.criteria});

  double get totalObtained => criteria.fold(0, (sum, item) => sum + item.obtainedPoints);
  double get totalPossible => criteria.fold(0, (sum, item) => sum + item.maxPoints);

  double get weightedScore {
    if (totalPossible == 0) return 0;
    return (totalObtained / totalPossible) * weight;
  }
}

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
    } else if (subject.contains('نجليزي') || subject.contains('English')) {
      sTasks.add("📺 شاهد مقطع كرتوني قصير بالإنجليزية يومياً (ممتع ومفيد!).");
      sTasks.add("🎮 العب ألعاب تعليمية للغة الإنجليزية لمدة 10 دقائق.");
      sTasks.add("🗣️ حاول تسمية الأشياء حولك باللغة الإنجليزية (كرسي، طاولة..).");

      pTasks.add("🌍 الإنجليزية لغة العالم: ذكروا طفلكم بأنها ستجعله يفهم ألعابه وبرامجه المفضلة.");
      pTasks.add("👏 التشجيع المستمر: صفقوا له عندما ينطق كلمة صحيحة، هذا يبني ثقة هائلة.");
      pTasks.add("📱 التكنولوجيا: استخدموا التطبيقات المسلية لتعلم اللغة معاً كعائلة.");
    } else if (subject.contains('علوم')) {
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

// ===========================================================================
// STUDENT RESULTS VIEW & CARDS
// ===========================================================================

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

  String _selectedYear = 'العام الحالي';
  List<String> _availableYears = ['العام الحالي'];
  Map<String, dynamic> _displayData = {};
  Map<String, Map<String, dynamic>> _archivedDataCache = {};

  @override
  void initState() {
    super.initState();
    _displayData = widget.studentData;
    _fetchTeachers();
    _fetchArchivedYears();
  }

  Future<void> _fetchArchivedYears() async {
    try {
      final uid = widget.studentData['uid'] ?? widget.studentData['id'] ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final archivesSnap = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .collection('archives')
          .get();

      if (archivesSnap.docs.isNotEmpty) {
        final List<String> years = archivesSnap.docs.map((doc) => doc.id).toList();
        years.sort((a, b) => b.compareTo(a));

        for (var doc in archivesSnap.docs) {
          _archivedDataCache[doc.id] = doc.data();
        }

        if (mounted) {
          setState(() {
            _availableYears.addAll(years);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching archives: $e");
    }
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
            'الصف الثالث الثانوي': {'field': 'grade333', 'classField': 'class333'},
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

  Map<String, List<AnalysisResult>> _buildSubjectAnalyses(int targetTerm) {
    final Map<String, Map<String, Map<String, dynamic>>> subjectGroupedData = {};
    String studentGrade = _displayData['grades'] ?? widget.studentData['grades'] ?? 'عام';

    _displayData.forEach((key, value) {
      if (value is num && widget.allTestsMap.containsKey(key)) {
        if (_getTermFromKey(key) == targetTerm) {
          final testInfo = widget.allTestsMap[key]!;
          subjectGroupedData.putIfAbsent(testInfo.subject, () => {});
          subjectGroupedData[testInfo.subject]!.putIfAbsent(testInfo.testGroup, () => {'grades': <String, num>{}, 'evaluations': <String, dynamic>{}});
          (subjectGroupedData[testInfo.subject]![testInfo.testGroup]!['grades'] as Map<String, num>)[testInfo.key] = value;

          final evalKey = 'eval_${testInfo.key}';
          if (_displayData.containsKey(evalKey) && _displayData[evalKey] != null) {
            (subjectGroupedData[testInfo.subject]![testInfo.testGroup]!['evaluations'] as Map<String, dynamic>)[testInfo.key] = _displayData[evalKey];
          }
        }
      }
    });

    final Map<String, List<AnalysisResult>> finalAnalyses = {};

    subjectGroupedData.forEach((subjectName, groups) {
      final List<AnalysisResult> subjectAnalyses = [];
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

  List<OverallSubjectMetric> _calculateOverallMetrics(Map<String, List<AnalysisResult>> subjectAnalyses) {
    final List<OverallSubjectMetric> metrics = [];
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
        metrics.add(OverallSubjectMetric(
          subjectName: subjectName,
          overallPercentage: totalAverageSum / totalTests,
          overallAverage: totalWeightedSum / totalTests,
        ));
      }
    });
    return metrics;
  }

  AnalysisResult _analyzeSubjectGrades({
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
      return AnalysisResult(
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

    return AnalysisResult(
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

  Widget _buildYearSelector() {
    if (_availableYears.length <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          isExpanded: true,
          icon: const Icon(Icons.history, color: Colors.blue),
          items: _availableYears.map((String year) {
            return DropdownMenuItem<String>(
              value: year,
              child: Row(
                children: [
                  Icon(year == 'العام الحالي' ? Icons.calendar_today : Icons.archive,
                      color: year == _selectedYear ? Colors.blue.shade800 : Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    year == 'العام الحالي' ? 'نتائج العام الدراسي الحالي' : 'نتائج العام الدراسي: $year',
                    style: TextStyle(
                      fontWeight: year == 'العام الحالي' ? FontWeight.bold : FontWeight.normal,
                      color: year == _selectedYear ? Colors.blue.shade800 : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedYear) {
              setState(() {
                _selectedYear = newValue;
                if (newValue == 'العام الحالي') {
                  _displayData = widget.studentData;
                } else {
                  _displayData = _archivedDataCache[newValue] ?? {};
                }
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

        int initialIndex = (term1Locked && !term2Locked) ? 1 : 0;
        if (term1Locked && term2Locked) initialIndex = 1;

        return DefaultTabController(
          key: ValueKey('results_tabs_${initialIndex}_$_selectedYear'),
          length: 2,
          initialIndex: initialIndex,
          child: Column(
            children: [
              _buildYearSelector(),
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

  Widget _buildTermView(int term, Map<String, List<AnalysisResult>> analyses, List<OverallSubjectMetric> metrics) {
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
              OverallSummaryCard(metrics: metrics),
              const SizedBox(height: 20),
              ...analyses.entries.map((entry) {
                final subjectName = entry.key;
                final subjectAnalyses = entry.value;
                final subjectIcon = widget.subjects.firstWhere((s) => s.name == subjectName, orElse: () => Subject(name: '', icon: Icons.book)).icon;
                final subjectColor = widget.subjectColors[subjectName] ?? Colors.blue;

                final TeacherContactInfo? teacherInfo = _subjectTeachers[subjectName];

                return Column(
                  children: subjectAnalyses.map((analysis) => DetailedSubjectCard(
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

class OverallSummaryCard extends StatelessWidget {
  final List<OverallSubjectMetric> metrics;
  const OverallSummaryCard({super.key, required this.metrics});

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

class DetailedSubjectCard extends StatelessWidget {
  final AnalysisResult analysis;
  final IconData icon;
  final Color color;
  final TeacherContactInfo? teacherInfo;

  const DetailedSubjectCard({
    super.key,
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

                      Row(children: const [
                        Icon(Icons.person_outline, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text("مهام البطل (الطالب):", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      ...analysis.studentTasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0, right: 26.0),
                        child: Text("• $task", style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87)),
                      )),

                      const SizedBox(height: 16),
                      Row(children: const [
                        Icon(Icons.favorite_border, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text("دور الأسرة الكريمة:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

// ===========================================================================
// TEACHER EXCELLENCE AWARD HUB & PAGES
// ===========================================================================

class ExcellenceHubPage extends StatelessWidget {
  const ExcellenceHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("جائزة المعرفة للتميز"),
        backgroundColor: const Color(0xFF1A237E),
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
          Image.asset('assets/m4.png', height: 80, color: Colors.white.withOpacity(0.9), errorBuilder: (c,e,s) => const Icon(Icons.verified, size: 80, color: Colors.amber)),
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

// ===========================================================================
// GLOBAL HELPERS & BACKGROUND HANDLER
// ===========================================================================

class GlobalRefreshListener extends StatefulWidget {
  final Widget child;
  const GlobalRefreshListener({super.key, required this.child});

  @override
  State<GlobalRefreshListener> createState() => _GlobalRefreshListenerState();
}

class _GlobalRefreshListenerState extends State<GlobalRefreshListener> {
  int? _currentAppVersion;
  StreamSubscription? _versionSubscription;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _versionSubscription = FirebaseFirestore.instance
          .collection('settings')
          .doc('app_state')
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('version')) {
            int serverVersion = data['version'] is int
                ? data['version']
                : int.tryParse(data['version'].toString()) ?? 0;

            if (_currentAppVersion == null) {
              _currentAppVersion = serverVersion;
            } else if (serverVersion > _currentAppVersion!) {
              html.window.location.reload();
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _versionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class QRSessionTimer {
  static Timer? _timer;
  static final ValueNotifier<int> remainingSeconds = ValueNotifier<int>(0);
  static bool isActive = false;

  static void startSession(BuildContext context) {
    isActive = true;
    remainingSeconds.value = 300;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        stopSession();
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('انتهت جلسة السبورة. تم الخروج تلقائياً.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  static void stopSession() {
    _timer?.cancel();
    isActive = false;
    remainingSeconds.value = 0;
  }
}

class QRSessionOverlay extends StatelessWidget {
  final Widget child;
  const QRSessionOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (QRSessionTimer.isActive)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: QRSessionTimer.remainingSeconds,
              builder: (context, seconds, _) {
                if (seconds <= 0) return const SizedBox.shrink();
                final mins = (seconds / 60).floor();
                final secs = seconds % 60;
                final bool isUrgent = seconds < 60;

                return Material(
                  color: isUrgent ? Colors.redAccent.shade700 : Colors.red,
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'جلسة مؤقتة: سيتم الخروج خلال ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () async {
                            QRSessionTimer.stopSession();
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: const Row(
                              children: [
                                Icon(Icons.logout, size: 12, color: Colors.red),
                                SizedBox(width: 4),
                                Text('خروج', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class GlobalScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class ExitPopupWrapper extends StatelessWidget {
  final Widget child;
  const ExitPopupWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (QRSessionTimer.isActive) {
          QRSessionTimer.stopSession();
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
          return;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.power_settings_new, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text('تنبيه الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text('هل تريد فعلاً الخروج من التطبيق؟', style: TextStyle(fontSize: 16)),
            actionsPadding: const EdgeInsets.all(16),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('تراجع (بقاء)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  SystemNavigator.pop();
                },
                icon: const Icon(Icons.exit_to_app, size: 18),
                label: const Text('خروج نهائي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

Future<void> _launchUrlHelper(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint("Could not launch $url");
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void _playNotificationSound() {
  if (kIsWeb) {
    try {
      final html.AudioElement audio = html.AudioElement('1.mp3');
      audio.play().catchError((e) {});
    } catch (e) {}
  }
}

void _showBrowserNotification(String title, String body) {
  if (kIsWeb && html.Notification.supported) {
    if (html.Notification.permission == 'granted') {
      try {
        html.Notification(title, body: body, icon: 'icons/Icon-192.png');
      } catch (e) {}
    }
  }
}

// ===========================================================================
// MAIN ENTRY POINT & APPLICATION ROOT
// ===========================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _initializeAfterFirebase();
          return const TeacherLoginApp();
        }
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SafeLoadingWidget(),
          ),
        );
      },
    );
  }

  Future<void> _initializeAfterFirebase() async {
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      }
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {}
  }
}

class SafeLoadingWidget extends StatelessWidget {
  const SafeLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/m1.png',
              height: 150,
              width: 150,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.school, size: 100, color: Theme.of(context).primaryColor);
              },
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 15),
            const Text(
              "جاري التحقق من البيانات...",
              style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo'),
            )
          ],
        ),
      ),
    );
  }
}

class TeacherLoginApp extends StatelessWidget {
  const TeacherLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D47A1);
    const Color accentColor = Color(0xFFFFC107);
    const Color backgroundColor = Color(0xFFF4F7FA);

    return GlobalRefreshListener(
      child: MaterialApp(
        title: ' مدارس المعرفة الاهلية بمكة',
        debugShowCheckedModeBanner: false,
        scrollBehavior: GlobalScrollBehavior(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', ''),
        ],
        locale: const Locale('ar', ''),
        theme: ThemeData(
          fontFamily: 'Cairo',
          primaryColor: primaryColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor,
            secondary: accentColor,
            background: backgroundColor,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: backgroundColor,
          cardTheme: CardThemeData(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
              textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryColor, width: 2),
                foregroundColor: primaryColor,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
              )),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
            bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/admission': (context) => const AdmissionPage(),
          '/login': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
            final accountType = args?['accountType'] ?? 'student';
            return LoginPage(accountType: accountType);
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _firestore = FirebaseFirestore.instance;
  Future<String>? _cachedRoleFuture;
  String? _cachedUid;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final messaging = FirebaseMessaging.instance;
        try {
          await messaging.subscribeToTopic('public_announcements');
        } catch (e) {}

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.notification != null) {
            final title = message.notification!.title ?? 'إشعار جديد';
            final body = message.notification!.body ?? 'لديك إشعار جديد';
            _playNotificationSound();
            _showBrowserNotification(title, body);
          }
        });
      } catch(e) {}
    }
  }

  Future<void> _handleStudentTokenRegistration(DocumentReference studentDocRef, Map<String, dynamic>? studentData) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.requestPermission(
          alert: true, badge: true, sound: true, provisional: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          String? token = await messaging.getToken();
          if (token != null) {
            final currentToken = studentData?['fcmToken'];
            if (currentToken != token) {
              await studentDocRef.set({'fcmToken': token}, SetOptions(merge: true));
            }
          }
        }
      } catch (e) {}
    }
  }

  Future<String> _getUserRole(User user) async {
    try {
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        return 'teacher';
      }

      final studentDocRef = _firestore.collection('students').doc(user.uid);
      final studentDoc = await studentDocRef.get();
      if (studentDoc.exists) {
        studentDocRef.update({
          'lastSeen': FieldValue.serverTimestamp(),
        }).catchError((e) {});
        _handleStudentTokenRegistration(studentDocRef, studentDoc.data() as Map<String, dynamic>?);
        return 'student';
      }

      final pendingTeacher = await _firestore.collection('pending_teachers').doc(user.uid).get();
      if (pendingTeacher.exists) return 'pending';

      final pendingStudent = await _firestore.collection('pending_students').doc(user.uid).get();
      if (pendingStudent.exists) return 'pending';

      return 'unregistered';

    } catch (e) {
      debugPrint("Firebase Read Error: $e");
      return 'error:$e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.white, body: SafeLoadingWidget());
        }
        if (authSnapshot.hasError) {
          return const Scaffold(body: Center(child: Text("حدث خطأ في المصادقة.")));
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          final user = authSnapshot.data!;
          if (_cachedRoleFuture == null || _cachedUid != user.uid) {
            _cachedUid = user.uid;
            _cachedRoleFuture = _getUserRole(user);
          }

          return FutureBuilder<String>(
            future: _cachedRoleFuture,
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(backgroundColor: Colors.white, body: SafeLoadingWidget());
              }

              final role = roleSnapshot.data;

              switch (role) {
                case 'teacher':
                  return const ExitPopupWrapper(child: QRSessionOverlay(child: AddPage()));
                case 'student':
                  return const ExitPopupWrapper(child: StudentViewPage());
                case 'pending':
                  return const ExitPopupWrapper(child: PendingApprovalScreen());
                case 'unregistered':
                  return const ExitPopupWrapper(child: RegistrationFlow());
                case 'unauthorized':
                  return const ExitPopupWrapper(child: WelcomePage());
                default:
                  if (role != null && role.startsWith('error:')) {
                    return Scaffold(
                      body: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.security_update_warning_outlined, color: Colors.red, size: 80),
                              const SizedBox(height: 20),
                              const Text("عذراً، فشل النظام في قراءة بياناتك من Firebase بسبب صلاحيات (Security Rules) أو مشكلة بالاتصال.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text(role.replaceFirst('error:', ''), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 14), textDirection: TextDirection.ltr),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _cachedRoleFuture = null;
                                  FirebaseAuth.instance.signOut();
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text("تسجيل الخروج والمحاولة مرة أخرى"),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const ExitPopupWrapper(child: WelcomePage());
              }
            },
          );
        }
        return const ExitPopupWrapper(child: WelcomePage());
      },
    );
  }
}

// ===========================================================================
// ADMISSION & WELCOME & AUTH FLOW SCREENS
// ===========================================================================

class AdmissionPage extends StatefulWidget {
  const AdmissionPage({super.key});

  @override
  State<AdmissionPage> createState() => _AdmissionPageState();
}

class _AdmissionPageState extends State<AdmissionPage> {
  final _admissionFormKey = GlobalKey<FormState>();
  final _studentNameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();

  String? _selectedAdmissionGrade;
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  final List<String> _admissionGrades = [
    'الأول الابتدائي', 'الثاني الابتدائي', 'الثالث الابتدائي', 'الرابع الابتدائي', 'الخامس الابتدائي', 'السادس الابتدائي',
    'الأول المتوسط', 'الثاني المتوسط', 'الثالث المتوسط',
    'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي',
  ];

  @override
  void dispose() {
    _studentNameCtrl.dispose();
    _studentIdCtrl.dispose();
    _parentPhoneCtrl.dispose();
    super.dispose();
  }

  void _showCheckStatusDialog() {
    final TextEditingController searchCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('الاستعلام عن حالة القبول', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل رقم هوية الطالب للتحقق من حالة القبول وموعد الزيارة المحدد لك', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: searchCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'رقم الهوية',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              String id = searchCtrl.text.trim();
              Navigator.pop(dialogContext);

              if (id.isEmpty) return;

              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator())
              );

              try {
                final query = await FirebaseFirestore.instance.collection('admission_requests')
                    .where('studentId', isEqualTo: id).get();

                if (mounted) Navigator.pop(context);

                if (query.docs.isEmpty) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('نتيجة الاستعلام', textAlign: TextAlign.center),
                        content: const Text('لا توجد بيانات مسجلة أو أن الطلب لا يزال قيد المعالجة المبدئية. يرجى مراجعتنا لاحقاً.', textAlign: TextAlign.center),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
                      ),
                    );
                  }
                } else {
                  final data = query.docs.first.data();
                  String status = data['status'] ?? 'pending';
                  String visitTime = data['visitTime'] ?? 'غير محدد';

                  String statusText = '';
                  Color statusColor = Colors.black;

                  if (status == 'pending') {
                    statusText = 'الطلب قيد المراجعة والإنتظار';
                    statusColor = Colors.orange;
                  } else if (status == 'approved') {
                    statusText = 'تم القبول المبدئي!';
                    statusColor = Colors.green;
                  } else if (status == 'rejected') {
                    statusText = 'نعتذر، لم يتم القبول.';
                    statusColor = Colors.red;
                  }

                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('نتيجة الاستعلام', textAlign: TextAlign.center),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(data['studentName'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 10),
                            Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                            const Divider(height: 30),
                            const Text('موعد الزيارة المحدد لك:', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text(visitTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('بحث'),
          )
        ],
      ),
    );
  }

  void _submitAdmission() async {
    if (_admissionFormKey.currentState!.validate()) {
      if (_selectedAdmissionGrade == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الصف الدراسي'), backgroundColor: Colors.red));
        return;
      }
      if (_selectedAdmissionGrade == 'الأول الابتدائي' && _selectedDateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار تاريخ الميلاد'), backgroundColor: Colors.red));
        return;
      }

      setState(() => _isLoading = true);

      final String phone = _parentPhoneCtrl.text.trim();
      final String? dobString = _selectedDateOfBirth != null
          ? '${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2,'0')}-${_selectedDateOfBirth!.day.toString().padLeft(2,'0')}'
          : null;

      try {
        await FirebaseFirestore.instance.collection('admission_requests').add({
          'studentName': _studentNameCtrl.text.trim(),
          'studentId': _studentIdCtrl.text.trim(),
          'parentPhone': phone,
          'grade': _selectedAdmissionGrade,
          'dateOfBirth': dobString,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error saving admission request to Firestore: $e');
      }

      final String message = '''
<b>طلب التحاق جديد 🏫</b>

<b>اسم الطالب:</b> ${_studentNameCtrl.text.trim()}
<b>رقم الهوية:</b> ${_studentIdCtrl.text.trim()}
<b>الصف الدراسي:</b> $_selectedAdmissionGrade${dobString != null ? '\n<b>تاريخ الميلاد:</b> $dobString' : ''}

<b>للتواصل:</b>
<a href="https://wa.me/966$phone">اضغط هنا لمراسلة ولي الأمر عبر واتساب (+966 $phone)</a>
''';

      bool success = await TelegramStorage.sendMessage(message);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 80),
                    const SizedBox(height: 20),
                    const Text('تم الإرسال بنجاح', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text('تم استلام طلب الالتحاق الخاص بك وإرساله للإدارة بنجاح. سيقوم فريق القبول والتسجيل بالتواصل معكم قريباً.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('العودة للرئيسية'),
                    )
                  ],
                ),
              )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استلام الطلب ولكن حدث خطأ في إرسال الإشعار للإدارة.'), backgroundColor: Colors.orange));
        }
      }
    }
  }

  List<Widget> _getGradeWhatsAppIcons(String grade) {
    List<String> numbers = [];
    if (grade.contains('الابتدائي')) {
      numbers = ['966502361091'];
    } else {
      numbers = ['966556411336', '966500468552'];
    }
    return numbers.map((n) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () => _launchUrlHelper('https://wa.me/$n'),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.string(waIconSvgGlobal, width: 22, height: 22, colorFilter: const ColorFilter.mode(Color(0xFF25D366), BlendMode.srcIn)),
        ),
      ),
    )).toList();
  }

  Widget _buildInteractiveFeatures(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('البروشور التعريفي والمميزات', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
        const SizedBox(height: 10),
        const Text('اضغط على اسم أو أيقونة كل مرحلة لاستعراض مميزاتها بالتفصيل', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 30),

        _buildExpandableFeatureCard(
            title: 'ابتدائية المعرفة',
            mainIcon: Icons.school,
            color: Colors.blue,
            features: [
              'تدريس المنهج السعودي الوطني.',
              'لغة إنجليزية مكثفة (4 حصص أسبوعياً) سلسلة كتب FAMILY AND FRIENDS.',
              'حصة سباحة، حصة روبوت، حصة تنمية مهارات، حصص سلوك، وحصص رقمية.',
              'كادر وظيفي متميز ومؤهل.',
              'الاستفادة من مبادئ التوكاتسو وتطبيقها على الجانب الشخصي.',
              'منصة تعليمية متكاملة للمعلمين.',
              'نظام آلي لمناداة الطلاب بطلب الطالب عبر منصتنا (elm3rfa.vip) ويظهر للمعلمين والإدارة على السبورات الذكية.',
              'سجل شامل سلوكي للطالب في جميع الجوانب الحسنة.',
            ],
            contacts: [
              {'number': '966502361091', 'label': 'مسئول الاستقبال والقبول\n0502361091'}
            ]
        ),

        _buildExpandableFeatureCard(
            title: 'متوسطة المعرفة',
            mainIcon: Icons.menu_book,
            color: Colors.orange,
            features: ['جاري التحميل...'],
            contacts: [
              {'number': '966556411336', 'label': '0556411336'},
              {'number': '966500468552', 'label': '0500468552'},
            ]
        ),

        _buildExpandableFeatureCard(
            title: 'ثانوية المعرفة',
            mainIcon: Icons.account_balance,
            color: Colors.teal,
            features: ['جاري التحميل...'],
            contacts: [
              {'number': '966556411336', 'label': '0556411336'},
              {'number': '966500468552', 'label': '0500468552'},
            ]
        ),
      ],
    );
  }

  Widget _buildExpandableFeatureCard({
    required String title,
    required IconData mainIcon,
    required Color color,
    required List<String> features,
    required List<Map<String, String>> contacts,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(mainIcon, color: color, size: 30),
          ),
          title: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          subtitle: const Text('اضغط لعرض المميزات والتفاصيل', style: TextStyle(color: Colors.grey, fontSize: 14)),
          childrenPadding: const EdgeInsets.all(24),
          children: [
            ...features.map((f) => _buildFeatureItem(f)),
            const SizedBox(height: 24),
            Column(
              children: contacts.map((contact) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrlHelper('https://wa.me/${contact['number']}'),
                      icon: SvgPicture.string(waIconSvgGlobal, width: 26, height: 26, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                      label: Text(contact['label']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  )
              ).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'wa_floating_btn_admission',
        onPressed: () => _launchUrlHelper('https://wa.me/966502361091'),
        backgroundColor: const Color(0xFF25D366),
        tooltip: 'تواصل مع أ/ عماد الجندي',
        child: SvgPicture.string(waIconSvgGlobal, width: 32, height: 32, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: const Text('طلب التحاق إلكتروني'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          image: DecorationImage(
            image: const AssetImage('assets/hero_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95), BlendMode.dstATop),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: isMobile ? 16 : 40),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 24 : 50),
                      child: Form(
                        key: _admissionFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'نموذج الانضمام المبدئي',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: isMobile ? 28 : 34, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'مرحباً بك في مدارس المعرفة الأهلية بمكة. يرجى تعبئة الحقول وسنتواصل معك بأقرب وقت لإكمال إجراءات القبول.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.6),
                            ),
                            const SizedBox(height: 40),

                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _showCheckStatusDialog,
                                icon: const Icon(Icons.search, size: 20),
                                label: const Text('الاستعلام عن حالة القبول وموعد الزيارة'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                  side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                  foregroundColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                            const Text('البيانات الأساسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Divider(),
                            const SizedBox(height: 16),

                            Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                SizedBox(
                                  width: isMobile ? double.infinity : 330,
                                  child: TextFormField(
                                    controller: _studentNameCtrl,
                                    decoration: const InputDecoration(labelText: 'اسم الطالب الرباعي *', prefixIcon: Icon(Icons.person_outline)),
                                    validator: (v) => v!.isEmpty ? 'الرجاء إدخال اسم الطالب' : null,
                                  ),
                                ),
                                SizedBox(
                                  width: isMobile ? double.infinity : 330,
                                  child: TextFormField(
                                    controller: _studentIdCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'رقم هوية الطالب *',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                      helperText: 'يستخدم لاحقاً للاستعلام عن حالة القبول',
                                      helperMaxLines: 2,
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم الهوية' : null,
                                  ),
                                ),
                                SizedBox(
                                  width: isMobile ? double.infinity : 330,
                                  child: TextFormField(
                                    controller: _parentPhoneCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'رقم جوال ولي الأمر للتواصل *',
                                      prefixIcon: Icon(Icons.phone_android),
                                      prefixText: '+966 ',
                                      hintText: '5xxxxxxxx',
                                      hintTextDirection: TextDirection.ltr,
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال رقم الجوال' : null,
                                  ),
                                ),
                                SizedBox(
                                  width: isMobile ? double.infinity : 330,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(labelText: 'الصف الدراسي المطلوب *', prefixIcon: Icon(Icons.school_outlined)),
                                        value: _selectedAdmissionGrade,
                                        items: _admissionGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                        onChanged: (v) => setState(() => _selectedAdmissionGrade = v),
                                        validator: (v) => v == null ? 'الرجاء اختيار الصف' : null,
                                      ),
                                      if (_selectedAdmissionGrade != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('تواصل مباشر:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              const SizedBox(width: 8),
                                              ..._getGradeWhatsAppIcons(_selectedAdmissionGrade!)
                                            ],
                                          ),
                                        )
                                    ],
                                  ),
                                ),

                                if (_selectedAdmissionGrade == 'الأول الابتدائي')
                                  SizedBox(
                                    width: isMobile ? double.infinity : 330,
                                    child: InkWell(
                                      onTap: () async {
                                        DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now().subtract(const Duration(days: 6 * 365)),
                                          firstDate: DateTime(2010),
                                          lastDate: DateTime.now(),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setState(() => _selectedDateOfBirth = picked);
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'تاريخ الميلاد *',
                                          prefixIcon: const Icon(Icons.calendar_month),
                                          errorText: (_selectedAdmissionGrade == 'الأول الابتدائي' && _selectedDateOfBirth == null && _isLoading)
                                              ? 'الرجاء اختيار تاريخ الميلاد'
                                              : null,
                                        ),
                                        child: Text(
                                            _selectedDateOfBirth == null
                                                ? 'اضغط لاختيار التاريخ'
                                                : '${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2,'0')}-${_selectedDateOfBirth!.day.toString().padLeft(2,'0')}'
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 50),
                            SizedBox(
                              height: 60,
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : ElevatedButton.icon(
                                icon: const Icon(Icons.send_rounded, size: 24),
                                label: const Text('إرسال طلب التحاق', style: TextStyle(fontSize: 18, height: 1.2)),
                                onPressed: _submitAdmission,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildInteractiveFeatures(isMobile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernHoverCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const ModernHoverCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(32),
    this.backgroundColor,
  });

  @override
  State<ModernHoverCard> createState() => _ModernHoverCardState();
}

class _ModernHoverCardState extends State<ModernHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -10.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? Theme.of(context).primaryColor.withOpacity(0.12) : Colors.black.withOpacity(0.04),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 10 : 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class ModernBrochureViewer extends StatefulWidget {
  final List<String> fileIds;
  final List<String> fallbackImages;
  const ModernBrochureViewer({super.key, required this.fileIds, required this.fallbackImages});

  @override
  State<ModernBrochureViewer> createState() => _ModernBrochureViewerState();
}

class _ModernBrochureViewerState extends State<ModernBrochureViewer> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && !_isUserInteracting) {
        int count = widget.fileIds.isNotEmpty ? widget.fileIds.length : widget.fallbackImages.length;
        if (count == 0) return;

        int nextIndex = _currentIndex + 1;
        if (nextIndex >= count) {
          nextIndex = 0;
        }
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _showModernImageDialog(BuildContext context, String tag, bool isFirebase) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      barrierDismissible: true,
      barrierLabel: 'إغلاق',
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: tag,
                      child: isFirebase
                          ? Image.network(tag, fit: BoxFit.contain)
                          : Image.asset(tag, fit: BoxFit.contain, width: MediaQuery.of(context).size.width * 0.95),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    iconSize: 32,
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final bool useFirebase = widget.fileIds.isNotEmpty;
    final int count = useFirebase ? widget.fileIds.length : widget.fallbackImages.length;

    if (count == 0) return const SizedBox.shrink();

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: isMobile ? 16 / 11 : 21 / 8,
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollStartNotification) {
                    setState(() {
                      _isUserInteracting = true;
                    });
                  } else if (notification is ScrollEndNotification) {
                    setState(() {
                      _isUserInteracting = false;
                    });
                    _startAutoPlay();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() { _currentIndex = index; });
                  },
                  itemCount: count,
                  itemBuilder: (context, index) {
                    String tag = useFirebase ? widget.fileIds[index] : widget.fallbackImages[index];

                    return GestureDetector(
                      onTap: () => _showModernImageDialog(context, tag, useFirebase),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Hero(
                                  tag: tag,
                                  child: useFirebase
                                      ? Image.network(
                                    tag,
                                    fit: BoxFit.fill,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                                    ),
                                  )
                                      : Image.asset(
                                    tag,
                                    fit: BoxFit.fill,
                                    errorBuilder: (c, e, s) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 15,
                                left: 15,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(Icons.pan_tool_outlined, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index ? const Color(0xFF0D47A1) : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class TopHeroSlider extends StatefulWidget {
  final bool isMobile;
  final List<String> fileIds;
  const TopHeroSlider({super.key, required this.isMobile, required this.fileIds});

  @override
  State<TopHeroSlider> createState() => _TopHeroSliderState();
}

class _TopHeroSliderState extends State<TopHeroSlider> {
  late PageController _pageController;
  Timer? _timer;

  final List<String> _images = ['assets/PP1.jpg', 'assets/5v.jpg'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 10000);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: SizedBox(
        width: screenWidth,
        height: widget.isMobile ? screenWidth * 0.6 : screenWidth * 0.3,
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            if (widget.fileIds.isNotEmpty) {
              final actualIndex = index % widget.fileIds.length;
              return Image.network(
                widget.fileIds[actualIndex],
                fit: BoxFit.fill,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              );
            } else {
              final actualIndex = index % _images.length;
              return Image.asset(
                _images[actualIndex],
                fit: BoxFit.fill,
              );
            }
          },
        ),
      ),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isInstallable = false;
  String _notificationPermission = 'default';
  bool _isGuestLoading = false;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _brochureKey = GlobalKey();
  final GlobalKey _loginKey = GlobalKey();

  final List<String> _brochureImages = [
    'assets/5v.jpg', 'assets/v2.jpg', 'assets/3v.jpg', 'assets/v1.jpg',
    'assets/4v.jpg', 'assets/PP2.jpg', 'assets/PP3.jpg', 'assets/PP4.jpg',
    'assets/PP5.jpg', 'assets/PP6.jpg', 'assets/PP7.jpg', 'assets/PP9.jpg',
    'assets/PP10.jpg', 'assets/PP11.jpg'
  ];

  final String _waUrl = 'https://wa.me/966502361091';
  final String _xUrl = 'https://x.com/almarefa99?t=Yi1juWC3pAHWDK9oeHeY3g&s=09';
  final String _snapUrl = 'https://www.snapchat.com/@almarefa19?share_id=Q4tytyVDgKM&locale=ar-AE';
  final String _instaUrl = 'https://www.instagram.com/accounts/emailsignup/';
  final String _tiktokUrl = 'https://www.tiktok.com/@ahmarefa99';

  @override
  void initState() {
    super.initState();
    _setupPwaListeners();
    _checkNotificationPermission();
  }

  void _scrollToSection(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Widget _buildSocialIcon(String svgData, String url, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: IconButton(
        icon: SvgPicture.string(svgData, width: 22, height: 22, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
        onPressed: () => _launchUrlHelper(url),
        tooltip: 'تواصل معنا',
      ),
    );
  }

  void _setupPwaListeners() {
    if (kIsWeb) {
      js.context['pwa-installable-listener'] = (event) {
        try {
          final isReady = js.context['isInstallable'] ?? false;
          if (mounted && _isInstallable != isReady) {
            setState(() { _isInstallable = isReady; });
          }
        } catch (e) {}
      };
      try {
        js.context.callMethod('addEventListener', ['pwa-installable', js.context['pwa-installable-listener']]);
        if (js.context.hasProperty('isInstallable')) {
          _isInstallable = js.context['isInstallable'] ?? false;
        }
      } catch(e) {}

      js.context['pwa-update-listener'] = (event) {
        try {
          if (kIsWeb) {
            html.window.location.reload();
          }
        } catch (e) {}
      };
      try {
        js.context.callMethod('addEventListener', ['pwa-update-available', js.context['pwa-update-listener']]);
      } catch (e) {}
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      try {
        if (js.context.hasProperty('pwa-installable-listener')) {
          js.context.callMethod('removeEventListener', ['pwa-installable', js.context['pwa-installable-listener']]);
        }
        if (js.context.hasProperty('pwa-update-listener')) {
          js.context.callMethod('removeEventListener', ['pwa-update-available', js.context['pwa-update-listener']]);
        }
      } catch (e) {}
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _checkNotificationPermission() async {
    if (kIsWeb) {
      if (html.Notification.supported) {
        if(mounted) {
          setState(() { _notificationPermission = html.Notification.permission ?? 'default'; });
        }
      }
    } else {
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        if(mounted) {
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            setState(() => _notificationPermission = 'granted');
          } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
            setState(() => _notificationPermission = 'denied');
          } else {
            setState(() => _notificationPermission = 'default');
          }
        }
      } catch (e) {
        if(mounted) setState(() => _notificationPermission = 'default');
      }
    }
  }

  void _showInstallPrompt() {
    if (kIsWeb) {
      try { js.context.callMethod('showInstallPrompt'); } catch (e) {}
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (kIsWeb) {
      html.window.location.reload();
    } else {
      _setupPwaListeners();
      _checkNotificationPermission();
      if (mounted) setState(() {});
    }
  }

  void _signInWithGoogle() {
    GoogleAuthProvider authProvider = GoogleAuthProvider();
    authProvider.addScope('email');
    authProvider.setCustomParameters({
      'prompt': 'select_account',
    });

    if (kIsWeb) {
      FirebaseAuth.instance.signInWithPopup(authProvider).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء الدخول أو حظر النافذة من المتصفح'), backgroundColor: Colors.red),
          );
        }
      });
    } else {
      FirebaseAuth.instance.signInWithProvider(authProvider);
    }
  }

  void _showQRLoginDialog() {
    final String sessionId = const Uuid().v4();

    FirebaseFirestore.instance.collection('qr_logins').doc(sessionId).set({
      'created_at': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('qr_logins').doc(sessionId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  if (data['auth_token'] != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!context.mounted) return;
                      Navigator.pop(context);

                      try {
                        await FirebaseAuth.instance.signInWithCustomToken(data['auth_token']);
                        FirebaseFirestore.instance.collection('qr_logins').doc(sessionId).delete();

                        if (context.mounted) {
                          QRSessionTimer.startSession(context);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('فشل الدخول بالتوكن: $e'), backgroundColor: Colors.red)
                        );
                      }
                    });
                  }
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('دخول سريع آمن (QR)', textAlign: TextAlign.center),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: QrImageView(
                          data: sessionId,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'افتح تطبيق المعلم على هاتفك، ثم اضغط على "دخول السبورة الذكية" من لوحة التحكم وامسح هذا الكود.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'أمان 🔒: سيتم الخروج تلقائياً بعد 5 دقائق.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const CircularProgressIndicator(),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleInstall() {
    if (kIsWeb) {
      if (_isInstallable) {
        _showInstallPrompt();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('التطبيق مثبت بالفعل، أو يمكنك إضافته للشاشة الرئيسية من قائمة خيارات المتصفح.'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrochureSection(BuildContext context, bool isMobile, List<String> fileIds, {List<String> fallback = const []}) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).primaryColor.withOpacity(0.02),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: isMobile ? 10 : 40),
      child: Column(
        children: [
          ModernBrochureViewer(fileIds: fileIds, fallbackImages: fallback),
        ],
      ),
    );
  }

  Widget _buildLogosSection(bool isMobile, List<String> logosIds) {
    return Container(
      width: double.infinity,
      color: Colors.purple.withOpacity(0.05),
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: isMobile ? 10 : 40),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: logosIds.map((url) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
              image: DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.contain,
              )
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildReelsSection(bool isMobile, List<Map<String, dynamic>> reelsData) {
    return Container(
      width: double.infinity,
      color: Colors.red.withOpacity(0.02),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: isMobile ? 10 : 40),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: reelsData.map((data) {
          final url = data['imageUrl'];
          final title = data['title']?.isNotEmpty == true ? data['title'] : 'مقطع فيديو';
          return InkWell(
            onTap: () => _launchUrlHelper(url),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('website_brochures').orderBy('order', descending: false).get(),
        builder: (context, snapshot) {
          List<String> heroIds = [];
          List<String> middleIds = [];
          List<String> awardsIds = [];
          List<String> logosIds = [];
          List<String> facilitiesIds = [];
          List<Map<String, dynamic>> reelsData = [];

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final String? imageUrl = data['imageUrl'];
              final String type = data['type'] ?? 'hero';

              if (imageUrl != null && imageUrl.isNotEmpty) {
                if (type == 'hero') {
                  heroIds.add(imageUrl);
                } else if (type == 'middle') {
                  middleIds.add(imageUrl);
                } else if (type == 'awards') {
                  awardsIds.add(imageUrl);
                } else if (type == 'logos') {
                  logosIds.add(imageUrl);
                } else if (type == 'facilities') {
                  facilitiesIds.add(imageUrl);
                } else if (type == 'reels') {
                  reelsData.add(data);
                }
              }
            }
          }

          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            floatingActionButton: FloatingActionButton(
              heroTag: 'wa_floating_btn_welcome',
              onPressed: () => _launchUrlHelper('https://wa.me/966502361091'),
              backgroundColor: const Color(0xFF25D366),
              tooltip: 'تواصل مع أ/ عماد الجندي',
              child: SvgPicture.string(waIconSvgGlobal, width: 32, height: 32, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

            appBar: AppBar(
              backgroundColor: Colors.white.withOpacity(0.95),
              toolbarHeight: 80,
              title: Row(
                children: [
                  if (screenWidth > 600) _buildNavButton('المرفقات', () => _scrollToSection(_brochureKey)),
                  if (screenWidth > 600) _buildNavButton('طلب التحاق', () => Navigator.of(context).pushNamed('/admission')),
                  if (screenWidth > 600) _buildNavButton('دخول المنصة', () => _scrollToSection(_loginKey)),
                ],
              ),
              actions: [
                if (screenWidth > 800) ...[
                  _buildSocialIcon(waIconSvgGlobal, _waUrl, const Color(0xFF25D366)),
                  _buildSocialIcon(_xIconSvg, _xUrl, Theme.of(context).primaryColor),
                  _buildSocialIcon(_snapIconSvg, _snapUrl, Theme.of(context).primaryColor),
                  _buildSocialIcon(_instaIconSvg, _instaUrl, Theme.of(context).primaryColor),
                  _buildSocialIcon(_tiktokIconSvg, _tiktokUrl, Theme.of(context).primaryColor),
                  const SizedBox(width: 16),
                ],

                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenWidth > 600 ? 16.0 : 8.0),
                  child: IconButton(
                    icon: Icon(Icons.install_mobile, size: screenWidth > 600 ? 28 : 28, color: Colors.green.shade600),
                    onPressed: _handleInstall,
                    tooltip: 'تثبيت التطبيق',
                  ),
                ),

                if (screenWidth > 600) const SizedBox(width: 8),

                if (isMobile)
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded, size: 30),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  )
              ],
            ),
            endDrawer: isMobile ? _buildMobileDrawer(screenWidth) : null,
            body: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Theme.of(context).primaryColor,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    child: Column(
                      children: [
                        TopHeroSlider(isMobile: isMobile, fileIds: heroIds),
                        Container(key: _heroKey, child: _buildWebsiteHeroSection(context, isMobile)),

                        Container(
                          key: _brochureKey,
                          child: Column(
                            children: [
                              if (middleIds.isNotEmpty || _brochureImages.isNotEmpty)
                                _buildSectionTitle('بروشور المدرسة', Icons.menu_book, Theme.of(context).primaryColor),
                              _buildBrochureSection(context, isMobile, middleIds, fallback: _brochureImages),
                            ],
                          ),
                        ),

                        if (facilitiesIds.isNotEmpty) ...[
                          _buildSectionTitle('مرافق المدرسة', Icons.apartment, Colors.teal),
                          _buildBrochureSection(context, isMobile, facilitiesIds),
                        ],

                        if (awardsIds.isNotEmpty) ...[
                          _buildSectionTitle('جوائز المدرسة', Icons.emoji_events, Colors.amber.shade700),
                          _buildBrochureSection(context, isMobile, awardsIds),
                        ],

                        if (logosIds.isNotEmpty) ...[
                          _buildSectionTitle('شركاء النجاح', Icons.handshake, Colors.purple),
                          _buildLogosSection(isMobile, logosIds),
                        ],

                        if (reelsData.isNotEmpty) ...[
                          _buildSectionTitle('ريلز الطلاب', Icons.video_library, Colors.red),
                          _buildReelsSection(isMobile, reelsData),
                        ],

                        Container(key: _loginKey, child: _buildLoginSection(context, isMobile)),
                        _buildWebsiteFooter(isMobile),
                      ],
                    ),
                  ),
                ),

                StickySideMenu(
                  onScrollTo: _scrollToSection,
                  heroKey: _heroKey,
                  brochureKey: _brochureKey,
                  loginKey: _loginKey,
                ),

                if (_isGuestLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          SizedBox(height: 16),
                          Text(
                            'جاري تهيئة الحساب السريع...',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildNavButton(String title, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey.shade800,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        child: Text(title),
      ),
    );
  }

  Widget _buildMobileDrawer(double screenWidth) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 30,
              bottom: 30,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                    'assets/m1.png',
                    height: 70,
                    errorBuilder: (c, e, s) => const Icon(Icons.school, size: 70, color: Colors.white)
                ),
                const SizedBox(height: 16),
                const Text(
                  'مدارس  المعرفة الاهلية بمكة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.image_outlined), title: const Text('المرفقات', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); _scrollToSection(_brochureKey); }),
          ListTile(leading: const Icon(Icons.wechat, color: Colors.green), title: const Text('تواصل معنا (واتساب)', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); _launchUrlHelper(_waUrl); }),
          const Divider(),

          if (screenWidth <= 600) ...[
            ListTile(leading: const Icon(Icons.touch_app, color: Colors.blue), title: const Text('طلب التحاق', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); Navigator.of(context).pushNamed('/admission'); }),
            ListTile(leading: const Icon(Icons.login, color: Colors.blue), title: const Text('دخول المنصة', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); _scrollToSection(_loginKey); }),
            const Divider(),
          ],

          Container(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              'مدارس المعرفة الرائدة بمكة المكرمة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWebsiteHeroSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          image: const AssetImage('assets/hero_bg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.9), BlendMode.dstATop),
        ),
      ),
      padding: EdgeInsets.fromLTRB(isMobile ? 24 : 40, 80, isMobile ? 24 : 40, isMobile ? 40 : 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedTextKit(
            repeatForever: false,
            isRepeatingAnimation: false,
            animatedTexts: [
              TypewriterAnimatedText(
                'مدارس  المعرفة الاهلية ترحب بكم\nنصنع المستقبل ونبني\nجيلاً واعياً ومبدعاً',
                textAlign: TextAlign.center,
                textStyle: TextStyle(fontSize: isMobile ? 28 : 42, fontWeight: FontWeight.w900, color: const Color(0xFF1A1A1A), height: 1.4),
                speed: const Duration(milliseconds: 60),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Text(
              'تعليم متميز منافس محلياً وعالمياً، في مجتمع مدرسي محفز للإبداع والابتكار.\n(المرحلة الابتدائية - المتوسطة - الثانوية)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: isMobile ? 18 : 22,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.touch_app, size: 24),
                  label: const Text('قدم الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 40 : 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pushNamed('/admission'),
                ),
              ),
              ModernHoverCard(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.login, size: 24),
                  label: const Text('دخول المنصة'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 40 : 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 2.5),
                  ),
                  onPressed: () => _scrollToSection(_loginKey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        image: DecorationImage(
          image: const AssetImage('assets/hero_bg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Theme.of(context).primaryColor.withOpacity(0.95), BlendMode.dstATop),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Icon(Icons.fingerprint_rounded, size: 60, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 16),
              const Text('بوابة الدخول الموحدة', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              Text('يرجى تحديد صفتك للمتابعة والدخول للنظام', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
              const SizedBox(height: 40),

              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      minimumSize: const Size(300, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage(accountType: 'teacher'))),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('تسجيل دخول المعلمين والإداريين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade800,
                      minimumSize: const Size(300, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage(accountType: 'student'))),
                    icon: const Icon(Icons.family_restroom),
                    label: const Text('تسجيل دخول الطلاب وأولياء الأمور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),

              const SizedBox(height: 50),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: _signInWithGoogle,
                      icon: SvgPicture.asset('assets/g1.svg', height: 24),
                      label: const Text('الدخول السريع بحساب Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _showQRLoginDialog,
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white70),
                      label: const Text('دخول السبورة الذكية للمعلمين (QR)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebsiteFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: isMobile ? 16 : 40),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 40.0,
            spacing: 30.0,
            children: [
              _buildFooterWebColumn(
                'مدارس  المعرفة الاهلية بمكة',
                [
                  'نصنع المستقبل ونبني جيلاً واعياً ومبدعاً.',
                  'قيمنا: الاعتزاز بالدين، المواطنة، المسؤولية، الإبداع.',
                ],
                isBrand: true,
                isMobile: isMobile,
              ),
              _buildFooterWebColumn(
                'التواصل والدعم',
                [
                  'مطور الموقع: مصطفى سعيد (966569064173+)',
                  'وكيل الشئون التعليمية: أ/ عماد الجندي (966502361091+)',
                ],
                isMobile: isMobile,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(waIconSvgGlobal, _waUrl, const Color(0xFF25D366)),
              _buildSocialIcon(_xIconSvg, _xUrl, Colors.white),
              _buildSocialIcon(_snapIconSvg, _snapUrl, const Color(0xFFFFFC00)),
              _buildSocialIcon(_instaIconSvg, _instaUrl, Colors.pinkAccent),
              _buildSocialIcon(_tiktokIconSvg, _tiktokUrl, Colors.white),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: ClipOval(
              child: Image.asset(
                'assets/m1.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 35, color: Theme.of(context).primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterWebColumn(String title, List<String> items, {bool isBrand = false, required bool isMobile}) {
    return SizedBox(
      width: isMobile ? double.infinity : 300,
      child: Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: isBrand ? 24 : 20, color: Colors.white),
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
          ),
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            height: 3,
            width: 40,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(2)),
          ),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: Text(
              item,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade400, height: 1.6),
              textAlign: isMobile ? TextAlign.center : TextAlign.start,
              textDirection: TextDirection.rtl,
            ),
          )),
        ],
      ),
    );
  }
}

// ===========================================================================
// STICKY SIDE MENU
// ===========================================================================

class StickySideMenu extends StatefulWidget {
  final Function(GlobalKey) onScrollTo;
  final GlobalKey heroKey;
  final GlobalKey brochureKey;
  final GlobalKey loginKey;

  const StickySideMenu({
    super.key,
    required this.onScrollTo,
    required this.heroKey,
    required this.brochureKey,
    required this.loginKey,
  });

  @override
  State<StickySideMenu> createState() => _StickySideMenuState();
}

class SideMenuItem {
  final String title;
  final Color color;
  final Widget icon;
  final VoidCallback action;
  final bool isSocial;

  SideMenuItem({
    required this.title,
    required this.color,
    required this.icon,
    required this.action,
    this.isSocial = false,
  });
}

class _StickySideMenuState extends State<StickySideMenu> {
  int? _expandedIndex;

  late final List<SideMenuItem> menuItems = [
    SideMenuItem(
      title: 'الرئيسية',
      color: const Color(0xFF2196F3),
      icon: const Icon(Icons.home, color: Colors.white, size: 24),
      action: () => widget.onScrollTo(widget.heroKey),
    ),
    SideMenuItem(
      title: 'المرفقات والبروشور',
      color: const Color(0xFF009688),
      icon: const Icon(Icons.image_outlined, color: Colors.white, size: 24),
      action: () => widget.onScrollTo(widget.brochureKey),
    ),
    SideMenuItem(
      title: 'بوابة الدخول الموحدة',
      color: const Color(0xFFFF9800),
      icon: const Icon(Icons.login, color: Colors.white, size: 24),
      action: () => widget.onScrollTo(widget.loginKey),
    ),
    SideMenuItem(
      title: 'طلب التحاق إلكتروني',
      color: const Color(0xFF9C27B0),
      icon: const Icon(Icons.assignment_turned_in, color: Colors.white, size: 24),
      action: () => Navigator.of(context).pushNamed('/admission'),
    ),
    SideMenuItem(
      title: 'واتساب',
      color: const Color(0xFF25D366),
      icon: SvgPicture.string(waIconSvgGlobal, width: 22, height: 22, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      action: () => _launchUrlHelper('https://wa.me/966502361091'),
      isSocial: true,
    ),
    SideMenuItem(
      title: 'منصة X',
      color: const Color(0xFF1DA1F2),
      icon: SvgPicture.string(_xIconSvg, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      action: () => _launchUrlHelper('https://x.com/almarefa99?t=Yi1juWC3pAHWDK9oeHeY3g&s=09'),
      isSocial: true,
    ),
    SideMenuItem(
      title: 'سناب شات',
      color: const Color(0xFFFFFC00),
      icon: SvgPicture.string(_snapIconSvg, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
      action: () => _launchUrlHelper('https://www.snapchat.com/@almarefa19?share_id=Q4tytyVDgKM&locale=ar-AE'),
      isSocial: true,
    ),
    SideMenuItem(
      title: 'تيك توك',
      color: const Color(0xFF010101),
      icon: SvgPicture.string(_tiktokIconSvg, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      action: () => _launchUrlHelper('https://www.tiktok.com/@ahmarefa99'),
      isSocial: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: MediaQuery.of(context).size.height * 0.18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(menuItems.length, (index) {
          final bool isExpanded = _expandedIndex == index;
          final item = menuItems[index];

          return GestureDetector(
            onTap: () {
              if (item.isSocial) {
                item.action();
                return;
              }

              if (isExpanded) {
                item.action();
                setState(() {
                  _expandedIndex = null;
                });
              } else {
                setState(() {
                  _expandedIndex = index;
                });

                Future.delayed(const Duration(seconds: 4), () {
                  if (mounted && _expandedIndex == index) {
                    setState(() {
                      _expandedIndex = null;
                    });
                  }
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              width: isExpanded ? 190 : 48,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(-2, 2),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isExpanded) ...[
                    Container(
                      width: double.infinity,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      item.icon,
                      if (isExpanded) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ===========================================================================
// SCAN BARCODE & LOGIN PAGE
// ===========================================================================

class ScanBarcodePage extends StatelessWidget {
  const ScanBarcodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('امسح الباركود الخاص بك'),
        backgroundColor: const Color(0xFFE65100),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? rawValue = barcode.rawValue;
            if (rawValue != null && rawValue.contains(':') && rawValue.contains('@')) {
              Navigator.pop(context, rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final String accountType;
  const LoginPage({super.key, required this.accountType});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!mounted || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ ما.';
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-email') {
        message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      } else if (e.code == 'network-request-failed') {
        message = 'مشكلة في الاتصال بالشبكة. يرجى المحاولة مرة أخرى.';
      } else if (e.code == 'too-many-requests') {
        message = 'تم حظر هذا الجهاز مؤقتًا بسبب كثرة محاولات الدخول الفاشلة.';
      } else {
        message = 'حدث خطأ غير متوقع (${e.code}).';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ غير متوقع. حاول مرة أخرى.'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTeacherCodeLoginDialog() {
    final TextEditingController codeCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.vpn_key_rounded, color: Color(0xFF0D47A1)),
                  SizedBox(width: 8),
                  Text('الدخول السريع (بالشفرة)'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('قم بإدخال الشفرة الخاصة بك للولوج إلى حسابك.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'الشفرة السرية', prefixIcon: Icon(Icons.password)),
                    keyboardType: TextInputType.text,
                  ),
                  if (_isLoading) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    final String enteredCode = codeCtrl.text.trim();
                    if (enteredCode.isEmpty) return;
                    setDialogState(() => _isLoading = true);
                    try {
                      final snap = await FirebaseFirestore.instance.collection('users')
                          .where('shared_code', isEqualTo: enteredCode)
                          .where('shared_code_enabled', isEqualTo: true)
                          .limit(1).get();

                      if (snap.docs.isNotEmpty) {
                        final data = snap.docs.first.data();

                        final dynamic emailRaw = data['email'] ?? data['Email'] ?? data['user_email'];
                        final dynamic passRaw = data['pp'] ?? data['Password'] ?? data['password'] ?? data['pass'];

                        final String? email = emailRaw?.toString().trim();
                        final String? pp = passRaw?.toString().trim();

                        if (email != null && email.isNotEmpty && pp != null && pp.isNotEmpty) {
                          await _auth.signInWithEmailAndPassword(email: email, password: pp);

                          if (mounted) {
                            Navigator.pop(ctx);
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                          return;
                        }
                      }

                      final guestDoc = await FirebaseFirestore.instance.collection('settings').doc('guest_access').get();
                      if (guestDoc.exists && guestDoc.data() != null) {
                        final guestData = guestDoc.data()!;
                        final String? sharedCode = guestData['shared_code']?.toString().trim();
                        final bool sharedEnabled = guestData['shared_code_enabled'] ?? false;

                        if (sharedEnabled && sharedCode == enteredCode) {
                          final String? gEmail = guestData['email']?.toString().trim() ?? guestData['Email']?.toString().trim();
                          final String? gPass = guestData['pp']?.toString().trim() ?? guestData['Password']?.toString().trim();

                          if (gEmail != null && gPass != null) {
                            await _auth.signInWithEmailAndPassword(email: gEmail, password: gPass);

                            if (mounted) {
                              Navigator.pop(ctx);
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            }
                            return;
                          }
                        }
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الشفرة غير صحيحة، أو غير مفعلة، أو بيانات الحساب المرتبط بها غير مكتملة.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) setDialogState(() => _isLoading = false);
                    }
                  },
                  child: const Text('دخول الآن'),
                )
              ],
            )
        )
    );
  }

  void _scanStudentBarcodeLogin() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanBarcodePage()));
    if (result != null && result is String && result.contains(':')) {
      setState(() => _isLoading = true);
      try {
        final parts = result.split(':');
        await _auth.signInWithEmailAndPassword(email: parts[0].trim(), password: parts[1].trim());
        if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الباركود غير صالح أو حساب الطالب غير موجود'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.accountType == 'teacher';
    final portalName = isTeacher ? 'بوابة المعلمين والإداريين' : 'بوابة الطلاب وأولياء الأمور';
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = math.min(screenWidth * 0.4, 150.0).clamp(100.0, 150.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                              tooltip: 'الرجوع',
                            ),
                          ],
                        ),

                        Image.asset('assets/m1.png', height: logoSize, width: logoSize, errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.school, size: logoSize, color: Theme.of(context).primaryColor.withOpacity(0.5));
                        }),
                        const SizedBox(height: 24),
                        Text(portalName,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
                        const SizedBox(height: 32),

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
                          validator: (value) => (value == null || value.isEmpty || !value.contains('@')) ? 'الرجاء إدخال بريد إلكتروني صحيح' : null,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_outline)),
                          validator: (value) => (value == null || value.isEmpty) ? 'الرجاء إدخال كلمة المرور' : null,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(onPressed: _signIn, child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 18))),
                        ),

                        const SizedBox(height: 24),
                        const Divider(thickness: 1),
                        const SizedBox(height: 16),

                        if (isTeacher)
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                              ),
                              onPressed: _isLoading ? null : _showTeacherCodeLoginDialog,
                              icon: const Icon(Icons.vpn_key_rounded),
                              label: const Text('الدخول باستخدام الشفرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),

                        if (!isTeacher)
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade800,
                                side: BorderSide(color: Colors.orange.shade800, width: 2),
                              ),
                              onPressed: _isLoading ? null : _scanStudentBarcodeLogin,
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              label: const Text('الدخول السريع بالباركود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// REGISTRATION FLOW
// ===========================================================================

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حالة الحساب')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text('حسابك قيد المراجعة', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text('تم إرسال بياناتك للإدارة بنجاح. يرجى الانتظار حتى يتم قبول طلبك لتتمكن من الدخول للبوابة.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async => await FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج والعودة للرئيسية'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({super.key});

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    if (selectedRole == 'teacher') return const TeacherRegistrationForm();
    if (selectedRole == 'student') return const StudentRegistrationForm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('استكمال التسجيل'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut(), tooltip: 'إلغاء وتسجيل خروج')],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('أهلاً بك! يبدو أنك تسجل دخولك لأول مرة.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text('يرجى تحديد صفتك في المدرسة لاستكمال بياناتك:', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoleCard(context, title: 'معلم', icon: Icons.person, color: Colors.blue, onTap: () => setState(() => selectedRole = 'teacher')),
                  const SizedBox(width: 20),
                  _buildRoleCard(context, title: 'طالب', icon: Icons.child_care, color: Colors.orange, onTap: () => setState(() => selectedRole = 'student')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherRegistrationForm extends StatefulWidget {
  const TeacherRegistrationForm({super.key});

  @override
  State<TeacherRegistrationForm> createState() => _TeacherRegistrationFormState();
}

class _TeacherRegistrationFormState extends State<TeacherRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameCtrl = TextEditingController();
  final _secondNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();

  String? _selectedStage;
  List<String> _selectedClasses = [];

  final List<String> stages = ['الصفوف الأولية', 'الصفوف العليا'];
  final List<String> availableClasses = ['1/أ', '1/ب', '2/أ', '2/ب', '3/أ', '3/ب', '4/أ', '5/أ', '6/أ'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المرحلة')));
      return;
    }
    if (_selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار فصل واحد على الأقل')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، فقدت جلسة الاتصال. يرجى تسجيل الدخول مجدداً')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pending_teachers').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'firstName': _firstNameCtrl.text.trim(),
        'secondName': _secondNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'fullName': '${_firstNameCtrl.text.trim()} ${_secondNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'idNumber': _idNumberCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'jobTitle': _jobTitleCtrl.text.trim(),
        'stage': _selectedStage,
        'classes': _selectedClasses,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات المعلم الجديد'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pushReplacementNamed('/registration')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text('يرجى تعبئة جميع البيانات بدقة ليتم مراجعتها من قبل الإدارة', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_firstNameCtrl, 'الاسم الأول')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_secondNameCtrl, 'الاسم الثاني')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_lastNameCtrl, 'الاسم الأخير')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_idNumberCtrl, 'رقم الهوية', isNumber: true),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneCtrl, 'رقم الهاتف', isNumber: true),
                      const SizedBox(height: 16),
                      _buildTextField(_jobTitleCtrl, 'الوظيفة (مثال: معلم رياضيات)'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'المرحلة الدراسية'),
                        value: _selectedStage,
                        items: stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _selectedStage = v),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الفصول التي تدرسها:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 8,
                              children: availableClasses.map((c) {
                                final isSelected = _selectedClasses.contains(c);
                                return FilterChip(
                                  label: Text(c),
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedClasses.add(c);
                                      } else {
                                        _selectedClasses.remove(c);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(onPressed: _submit, child: const Text('إرسال الطلب للإدارة')),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
    );
  }
}

class StudentRegistrationForm extends StatefulWidget {
  const StudentRegistrationForm({super.key});

  @override
  State<StudentRegistrationForm> createState() => _StudentRegistrationFormState();
}

class _StudentRegistrationFormState extends State<StudentRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameCtrl = TextEditingController();
  final _secondNameCtrl = TextEditingController();
  final _thirdNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();

  String? _selectedGrade;
  String? _selectedClass;

  final List<String> grades = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس'];
  final List<String> classes = ['أ', 'ب', 'ج'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGrade == null || _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الصف والفصل')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، فقدت جلسة الاتصال. يرجى تسجيل الدخول مجدداً')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pending_students').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'firstName': _firstNameCtrl.text.trim(),
        'secondName': _secondNameCtrl.text.trim(),
        'thirdName': _thirdNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'fullName': '${_firstNameCtrl.text.trim()} ${_secondNameCtrl.text.trim()} ${_thirdNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'idNumber': _idNumberCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'grade': _selectedGrade,
        'classRoom': _selectedClass,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات الطالب الجديد'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pushReplacementNamed('/registration')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text('يرجى تعبئة جميع البيانات بدقة ليتم مراجعتها من قبل الإدارة', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_firstNameCtrl, 'الاسم الأول')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_secondNameCtrl, 'الاسم الثاني')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_thirdNameCtrl, 'الاسم الثالث')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_lastNameCtrl, 'الاسم الأخير')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_idNumberCtrl, 'رقم الهوية', isNumber: true),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneCtrl, 'رقم هاتف ولي الأمر', isNumber: true),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'الصف الدراسي'),
                              value: _selectedGrade,
                              items: grades.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _selectedGrade = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'الفصل'),
                              value: _selectedClass,
                              items: classes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _selectedClass = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(onPressed: _submit, child: const Text('إرسال الطلب للإدارة')),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
    );
  }
}

// ===========================================================================
// TELEGRAM STORAGE ENGINE
// ===========================================================================

class TelegramConfig {
  static const String admissionBotToken = '8501072733:AAGm1XR1Iq1RXPb2OPEEDGelfsJNkqLKj6E';
  static const String admissionChatId = '-1003992521099';

  static const String portfolioBotToken = '8661424787:AAGoQP8pp4gTXxbgVVU6uRGNe_KNALCho6w';
  static const String portfolioChatId = '-3918816164';
}

class TelegramStorage {
  static Future<String?> uploadDocument(Uint8List bytes, String fileName, String caption, {bool isPortfolio = false}) async {
    String token = isPortfolio ? TelegramConfig.portfolioBotToken : TelegramConfig.admissionBotToken;
    String targetChatId = isPortfolio ? TelegramConfig.portfolioChatId : TelegramConfig.admissionChatId;

    String safeName = fileName.contains('.') ? fileName : '$fileName.jpg';
    var uri = Uri.parse('https://api.telegram.org/bot$token/sendDocument');
    var request = http.MultipartRequest('POST', uri)
      ..fields['chat_id'] = targetChatId
      ..fields['caption'] = caption
      ..files.add(http.MultipartFile.fromBytes('document', bytes, filename: safeName));
    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        var json = jsonDecode(responseData);
        return json['result']['document']['file_id'];
      }
    } catch (e) {
      debugPrint("Telegram Upload Error: $e");
    }
    return null;
  }

  static Future<String?> getFileUrl(String fileId, {bool isPortfolio = false}) async {
    if (fileId.startsWith('http')) return fileId;
    String token = isPortfolio ? TelegramConfig.portfolioBotToken : TelegramConfig.admissionBotToken;

    var uri = Uri.parse('https://api.telegram.org/bot$token/getFile?file_id=$fileId');
    try {
      var response = await http.get(uri);
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        String filePath = json['result']['file_path'];
        return 'https://api.telegram.org/file/bot$token/$filePath';
      }
    } catch (e) {
      debugPrint("Telegram getFile Error: $e");
    }
    return null;
  }

  static Future<bool> sendMessage(String message, {bool isPortfolio = false}) async {
    String token = isPortfolio ? TelegramConfig.portfolioBotToken : TelegramConfig.admissionBotToken;
    String targetChatId = isPortfolio ? TelegramConfig.portfolioChatId : TelegramConfig.admissionChatId;

    var uri = Uri.parse('https://api.telegram.org/bot$token/sendMessage');
    try {
      var response = await http.post(uri, body: {
        'chat_id': targetChatId,
        'text': message,
        'parse_mode': 'HTML',
        'disable_web_page_preview': 'true',
      });
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Telegram sendMessage Error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Telegram sendMessage Error: $e");
      return false;
    }
  }
}

class SmartTelegramImage extends StatefulWidget {
  final String fileId;
  final BoxFit fit;
  final bool isPortfolio;
  const SmartTelegramImage({super.key, required this.fileId, this.fit = BoxFit.cover, this.isPortfolio = false});

  @override
  State<SmartTelegramImage> createState() => _SmartTelegramImageState();
}

class _SmartTelegramImageState extends State<SmartTelegramImage> {
  String? _url;
  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    String? url = await TelegramStorage.getFileUrl(widget.fileId, isPortfolio: widget.isPortfolio);
    if (mounted && url != null) {
      setState(() {
        _url = kIsWeb ? 'https://api.codetabs.com/v1/proxy/?quest=${Uri.encodeComponent(url)}' : url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) return const Center(child: CircularProgressIndicator());
    return Image.network(_url!, fit: widget.fit, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
  }
}
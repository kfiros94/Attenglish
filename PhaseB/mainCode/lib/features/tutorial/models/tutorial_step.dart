import 'package:flutter/material.dart';

/// Position for the tooltip relative to the highlighted area
enum TooltipPosition {
  top,
  bottom,
  left,
  right,
  center,
}

/// A single step in the tutorial flow
class TutorialStep {
  /// Unique identifier for this step
  final String id;

  /// The GlobalKey of the widget to highlight (null for welcome/center messages)
  final GlobalKey? targetKey;

  /// Title of the tooltip (short, friendly)
  final String title;

  /// Main message (clear, under 50 words)
  final String message;

  /// Hebrew title for RTL support
  final String? titleHe;

  /// Hebrew message for RTL support
  final String? messageHe;

  /// Where to position the tooltip
  final TooltipPosition tooltipPosition;

  /// Optional icon to show in tooltip
  final IconData? icon;

  /// Whether this is a welcome/intro step (no highlight, centered)
  final bool isWelcomeStep;

  /// Whether this is the final step
  final bool isFinalStep;

  /// Custom action when step is shown (e.g., scroll to widget)
  final VoidCallback? onStepShow;

  const TutorialStep({
    required this.id,
    this.targetKey,
    required this.title,
    required this.message,
    this.titleHe,
    this.messageHe,
    this.tooltipPosition = TooltipPosition.bottom,
    this.icon,
    this.isWelcomeStep = false,
    this.isFinalStep = false,
    this.onStepShow,
  });

  /// Get localized title
  String getTitle(bool isRTL) => isRTL && titleHe != null ? titleHe! : title;

  /// Get localized message
  String getMessage(bool isRTL) => isRTL && messageHe != null ? messageHe! : message;
}

/// Pre-defined tutorial steps for Students
class StudentTutorialSteps {
  static List<TutorialStep> getSteps({
    GlobalKey? lessonsKey,
    GlobalKey? progressKey,
    GlobalKey? profileKey,
  }) {
    return [
      // Step 1: Welcome
      const TutorialStep(
        id: 'student_welcome',
        title: 'Welcome to Attenglish!',
        message: 'Ready to learn English in a fun way?\n\nLet me show you around. It only takes 1 minute.',
        titleHe: 'ברוכים הבאים לאטנגליש!',
        messageHe: 'מוכנים ללמוד אנגלית בדרך כיפית?\n\nבואו אראה לכם את המקום. זה לוקח רק דקה.',
        icon: Icons.waving_hand,
        isWelcomeStep: true,
        tooltipPosition: TooltipPosition.center,
      ),

      // Step 2: Lesson Cards
      TutorialStep(
        id: 'student_lessons',
        targetKey: lessonsKey,
        title: 'Your Lessons',
        message: 'This is your home.\n\nTap any lesson card to start learning.\nEach card shows what you\'ll practice.',
        titleHe: 'השיעורים שלך',
        messageHe: 'זה הבית שלך.\n\nלחץ על כרטיס שיעור כדי להתחיל ללמוד.\nכל כרטיס מראה מה תתרגל.',
        icon: Icons.school,
        tooltipPosition: TooltipPosition.bottom,
      ),

      // Step 3: Doing Activities
      const TutorialStep(
        id: 'student_activities',
        title: 'Doing Activities',
        message: 'Each lesson has fun activities.\n\nTake your time. There\'s no rush.\nAnswer when you\'re ready.',
        titleHe: 'ביצוע פעילויות',
        messageHe: 'כל שיעור מכיל פעילויות כיפיות.\n\nקח את הזמן שלך. אין לחץ.\nענה כשאתה מוכן.',
        icon: Icons.edit_note,
        isWelcomeStep: true,
        tooltipPosition: TooltipPosition.center,
      ),

      // Step 4: Earning Points
      const TutorialStep(
        id: 'student_points',
        title: 'Earning Points',
        message: 'You earn XP points for every activity!\n\nThe better you do, the more points you get.\nWatch your score grow!',
        titleHe: 'צבירת נקודות',
        messageHe: 'אתה צובר נקודות XP על כל פעילות!\n\nככל שתצליח יותר, תקבל יותר נקודות.\nצפה בניקוד שלך גדל!',
        icon: Icons.stars,
        isWelcomeStep: true,
        tooltipPosition: TooltipPosition.center,
      ),

      // Step 5: Final
      const TutorialStep(
        id: 'student_complete',
        title: 'You\'re all set!',
        message: 'You know the basics now.\n\nTap the ? button anytime for help.\nNow go learn something awesome!',
        titleHe: 'אתה מוכן!',
        messageHe: 'אתה מכיר את הבסיס עכשיו.\n\nלחץ על כפתור ? בכל עת לעזרה.\nעכשיו לך ללמוד משהו מדהים!',
        icon: Icons.celebration,
        isWelcomeStep: true,
        isFinalStep: true,
        tooltipPosition: TooltipPosition.center,
      ),
    ];
  }
}

/// Pre-defined tutorial steps for Teachers
class TeacherTutorialSteps {
  static List<TutorialStep> getSteps({
    GlobalKey? aiGeneratorKey,
    GlobalKey? classroomsKey,
    GlobalKey? progressKey,
    GlobalKey? createLessonKey,
    GlobalKey? libraryKey,
  }) {
    return [
      // Step 1: Welcome
      const TutorialStep(
        id: 'teacher_welcome',
        title: 'Welcome to Attenglish!',
        message: 'Let\'s get you set up to teach.\n\nI\'ll show you the main features.\nTakes about 2 minutes.',
        titleHe: 'ברוכים הבאים לאטנגליש!',
        messageHe: 'בואו נכין אתכם להוראה.\n\nאראה לכם את התכונות העיקריות.\nלוקח כ-2 דקות.',
        icon: Icons.waving_hand,
        isWelcomeStep: true,
        tooltipPosition: TooltipPosition.center,
      ),

      // Step 2: AI Generator
      TutorialStep(
        id: 'teacher_ai',
        targetKey: aiGeneratorKey,
        title: 'AI Generator',
        message: 'Short on time? Let AI help!\n\nThe AI Generator creates activities for you.\nJust describe what you want to teach.',
        titleHe: 'מחולל AI',
        messageHe: 'אין לך זמן? תן ל-AI לעזור!\n\nמחולל ה-AI יוצר פעילויות בשבילך.\nפשוט תאר מה אתה רוצה ללמד.',
        icon: Icons.auto_awesome,
        tooltipPosition: TooltipPosition.bottom,
      ),

      // Step 3: Classrooms
      TutorialStep(
        id: 'teacher_classrooms',
        targetKey: classroomsKey,
        title: 'My Classrooms',
        message: 'Your classrooms are here.\n\nAdd students, organize classes, and\nassign lessons to specific groups.',
        titleHe: 'הכיתות שלי',
        messageHe: 'הכיתות שלך נמצאות כאן.\n\nהוסף תלמידים, ארגן כיתות, והקצה\nשיעורים לקבוצות ספציפיות.',
        icon: Icons.school,
        tooltipPosition: TooltipPosition.bottom,
      ),

      // Step 4: Student Progress
      TutorialStep(
        id: 'teacher_progress',
        targetKey: progressKey,
        title: 'Student Progress',
        message: 'See how your students are doing.\n\nView scores, completed lessons, and\nidentify who needs extra help.',
        titleHe: 'התקדמות תלמידים',
        messageHe: 'ראה איך התלמידים שלך מתקדמים.\n\nצפה בציונים, שיעורים שהושלמו,\nוזהה מי צריך עזרה נוספת.',
        icon: Icons.analytics,
        tooltipPosition: TooltipPosition.bottom,
      ),

      // Step 5: Create Lesson
      TutorialStep(
        id: 'teacher_create',
        targetKey: createLessonKey,
        title: 'Create Lesson',
        message: 'Tap here to create a new lesson.\n\nYou\'ll add a title, content, and activities.\nIt\'s easy - just follow the steps.',
        titleHe: 'צור שיעור',
        messageHe: 'לחץ כאן ליצירת שיעור חדש.\n\nתוסיף כותרת, תוכן ופעילויות.\nזה קל - פשוט עקוב אחרי השלבים.',
        icon: Icons.edit_note,
        tooltipPosition: TooltipPosition.bottom,
      ),

      // Step 6: Content Library
      TutorialStep(
        id: 'teacher_library',
        targetKey: libraryKey,
        title: 'Content Library',
        message: 'All your lessons are saved here.\n\nEdit, reuse, or share your content.\nBuild your teaching library over time.',
        titleHe: 'ספריית תכנים',
        messageHe: 'כל השיעורים שלך נשמרים כאן.\n\nערוך, השתמש שוב, או שתף תוכן.\nבנה את ספריית ההוראה שלך לאורך זמן.',
        icon: Icons.library_books,
        tooltipPosition: TooltipPosition.bottom,
      ),

      // Step 7: Final
      const TutorialStep(
        id: 'teacher_complete',
        title: 'You\'re ready to teach!',
        message: 'You know the basics now.\n\nTip: Start by creating a classroom,\nthen add your first lesson.\n\nTap ? anytime for help.',
        titleHe: 'אתה מוכן ללמד!',
        messageHe: 'אתה מכיר את הבסיס עכשיו.\n\nטיפ: התחל ביצירת כיתה,\nואז הוסף את השיעור הראשון שלך.\n\nלחץ ? בכל עת לעזרה.',
        icon: Icons.celebration,
        isWelcomeStep: true,
        isFinalStep: true,
        tooltipPosition: TooltipPosition.center,
      ),
    ];
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'فلوسي';

  @override
  String get trackSpending => 'تتبع نفقاتك بحكمة';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get noAccount => 'ليس لديك حساب؟ ';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordDescription =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لاستعادة حسابك.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get sendLink => 'إرسال الرابط';

  @override
  String get passwordResetSent =>
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني!';

  @override
  String get pleaseEnterEmail => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get pleaseEnterValidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordTooShort => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get joinCommunity => 'انضم إلى مجتمعنا من المنفقين الحكماء';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get pleaseEnterName => 'يرجى إدخال اسمك';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get accountCreated => 'تم إنشاء الحساب بنجاح!';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get transactions => 'المعاملات';

  @override
  String get reports => 'التقارير';

  @override
  String get budget => 'الميزانية';

  @override
  String get debts => 'الديون';

  @override
  String get subscriptions => 'الاشتراكات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get totalBalance => 'إجمالي الرصيد';

  @override
  String get income => 'الدخل';

  @override
  String get expenses => 'المصاريف';

  @override
  String get recentTransactions => 'المعاملات الأخيرة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get addTransaction => 'إضافة معاملة';

  @override
  String get amount => 'المبلغ';

  @override
  String get category => 'الفئة';

  @override
  String get date => 'التاريخ';

  @override
  String get note => 'ملاحظة (اختياري)';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get lyd => 'د.ل';

  @override
  String get noTransactions => 'لا توجد معاملات بعد';

  @override
  String get selectCategory => 'اختر الفئة';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get welcomeBack => 'مرحباً بك،';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get spent => 'تم صرفه';

  @override
  String get remaining => 'متبقي';

  @override
  String setLimit(Object period) {
    return 'تحديد سقف $period';
  }

  @override
  String periodLimit(Object period) {
    return 'سقف $period';
  }

  @override
  String get daily => 'يومي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get monthly => 'شهري';

  @override
  String get allTransactions => 'كل المعاملات';

  @override
  String spentColon(Object amount) {
    return 'تم صرف: $amount د.ل';
  }

  @override
  String get cash => 'نقداً';

  @override
  String get card => 'بطاقة';

  @override
  String get transfer => 'تحويل';

  @override
  String todayAt(Object time) {
    return 'اليوم، $time';
  }

  @override
  String yesterdayAt(Object time) {
    return 'أمس، $time';
  }

  @override
  String get expense => 'مصروف';

  @override
  String get editTransaction => 'تعديل المعاملة';

  @override
  String get addIncome => 'إضافة دخل';

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get arabicScan => 'مسح عربي';

  @override
  String get latinScan => 'مسح لاتيني';

  @override
  String get aiExtract => 'استخراج بالذكاء الاصطناعي';

  @override
  String get descriptionHint => 'الوصف أو ملاحظات...';

  @override
  String get updateTransaction => 'تحديث المعاملة';

  @override
  String get saveTransaction => 'حفظ المعاملة';

  @override
  String get deleteTransaction => 'حذف المعاملة';

  @override
  String get deleteConfirmation => 'هل أنت متأكد من حذف هذه المعاملة؟';

  @override
  String get transactionSaved => 'تم حفظ المعاملة';

  @override
  String get transactionUpdated => 'تم تحديث المعاملة';

  @override
  String get transactionDeleted => 'تم حذف المعاملة';

  @override
  String get noTextFound => 'لم يتم العثور على نص في الصورة';

  @override
  String get noArabicTextFound => 'لم يتم العثور على نص عربي في الصورة';

  @override
  String ocrError(Object error) {
    return 'خطأ في التعرف على النص: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'خطأ في حفظ المعاملة: $error';
  }

  @override
  String errorDeleting(Object error) {
    return 'خطأ في حذف المعاملة: $error';
  }

  @override
  String get totalSaved => 'إجمالي المدخرات';

  @override
  String get activeGoals => 'الأهداف النشطة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get userName => 'اسم المستخدم';

  @override
  String get debtsAndLoans => 'الديون والقروض';

  @override
  String get recentDebts => 'الديون الأخيرة';

  @override
  String get noDebtsYet => 'لا توجد ديون مسجلة بعد';

  @override
  String get iOwe => 'عليّ ديون';

  @override
  String get owedToMe => 'ديون لي';

  @override
  String get markAsPaid => 'تحديد كمُسدد';

  @override
  String get markAsUnpaid => 'تحديد كغير مُسدد';

  @override
  String amountLyd(Object amount) {
    return '$amount د.ل';
  }

  @override
  String get yourSubscriptions => 'اشتراكاتك';

  @override
  String get noSubscriptionsYet => 'لا توجد اشتراكات بعد';

  @override
  String get totalMonthlyEst => 'إجمالي التقدير الشهري';

  @override
  String get active => 'نشط';

  @override
  String nextBilling(Object date) {
    return 'القادم: $date';
  }

  @override
  String get oneTime => 'لمرة واحدة';

  @override
  String get monthlyBudgets => 'الميزانيات الشهرية';

  @override
  String get totalMonthlyBudget => 'إجمالي الميزانية الشهرية';

  @override
  String get setMonthlyBudget => 'تحديد الميزانية الشهرية';

  @override
  String get budgetLimitLyd => 'سقف الميزانية (د.ل)';

  @override
  String setCategoryLimit(Object category) {
    return 'تحديد سقف $category';
  }

  @override
  String categoryBudgetLyd(Object category) {
    return 'ميزانية $category (د.ل)';
  }

  @override
  String get categories => 'الفئات';

  @override
  String get used => 'مستخدم';

  @override
  String get overBudget => 'تجاوز الميزانية';

  @override
  String get left => 'متبقي';

  @override
  String get aiInsightTitle => 'رؤى ذكية';

  @override
  String get projectedMonthly => 'التوقع الشهري';

  @override
  String get spentThisWeek => 'تم صرفه هذا الأسبوع';

  @override
  String get newSubscription => 'اشتراك جديد';

  @override
  String get serviceName => 'اسم الخدمة';

  @override
  String get serviceNameHint => 'مثال: نتفلكس، سبوتيفاي';

  @override
  String get billingAmount => 'مبلغ الفاتورة';

  @override
  String get recurring => 'متكرر';

  @override
  String get autoRenewalEnabled => 'التجديد التلقائي مفعّل';

  @override
  String get frequency => 'التكرار';

  @override
  String get currency => 'العملة';

  @override
  String get nextBillingDate => 'تاريخ الفاتورة القادمة';

  @override
  String get addSubscription => 'إضافة اشتراك';

  @override
  String get pleaseEnterServiceName => 'يرجى إدخال اسم الخدمة';

  @override
  String get addNewDebt => 'إضافة دين جديد';

  @override
  String get whoDoYouOwe => 'لمن تدين؟';

  @override
  String get whoOwesYou => 'من يدين لك؟';

  @override
  String get amountLydLabel => 'المبلغ (د.ل)';

  @override
  String get notes => 'ملاحظات';

  @override
  String get reminderDate => 'تاريخ التذكير';

  @override
  String get notSet => 'غير محدد';

  @override
  String get saveDebt => 'حفظ الدين';

  @override
  String get pleaseEnterValidPersonAndAmount =>
      'يرجى إدخال شخص/مكان ومبلغ صحيحين';

  @override
  String errorOccurred(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get security => 'الأمان';

  @override
  String get biometricLogin => 'تسجيل الدخول البيومتري';

  @override
  String get biometricLoginDesc =>
      'طلب التحقق ببصمة الإصبع أو الوجه عند فتح التطبيق';

  @override
  String get biometricNotAvailable =>
      'المصادقة البيومترية غير مهيأة على هذا الجهاز';

  @override
  String get biometricEnableFailed =>
      'تعذر تفعيل تسجيل الدخول البيومتري. يرجى المحاولة مرة أخرى.';

  @override
  String get biometricAuthFailed => 'فشل المصادقة. يرجى المحاولة مرة أخرى.';

  @override
  String get unlockApp => 'فتح التطبيق';

  @override
  String get unlockAppDesc => 'تحقق من هويتك للمتابعة';

  @override
  String get usePasswordInstead => 'استخدام كلمة المرور بدلاً من ذلك';

  @override
  String get spendingOverview => 'نظرة عامة على الإنفاق';

  @override
  String get showFullSpendingReports => 'عرض تقرير الإنفاق الكامل';

  @override
  String get viewFullReports => 'عرض التقارير الكاملة';

  @override
  String get noExpensesYet => 'لا توجد مصروفات بعد';

  @override
  String get total => 'الإجمالي';

  @override
  String get language => 'اللغة';

  @override
  String get languageDesc => 'اختر لغتك المفضلة';

  @override
  String get generateInsight => 'توليد رؤية';

  @override
  String get generatingInsight => 'جارٍ توليد الرؤية...';

  @override
  String get aiInsightEmpty =>
      'حلّل إنفاقك الأخير واحصل على توقّع بالذكاء الاصطناعي للأسبوع القادم.';
}

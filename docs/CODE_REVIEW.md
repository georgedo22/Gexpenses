# مراجعة الكود وتحسينات مقترحة — GExpenses

> مراجعة شاملة للمشروع من منظور Flutter Architecture + UI/UX.
> الحالة العامة: **مشروع نظيف ومنظم بشكل جيد فوق المعتاد** — المعمارية سليمة، سلامة البيانات مُعالَجة بجدية، وهناك نظام تصميم مركزي واختبارات فعلية. الملاحظات التالية هي تطويرات وصقل، وليس إصلاحات لمشاكل جوهرية.

---

## ✅ حالة التنفيذ (محدَّث)

نُفِّذت جميع الإصلاحات السريعة والمتوسطة:

| البند | الحالة |
|---|---|
| T1 مزودات التقارير بدل FutureBuilder | ✅ `dailyReportProvider` وأخواتها + حذف `reportsVersionProvider` |
| T2 انتظار التحديث عند السحب | ✅ `await ref.refresh(...future)` |
| T3 الفروقات بالسنتات | ✅ `adjustBalanceCentsInTx` |
| T4 التوطين عربي/إنجليزي + RTL | ✅ `AppLocalizationsAr` + `GlobalMaterial/Cupertino/WidgetsLocalizations` + كل النصوص المتناثرة + تواريخ محلية |
| T5 حوارات تمتلك متحكماتها | ✅ `EditBalanceDialog` / `IncomeEditorDialog` / `BudgetEditorDialog` |
| T6 `autoDispose` للبحث | ✅ |
| T7 `CurrencyFormatter` | ✅ جزئيًا (إصلاح RTL في `formatCompact`) — الترحيل الكامل إلى Notifier مُؤجَّل |
| T8 تفكيك الملفات الضخمة | ✅ `reports/tabs/*` + `widgets/charts/*` + استخراج الحوارات |
| T9 تسجيل الأخطاء + حماية `main` | ✅ `FlutterError.onError` + `PlatformDispatcher.onError` |
| T10 WAL + إزالة الكود الميت | ✅ |
| U1 العملة في الترحيب | ✅ |
| U2 توحيد نمط الحذف | ✅ (سحب = فوري + تراجع؛ زر صريح = حوار) |
| U3 CTA في الحالات الفارغة | ✅ |
| U4 تفاعل الرسوم البيانية | ✅ tooltips + لمس المخطط الدائري |
| U5 التنقل بالتواريخ | ✅ النقر على التسمية يفتح منتقي التاريخ |
| U6 ملخص الشهر في الرئيسية | ✅ `MonthSummaryCard` |
| U8 اهتزاز الحفظ | ✅ |
| U9 الوصولية | ✅ Semantics + ألوان فئات بتباين ≥3:1 |
| U10 اختصارات لوحة المفاتيح | ✅ Ctrl/Cmd+N — (restoration/go_router مُؤجَّل) |
| إشعارات الميزانية (U7) | ⏳ تحتاج إضافة plugin جديد — مُؤجَّل لخارطة الطريق |

---

## 1. نقاط القوة (لا تغيّرها)

| الجانب | التقييم |
|---|---|
| المعمارية (core / data / domain / l10n / presentation) | ✅ طبقات واضحة، DI عبر Riverpod، Repository يقرأ فقط والكتابة في Service (قرار مدروس وموثّق) |
| سلامة البيانات | ✅ كل تعديل يمسّ المصروف/الدخل والرصيد يتم داخل `runInTransaction` — لا يمكن أن ينفصلا |
| النقود | ✅ تخزين integer cents مع migration حقيقي v1→v2 في `onUpgrade` |
| نظام التصميم | ✅ `AppColors` / `AppTypography` / `AppMotion` مركزي + Material 3 مخصص في مكان واحد |
| الحركة | ✅ احترام `disableAnimations` (reduced motion) في كل الانتقالات، وstagger entrance محسوب |
| التوسع الأفقي | ✅ `EdgeInsetsDirectional` + `AlignmentDirectional` (تحضير ممتاز لـ RTL)، و`ResponsiveContent` + NavigationRail للشاشات الكبيرة |
| الاختبارات | ✅ تغطية جيدة لـ parser وطبقة البيانات بالكامل (transactions, migration, backup round-trip, reset) + smoke tests للشاشات |
| منع انجراف الفلوت | ✅ `parseAmountInput` يقبل الأرقام العربية/الفارسية (٠-٩ / ۰-۹) — تفصيلة احترافية |

---

## 2. الأولويات — نظرة سريعة

| # | الملاحظة | النوع | الأولوية |
|---|---|---|---|
| T1 | FutureBuilder في التقارير ينشئ Future جديدًا في كل rebuild | تقني | 🔴 عالية |
| T2 | `RefreshIndicator` لا ينتظر اكتمال التحديث | تقني | 🔴 عالية |
| T3 | فرق المبلغ عند التعديل يُحسب بـ double (خطر سنت واحد) | تقني | 🟠 متوسطة-عالية |
| T4 | التوطين (l10n) يدوي وإنجليزي فقط + نصوص متناثرة خارجه | تقني/UX | 🔴 عالية (للسوق العربي) |
| T5 | `TextEditingController` مسرب عمدًا في الحوارات | تقني | 🟠 متوسطة |
| U1 | العملة غير مطلوبة في مرحلة الترحيب | UX | 🟠 متوسطة |
| U2 | حذف بمزدوج: حوار تأكيد + زر تراجع | UX | 🟠 متوسطة |
| A1 | لا توجد Semantics/semanticLabel في المشروع كله | وصولية | 🔴 عالية |
| A2 | لون `bills` الأصفر `#FFE66D` تباينه ضعيف جدًا في الثيم الفاتح | وصولية | 🟠 متوسطة |
| S1 | لا يوجد تسجيل أخطاء (crash logging) | متانة | 🟠 متوسطة |

---

## 3. الملاحظات التقنية (Code / Architecture)

### T1 — مشكلة FutureBuilder الكلاسيكية في شاشة التقارير 🔴
**الملف:** `lib/presentation/screens/reports/reports_screen.dart`

```dart
// _ReportView — الـ future يُنشأ في build() ثم يُعاد إنشاؤه في أي rebuild:
_ReportView<DailyReport>(
  future: service.getDailyReport(date), // ⚠️ future جديد في كل build!
  ...
)
```

أي إعادة بناء (تبديل تبويب، `setState` لتغيير التاريخ، تغيير الثيم، invalidation) تنشئ Future جديدًا → إعادة استعلام القاعدة + وميض (flicker) في القوائم. مع أنكم تستخدمون Riverpod بالفعل، فالحل الأمثل هو مزودات عائلية للتقارير:

```dart
final dailyReportProvider =
    FutureProvider.autoDispose.family<DailyReport, DateTime>((ref, date) {
  return ref.watch(reportServiceProvider).getDailyReport(date);
});
// في الواجهة:
final reportAsync = ref.watch(dailyReportProvider(date));
```

وهذا يلغي الحاجة إلى `reportsVersionProvider` و`reportKey` بالكامل (تحديث تلقائي عبر `invalidate`)، ويمنع إعادة الجلب عند rebuilds غير الضرورية. البديل الأقل جذرية: تخزين الـ Future في `State` عبر `didUpdateWidget`.

### T2 — السحب للتحديث لا ينتظر التحديث 🔴
**الملف:** `lib/presentation/screens/home/home_screen.dart`

```dart
onRefresh: () async {
  ref.invalidate(recentExpensesProvider);   // لا ننتظر!
  ref.invalidate(currentBalanceProvider);
  ref.invalidate(isLowBalanceProvider);
},
```

مؤشر التحديث يختفي قبل وصول البيانات الجديدة. كما أن القائمة غير متسقة: `monthSummaryProvider` و`filteredExpensesProvider` لا يتجددان. الحل:

```dart
onRefresh: () async {
  invalidateExpenseProviders(ref); // كل شيء
  await Future.wait([
    ref.refresh(recentExpensesProvider.future),
    ref.refresh(currentBalanceProvider.future),
    ref.refresh(initialBalanceProvider.future),
    ref.refresh(isLowBalanceProvider.future),
  ]);
},
```

### T3 — فرق المبلغ عند التعديل: احسب بالسنتات لا بالـ double 🟠
**الملف:** `lib/domain/services/expense_service.dart`

```dart
final difference = newExpense.amount - oldExpense.amount; // double ⚠️
await _db.adjustBalanceInTx(txn, -difference);
```

النطاق الأدنى يخزّن cents، لكن الفرق يمر عبر double ثم يُعاد تقريبه. الأدق حساب الفرق كأعداد صحيحة مباشرة (لا يمكن أن ينجرف أبدًا):

```dart
final diffCents = newExpense.amountCents - oldExpense.amountCents;
if (diffCents != 0) await _db.adjustBalanceCentsInTx(txn, -diffCents);
```

(ينطبق ذاته على `addExpense`/`deleteExpense`: تمرير `amountCents` إلى `adjustBalanceInTx` بدل double). مع أن `(x * 100).round()` يعالج معظم الحالات، فإن مسار double ذهابًا وإيابًا هو بالضبط نوع الانجراف الذي قمتم ببنية الطبقة لتجنبه.

### T4 — التوطين: أكبر فجوة استراتيجية 🔴 (خصوصًا للسوق العربي)
**الملف:** `lib/l10n/app_localizations.dart` + أماكن متفرقة

- `AppLocalizations` مكتوب يدويًا وإنجليزي فقط (`supportedLocales = [Locale('en')]`)، رغم أن التطبيق **يدعم بالفعل إدخال الأرقام العربية** (`amount_input.dart`) وقائمة العملات تضم ₦ و SYP و د.إ و ﷼.
- نصوص **خارج** نظام l10n تماماً (ستظهر إنجليزي دائمًا حتى بعد التوطين):
  - `core/utils/date_helper.dart`: `'Today'`, `'Yesterday'`, `'$diff days ago'`
  - `presentation/widgets/period_navigator.dart`: `tooltip: 'Previous'` / `'Next'`
  - `reports_screen.dart` (`_PieChartWidget`): `'Categories'`
  - `reports_screen.dart` (أسبوعي): `'Week of ... – ...'`
  - `domain/services/backup_service.dart`: fallback title `'Expense'`
  - أنماط تاريخ ثابتة بالإنجليزية: `DateFormat('EEE, MMM d, yyyy · h:mm a')` في `add_expense_screen.dart`، `DateFormat('EEEE, MMMM d')` في `home_screen.dart`.

**التوصية:** الانتقال إلى التوطين الرسمي `flutter gen-l10n` مع ملفات `.arb` (en + ar) وتفعيل RTL تلقائيًا عبر `Locale('ar')`. عندئذٍ:
- استخدم `DateFormat.yMMMd(Localizations.localeOf(context).toString())` أو نمطًا محليًا بدل الأنماط المكتوبة يدويًا.
- حوّل `ExpenseCategory.label` (الإنجليزي المخزّن في `domain/enums/expense_category.dart`) إلى مفاتيح l10n — حاليًا اسم الفئة العرضي مرتبط بالإنجليزية في طبقة الـ domain.
- فعّل `intl` date initialization عبر `flutter_localizations` (مضاف أصلًا في pubspec لكن غير مستغل لأن اللغة الوحيدة en).

### T5 — تسريب `TextEditingController` المتعمّد 🟠
**الملف:** `settings_screen.dart` (`_showEditBalanceDialog`)، `income_screen.dart` (`showIncomeEditor`)

الكود يوثّق سبب عدم الاستدعاء dispose (حوار يُدمَّر بعد اكتمال `showDialog` أثناء animation الخروج). التراكم هنا حقيقي (متحكم لكل فتح حوار). الحل النظيف: جعل محتوى الحوار StatefulWidget يمتلك المتحكمات ويتخلص منها في `dispose` الخاص به:

```dart
class _EditBalanceDialog extends StatefulWidget { ... }
class _EditBalanceDialogState extends State<_EditBalanceDialog> {
  late final TextEditingController _controller = TextEditingController();
  @override
  void dispose() { _controller.dispose(); super.dispose(); } // آمن: يُدمر مع العنصر نفسه
  ...
}
```

### T6 — `filteredExpensesProvider` بدون `autoDispose`
كل استعلام بحث (كل ضغطة مفتاح بعد debounce) تنشئ إدخال `family` يبقى في الذاكرة إلى الأبد. أضف:

```dart
final filteredExpensesProvider =
    FutureProvider.autoDispose.family<List<Expense>, ExpenseFilter>(...)
```

المزودات العامة (`currentBalanceProvider` إلخ) منطقي أن تبقى عامة؛ أما العائلية فمرتبطة بجلسة استخدام مؤقتة.

### T7 — `CurrencyFormatter.symbol` حالة عامة قابلة للتعديل (static mutable)
يعمل، لكنه هشّ: أي واجهة تُبنى قبل/أثناء تغيير العملة قد تعرض رمزًا قديمًا، ولا يوجد مكان واحد يحدد "متى تتغير". الترقية الطبيعية مع Riverpod:

```dart
class CurrencyNotifier extends Notifier<String> { ... }
final currencyProvider = NotifierProvider<CurrencyNotifier, String>(...);
```

ويمكن الإبقاء على نفس واجهة `CurrencyFormatter.format()` كطبقة عرض فوق المزود. ملاحظة أصغر: `formatCompact` يركّب `'$symbol$value k'` يدويًا — مع رموز طويلة مثل `د.إ` أو RTL النتيجة قد تبدو `د.إ1.2k` بترتيب غير صحيح؛ استخدم `NumberFormat.compactCurrency`.

### T8 — تفكيك الملفات الضخمة
- `reports_screen.dart` — **1117 سطرًا**: `_Panel`، `_SummaryCard`، `_BarChartWidget`، `_PieChartWidget`، `_CategoryLegendItem` + 5 تبويبات في ملف واحد. اسحبها إلى `presentation/widgets/charts/` و`presentation/screens/reports/tabs/`.
- `settings_screen.dart` — **602 سطور** بها 3 حوارات كاملة + قائمة عملات مضمّنة في دالة. استخرج `settings/currency_picker.dart` و`settings/dialogs/*.dart`.
- `database_helper.dart` — 540 سطرًا يجمع CRUD + aggregates + tx-helpers. يمكن فصل `balance`/`budgets` إلى DAOs صغيرة، لكنه مقبول حاليًا.

### T9 — المتانة وتسجيل الأخطاء
- `main()` لا يحمي `SharedPreferences.getInstance()` — فشل القراءة يمنع الإقلاع كليًا. لفّها في try/catch مع قيمة افتراضية `$`.
- لا يوجد `FlutterError.onError` أو `PlatformDispatcher.instance.onError`. على الأقل سجّلها عبر `debugPrint`/ملف؛ لاحقًا Sentry أو Firebase Crashlytics.
- `expense_tile.dart` يعرض `e.toString()` للمستخدم في SnackBar — وحّد على `l10n.errorGeneric` + `debugPrint` للتفاصيل (الممارسة المتبقية في باقي الشاشات).

### T10 — ملاحظات SQL صغيرة
- البحث `LIKE '%q%'` لا يستفيد من الفهارس — مقبول حتى الآن، وعند نمو البيانات فكّر في FTS5 virtual table.
- أضف `PRAGMA journal_mode = WAL` في `onConfigure` (بجانب `foreign_keys`) — تحسين ملموس لسرعة الكتابة على الأجهزة الضعيفة.
- `importExpenses` تدرج كل الصفوف في transaction واحدة (جيد) لكن بلا حد أقصى لحجم الملف المُستورد — أضف تحققًا على حجم الملف قبل `utf8.decode`.

### T11 — تفاصيل صغيرة
- `Expense.fromJson` تعليقها يقول "decrypted/imported JSON" — لا يوجد تشفير في المشروع؛ احذف كلمة decrypted (doc bug).
- `MainScreen._buildScreens` يستدعي `ReportsScreen()` و`SettingsScreen()` بدون `const` (يمكن `const ReportsScreen()`).
- `analysis_options.yaml` يستخدم `flutter_lints` فقط. أضف على الأقل:
  `unawaited_futures`، `discarded_futures`، `prefer_final_locals`، `close_sinks` — كانت ستحجب مشكلة T1 مبكرًا. ويمكن تفعيل `strict-casts`/`strict-inference` من `package:lints/recommended.yaml` تدريجيًا.
- `database_helper.updateExpense/insertExpense` (خارج tx) صارت غير مستخدمة بعد نقل الكتابة إلى Service — احذفها لتقليل سطح الهجوم على الاتساق، أوعلّمها `@visibleForTesting`.

---

## 4. ملاحظات UI/UX

### U1 — اطلب العملة في مرحلة الترحيب 🟠
`SetBalanceScreen` يطلب الرصيد فقط، والعملة الافتراضية `$` مخفية في الإعدادات. المستخدم في نيجيريا/الخليج/مصر سيشوف `$` في كل مكان قبل أن يكتشف الإعدادات. أضف اختيار العملة (dropdown أو bottom sheet مدمج) فوق حقل الرصيد في شاشة الترحيب — نفس الـ `currencies` map في `settings_screen` (انقلها إلى `core/constants/currencies.dart` واستخدمها في المكانين).

### U2 — الحذف: حوار تأكيد + تراجع = احتكاك مزدوج 🟠
`ExpenseTile` يعرض `confirmDismiss` (حوار) ثم بعد الحذف SnackBar بزر تراجع. النمط Material الموصى به: **تراجع فقط** (الحذف فوري مع إمكانية التراجع — أسرع بكثير في الاستخدام اليومي) أو **حوار فقط**. مع وجود transaction آمنة وإعادة إدراج في التراجع، التراجع وحده كافٍ وآمن.

### U3 — CTA ناقصة في الحالات الفارغة
`EmptyStateWidget` داخل التقارير (`_DailyTab`, `_WeeklyTab`...) لا يعرض زر "إضافة مصروف" — `onAddExpense` يُمرَّر للرئيسية فقط. أضف CTA في:
- التقرير اليومي/الأسبوعي الفارغ → "أضف مصروفًا اليوم"
- شاشة الميزانيات الفارغة (يوجد — جيد ✅)

### U4 — الرسوم البيانية بلا تفاعل
`BarTouchData(enabled: false)` و`PieChartSectionData(title: '')`. تفعيل tooltips في fl_chart يحوّل المخطط من "صورة" إلى "أداة استكشاف" (fl_chart يدعم tooltip بسيط عبر `BarTouchTooltipData`). وفي المخطط الدائري: اجعل اللمس يبرز الفئة وقيمتها في المركز بدل عداد "Categories".

### U5 — التنقل بين الفترات
- اضغط على **تسمية** التاريخ نفسها (مثل "Week of ...") لفتح date picker للانتقال المباشر — 12 ضغطة سهم للوصول لسنة назад مرهقة.
- `add_expense_screen._pickDate`: تاريخ ثم وقت في حوارين متتاليين — Material 3 يوفر تجربة أفضل (`showDatePicker` + `showTimePicker` في حوار واحد، أو حقل dateTime موحد). كما أن `lastDate: DateTime.now()` يمنع المصروفات المستقبلية (إذا كان مقصودًا فتوثيقه؛ الميزانية المجدولة مستقبلًا ستحتاجه).
- تبويب Custom: استخدم `showDateRangePicker` المدمج بدل منتقيين منفصلين إن لم تكن قد استخدمتَه.

### U6 — أثري الرئيسية
`monthSummaryProvider` (دخل/مصروف/صافي الشهر) مُعرَّف ومحدَّث لكن لا يظهر في الرئيسية. بطاقة "ملخص الشهر" أسفل بطاقة الرصيد سترد على السؤال الأول لكل مستخدم مصروفات: **"كم بقي هذا الشهر؟"**. واقتراح ثانٍ: أعلى فئة إنفاق هذا الشهر بمؤشر صغير.

### U7 — التنبيهات الاستباقية
`isNearLimit` (80%) و`isLowBalance` (20%) موجودان في المنطق لكن لا يشعر بهما المستخدم إلا بزيارة الشاشات. إشعار محلي واحد (`flutter_local_notifications`) عند عبور العتبة — أو على الأقل شارة/بانر في الرئيسية — سيرفع القيمة المُدركة للتطبيق بشكل كبير.

### U8 — لمسات إحساسية
- `HapticFeedback.lightImpact()` عند حفظ المصروف/تراجع عن الحذف.
- اهتزاز خفيف عند تجاوز الميزانية (تحذير).

### U9 — إمكانية الوصولية (Accessibility) 🔴
- **لا توجد `Semantics`/`semanticLabel` في المشروع كله** (الاستثناء الوحيد: tooltips). تحديدًا:
  - المخططات البيانية: `Semantics(label: 'Bar chart of daily spending…', child: ...)` أو `ExcludeSemantics` + وصف نصي ملخص بجانبها.
  - `AnimatedAmount`: أضف `Semantics(label: CurrencyFormatter.format(value))` — قارئ الشاشة يقرأ الرقم أثناء الـ tween رقمًا رقمًا.
  - `_CategoryTile`/`ExpenseTile`: دمج القراءة في عنصر واحد (العنوان + الفئة + التاريخ + المبلغ) عبر `MergeSemantics`.
- **تباين الألوان:** `AppColors.bills = #FFE66D` كلون أيقونة/نص على أبيض = تباين ≈ 1.3:1 (فشل WCAG AA). استخدم درجة أغمق للثيم الفاتح (مثلًا `#A16207` أو `#B45309`) مع إبقاء الأصفر الفاتح للداكن. راجع كذلك `entertainment #FF9F43` (تباين حدّي ≈ 2.2:1).
- **مقياس النص:** ارتفاعات ثابتة (`_CategoryTile` = 86، NavigationBar = 68، `_SaveBar` = 54، `AnimatedAmount` داخل `FittedBox` — الأخير ممتاز ✅) قد تقصّ النص عند textScale = 200%. جرّب `flutter run --dart-define=DEBUG_TEXT_SCALE=2.0` أو اختبار `textScaleFactor` في الـ widget tests.

### U10 — تجربة متعددة المنصات
التطبيق يُبنى على 6 منصات لكن:
- لا **اختصارات لوحة مفاتيح** على سطح المكتب (Ctrl+N مصروف جديد، Ctrl+F بحث، Ctrl+Z تراجع حذف).
- لا **restoration**: `_currentIndex` وتاريخ التقرير المحدد يضيعان عند إعادة التشغيل — `RestorationMixin` (مهم للويب وسطح المكتب).
- على الويب: لا يوجد router (`go_router`) → لا deep links ولا روابط `/reports` قابلة للمشاركة. ليس عاجلًا لكنه يحسن الويب.

### U11 — اقتراحات منتجية (خارطة المنتج)
1. **مصروفات متكررة** (اشتراك شهري) — الطلب الأكثر شيوعًا في تطبيقات المصروفات.
2. **تصدير التقارير** كصورة/PDF (زر مشاركة في التقارير — `share_plus` موجود أصلًا).
3. **ميزانيات ذكية:** اقتراح حد شهري اعتمادًا على متوسط آخر 3 أشهر (البيانات متوفرة في `ReportService`).
4. **الاستيراد لا يوفّق الرصيد** (قرار موثّق ومدروس ✅) — لكن أضف خيارًا في شاشة نتيجة الاستيراد: "تحديث الرصيد ليشمل المستورد؟ نعم/لا" لتقليل الالتباس.
5. Widget للشاشة الرئيسية (home screen widget) يعرض الرصيد — ميزة مميزة على Android/iOS.

---

## 5. الأداء

| النقطة | التقييم |
|---|---|
| فهارس `date_time`/`category` | ✅ موجودة |
| استعلامات مجمّعة (N+1 مُصلَح في الأسبوعي) | ✅ موثّق في الكود |
| IndexedStack يحفظ حالة التبويبات | ✅ |
| تخزين مؤقت لـ `NumberFormat` | ✅ |
| `RepaintBoundary` حول المخططات | ⚠️ مفقود — أضفه حول `PieChart`/`BarChart` (إعادة رسم متكررة عند animations) |
| WAL mode | ⚠️ مفقود (انظر T10) |
| إعادة جلب غير ضرورية (T1) | ⚠️ أكبر مصدر هدر حاليًا |

---

## 6. الاختبارات والـ CI

**الحصيلة الحالية جيدة** (parser + data layer كاملة + smoke tests). المطلوب إضافيًا:

1. **Unit tests لـ `ReportService`**: حدود الأسبوع الذي يمتد على شهرين، `changePercent` عند صفر، `CustomReport.dayCount`، التقرير الشهري مع دخل.
2. **Golden tests** للثيمين (فاتح/داكن) للمكونات الرئيسية: `BalanceCard`, `ExpenseTile`, `_CategoryTile` — تمنع انزلاقات التصميم.
3. **`integration_test`** واحد على الأقل: تدفق "ترحيب → إضافة مصروف → الرصيد ينخفض → تراجع".
4. **اختبارات الوصولية:** `meetsGuideline(textContrastGuideline)` و`androidTapTargetGuideline` في widget tests — ستقف على مشكلة `bills` الأصفر تلقائيًا.
5. في الـ CI أضف: `flutter analyze --fatal-infos` و`dart format --set-exit-if-changed .` (ملف `analyze_result.txt` فارغ حاليًا).
6. اختبر textScale 1.5 و2.0 في smoke tests.

---

## 7. خارطة طريق مقترحة

### سريع (يوم عمل)
- [ ] T1: تحويل تقارير FutureBuilder إلى `FutureProvider.family` (يحذف `reportsVersionProvider`)
- [ ] T2: `onRefresh` يستنى البيانات
- [ ] T3: حساب الفروقات بالسنتات
- [ ] T6: `autoDispose` على `filteredExpensesProvider`
- [ ] A2: تصحيح لون `bills` (و`entertainment`) للثيم الفاتح
- [ ] Semantics لبطاقة الرصيد والمخططات
- [ ] تنظيف النصوص المتناثرة إلى l10n (`DateHelper`, tooltips, 'Categories')

### متوسط (2–5 أيام)
- [ ] T4: `flutter gen-l10n` + ar/en + RTL (مع تحويل `ExpenseCategory.label` إلى مفاتيح)
- [ ] U1: اختيار العملة في الترحيب
- [ ] U2: توحيد نمط الحذف (تراجع فقط)
- [ ] T5: حوارات بـ StatefulWidget تمتلك المتحكمات
- [ ] T8: تفكيك `reports_screen.dart` و`settings_screen.dart`
- [ ] U4: tooltips تفاعلية للرسوم البيانية
- [ ] U6: بطاقة ملخص الشهر في الرئيسية
- [ ] T9: `FlutterError.onError` + حماية `main()`

### استراتيجي (أسبوع+)
- [ ] U7: إشعارات الميزانية/الرصيد المنخفض
- [ ] U10: اختصارات لوحة المفاتيح + restoration + go_router للويب
- [ ] Golden + integration tests + a11y guidelines في CI
- [ ] U11: المصروفات المتكررة، تصدير التقارير، الاقتراحات الذكية

---

*أُعدّت هذه المراجعة بناءً على قراءة كاملة لـ `lib/` (7,657 سطرًا) و`test/` و`pubspec.yaml`.*

// Numbers for the child's home screen, from parent_child_overview (supabase/030_parent_ratings_next_lesson.sql)
// or, for a signed-in child, child_home (033_shop_and_child_accounts.sql), which adds their shop orders.

class ChildStats {
  final int balance;
  final int earned;
  final int lessonsAttended;
  final int attendancePercent; // of held lessons; 0 before the first one
  final int streak; // present in a row, newest first; excused absences don't break it
  final int greatClasses; // teacher rated the class "great" (3)
  final int planDone;
  final int planTotal;
  final Map<String, dynamic>? nextLesson; // {lesson_date, start_time, end_time, course}
  final List<Map<String, dynamic>> recentCoins;
  final List<Map<String, dynamic>> orders; // newest first; parents' overview has none
  final int reserved; // coins kept for orders not handed over yet

  int get free => balance - reserved;

  const ChildStats({
    required this.balance,
    required this.earned,
    required this.lessonsAttended,
    required this.attendancePercent,
    required this.streak,
    required this.greatClasses,
    required this.planDone,
    required this.planTotal,
    required this.nextLesson,
    required this.recentCoins,
    required this.orders,
    required this.reserved,
  });

  factory ChildStats.fromOverview(Map<String, dynamic> o, DateTime now) {
    final coins = List<Map<String, dynamic>>.from(o['coins'] as List);
    final attendance = List<Map<String, dynamic>>.from(o['attendance'] as List)
      ..sort((a, b) => (b['lessons']['lesson_date'] as String).compareTo(a['lessons']['lesson_date'] as String));
    final present = attendance.where((a) => a['present'] == true).length;

    var streak = 0;
    for (final a in attendance) {
      if (a['present'] == true) {
        streak++;
      } else if (a['absence_excused'] != true) {
        break;
      }
    }

    final planIds = (o['plan'] as List).map((l) => l['id']).toSet();
    final doneIds = (o['done_lesson_ids'] as List).toSet();
    final orders = List<Map<String, dynamic>>.from((o['orders'] ?? const []) as List);

    return ChildStats(
      balance: coins.fold(0, (sum, t) => sum + (t['amount'] as int)),
      earned: coins.fold(0, (sum, t) => sum + ((t['amount'] as int) > 0 ? t['amount'] as int : 0)),
      lessonsAttended: present,
      attendancePercent: attendance.isEmpty ? 0 : (present * 100 / attendance.length).round(),
      streak: streak,
      greatClasses: attendance.where((a) => a['class_rating'] == 3).length,
      planDone: planIds.intersection(doneIds).length,
      planTotal: planIds.length,
      nextLesson: List<Map<String, dynamic>>.from(
        o['upcoming'] as List,
      ).where((l) => lessonEnd(l).isAfter(now)).firstOrNull,
      recentCoins: coins.take(5).toList(), // already newest first
      orders: orders,
      reserved: orders.where((x) => x['status'] == 'pending').fold(0, (sum, x) => sum + (x['price'] as int)),
    );
  }
}

// shortcut: device time, not Asia/Yerevan like the website; fine while every family is in Armenia
DateTime lessonEnd(Map<String, dynamic> l) {
  final time = (l['end_time'] ?? l['start_time'] ?? '23:59') as String;
  return DateTime.parse('${l['lesson_date']}T$time');
}

DateTime lessonStart(Map<String, dynamic> l) => DateTime.parse('${l['lesson_date']}T${l['start_time'] ?? '00:00'}');

// lesson on 2026-10-29, today 2026-10-27 -> 2
int daysUntil(DateTime lessonDay, DateTime now) => DateTime.utc(
  lessonDay.year,
  lessonDay.month,
  lessonDay.day,
).difference(DateTime.utc(now.year, now.month, now.day)).inDays;

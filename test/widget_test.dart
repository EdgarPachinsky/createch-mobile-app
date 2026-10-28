import 'package:createch_mobile/child_stats.dart';
import 'package:createch_mobile/login_screen.dart';
import 'package:createch_mobile/strings.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> visit(String date, {bool present = true, bool? excused, int? rating}) => {
  'present': present,
  'absence_excused': excused,
  'class_rating': rating,
  'lessons': {'lesson_date': date},
};

void main() {
  test('phone numbers sign in like on the website', () {
    expect(phoneLoginEmail('091 23 45 67'), '37491234567@phone.createch.invalid');
    expect(phoneLoginEmail('+374 91 234567'), '37491234567@phone.createch.invalid');
    expect(phoneLoginEmail('0037491234567'), '37491234567@phone.createch.invalid');
    expect(phoneLoginEmail('91234567'), '37491234567@phone.createch.invalid');
  });

  test('the login field picks email, parent phone or child login', () {
    expect(loginEmail(' Mom@Mail.com '), 'Mom@Mail.com');
    expect(loginEmail('+374 (91) 23-45-67'), '37491234567@phone.createch.invalid');
    expect(loginEmail(' Aram.P '), 'aram.p@child.createch.invalid');
    expect(loginEmail('1234567'), '1234567@child.createch.invalid'); // too short for a phone
  });

  test('shop errors from the database', () {
    expect(shopErrorKey('Not enough TechCoins'), 'err_not_enough');
    expect(shopErrorKey('Sold out'), 'err_sold_out');
    expect(shopErrorKey('This item is not in the shop'), 'err_not_in_shop');
    expect(shopErrorKey('This order can no longer be cancelled'), 'err_cannot_cancel');
    expect(shopErrorKey('boom'), 'err_generic');
  });

  test('pending orders keep coins aside', () {
    final s = ChildStats.fromOverview({
      'coins': [
        {'amount': 100, 'reason': null, 'created_at': '2026-10-20T10:00:00Z'},
      ],
      'attendance': [],
      'plan': [],
      'done_lesson_ids': [],
      'upcoming': [],
      'orders': [
        {'price': 30, 'status': 'pending'},
        {'price': 20, 'status': 'pending'},
        {'price': 50, 'status': 'delivered'}, // already taken off as a coin row
        {'price': 70, 'status': 'cancelled'},
      ],
    }, DateTime(2026, 10, 27));
    expect((s.balance, s.reserved, s.free), (100, 50, 50));
  });

  test('stats from the parent overview', () {
    final s = ChildStats.fromOverview({
      'coins': [
        {'amount': 20, 'reason': 'x', 'created_at': '2026-10-20T10:00:00Z'},
        {'amount': -5, 'reason': 'y', 'created_at': '2026-10-10T10:00:00Z'},
      ],
      'attendance': [
        visit('2026-10-01', present: false), // unexcused: ends the streak
        visit('2026-10-20', rating: 3),
        visit('2026-10-13', present: false, excused: true), // excused: streak goes on
        visit('2026-10-08', rating: 2),
      ],
      'plan': [
        {'id': 'a'},
        {'id': 'b'},
        {'id': 'c'},
      ],
      'done_lesson_ids': ['a', 'z'],
      'upcoming': [
        {'lesson_date': '2026-10-27', 'start_time': '10:00:00', 'end_time': '11:00:00'}, // already over
        {'lesson_date': '2026-10-29', 'start_time': '10:00:00', 'end_time': null},
      ],
    }, DateTime(2026, 10, 27, 12));

    expect(s.balance, 15);
    expect(s.earned, 20);
    expect(s.lessonsAttended, 2);
    expect(s.attendancePercent, 50);
    expect(s.streak, 2);
    expect(s.greatClasses, 1);
    expect((s.planDone, s.planTotal), (1, 3));
    expect(s.nextLesson!['lesson_date'], '2026-10-29');
    expect(s.orders, isEmpty); // parents' overview has no orders
    expect(s.reserved, 0);
  });

  test('days until a lesson', () {
    final now = DateTime(2026, 10, 27, 23);
    expect(daysUntil(DateTime(2026, 10, 27, 10), now), 0);
    expect(daysUntil(DateTime(2026, 10, 28, 1), now), 1);
    expect(daysUntil(DateTime(2026, 11, 3), now), 7);
  });
}

import 'package:flutter/widgets.dart';

// UI text in Armenian (default) and English. t(context, ...) depends on the app's locale, so a language switch rebuilds it.
const _strings = <String, (String, String)>{
  'tagline': ('Սովորիր։ Կառուցիր։ Վաստակիր TechCoins։ 🚀', 'Learn. Build. Earn TechCoins! 🚀'),
  'lets_go': ('Գնացի՜նք 👋', "Let's go! 👋"),
  'login_hint': ('Մուտքանունն ու գաղտնաբառը կտան Createch-ում', 'Createch gives you your login and password'),
  'login_label': ('Մուտքանուն կամ հեռախոս', 'Login or phone'),
  'password': ('Գաղտնաբառ', 'Password'),
  'show_password': ('Ցույց տալ գաղտնաբառը', 'Show password'),
  'hide_password': ('Թաքցնել գաղտնաբառը', 'Hide password'),
  'sign_in': ('Մուտք', 'Sign in'),
  'sign_out': ('Ելք', 'Sign out'),
  'err_empty': ('Գրիր մուտքանունն ու գաղտնաբառը', 'Type your login and password'),
  'err_credentials': ('Սխալ մուտքանուն կամ գաղտնաբառ', 'Wrong login or password'),
  'err_network': ('Կապ չկա։ Ստուգիր ինտերնետը և նորից փորձիր', 'No connection. Check the internet and try again'),
  'err_generic': ('Ինչ-որ բան սխալ գնաց', 'Something went wrong'),
  'who_is_playing': ('Ո՞վ է խաղում 🎮', 'Who is playing? 🎮'),
  'no_kids': (
    'Այս հաշվին դեռ երեխա կցված չէ։\nԽնդրեք Createch-ին կցել։',
    'No children on this account yet.\nAsk Createch to link them.',
  ),
  'load_error': ('Չհաջողվեց բեռնել։ Ստուգիր ինտերնետը։', "Couldn't load. Check the internet."),
  'try_again': ('Կրկին փորձել', 'Try again'),
  'hi': ('Բարև, {name} 👋', 'Hi, {name}! 👋'),
  'class': ('{grade} դասարան', 'Class {grade}'),
  'my_coins': ('Իմ TechCoins-ը', 'My TechCoins'),
  'earned_total': ('Ընդամենը վաստակած՝ {n}', '{n} earned in total'),
  'reserved': ('🔒 {n}՝ պատվերների համար', '🔒 {n} kept for orders'),
  'next_lesson': ('Հաջորդ դասը 🚀', 'Next lesson 🚀'),
  'no_lessons': ('Դեռ դաս նախատեսված չէ։ Հանգստի ժամանակն է։', 'No lessons planned yet. Time to rest!'),
  'today': ('Այսօր', 'Today!'),
  'tomorrow': ('Վաղը', 'Tomorrow'),
  'in_days': ('{n} օրից', 'In {n} days'),
  'streak': ('Դաս անընդմեջ', 'Lessons in a row'),
  'attended': ('Հաճախած դաս', 'Lessons attended'),
  'attendance': ('Հաճախում', 'Attendance'),
  'super_classes': ('Սուպեր դասեր', 'Super classes'),
  'my_course': ('Իմ դասընթացը 🎮', 'My course 🎮'),
  'course_progress': ('Անցած դասեր՝ {done}/{total}', '{done} of {total} lessons done'),
  'course_done': (' — դասընթացն ավարտված է 🏆', ' — course complete! 🏆'),
  'shop': ('TechCoins խանութ 🛍️', 'TechCoins shop 🛍️'),
  'shop_title': ('Խանութ 🛍️', 'Shop 🛍️'),
  'open_shop': ('Բացել խանութը', 'Open the shop'),
  'more_to': ('Եվս {n} մետաղադրամ՝ {item}', '{n} more coins to {item}'),
  'can_get_all': ('Կարող ես վերցնել ամեն ինչ 🤩', 'You can get anything! 🤩'),
  'latest_coins': ('Վերջին մետաղադրամները', 'Latest coins'),
  'first_coins': ('Վաստակիր առաջին մետաղադրամները դասին 💪', 'Earn your first coins in class! 💪'),
  'great_job': ('Կեցցե՛ս', 'Great job!'),
  'spent': ('Ծախսված', 'Spent'),
  'cat_all': ('Բոլորը', 'All'),
  'cat_perks': ('Դասի արտոնություններ', 'Class perks'),
  'cat_digital': ('Թվային', 'Digital'),
  'cat_merch': ('Createch ապրանքներ', 'Createch merch'),
  'cat_big': ('Մեծ նպատակներ', 'Big goals'),
  'left': ('Մնաց {n}', '{n} left'),
  'until': ('Մինչև {date}', 'Until {date}'),
  'get_it': ('Վերցնել', 'Get it'),
  'confirm_title': ('Վերցնե՞լ՝ {item}', 'Get {item}?'),
  'confirm_body': (
    '{price} TechCoins կպահվի, մինչև ուսուցիչը տա քեզ նվերը։',
    '{price} TechCoins are kept for it until your teacher hands it over.',
  ),
  'yes_get': ('Այո, վերցնել', 'Yes, get it'),
  'cancel': ('Չեղարկել', 'Cancel'),
  'no': ('Ոչ', 'No'),
  'requested': ('Պատվերն ուղարկված է։ Ուսուցիչը շուտով կտա քեզ 🎉', 'Ordered! Your teacher will hand it over soon 🎉'),
  'my_orders': ('Իմ պատվերները', 'My orders'),
  'no_orders': ('Դեռ պատվեր չկա', 'No orders yet'),
  'status_pending': ('Սպասում է', 'Waiting'),
  'status_delivered': ('Ստացված', 'Received'),
  'status_cancelled': ('Չեղարկված', 'Cancelled'),
  'cancel_order': ('Չեղարկել պատվերը', 'Cancel the order'),
  'cancel_order_q': ('Չեղարկե՞լ՝ {item}', 'Cancel {item}?'),
  'order_cancelled': ('Պատվերը չեղարկված է', 'Order cancelled'),
  'free_coins': ('Ծախսելու համար՝ {n}', '{n} to spend'),
  'parent_view_only': ('Երեխան պատվիրում է իր սեփական հաշվից։', 'Your child orders from their own account.'),
  'shop_empty': ('Խանութը դեռ դատարկ է', 'The shop is empty for now'),
  'err_not_enough': ('Բավարար TechCoins չկա', 'Not enough TechCoins'),
  'err_sold_out': ('Վերջացել է', 'Sold out'),
  'err_not_in_shop': ('Այս նվերն այլևս խանութում չէ', 'This item is no longer in the shop'),
  'err_cannot_cancel': ('Այս պատվերն այլևս հնարավոր չէ չեղարկել', 'This order can no longer be cancelled'),
};

const _monthsHy = ['հնվ', 'փտր', 'մրտ', 'ապր', 'մյս', 'հնս', 'հլս', 'օգս', 'սեպ', 'հոկ', 'նոյ', 'դեկ'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdaysHy = ['Երկուշաբթի', 'Երեքշաբթի', 'Չորեքշաբթի', 'Հինգշաբթի', 'Ուրբաթ', 'Շաբաթ', 'Կիրակի'];
const _weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

bool isEnglish(BuildContext context) => Localizations.localeOf(context).languageCode == 'en';

// t(context, 'in_days', {'n': 3}) -> '3 օրից'
String t(BuildContext context, String key, [Map<String, Object> args = const {}]) {
  final pair = _strings[key]!;
  var text = isEnglish(context) ? pair.$2 : pair.$1;
  args.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
  return text;
}

String monthShort(BuildContext context, int month) => (isEnglish(context) ? _monthsEn : _monthsHy)[month - 1];

String weekdayName(BuildContext context, int weekday) => (isEnglish(context) ? _weekdaysEn : _weekdaysHy)[weekday - 1];

// '24 հոկ' / '24 Oct'
String shortDate(BuildContext context, DateTime d) => '${d.day} ${monthShort(context, d.month)}';

// the translation key for a shop error raised by the database (supabase/033_shop_and_child_accounts.sql)
String shopErrorKey(String message) => switch (message) {
  _ when message.contains('Not enough TechCoins') => 'err_not_enough',
  _ when message.contains('Sold out') => 'err_sold_out',
  _ when message.contains('not in the shop') => 'err_not_in_shop',
  _ when message.contains('can no longer be cancelled') => 'err_cannot_cancel',
  _ => 'err_generic',
};

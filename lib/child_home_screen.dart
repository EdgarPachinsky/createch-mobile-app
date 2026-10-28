import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'child_stats.dart';
import 'kids_screen.dart';
import 'settings.dart';
import 'shop_screen.dart';
import 'strings.dart';
import 'theme.dart';

class HomeData {
  final Map<String, dynamic> child; // full_name, grade, section, group_name
  final ChildStats stats;
  final List<Map<String, dynamic>> shopItems;
  const HomeData(this.child, this.stats, this.shopItems);
}

// A parent's child (a my_children row), or with null the signed-in child (child_home RPC).
Future<HomeData> loadHome(Map<String, dynamic>? parentsChild) async {
  final db = Supabase.instance.client;
  final Future<dynamic> overviewCall = parentsChild == null
      ? db.rpc('child_home')
      : db.rpc('parent_child_overview', params: {'p_child': parentsChild['id']});
  final (result, items) = await (overviewCall, loadShopItems()).wait;
  final overview = result as Map<String, dynamic>;
  return HomeData(
    parentsChild ?? overview['child'] as Map<String, dynamic>,
    ChildStats.fromOverview(overview, DateTime.now()),
    items,
  );
}

// The child's own page: TechCoins, next lesson, stats, course progress and the TechCoins shop.
class ChildHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? child; // a my_children row; null = the signed-in child's own page
  final bool canGoBack;
  const ChildHomeScreen({super.key, required this.child, required this.canGoBack});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  late Future<HomeData> _data = loadHome(widget.child);

  Future<void> _reload() {
    final next = loadHome(widget.child);
    setState(() {
      _data = next; // a block: setState must not return the Future
    });
    return next;
  }

  Future<void> _openShop(HomeData data) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopScreen(data: data, canBuy: widget.child == null, reload: () => loadHome(widget.child)),
      ),
    );
    if (mounted) _reload(); // orders made there change the coins here
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _data,
      builder: (context, snap) {
        if (snap.hasError) return ErrorView(onRetry: _reload);
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final d = snap.data!;
        final s = d.stats;
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              slivers: [
                _header(d.child),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.list(
                    children: [
                      _CoinCard(balance: s.balance, earned: s.earned, reserved: s.reserved),
                      const SizedBox(height: 16),
                      _NextLessonCard(lesson: s.nextLesson),
                      const SizedBox(height: 16),
                      _statsGrid(s),
                      const SizedBox(height: 16),
                      if (s.planTotal > 0) ...[
                        _CourseProgress(done: s.planDone, total: s.planTotal),
                        const SizedBox(height: 16),
                      ],
                      if (d.shopItems.isNotEmpty) ...[
                        _ShopPreview(items: d.shopItems, free: s.free, onOpen: () => _openShop(d)),
                        const SizedBox(height: 16),
                      ],
                      _RecentCoins(coins: s.recentCoins),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(Map<String, dynamic> child) {
    final name = child['full_name'] as String;
    final grade = child['grade'];
    final group = child['group_name'];
    final subtitle = [
      if (grade != null) t(context, 'class', {'grade': '$grade${child['section'] ?? ''}'}),
      ?group,
    ].join(' · ');
    return SliverAppBar(
      pinned: true,
      expandedHeight: 190,
      automaticallyImplyLeading: widget.canGoBack,
      foregroundColor: Colors.white,
      backgroundColor: violet,
      actions: const [
        SettingsButtons(color: Colors.white),
        SignOutButton(),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: funGradient),
          padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
          child: Row(
            children: [
              Avatar(name: name, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t(context, 'hi', {'name': name.split(' ').first}),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsGrid(ChildStats s) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    padding: EdgeInsets.zero, // otherwise it adds the top safe area again
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.5,
    children: [
      _StatTile(emoji: '🔥', value: '${s.streak}', label: t(context, 'streak'), color: pink),
      _StatTile(emoji: '✅', value: '${s.lessonsAttended}', label: t(context, 'attended'), color: mint),
      _StatTile(emoji: '📅', value: '${s.attendancePercent}%', label: t(context, 'attendance'), color: sky),
      _StatTile(emoji: '⭐', value: '${s.greatClasses}', label: t(context, 'super_classes'), color: gold),
    ],
  );
}

class Box extends StatelessWidget {
  final Widget child;
  final Color? color; // default: the theme's card colour
  final Gradient? gradient;
  const Box({super.key, required this.child, this.color, this.gradient});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color ?? cardColor(context),
      gradient: gradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: purple.withValues(alpha: isDark(context) ? 0.3 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class BoxTitle extends StatelessWidget {
  final String text;
  const BoxTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
}

class _CoinCard extends StatelessWidget {
  final int balance;
  final int earned;
  final int reserved;
  const _CoinCard({required this.balance, required this.earned, required this.reserved});

  @override
  Widget build(BuildContext context) => Box(
    gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFF9800)]),
    child: Row(
      children: [
        const Coin(size: 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(context, 'my_coins'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              // counts up from 0 every time the page opens
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: balance),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text(
                  '$v',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                ),
              ),
              Text(t(context, 'earned_total', {'n': earned}), style: const TextStyle(color: Colors.white)),
              if (reserved > 0)
                Text(t(context, 'reserved', {'n': reserved}), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    ),
  );
}

// a gold TechCoin; iOS draws the 🪙 emoji as a silver eagle coin
class Coin extends StatelessWidget {
  final double size;
  const Coin({super.key, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(colors: [Color(0xFFFFF176), gold, Color(0xFFF57C00)]),
      border: Border.all(color: const Color(0xFFFFE082), width: size / 16),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: size / 8, offset: Offset(0, size / 16))],
    ),
    child: Text(
      'T',
      style: TextStyle(fontSize: size * 0.55, fontWeight: FontWeight.bold, color: Colors.white, height: 1),
    ),
  );
}

class _NextLessonCard extends StatelessWidget {
  final Map<String, dynamic>? lesson;
  const _NextLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    if (l == null) {
      return Box(
        child: Row(
          children: [
            const Text('🏖️', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(child: Text(t(context, 'no_lessons'), style: const TextStyle(fontSize: 16))),
          ],
        ),
      );
    }
    final start = lessonStart(l);
    final days = daysUntil(start, DateTime.now());
    final when = days <= 0
        ? t(context, 'today')
        : days == 1
        ? t(context, 'tomorrow')
        : t(context, 'in_days', {'n': days});
    final time = [l['start_time'], l['end_time']].whereType<String>().map((t) => t.substring(0, 5)).join(' – ');
    return Box(
      child: Row(
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(gradient: funGradient, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Text(
                  monthShort(context, start.month),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${start.day}',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t(context, 'next_lesson'), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  when,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark(context) ? pink : violet),
                ),
                Text([weekdayName(context, start.weekday), if (time.isNotEmpty) time].join(' · ')),
                if (l['course'] != null)
                  Text('${l['course']}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  const _StatTile({required this.emoji, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Box(
    color: color.withValues(alpha: isDark(context) ? 0.25 : 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

class _CourseProgress extends StatelessWidget {
  final int done;
  final int total;
  const _CourseProgress({required this.done, required this.total});

  @override
  Widget build(BuildContext context) => Box(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoxTitle(t(context, 'my_course')),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: done / total,
            minHeight: 16,
            color: mint,
            backgroundColor: mint.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t(context, 'course_progress', {'done': done, 'total': total}) +
              (done == total ? t(context, 'course_done') : ''),
        ),
      ],
    ),
  );
}

class _ShopPreview extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int free;
  final VoidCallback onOpen;
  const _ShopPreview({required this.items, required this.free, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final byPrice = [...items]..sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
    final goal = byPrice.where((i) => (i['price'] as int) > free).firstOrNull;
    return Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BoxTitle(t(context, 'shop')),
          const SizedBox(height: 8),
          Text(
            goal == null
                ? t(context, 'can_get_all')
                : t(context, 'more_to', {
                    'n': (goal['price'] as int) - free,
                    'item': '${goal['emoji']} ${itemName(context, goal)}',
                  }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: byPrice.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = byPrice[i];
                final canAfford = free >= (item['price'] as int);
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onOpen,
                  child: Container(
                    width: 116,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: canAfford ? gold.withValues(alpha: 0.18) : softColor(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: canAfford ? gold : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['emoji']}', style: const TextStyle(fontSize: 30)),
                        Text(
                          itemName(context, item),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Price(price: item['price'] as int, locked: !canAfford),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpen,
              style: FilledButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.storefront),
              label: Text(t(context, 'open_shop'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// '🔒 120 (coin)'
class Price extends StatelessWidget {
  final int price;
  final bool locked;
  const Price({super.key, required this.price, this.locked = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('${locked ? '🔒 ' : ''}$price ', style: const TextStyle(fontWeight: FontWeight.bold)),
      const Coin(size: 16),
    ],
  );
}

class _RecentCoins extends StatelessWidget {
  final List<Map<String, dynamic>> coins;
  const _RecentCoins({required this.coins});

  @override
  Widget build(BuildContext context) => Box(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoxTitle(t(context, 'latest_coins')),
        if (coins.isEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t(context, 'first_coins'))),
        for (final c in coins)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text((c['amount'] as int) > 0 ? '🎉' : '🛒', style: const TextStyle(fontSize: 26)),
            title: Text((c['reason'] as String?) ?? t(context, (c['amount'] as int) > 0 ? 'great_job' : 'spent')),
            subtitle: Text(shortDate(context, DateTime.parse(c['created_at'] as String).toLocal())),
            trailing: Text(
              '${(c['amount'] as int) > 0 ? '+' : ''}${c['amount']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: (c['amount'] as int) > 0 ? Colors.green : Colors.redAccent,
              ),
            ),
          ),
      ],
    ),
  );
}

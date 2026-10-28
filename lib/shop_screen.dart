import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'child_home_screen.dart';
import 'settings.dart';
import 'strings.dart';
import 'theme.dart';

const shopCategories = ['perks', 'digital', 'merch', 'big'];

// What's in the shop today (shop_items, supabase/033_shop_and_child_accounts.sql), in the admins' order
Future<List<Map<String, dynamic>>> loadShopItems() async {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  try {
    return List<Map<String, dynamic>>.from(
      await Supabase.instance.client
          .from('shop_items')
          .select()
          .eq('active', true)
          .or('available_until.is.null,available_until.gte.$today')
          .order('sort', ascending: true),
    );
  } on PostgrestException {
    // shortcut: an empty shop until migration 033 has been run; drop the catch once it is everywhere
    return [];
  }
}

// an order keeps copies of the item's names from when it was asked for
String orderName(BuildContext context, Map<String, dynamic> order) =>
    (isEnglish(context) ? order['item_name_en'] as String? : null) ?? order['item_name'] as String;

String itemName(BuildContext context, Map<String, dynamic> item) =>
    (isEnglish(context) ? item['name_en'] as String? : null) ?? item['name'] as String;

String? itemDescription(BuildContext context, Map<String, dynamic> item) =>
    (isEnglish(context) ? item['description_en'] as String? : null) ?? item['description'] as String?;

// The whole shop by category. A signed-in child orders here; a parent only looks.
class ShopScreen extends StatefulWidget {
  final HomeData data;
  final bool canBuy;
  final Future<HomeData> Function() reload;
  const ShopScreen({super.key, required this.data, required this.canBuy, required this.reload});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late HomeData _data = widget.data;
  String? _category; // null = all
  bool _busy = false;

  Future<bool> _ask(String title, String body, String yes) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t(context, 'no'))),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(yes)),
          ],
        ),
      ) ??
      false;

  // runs an order RPC, says how it went and shows the fresh coins and orders
  Future<void> _run(String rpc, Map<String, dynamic> params, String done) async {
    setState(() => _busy = true);
    var result = done;
    try {
      await Supabase.instance.client.rpc(rpc, params: params);
    } on PostgrestException catch (e) {
      result = shopErrorKey(e.message);
    } catch (_) {
      result = 'err_network';
    }
    try {
      final fresh = await widget.reload();
      if (mounted) setState(() => _data = fresh);
    } catch (_) {} // the old numbers stay; pull to refresh on the home page
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(context, result))));
  }

  Future<void> _buy(Map<String, dynamic> item) async {
    final name = '${item['emoji']} ${itemName(context, item)}';
    if (await _ask(
      t(context, 'confirm_title', {'item': name}),
      t(context, 'confirm_body', {'price': item['price']}),
      t(context, 'yes_get'),
    )) {
      await _run('shop_request', {'p_item': item['id']}, 'requested');
    }
  }

  Future<void> _cancel(Map<String, dynamic> order) async {
    final name = '${order['emoji']} ${orderName(context, order)}';
    if (await _ask(t(context, 'cancel_order_q', {'item': name}), '', t(context, 'cancel_order'))) {
      await _run('shop_cancel', {'p_order': order['id']}, 'order_cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final free = _data.stats.free;
    final items = _data.shopItems.where((i) => _category == null || i['category'] == _category).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'shop_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: const [SettingsButtons()],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Box(
              gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFF9800)]),
              child: Row(
                children: [
                  const Coin(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.canBuy ? t(context, 'free_coins', {'n': free}) : t(context, 'parent_view_only'),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_busy)
                    const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in [null, ...shopCategories])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t(context, 'cat_${c ?? 'all'}')),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(t(context, 'shop_empty'), textAlign: TextAlign.center),
              ),
            for (final item in items) Padding(padding: const EdgeInsets.only(bottom: 12), child: _itemCard(item, free)),
            if (widget.canBuy) ...[
              const SizedBox(height: 8),
              BoxTitle(t(context, 'my_orders')),
              const SizedBox(height: 8),
              Box(
                child: _data.stats.orders.isEmpty
                    ? Text(t(context, 'no_orders'))
                    : Column(children: [for (final o in _data.stats.orders) _orderTile(o)]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> item, int free) {
    final price = item['price'] as int;
    final description = itemDescription(context, item);
    final until = item['available_until'] as String?;
    final badges = [
      if (item['stock'] != null) t(context, 'left', {'n': item['stock']}),
      if (until != null) t(context, 'until', {'date': shortDate(context, DateTime.parse(until))}),
    ];
    return Box(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: softColor(context), borderRadius: BorderRadius.circular(18)),
            child: Text('${item['emoji']}', style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemName(context, item), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (description != null)
                  Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final b in badges)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: pink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(b, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Price(price: price, locked: widget.canBuy && free < price),
                    const Spacer(),
                    if (widget.canBuy)
                      FilledButton(
                        onPressed: free >= price ? () => _buy(item) : null,
                        style: FilledButton.styleFrom(backgroundColor: violet, foregroundColor: Colors.white),
                        child: Text(t(context, 'get_it')),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> o) {
    final status = o['status'] as String;
    final color = switch (status) {
      'delivered' => mint,
      'pending' => gold,
      _ => Colors.grey,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text('${o['emoji']}', style: const TextStyle(fontSize: 26)),
      title: Text(orderName(context, o)),
      subtitle: Row(
        children: [
          Text('${shortDate(context, DateTime.parse(o['created_at'] as String).toLocal())} · ${o['price']} '),
          const Coin(size: 14),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
            child: Text(
              t(context, 'status_$status'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          if (status == 'pending')
            IconButton(tooltip: t(context, 'cancel_order'), icon: const Icon(Icons.close), onPressed: () => _cancel(o)),
        ],
      ),
    );
  }
}

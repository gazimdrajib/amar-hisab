import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/inventory_providers.dart';
import '../../providers/purchases_providers.dart';
import '../../providers/sales_providers.dart';
import '../../widgets/common.dart';

/// App settings: server URL, currency, default warehouse, account, sync.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

void _refreshCaches(WidgetRef ref) {
  ref.read(productListProvider.notifier).refresh();
  ref.read(salesListProvider.notifier).refresh();
  ref.read(purchasesListProvider.notifier).refresh();
  ref.invalidate(warehouseListProvider);
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlCtrl;
  late TextEditingController _currencyCtrl;
  bool _checking = false;
  String? _serverStatus;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider).value;
    _urlCtrl = TextEditingController(text: settings?.baseUrl ?? '');
    _currencyCtrl = TextEditingController(text: settings?.currency ?? '৳');
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    await ref.read(appSettingsProvider.notifier).setBaseUrl(_urlCtrl.text.trim());
    await ref.read(appSettingsProvider.notifier).setCurrency(_currencyCtrl.text.trim());
    if (mounted) showSnack(context, 'Settings saved');
  }

  Future<void> _checkServer() async {
    setState(() {
      _checking = true;
      _serverStatus = null;
    });
    try {
      final status = await ref.refresh(setupStatusProvider.future);
      setState(() => _serverStatus = status['reachable'] == true
          ? 'Connected — ${status['initialized'] == true ? 'initialized' : 'setup pending'}'
          : 'Server unreachable');
    } catch (_) {
      setState(() => _serverStatus = 'Server unreachable');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final auth = ref.watch(authProvider);
    final warehouses = ref.watch(warehouseListProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings.when(
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionTitle('Server'),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                helperText: 'Android emulator: http://10.0.2.2:8080',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton.tonalIcon(
                onPressed: _checking ? null : _checkServer,
                icon: const Icon(Icons.wifi_find),
                label: Text(_checking ? 'Checking…' : 'Test connection'),
              ),
              const SizedBox(width: 12),
              if (_serverStatus != null)
                Flexible(child: Text(_serverStatus!)),
            ]),
            const SizedBox(height: 24),
            const _SectionTitle('POS'),
            TextField(
              controller: _currencyCtrl,
              decoration: const InputDecoration(
                labelText: 'Currency symbol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_exchange),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: warehouses.any((w) => w.id == s.defaultWarehouseId)
                  ? s.defaultWarehouseId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Default warehouse',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warehouse_outlined),
              ),
              items: warehouses
                  .map((w) =>
                      DropdownMenuItem(value: w.id, child: Text(w.name)))
                  .toList(),
              onChanged: (v) => v == null
                  ? null
                  : ref
                      .read(appSettingsProvider.notifier)
                      .setDefaultWarehouse(v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child:
                  FilledButton.icon(onPressed: _saveAll, icon: const Icon(Icons.save), label: const Text('Save'))
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Account'),
            if (auth.session != null) ...[
              ListTile(
                leading: CircleAvatar(
                    child: Text(auth.session!.user.fullName.isNotEmpty
                        ? auth.session!.user.fullName[0]
                        : '?')),
                title: Text(auth.session!.user.fullName),
                subtitle: Text(
                    '@${auth.session!.user.username} · role ${auth.session!.user.roleName ?? auth.session!.user.roleId}'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const _SectionTitle('Sync'),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Refresh local cache'),
              subtitle: const Text('Products, sales, purchases, warehouses'),
              onTap: () async {
                _refreshCaches(ref);
                showSnack(context, 'Cache refreshed');
              },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

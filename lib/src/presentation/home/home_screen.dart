import 'package:crypto_position/src/presentation/home/exchange_account.dart';
import 'package:crypto_position/src/presentation/home/home_screen_wm.dart';
import 'package:crypto_position/src/presentation/home/widgets/all_balances_view.dart';
import 'package:crypto_position/src/presentation/home/widgets/close_positions_panel.dart';
import 'package:crypto_position/src/presentation/home/widgets/close_positions_sheets.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

class HomeScreen extends ElementaryWidget<HomeScreenWm> {
  HomeScreen({super.key})
    : super((context) => homeScreenWmFactory(context: context));

  @override
  Widget build(HomeScreenWm wm) {
    return ValueListenableBuilder<bool>(
      valueListenable: wm.hasAnyCredentials,
      builder: (context, hasCreds, _) {
        if (!hasCreds) {
          return const Center(
            child: Text('Подключите API ключ на вкладке Settings'),
          );
        }

        return ValueListenableBuilder<List<ExchangeAccount>>(
          valueListenable: wm.accounts,
          builder: (context, accounts, _) {
            if (accounts.isEmpty) {
              return ValueListenableBuilder<bool>(
                valueListenable: wm.loading,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const Center(child: Text('Нет данных'));
                },
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ValueListenableBuilder<Set<String>>(
                    valueListenable: wm.selectedKeys,
                    builder: (context, selected, _) => RefreshIndicator(
                      onRefresh: wm.refresh,
                      child: AllBalancesView(
                        accounts: accounts,
                        selectedKeys: selected,
                        onToggleSelection: wm.toggleSelection,
                      ),
                    ),
                  ),
                ),
                ClosePositionsPanel(
                  selectedKeys: wm.selectedKeys,
                  busy: wm.closeBusy,
                  progress: wm.closeProgress,
                  onCancelSelection: wm.clearSelection,
                  onAbort: wm.abortClose,
                  onClose: () => _closeSelected(context, wm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Plan → confirm → run → report. Nothing is sent until the user confirms the
  /// exact orders in the dialog.
  Future<void> _closeSelected(BuildContext context, HomeScreenWm wm) async {
    final items = await wm.planClose();
    if (items.isEmpty || !context.mounted) return;

    final confirmed = await showCloseConfirmation(context, items, wm.tuning);
    if (confirmed != true) return;

    await wm.executeClose(items);
    final report = wm.closeReport.value;
    if (report == null || !context.mounted) return;

    await showCloseReport(context, report);
  }
}

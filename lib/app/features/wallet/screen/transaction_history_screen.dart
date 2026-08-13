import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_studio/app/constant/resources/app_string.dart';
import 'package:the_builder_studio/app/core/base/base_view.dart';
import 'package:the_builder_studio/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_studio/app/features/wallet/model/wallet_transaction_history_model.dart';
import 'package:the_builder_studio/app/features/wallet/utility/wallet_ui_metrics.dart';
import 'package:the_builder_studio/app/widget/section_card.dart';

class WalletTransactionHistoryScreen extends BaseView<WalletController> {
  const WalletTransactionHistoryScreen({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppString.walletHistoryTitle)),
      body: SafeArea(
        child: Obx(() {
          final records = controller.history;
          if (records.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(WalletSpacing.lg),
              children: const [
                SectionCard(
                  title: AppString.walletHistoryTitle,
                  child: Text(AppString.walletNoHistory),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(WalletSpacing.lg),
            itemBuilder: (_, index) => _HistoryTile(record: records[index]),
            separatorBuilder: (_, _) =>
                const SizedBox(height: WalletSpacing.sm),
            itemCount: records.length,
          );
        }),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final WalletTransactionHistoryModel record;

  @override
  Widget build(BuildContext context) {
    final isSuccess = record.status == WalletTransactionStatus.success;
    final title = '${record.amount} ${record.assetCode}';
    final subtitle =
        '${_short(record.senderPublicKey)} -> ${_short(record.recipientPublicKey)}';

    return SectionCard(
      title: title,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: isSuccess
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(
          isSuccess
              ? AppString.walletTransactionSuccess
              : AppString.walletTransactionFailed,
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Detail(
                    AppString.walletRecipientLabel,
                    record.recipientPublicKey,
                  ),
                  _Detail(
                    AppString.walletPublicKeyLabel,
                    record.senderPublicKey,
                  ),
                  _Detail(AppString.walletNetworkLabel, record.network),
                  if (record.transactionHash?.isNotEmpty == true)
                    _Detail(
                      AppString.walletTransactionHashLabel,
                      record.transactionHash!,
                    ),
                  if (record.errorMessage?.isNotEmpty == true)
                    _Detail(AppString.walletErrorLabel, record.errorMessage!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _short(String value) {
    if (value.length <= 12) {
      return value;
    }
    return '${value.substring(0, 6)}...${value.substring(value.length - 6)}';
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WalletSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: WalletSpacing.xs),
          SelectableText(value),
        ],
      ),
    );
  }
}

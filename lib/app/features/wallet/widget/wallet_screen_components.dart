import 'package:flutter/material.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletStepIndicator extends StatelessWidget {
  const WalletStepIndicator({
    super.key,
    required this.current,
    required this.total,
    required this.label,
  });
  final int current;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: LinearProgressIndicator(
          value: current / total,
          minHeight: 8,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
      const SizedBox(width: 12),
      Text('$label • $current of $total'),
    ],
  );
}

class WalletActivationError extends StatelessWidget {
  const WalletActivationError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => message.isEmpty
      ? const SizedBox.shrink()
      : Text(
          message,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        );
}

class WalletBoundaryNotice extends StatelessWidget {
  const WalletBoundaryNotice({
    super.key,
    required this.icon,
    required this.text,
  });
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => WalletCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: AppColors.violet),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class WalletPreviewNotice extends StatelessWidget {
  const WalletPreviewNotice({super.key});

  @override
  Widget build(BuildContext context) => const WalletCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.science_outlined),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'UI preview only. Rewards activation and transfers are not connected yet.',
          ),
        ),
      ],
    ),
  );
}

class WalletActionCard extends StatelessWidget {
  const WalletActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 34, color: AppColors.violet),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    ),
  );
}

class WalletReviewRow extends StatelessWidget {
  const WalletReviewRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

class WalletHistoryItem extends StatelessWidget {
  const WalletHistoryItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(child: Icon(icon)),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: Text(amount, style: Theme.of(context).textTheme.titleMedium),
  );
}

import 'package:flutter/material.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';

class BuilderIdentityCard extends StatelessWidget {
  const BuilderIdentityCard.editable({
    super.key,
    required this.nameController,
    required this.phoneController,
    this.errorText = '',
    this.enabled = true,
  }) : name = null,
       phone = null,
       status = null,
       editable = true;

  const BuilderIdentityCard.summary({
    super.key,
    required this.name,
    required this.phone,
    this.status,
  }) : nameController = null,
       phoneController = null,
       errorText = '',
       enabled = false,
       editable = false;

  final TextEditingController? nameController;
  final TextEditingController? phoneController;
  final String? name;
  final String? phone;
  final String? status;
  final String errorText;
  final bool editable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.violetSoft,
                  child: Icon(Icons.person_outline, color: AppColors.violet),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Builder details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        editable
                            ? 'Used for your Rewards activation request.'
                            : 'Included in this activation request.',
                      ),
                    ],
                  ),
                ),
                if (status != null)
                  Chip(
                    label: Text(status!),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (editable) ...<Widget>[
              TextField(
                controller: nameController,
                enabled: enabled,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Builder name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                enabled: enabled,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number with country code',
                  hintText: '+95 ...',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              if (errorText.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  errorText,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ] else ...<Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined),
                title: Text(name ?? ''),
                subtitle: const Text('Builder name'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_outlined),
                title: Text(phone ?? ''),
                subtitle: const Text('Phone number'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

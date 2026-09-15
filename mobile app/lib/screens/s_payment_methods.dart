import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../widgets/common.dart';

/// Payment methods screen — saved cards, add new, billing history.
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String _defaultCard = 'visa-4242';

  static const _cards = <_Card>[
    _Card('visa-4242', 'Visa', '•••• •••• •••• 4242', '12/27', Icons.credit_card_rounded, RC.info),
    _Card('mc-5555', 'Mastercard', '•••• •••• •••• 5555', '08/26', Icons.credit_card_rounded, RC.danger),
    _Card('amex-3782', 'Amex', '•••• •••••• 3782', '03/28', Icons.credit_card_rounded, RC.teal),
  ];

  void _setDefault(String id) {
    setState(() => _defaultCard = id);
    toast(context, 'Default card updated',
        icon: Icons.check_circle_outline_rounded);
  }

  void _removeCard(String id) {
    setState(() => _defaultCard = _cards.firstWhere((c) => c.id != id).id);
    toast(context, 'Card removed', icon: Icons.delete_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: RC.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Payment Methods', style: RT.h2),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: RS.x8),

          // ---- Saved cards ----
          const SectionTitle('Saved Cards'),
          Padding(
            padding: RS.page,
            child: Column(
              children: [
                for (final card in _cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: RS.x12),
                    child: RCard(
                      padding: const EdgeInsets.all(RS.x16),
                      selected: card.id == _defaultCard,
                      child: Row(
                        children: [
                          IconBubble(card.icon,
                              tint: card.tint, size: 42, solid: card.id == _defaultCard),
                          const SizedBox(width: RS.x14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(card.brand, style: RT.title),
                                    const SizedBox(width: RS.x6),
                                    if (card.id == _defaultCard)
                                      const RBadge('Default', color: RC.teal),
                                  ],
                                ),
                                const SizedBox(height: RS.x4),
                                Text(card.number, style: RT.bodyStrong.copyWith(fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Expires ${card.expiry}', style: RT.captionSm),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded,
                                size: 20, color: RC.textTertiary),
                            onSelected: (value) {
                              if (value == 'default') _setDefault(card.id);
                              if (value == 'remove') _removeCard(card.id);
                            },
                            itemBuilder: (_) => [
                              if (card.id != _defaultCard)
                                const PopupMenuItem(
                                  value: 'default',
                                  child: Text('Set as default'),
                                ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove',
                                    style: TextStyle(color: RC.danger)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---- Add card ----
          Padding(
            padding: RS.page,
            child: RButton(
              'Add New Card',
              kind: RButtonKind.outline,
              expanded: true,
              icon: Icons.add_card_rounded,
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => Padding(
                    padding:
                        EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(RS.x20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Add a card', style: RT.h1),
                            const SizedBox(height: RS.x6),
                            const Text('Enter your card details below.',
                                style: RT.caption),
                            const SizedBox(height: RS.x20),
                            const RTextField(
                              label: 'Card Number',
                              hint: '•••• •••• •••• ••••',
                              icon: Icons.credit_card_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: RS.x14),
                            Row(
                              children: [
                                const Expanded(
                                  child: RTextField(
                                    label: 'Expiry Date',
                                    hint: 'MM/YY',
                                    keyboardType: TextInputType.datetime,
                                  ),
                                ),
                                const SizedBox(width: RS.x12),
                                const Expanded(
                                  child: RTextField(
                                    label: 'CVV',
                                    hint: '•••',
                                    obscure: true,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: RS.x14),
                            const RTextField(
                              label: 'Cardholder Name',
                              hint: 'Name on card',
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: RS.x20),
                            RButton(
                              'Save Card',
                              expanded: true,
                              icon: Icons.check_rounded,
                              onPressed: () {
                                Navigator.pop(ctx);
                                toast(context, 'Card added successfully',
                                    icon: Icons.check_circle_outline_rounded);
                              },
                            ),
                            const SizedBox(height: RS.x12),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: RS.x12),

          // ---- Billing history ----
          const SectionTitle('Billing History'),
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.symmetric(horizontal: RS.x16),
              child: Column(
                children: [
                  _billingRow('May 2025', 'Premium Plan', '\$29.99', RC.success),
                  const ThinDivider(inset: 50),
                  _billingRow('Apr 2025', 'Premium Plan', '\$29.99', RC.success),
                  const ThinDivider(inset: 50),
                  _billingRow('Mar 2025', 'Premium Plan', '\$29.99', RC.success),
                  const ThinDivider(inset: 50),
                  _billingRow('Feb 2025', 'Basic Plan', '\$9.99', RC.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x32),
        ],
      ),
    );
  }

  Widget _billingRow(String date, String desc, String amount, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RS.x12),
      child: Row(
        children: [
          IconBubble(Icons.receipt_long_outlined,
              tint: statusColor, size: 36),
          const SizedBox(width: RS.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: RT.title),
                const SizedBox(height: 2),
                Text(desc, style: RT.captionSm),
              ],
            ),
          ),
          Text(amount,
              style: RT.bodyStrong.copyWith(color: RC.navy)),
        ],
      ),
    );
  }
}

class _Card {
  const _Card(this.id, this.brand, this.number, this.expiry, this.icon, this.tint);
  final String id;
  final String brand;
  final String number;
  final String expiry;
  final IconData icon;
  final Color tint;
}

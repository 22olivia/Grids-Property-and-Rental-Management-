import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/models/models.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';

/// SCREEN 17 — CHOOSE YOUR PLAN
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _navIndex = 0;
  bool _yearly = false;
  String? _chosen;

  late Future<List<SubscriptionPlan>> _plans;

  @override
  void initState() {
    super.initState();
    _plans = Services.plans.plans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ResivynHeader(
              showBack: true,
              trailing: [
                GestureDetector(
                  onTap: () => toast(context, 'Billing history',
                      icon: Icons.receipt_long_outlined),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: RS.x14, vertical: RS.x10),
                    decoration: BoxDecoration(
                      color: RC.surface,
                      borderRadius: RR.chip,
                      border: Border.all(color: RC.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 14, color: RC.navy),
                        const SizedBox(width: RS.x6),
                        Text('billing'.tr(),
                            style: RT.captionSm.copyWith(
                              color: RC.navy,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            PageTitle(
              'choose_plan'.tr(),
              subtitle: 'select_best_plan'.tr(),
            ),

            // ---- Billing toggle ----
            Padding(
              padding: RS.page,
              child: RSegmented(
                items: const ['Monthly', 'Yearly (Save 20%)'],
                selectedIndex: _yearly ? 1 : 0,
                onChanged: (i) => setState(() => _yearly = i == 1),
              ),
            ),

            if (_yearly)
              Padding(
                padding: const EdgeInsets.fromLTRB(RS.x20, RS.x12, RS.x20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: RS.x14, vertical: RS.x10),
                  decoration: const BoxDecoration(
                    color: RC.successSoft,
                    borderRadius: RR.chip,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.savings_outlined,
                          size: 15, color: RC.success),
                      const SizedBox(width: RS.x8),
                      Expanded(
                        child: Text(
                          'save_yearly'.tr(),
                          style: RT.captionSm.copyWith(
                            color: RC.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: RS.x24),

            // ---- Plan cards ----
            FutureBuilder<List<SubscriptionPlan>>(
              future: _plans,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: RC.teal, strokeWidth: 2.5),
                    ),
                  );
                }
                final plans = snapshot.data!;
                return Padding(
                  padding: RS.page,
                  child: Column(
                    children: [
                      for (final plan in plans)
                        Padding(
                          padding: const EdgeInsets.only(bottom: RS.x16),
                          child: _PlanCard(
                            plan: plan,
                            yearly: _yearly,
                            chosen: _chosen == plan.name,
                            onChoose: () {
                              setState(() => _chosen = plan.name);
                              toast(context, '${plan.name} plan selected',
                                  icon: Icons.workspace_premium_outlined);
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // ---- Footer ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x8, RS.x20, 0),
              child: InfoBanner(
                title: 'all_plans_include'.tr(),
                body: 'plans_mobile_desc'.tr(),
                icon: Icons.phone_iphone_rounded,
                dark: true,
                ctaLabel: 'talk_to_sales'.tr(),
                onCta: () => Navigator.pushNamed(context, Routes.contact),
              ),
            ),

            const SizedBox(height: RS.x20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 13, color: RC.textTertiary),
                  const SizedBox(width: RS.x6),
                  Flexible(
                    child: Text('secure_payments'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RT.captionSm.copyWith(fontSize: 11)),
                  ),
                ],
              ),
            ),

            const BottomGutter(),
          ],
        ),
      ),

      bottomNavigationBar: ResivynBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.shell,
            (route) => route.settings.name == Routes.login,
            arguments: i,
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.yearly,
    required this.chosen,
    required this.onChoose,
  });

  final SubscriptionPlan plan;
  final bool yearly;
  final bool chosen;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final highlighted = plan.recommended;
    final price = yearly ? plan.yearlyPrice : plan.monthlyPrice;
    final unit = yearly ? '/ year' : '/ month';

    final fgTitle = highlighted ? Colors.white : RC.navy;
    final fgBody = highlighted ? Colors.white70 : RC.textSecondary;

    return Container(
      padding: const EdgeInsets.all(RS.x20),
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                colors: [RC.navy, RC.navySoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlighted ? null : RC.surface,
        borderRadius: RR.cardLg,
        border: Border.all(
          color: chosen ? RC.teal : (highlighted ? Colors.transparent : RC.border),
          width: chosen ? 1.8 : 1,
        ),
        boxShadow: highlighted ? RShadow.lifted : RShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  plan.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RT.label.copyWith(
                    color: highlighted ? RC.teal : RC.textTertiary,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const Spacer(),
              if (highlighted)
                RBadge('recommended'.tr(),
                    color: RC.teal, solid: true, uppercase: true),
              if (chosen && !highlighted)
                RBadge('selected'.tr(), color: RC.teal, uppercase: true),
            ],
          ),
          const SizedBox(height: RS.x8),
          Text(plan.tagline, style: RT.caption.copyWith(color: fgBody)),

          const SizedBox(height: RS.x16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'AED $price',
                  maxLines: 1,
                  style: RT.display.copyWith(color: fgTitle, fontSize: 30),
                ),
                const SizedBox(width: RS.x6),
                Text(unit,
                    maxLines: 1,
                    style: RT.caption.copyWith(color: fgBody)),
              ],
            ),
          ),

          const SizedBox(height: RS.x20),
          Divider(
            height: 1,
            color: highlighted ? Colors.white24 : RC.border,
          ),
          const SizedBox(height: RS.x16),

          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: RS.x10),
              child: Row(
                children: [
                  Icon(
                    feature.included
                        ? Icons.check_circle_rounded
                        : Icons.remove_circle_outline_rounded,
                    size: 17,
                    color: feature.included
                        ? RC.teal
                        : (highlighted ? Colors.white30 : RC.textTertiary),
                  ),
                  const SizedBox(width: RS.x10),
                  Expanded(
                    child: Text(
                      feature.label,
                      style: RT.body.copyWith(
                        color: feature.included
                            ? (highlighted ? Colors.white : RC.navy)
                            : (highlighted ? Colors.white38 : RC.textTertiary),
                        decoration: feature.included
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: RS.x12),
          RButton(
            chosen ? 'current_selection'.tr() : 'choose_plan_btn'.tr(),
            kind: chosen
                ? RButtonKind.soft
                : (highlighted ? RButtonKind.primary : RButtonKind.outline),
            expanded: true,
            icon: chosen ? Icons.check_rounded : null,
            onPressed: onChoose,
          ),
        ],
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/tokens.dart';
import 'resivyn_image.dart';

// ---------------------------------------------------------------------------
// Feedback helper — keeps every control in the app genuinely interactive.
// ---------------------------------------------------------------------------

void toast(BuildContext context, String message, {IconData? icon}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1600),
        content: Row(
          children: [
            Icon(icon ?? Icons.check_circle_outline, color: RC.teal, size: 18),
            const SizedBox(width: RS.x12),
            Expanded(
              child: Text(
                message,
                style: RT.bodyStrong.copyWith(color: Colors.white),
              ),
            ),
          ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Book Viewing — shared date / time picker sheet
// ---------------------------------------------------------------------------

void showBookViewingSheet(BuildContext context, {String? propertyTitle}) {
  final now = DateTime.now();
  final dates = List.generate(7, (i) => now.add(Duration(days: i)));
  const timeSlots = [
    '9:00 AM – 10:00 AM',
    '10:00 AM – 11:00 AM',
    '11:00 AM – 12:00 PM',
    '2:00 PM – 3:00 PM',
    '3:00 PM – 4:00 PM',
    '4:00 PM – 5:00 PM',
  ];
  const available = [true, true, true, false, true, true];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String monthShort(int m) => months[m - 1];
  String fmtDate(DateTime d) => '${monthShort(d.month)} ${d.day}, ${d.year}';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      int selectedDate = 0;
      int selectedSlot = -1;
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) => ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(RS.x20),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: RC.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: RS.x16),
                Row(
                  children: [
                    const IconBubble(Icons.event_available_rounded,
                        tint: RC.teal, size: 44),
                    const SizedBox(width: RS.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('book_a_viewing'.tr(), style: RT.h2),
                          const SizedBox(height: 2),
                          Text(
                            propertyTitle ?? 'schedule_property_visit'.tr(),
                            style: RT.captionSm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RS.x16),
                const ThinDivider(),

                const SizedBox(height: RS.x12),
                Text('select_date'.tr(), style: RT.title),
                const SizedBox(height: RS.x8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: RS.x8),
                    itemBuilder: (_, i) {
                      final d = dates[i];
                      final isSel = i == selectedDate;
                      final dayName = i == 0
                          ? 'Today'
                          : (i == 1 ? 'Tmrw' : _bWeekday(d.weekday));
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedDate = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 64,
                          decoration: BoxDecoration(
                            color: isSel ? RC.teal : RC.surface,
                            borderRadius: RR.chip,
                            border: Border.all(
                              color: isSel ? RC.teal : RC.border,
                            ),
                            boxShadow: isSel ? RShadow.teal : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: RT.captionSm.copyWith(
                                  color: isSel
                                      ? Colors.white70
                                      : RC.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: RS.x4),
                              Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      isSel ? Colors.white : RC.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                monthShort(d.month),
                                style: RT.captionSm.copyWith(
                                  color: isSel
                                      ? Colors.white70
                                      : RC.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: RS.x16),
                Text('available_time_slots'.tr(), style: RT.title),
                const SizedBox(height: RS.x8),
                for (var s = 0; s < timeSlots.length; s++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: RS.x8),
                    child: GestureDetector(
                      onTap: available[s]
                          ? () => setSheetState(() => selectedSlot = s)
                          : null,
                      child: _BookViewingSlot(
                        label: timeSlots[s],
                        available: available[s],
                        selected: s == selectedSlot,
                      ),
                    ),
                  ),

                const SizedBox(height: RS.x12),
                const ThinDivider(),

                const SizedBox(height: RS.x12),
                if (selectedSlot >= 0) ...[
                  Container(
                    padding: const EdgeInsets.all(RS.x12),
                    decoration: BoxDecoration(
                      color: RC.tealSoft,
                      borderRadius: RR.chip,
                      border: Border.all(color: RC.teal),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('booking_summary'.tr(), style: RT.title),
                        const SizedBox(height: RS.x8),
                        KeyValueRow(
                            'property_label'.tr(), propertyTitle ?? 'selected_property'.tr()),
                        KeyValueRow('Date', fmtDate(dates[selectedDate])),
                        KeyValueRow('Time', timeSlots[selectedSlot]),
                      ],
                    ),
                  ),
                  const SizedBox(height: RS.x16),
                ],

                RButton(
                  selectedSlot >= 0 ? 'confirm_booking'.tr() : 'select_time_slot'.tr(),
                  expanded: true,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: selectedSlot >= 0
                      ? () {
                          Navigator.pop(ctx);
                          _showBookingConfirmed(
                            context,
                            propertyTitle ?? 'selected_property'.tr(),
                            dates[selectedDate],
                            timeSlots[selectedSlot],
                          );
                        }
                      : null,
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showBookingConfirmed(
    BuildContext context, String propertyTitle, DateTime date, String timeSlot) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String monthShort(int m) => months[m - 1];
  String fmtDate(DateTime d) => '${monthShort(d.month)} ${d.day}, ${d.year}';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.7,
      expand: false,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(RS.x20),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: RC.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: RS.x24),
          const Center(
            child: IconBubble(Icons.check_circle_rounded,
                tint: RC.teal, size: 64, solid: true),
          ),
          const SizedBox(height: RS.x16),
          Center(child: Text('viewing_booked'.tr(), style: RT.h2)),
          const SizedBox(height: RS.x8),
          Center(
            child: Text(
              'viewing_scheduled'.tr(),
              style: RT.body.copyWith(color: RC.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: RS.x20),
          const ThinDivider(),
          const SizedBox(height: RS.x12),
          _BookingConfirmRow(
              Icons.home_outlined, 'property_label'.tr(), propertyTitle),
          const SizedBox(height: RS.x8),
          _BookingConfirmRow(
              Icons.calendar_today_rounded, 'Date', fmtDate(date)),
          const SizedBox(height: RS.x8),
          _BookingConfirmRow(
              Icons.access_time_rounded, 'Time', timeSlot),
          const SizedBox(height: RS.x8),
          _BookingConfirmRow(
            Icons.confirmation_num_outlined,
            'Booking ID',
            'VB-${DateTime.now().millisecondsSinceEpoch % 100000}',
          ),
          const SizedBox(height: RS.x20),
          RButton(
            'done'.tr(),
            expanded: true,
            kind: RButtonKind.navy,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  );
}

String _bWeekday(int w) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[w - 1];
}

// ---------------------------------------------------------------------------
// Wordmark
// ---------------------------------------------------------------------------

class ResivynWordmark extends StatelessWidget {
  const ResivynWordmark({super.key, this.compact = false, this.onLight = true});

  final bool compact;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final fg = onLight ? RC.navy : Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 24 : 28,
          height: compact ? 24 : 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 7 : 8),
            gradient: const LinearGradient(
              colors: [RC.teal, RC.tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              'R',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 14 : 16,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: RS.x8),
        Text(
          'RESIVYN',
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 14 : 16,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top bars
// ---------------------------------------------------------------------------

/// Circular icon button used across every header.
class RIconButton extends StatelessWidget {
  const RIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge = false,
    this.tooltip,
    this.floating = false,
    this.tint,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  final String? tooltip;

  /// Floating style is used over hero imagery (white pill, stronger shadow).
  final bool floating;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    // Own Material ancestor so the ripple works wherever this is placed —
    // including inside a Tooltip or outside a Scaffold body.
    final button = Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RC.surface,
              shape: BoxShape.circle,
              border: floating ? null : Border.all(color: RC.border),
              boxShadow: floating ? RShadow.soft : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 19, color: tint ?? RC.navy),
                if (badge)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: RC.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: RC.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// The standard RESIVYN header: logo + notification + profile.
class ResivynHeader extends StatelessWidget {
  const ResivynHeader({
    super.key,
    this.showBack = false,
    this.centerLogo = false,
    this.trailing,
    this.unreadBadge = true,
    this.avatarUrl,
  });

  final bool showBack;
  final bool centerLogo;
  final List<Widget>? trailing;
  final bool unreadBadge;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(RS.x20, RS.x8, RS.x20, RS.x12),
      child: Row(
        children: [
          if (showBack) ...[
            RIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: 'back'.tr(),
              onTap: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: RS.x12),
          ],
          if (centerLogo) const Spacer(),
          // Shrinks rather than overflowing when the trailing actions are wide.
          const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ResivynWordmark(),
            ),
          ),
          const Spacer(),
          ...?trailing,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards & sections
// ---------------------------------------------------------------------------

class RCard extends StatelessWidget {
  const RCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RS.x16),
    this.onTap,
    this.selected = false,
    this.color,
    this.radius = RR.card,
    this.showBorder = true,
    this.shadow,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool selected;
  final Color? color;
  final BorderRadius radius;
  final bool showBorder;
  final List<BoxShadow>? shadow;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? RC.surface,
        borderRadius: radius,
        border: showBorder
            ? Border.all(
                color: selected ? RC.teal : RC.border,
                width: selected ? 1.6 : 1,
              )
            : null,
        boxShadow: shadow ?? (selected ? RShadow.teal : RShadow.card),
      ),
      child: child,
    );

    final content = margin == null
        ? decorated
        : Padding(padding: margin!, child: decorated);

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.subtitle,
    this.padding =
        const EdgeInsets.only(left: RS.x20, right: RS.x20, top: RS.x24, bottom: RS.x12),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? subtitle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: RT.h2),
                if (subtitle != null) ...[
                  const SizedBox(height: RS.x4),
                  Text(subtitle!, style: RT.caption),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: RS.x12),
                child: Text(
                  actionLabel!,
                  style: RT.caption.copyWith(
                    color: RC.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum RButtonKind { primary, navy, outline, soft, ghost, danger }

class RButton extends StatelessWidget {
  const RButton(
    this.label, {
    super.key,
    this.onPressed,
    this.kind = RButtonKind.primary,
    this.icon,
    this.expanded = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final RButtonKind kind;
  final IconData? icon;
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    Border? border;
    List<BoxShadow>? shadow;

    switch (kind) {
      case RButtonKind.primary:
        bg = RC.teal;
        fg = Colors.white;
        shadow = RShadow.teal;
      case RButtonKind.navy:
        bg = RC.navy;
        fg = Colors.white;
        shadow = RShadow.soft;
      case RButtonKind.outline:
        bg = RC.surface;
        fg = RC.navy;
        border = Border.all(color: RC.borderStrong);
      case RButtonKind.soft:
        bg = RC.tealSoft;
        fg = RC.tealDark;
      case RButtonKind.ghost:
        bg = Colors.transparent;
        fg = RC.navy;
      case RButtonKind.danger:
        bg = RC.dangerSoft;
        fg = RC.danger;
    }

    final disabled = onPressed == null;

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 15 : 17, color: fg),
          const SizedBox(width: RS.x8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: RT.button.copyWith(
              color: fg,
              fontSize: compact ? 13 : 14.5,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: RR.button,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: RR.button,
            border: border,
            boxShadow: disabled ? null : shadow,
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: RR.button,
            child: Container(
              height: compact ? 40 : 52,
              padding: EdgeInsets.symmetric(horizontal: compact ? RS.x16 : RS.x20),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pills / tabs
// ---------------------------------------------------------------------------

/// Horizontally scrolling selectable pills (filters, categories).
class RPillBar extends StatelessWidget {
  const RPillBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = RS.page,
    this.icons,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsets padding;
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: RS.x8),
        itemBuilder: (context, i) {
          final active = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: RS.x16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? RC.teal : RC.surface,
                borderRadius: RR.chip,
                border: Border.all(color: active ? RC.teal : RC.border),
                boxShadow: active ? RShadow.teal : null,
              ),
              child: Row(
                children: [
                  if (icons != null) ...[
                    Icon(
                      icons![i],
                      size: 15,
                      color: active ? Colors.white : RC.textSecondary,
                    ),
                    const SizedBox(width: RS.x6),
                  ],
                  Text(
                    items[i],
                    style: RT.caption.copyWith(
                      color: active ? Colors.white : RC.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Segmented control with an equal-width sliding selection (Buy/Rent/Sell).
class RSegmented extends StatelessWidget {
  const RSegmented({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(RS.x4),
      decoration: BoxDecoration(
        color: RC.surface,
        borderRadius: RR.chip,
        border: Border.all(color: RC.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? RC.navy : Colors.transparent,
                    borderRadius: RR.chip,
                  ),
                  child: Text(
                    items[i],
                    style: RT.caption.copyWith(
                      color: i == selectedIndex ? Colors.white : RC.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Underlined tab row (Overview / Amenities / Floor Plan / Nearby).
class RUnderlineTabs extends StatelessWidget {
  const RUnderlineTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = RS.page,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RC.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(RS.x4, RS.x12, RS.x4, RS.x12),
                  margin: const EdgeInsets.only(right: RS.x24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == selectedIndex ? RC.teal : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    items[i],
                    style: RT.title.copyWith(
                      fontSize: 14,
                      color: i == selectedIndex ? RC.navy : RC.textTertiary,
                      fontWeight:
                          i == selectedIndex ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badges & bubbles
// ---------------------------------------------------------------------------

class RBadge extends StatelessWidget {
  const RBadge(
    this.label, {
    super.key,
    this.color = RC.teal,
    this.solid = false,
    this.icon,
    this.uppercase = false,
  });

  final String label;
  final Color color;
  final bool solid;
  final IconData? icon;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RS.x8, vertical: 5),
      decoration: BoxDecoration(
        color: solid ? color : color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: solid ? Colors.white : color),
            const SizedBox(width: RS.x4),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: solid ? Colors.white : color,
                letterSpacing: uppercase ? 0.7 : 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IconBubble extends StatelessWidget {
  const IconBubble(
    this.icon, {
    super.key,
    this.tint = RC.teal,
    this.size = 42,
    this.solid = false,
  });

  final IconData icon;
  final Color tint;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid ? tint : tint.withOpacity(0.11),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.46,
          color: solid ? Colors.white : tint,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric tiles
// ---------------------------------------------------------------------------

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tint = RC.teal,
    this.delta,
    this.deltaUp = true,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color tint;
  final String? delta;
  final bool deltaUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RCard(
      onTap: onTap,
      padding: const EdgeInsets.all(RS.x14),
      // Every child is flexible so the tile degrades gracefully instead of
      // overflowing when the grid cell is short or the copy is long.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) IconBubble(icon!, tint: tint, size: 32),
              const Spacer(),
              if (delta != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        deltaUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 11,
                        color: deltaUp ? RC.success : RC.danger,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          delta!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RT.captionSm.copyWith(
                            color: deltaUp ? RC.success : RC.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: RS.x8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: RT.metric, maxLines: 1),
                  ),
                ),
                const SizedBox(height: RS.x2),
                Flexible(
                  child: Text(
                    label,
                    style: RT.captionSm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A responsive grid that never overflows regardless of terminal/phone width.
class RGrid extends StatelessWidget {
  const RGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.gap = RS.x12,
    this.childAspectRatio = 1.45,
  });

  final List<Widget> children;
  final int columns;
  final double gap;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      childAspectRatio: childAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: children,
    );
  }
}

// ---------------------------------------------------------------------------
// Rows
// ---------------------------------------------------------------------------

class RowItem extends StatelessWidget {
  const RowItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? RS.x10 : RS.x12),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: RS.x12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: RT.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: RT.captionSm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: RS.x8), trailing!],
            if (trailing == null && showChevron)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: RC.textTertiary),
          ],
        ),
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value,
      {super.key, this.valueColor, this.bold = true});

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RS.x8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: RT.caption)),
          const SizedBox(width: RS.x12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (bold ? RT.bodyStrong : RT.body).copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

class ThinDivider extends StatelessWidget {
  const ThinDivider({super.key, this.inset = 0});
  final double inset;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: inset),
        child: const Divider(height: 1, thickness: 1, color: RC.border),
      );
}

// ---------------------------------------------------------------------------
// Greeting / weather
// ---------------------------------------------------------------------------

class WeatherChip extends StatelessWidget {
  const WeatherChip({
    super.key,
    this.temp = '32°C',
    this.condition = 'Sunny',
    this.icon = Icons.wb_sunny_rounded,
  });

  final String temp;
  final String condition;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RS.x12, vertical: RS.x8),
      decoration: const BoxDecoration(
        color: RC.warningSoft,
        borderRadius: RR.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: RC.warning),
          const SizedBox(width: RS.x6),
          Text(temp,
              style: RT.caption
                  .copyWith(color: RC.navy, fontWeight: FontWeight.w700)),
          const SizedBox(width: RS.x4),
          Text(condition, style: RT.captionSm.copyWith(color: RC.warning)),
        ],
      ),
    );
  }
}

class GreetingBlock extends StatelessWidget {
  const GreetingBlock({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.subtitleIcon = Icons.location_on_outlined,
    this.weather = true,
    this.avatarUrl,
    this.avatarName,
  });

  final String greeting;
  final String subtitle;
  final IconData subtitleIcon;
  final bool weather;
  final String? avatarUrl;
  final String? avatarName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: RS.page,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (avatarUrl != null) ...[
            ResivynAvatar(
              url: avatarUrl!,
              name: avatarName ?? greeting,
              size: 46,
              ring: true,
            ),
            const SizedBox(width: RS.x12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: RT.h1, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: RS.x4),
                Row(
                  children: [
                    Icon(subtitleIcon, size: 13, color: RC.textTertiary),
                    const SizedBox(width: RS.x4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: RT.captionSm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (weather) ...[const SizedBox(width: RS.x8), const WeatherChip()],
        ],
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.title,
      {super.key, this.subtitle, this.trailing, this.padding});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(RS.x20, RS.x8, RS.x20, RS.x16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: RT.display),
                if (subtitle != null) ...[
                  const SizedBox(height: RS.x6),
                  Text(subtitle!, style: RT.body),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: RS.x12), trailing!],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

class RTextField extends StatelessWidget {
  const RTextField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.icon,
    this.suffix,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final String? label;
  final TextEditingController? controller;
  final IconData? icon;
  final Widget? suffix;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: RT.caption.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: RS.x8),
        ],
        Container(
          decoration: BoxDecoration(
            color: RC.surface,
            borderRadius: RR.inner,
            border: Border.all(color: RC.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            readOnly: readOnly,
            onTap: onTap,
            style: RT.bodyStrong,
            cursorColor: RC.teal,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: RT.body.copyWith(color: RC.textTertiary),
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, size: 19, color: RC.textTertiary),
              suffixIcon: suffix,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: RS.x16,
                vertical: RS.x16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.tint = RC.teal,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final IconData? icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RS.x6),
      child: Row(
        children: [
          if (icon != null) ...[
            IconBubble(icon!, tint: tint, size: 36),
            const SizedBox(width: RS.x12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: RT.title),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: RT.captionSm),
                ],
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banners
// ---------------------------------------------------------------------------

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.info_outline_rounded,
    this.tint = RC.teal,
    this.ctaLabel,
    this.onCta,
    this.dark = false,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color tint;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fgTitle = dark ? Colors.white : RC.navy;
    final fgBody = dark ? Colors.white70 : RC.textSecondary;

    return Container(
      padding: const EdgeInsets.all(RS.x16),
      decoration: BoxDecoration(
        gradient: dark
            ? const LinearGradient(
                colors: [RC.navy, RC.navySoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: dark ? null : tint.withOpacity(0.08),
        borderRadius: RR.card,
        border: dark ? null : Border.all(color: tint.withOpacity(0.22)),
        boxShadow: dark ? RShadow.card : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: dark ? Colors.white.withOpacity(0.14) : tint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, size: 19, color: dark ? Colors.white : tint),
            ),
          ),
          const SizedBox(width: RS.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: RT.title.copyWith(color: fgTitle)),
                const SizedBox(height: RS.x4),
                Text(body, style: RT.caption.copyWith(color: fgBody)),
                if (ctaLabel != null) ...[
                  const SizedBox(height: RS.x12),
                  RButton(
                    ctaLabel!,
                    compact: true,
                    kind: dark ? RButtonKind.primary : RButtonKind.navy,
                    onPressed: onCta,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple horizontal progress bar used for occupancy / revenue comparisons.
class RProgressBar extends StatelessWidget {
  const RProgressBar({
    super.key,
    required this.value,
    this.color = RC.teal,
    this.height = 6,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: RC.border,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Numbered step indicator for multi-step forms.
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.steps,
    required this.currentIndex,
    this.onStepTap,
  });

  final List<String> steps;
  final int currentIndex;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: onStepTap == null ? null : () => onStepTap!(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i == 0
                              ? Colors.transparent
                              : (i <= currentIndex ? RC.teal : RC.border),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: i <= currentIndex ? RC.teal : RC.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i <= currentIndex ? RC.teal : RC.borderStrong,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: i < currentIndex
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: i == currentIndex
                                        ? Colors.white
                                        : RC.textTertiary,
                                  ),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i == steps.length - 1
                              ? Colors.transparent
                              : (i < currentIndex ? RC.teal : RC.border),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RS.x6),
                  Text(
                    steps[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RT.captionSm.copyWith(
                      fontSize: 9.5,
                      color: i <= currentIndex ? RC.navy : RC.textTertiary,
                      fontWeight:
                          i == currentIndex ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small icon + label tile used in "Quick Actions" clusters.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.tint = RC.teal,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: RR.inner,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RS.x8, horizontal: RS.x4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBubble(icon, tint: tint, size: 44),
            const SizedBox(height: RS.x8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: RT.captionSm.copyWith(
                color: RC.navy,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-of-page spacer that clears the bottom navigation bar.
class BottomGutter extends StatelessWidget {
  const BottomGutter({super.key, this.extra = 0});

  final double extra;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: RS.x32 + extra + MediaQuery.of(context).padding.bottom);
}

// ---------------------------------------------------------------------------
// Mock media / file picker helpers
// ---------------------------------------------------------------------------

/// Opens a bottom sheet offering the camera or the gallery, then invokes
/// [onPicked] with the full path of the selected image file.
Future<void> pickProfilePhoto(
  BuildContext context, {
  required ValueChanged<String> onPicked,
}) async {
  final source = await showModalBottomSheet<_PickSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: RS.x12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: RC.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(RS.x20),
            child: Text('Choose photo', style: RT.h2),
          ),
          ListTile(
            leading: const IconBubble(
                Icons.camera_alt_rounded, tint: RC.teal, size: 36),
            title: const Text('Take photo', style: RT.title),
            onTap: () => Navigator.pop(ctx, _PickSource.camera),
          ),
          const ThinDivider(inset: 48),
          ListTile(
            leading: const IconBubble(
                Icons.photo_library_outlined, tint: RC.info, size: 36),
            title: const Text('Choose from gallery', style: RT.title),
            onTap: () => Navigator.pop(ctx, _PickSource.gallery),
          ),
          const SizedBox(height: RS.x20),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  final picker = ImagePicker();
  XFile? file;
  try {
    file = switch (source) {
      _PickSource.camera =>
        await picker.pickImage(source: ImageSource.camera, maxWidth: 1200),
      _PickSource.gallery =>
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200),
    };
  } catch (_) {
    // Camera unavailable (e.g. no hardware) — fall back to gallery.
    file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
  }

  if (file == null) return; // User cancelled.
  onPicked(file.path);
}

enum _PickSource { camera, gallery }

/// Shows a bottom sheet that simulates a photo picker with mock images.
void showMockPhotoPicker(BuildContext context, {VoidCallback? onPicked}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: RS.x12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: RC.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(RS.x20),
            child: Text('Select photos', style: RT.h2),
          ),
          for (final item in const [
            ('Camera', Icons.camera_alt_rounded, RC.teal),
            ('Gallery', Icons.photo_library_outlined, RC.info),
            ('Files', Icons.folder_outlined, RC.purple),
          ])
            ListTile(
              leading: IconBubble(item.$2, tint: item.$3, size: 36),
              title: Text(item.$1, style: RT.title),
              trailing:
                  const Icon(Icons.chevron_right_rounded, color: RC.textTertiary),
              onTap: () {
                Navigator.pop(ctx);
                onPicked?.call();
                toast(context, 'Photo selected from ${item.$1}',
                    icon: Icons.check_circle_outline_rounded);
              },
            ),
          const SizedBox(height: RS.x20),
        ],
      ),
    ),
  );
}

/// Shows a bottom sheet that simulates a video picker.
void showMockVideoPicker(BuildContext context, {VoidCallback? onPicked}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: RS.x12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: RC.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(RS.x20),
            child: Text('Select video', style: RT.h2),
          ),
          for (final item in const [
            ('Record Video', Icons.videocam_rounded, RC.teal),
            ('Gallery', Icons.video_library_outlined, RC.purple),
            ('Files', Icons.folder_outlined, RC.info),
          ])
            ListTile(
              leading: IconBubble(item.$2, tint: item.$3, size: 36),
              title: Text(item.$1, style: RT.title),
              trailing:
                  const Icon(Icons.chevron_right_rounded, color: RC.textTertiary),
              onTap: () {
                Navigator.pop(ctx);
                onPicked?.call();
                toast(context, 'Video selected from ${item.$1}',
                    icon: Icons.check_circle_outline_rounded);
              },
            ),
          const SizedBox(height: RS.x20),
        ],
      ),
    ),
  );
}

/// Shows a dialog to paste a URL (for 360° tours, Matterport, etc.).
void showMockUrlDialog(BuildContext context,
    {String title = 'Paste tour link', String hint = 'https://...', VoidCallback? onPasted}) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: RC.surface,
      shape: const RoundedRectangleBorder(borderRadius: RR.card),
      title: Text(title, style: RT.h2),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.url,
        style: RT.bodyStrong,
        cursorColor: RC.teal,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: RT.body.copyWith(color: RC.textTertiary),
          border: const OutlineInputBorder(),
          focusedBorder:
              const OutlineInputBorder(borderSide: BorderSide(color: RC.teal)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: RT.bodyStrong.copyWith(color: RC.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onPasted?.call();
            toast(context, 'Link saved',
                icon: Icons.check_circle_outline_rounded);
          },
          child: Text('Save', style: RT.bodyStrong.copyWith(color: RC.teal)),
        ),
      ],
    ),
  );
}

/// Shows a bottom sheet that simulates a file/attachment picker.
void showMockAttachmentPicker(BuildContext context, {VoidCallback? onPicked}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: RS.x12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: RC.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(RS.x20),
            child: Text('Attach file', style: RT.h2),
          ),
          for (final item in const [
            ('Photo', Icons.photo_camera_outlined, RC.teal),
            ('Video', Icons.videocam_outlined, RC.purple),
            ('Document', Icons.description_outlined, RC.info),
            ('Screenshot', Icons.screenshot_outlined, RC.warning),
          ])
            ListTile(
              leading: IconBubble(item.$2, tint: item.$3, size: 36),
              title: Text(item.$1, style: RT.title),
              trailing:
                  const Icon(Icons.chevron_right_rounded, color: RC.textTertiary),
              onTap: () {
                Navigator.pop(ctx);
                onPicked?.call();
                toast(context, '${item.$1} attached',
                    icon: Icons.check_circle_outline_rounded);
              },
            ),
          const SizedBox(height: RS.x20),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Book viewing helper widgets
// ---------------------------------------------------------------------------

class _BookViewingSlot extends StatelessWidget {
  const _BookViewingSlot({
    required this.label,
    required this.available,
    this.selected = false,
  });

  final String label;
  final bool available;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isActive = available && selected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: RS.x14, vertical: RS.x10),
      decoration: BoxDecoration(
        color: isActive
            ? RC.teal
            : available
                ? RC.tealSoft
                : RC.surface,
        borderRadius: RR.chip,
        border: Border.all(
          color: isActive
              ? RC.teal
              : available
                  ? RC.teal
                  : RC.border,
          width: isActive ? 1.6 : 1,
        ),
        boxShadow: isActive ? RShadow.teal : null,
      ),
      child: Row(
        children: [
          Icon(
            isActive
                ? Icons.check_circle_rounded
                : available
                    ? Icons.access_time_rounded
                    : Icons.block_rounded,
            size: 16,
            color: isActive
                ? Colors.white
                : available
                    ? RC.tealDark
                    : RC.textTertiary,
          ),
          const SizedBox(width: RS.x8),
          Expanded(
            child: Text(
              label,
              style: RT.bodyStrong.copyWith(
                color: isActive
                    ? Colors.white
                    : available
                        ? RC.navy
                        : RC.textTertiary,
              ),
            ),
          ),
          if (isActive)
            const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          else if (available)
            const Icon(Icons.check_circle_outline_rounded,
                size: 18, color: RC.teal)
          else
            const Text('Taken', style: RT.captionSm),
        ],
      ),
    );
  }
}

class _BookingConfirmRow extends StatelessWidget {
  const _BookingConfirmRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: RC.teal),
        const SizedBox(width: RS.x10),
        Expanded(child: Text(label, style: RT.caption)),
        const SizedBox(width: RS.x8),
        Flexible(
          child: Text(value, style: RT.bodyStrong),
        ),
      ],
    );
  }
}
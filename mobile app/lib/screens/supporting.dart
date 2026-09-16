import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';
import '../widgets/property_card.dart';
import '../widgets/resivyn_image.dart';

/// Supporting screen — not in the 21-screen spec, but the Saved tab in the
/// bottom navigation needs a real destination.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = MockData.allProperties
        .where((p) => state.isSaved(p.id))
        .toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ResivynHeader(
          trailing: [
            RIconButton(
              icon: Icons.notifications_none_rounded,
              badge: true,
              tooltip: 'notifications'.tr(),
              onTap: () => Navigator.pushNamed(context, Routes.notifications),
            ),
          ],
        ),

        PageTitle(
          'Saved',
          subtitle: saved.isEmpty
              ? 'Properties you save appear here.'
              : '${saved.length} ${saved.length == 1 ? 'property' : 'properties'} saved',
        ),

        if (saved.isEmpty)
          Padding(
            padding: const EdgeInsets.all(RS.x20),
            child: RCard(
              padding: const EdgeInsets.all(RS.x32),
              child: Column(
                children: [
                  const IconBubble(Icons.bookmark_border_rounded,
                      tint: RC.textTertiary, size: 56),
                  const SizedBox(height: RS.x16),
                  const Text('Nothing saved yet', style: RT.h2),
                  const SizedBox(height: RS.x6),
                  const Text(
                    'Tap the heart on any listing to keep it here for later.',
                    textAlign: TextAlign.center,
                    style: RT.caption,
                  ),
                  const SizedBox(height: RS.x20),
                  RButton(
                    'Browse properties',
                    icon: Icons.search_rounded,
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.search),
                  ),
                ],
              ),
            ),
          )
        else
          for (final property in saved)
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, 0, RS.x20, RS.x16),
              child: PropertyCard(
                property: property,
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.propertyDetails,
                  arguments: property,
                ),
              ),
            ),

        const BottomGutter(),
      ],
    );
  }
}

/// Supporting screen — destination for the Community tab.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _filter = 0;

  late Future<List<Announcement>> _announcements;

  static const _filters = ['Feed', 'Events', 'Facilities', 'Neighbours'];

  // -- Helpful toggle state per announcement index --
  final Map<int, bool> _helpfulState = {};
  final Map<int, int> _helpfulCounts = {};

  // -- Comment state per announcement index --
  final Map<int, List<FeedComment>> _comments = {
    0: [
      FeedComment(
          author: 'Sarah M.',
          body: 'Thanks for the update!',
          time: '2 hours ago',
          avatarUrl: Img.avatarSara),
      FeedComment(
          author: 'Rohan K.',
          body: 'Will the pool be open on Sunday?',
          time: '1 hour ago',
          avatarUrl: Img.avatarMichael),
    ],
    1: [
      FeedComment(
          author: 'Aisha S.',
          body: 'Any alternative parking available?',
          time: '3 hours ago',
          avatarUrl: Img.avatarAisha),
    ],
  };
  final Map<int, TextEditingController> _commentControllers = {};

  // -- Events with RSVP state --
  static final _events = [
    const CommunityEvent(
      title: 'Community BBQ',
      schedule: 'Sat 10 May • 6:00 PM',
      place: 'Rooftop Terrace',
      description: 'Join your neighbours for a fun evening BBQ with live music and activities for kids.',
      maxAttendees: 80,
      attendees: 42,
    ),
    const CommunityEvent(
      title: 'Yoga by the Pool',
      schedule: 'Sun 11 May • 7:00 AM',
      place: 'Pool Deck',
      description: 'Start your morning with a relaxing yoga session led by a certified instructor.',
      maxAttendees: 20,
      attendees: 14,
    ),
    const CommunityEvent(
      title: 'Residents Meeting',
      schedule: 'Wed 14 May • 7:30 PM',
      place: 'Clubhouse',
      description: 'Monthly residents meeting to discuss community updates and upcoming projects.',
      maxAttendees: 100,
      attendees: 67,
    ),
  ];
  final Set<int> _rsvpEvents = {};

  // -- Facilities with status --
  static final _facilities = [
    const CommunityFacility(
      name: 'Swimming Pool',
      status: FacilityStatus.open,
      icon: Icons.pool_outlined,
      color: RC.info,
      hours: '6:00 AM – 10:00 PM',
    ),
    const CommunityFacility(
      name: 'Gym',
      status: FacilityStatus.open,
      icon: Icons.fitness_center_outlined,
      color: RC.teal,
      hours: 'Open 24 hours',
    ),
    const CommunityFacility(
      name: 'Clubhouse',
      status: FacilityStatus.bookable,
      icon: Icons.chair_outlined,
      color: RC.purple,
      hours: '8:00 AM – 11:00 PM',
      availableSlots: 2,
    ),
    const CommunityFacility(
      name: 'Tennis Court',
      status: FacilityStatus.closed,
      icon: Icons.sports_tennis_outlined,
      color: RC.warning,
      hours: 'Closed for maintenance',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _announcements = Services.tenant.announcements();
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: EdgeInsets.zero,
      children: [
        ResivynHeader(
          showBack: !widget.embedded,
          trailing: [
            RIconButton(
              icon: Icons.notifications_none_rounded,
              badge: true,
              tooltip: 'notifications'.tr(),
              onTap: () => Navigator.pushNamed(context, Routes.notifications),
            ),
            const SizedBox(width: RS.x8),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, Routes.profile),
              child: const ResivynAvatar(
                url: Img.avatarAlex,
                name: 'Alex Johnson',
                size: 40,
              ),
            ),
          ],
        ),

        const PageTitle(
          'Community',
          subtitle: 'Marina Heights • Dubai Marina',
        ),

        RPillBar(
          items: _filters,
          selectedIndex: _filter,
          onChanged: (i) => setState(() => _filter = i),
        ),

        const SizedBox(height: RS.x20),

        if (_filter == 0) ..._feed(),
        if (_filter == 1) ..._eventsTab(),
        if (_filter == 2) ..._facilitiesTab(),
        if (_filter == 3) ..._neighboursTab(),

        const BottomGutter(),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(body: SafeArea(bottom: false, child: body));
  }

  // -------------------------------------------------------------------------
  // FEED – with helpful toggle + comments
  // -------------------------------------------------------------------------

  List<Widget> _feed() => [
        FutureBuilder<List<Announcement>>(
          future: _announcements,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                      color: RC.teal, strokeWidth: 2.5),
                ),
              );
            }
            final items = snapshot.data!;
            return Padding(
              padding: RS.page,
              child: Column(
                children: [
                  for (var ai = 0; ai < items.length; ai++)
                    _buildFeedCard(items[ai], ai),
                ],
              ),
            );
          },
        ),
      ];

  Widget _buildFeedCard(Announcement a, int index) {
    final isHelpful = _helpfulState[index] ?? false;
    final helpfulCount = _helpfulCounts[index] ?? 0;
    final comments = _comments[index] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: RS.x12),
      child: RCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const IconBubble(Icons.campaign_outlined,
                    tint: RC.purple, size: 38),
                const SizedBox(width: RS.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Building Management', style: RT.title),
                      const SizedBox(height: 2),
                      Text(a.date, style: RT.captionSm),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: RS.x12),
            Text(a.title, style: RT.bodyStrong),
            const SizedBox(height: RS.x6),
            Text(a.body, style: RT.body),
            const SizedBox(height: RS.x12),
            const ThinDivider(),
            const SizedBox(height: RS.x8),

            // Action row
            Row(
              children: [
                _FeedAction(
                  icon: isHelpful
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  label: helpfulCount > 0 ? 'Helpful ($helpfulCount)' : 'Helpful',
                  active: isHelpful,
                  onTap: () {
                    setState(() {
                      final wasHelpful = _helpfulState[index] ?? false;
                      _helpfulState[index] = !wasHelpful;
                      final count = _helpfulCounts[index] ?? 0;
                      _helpfulCounts[index] =
                          wasHelpful ? (count > 0 ? count - 1 : 0) : count + 1;
                    });
                  },
                ),
                const SizedBox(width: RS.x20),
                _FeedAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comment (${comments.length})',
                  onTap: () {
                    setState(() {
                      if (_commentControllers.containsKey(index)) {
                        _commentControllers.remove(index);
                      } else {
                        _commentControllers[index] = TextEditingController();
                      }
                    });
                  },
                ),
              ],
            ),

            // Comments section
            if (_commentControllers.containsKey(index)) ...[
              const SizedBox(height: RS.x12),
              const ThinDivider(),
              const SizedBox(height: RS.x8),
              Text('Comments', style: RT.title),
              const SizedBox(height: RS.x8),

              // Existing comments
              for (final c in comments)
                Padding(
                  padding: const EdgeInsets.only(bottom: RS.x8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResivynAvatar(
                        url: c.avatarUrl ?? '',
                        name: c.author,
                        size: 28,
                      ),
                      const SizedBox(width: RS.x8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(c.author,
                                    style: RT.captionSm.copyWith(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: RS.x6),
                                Text(c.time,
                                    style: RT.captionSm
                                        .copyWith(color: RC.textTertiary)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(c.body, style: RT.body),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Comment input
              Row(
                children: [
                  const ResivynAvatar(
                    url: Img.avatarAlex,
                    name: 'Alex',
                    size: 28,
                  ),
                  const SizedBox(width: RS.x8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: RR.inner,
                        border: Border.all(color: RC.border),
                      ),
                      child: TextField(
                        controller: _commentControllers[index],
                        style: RT.body,
                        cursorColor: RC.teal,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle:
                              RT.body.copyWith(color: RC.textTertiary),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: RS.x12,
                            vertical: RS.x10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: RS.x8),
                  GestureDetector(
                    onTap: () {
                      final ctrl = _commentControllers[index];
                      final text = ctrl?.text.trim() ?? '';
                      if (text.isEmpty) return;
                      setState(() {
                        _comments.putIfAbsent(index, () => []);
                        _comments[index]!.add(FeedComment(
                          author: 'Alex Johnson',
                          body: text,
                          time: 'Just now',
                          avatarUrl: Img.avatarAlex,
                        ));
                        ctrl?.clear();
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: RC.teal,
                        borderRadius: RR.button,
                      ),
                      child: const Icon(Icons.send_rounded,
                          size: 17, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // EVENTS – with RSVP state + booking sheet
  // -------------------------------------------------------------------------

  List<Widget> _eventsTab() => [
        Padding(
          padding: RS.page,
          child: Column(
            children: [
              for (var i = 0; i < _events.length; i++)
                _buildEventCard(_events[i], i),
            ],
          ),
        ),
      ];

  Widget _buildEventCard(CommunityEvent event, int index) {
    final isRsvpd = _rsvpEvents.contains(index);
    final spotsLeft = event.maxAttendees - event.attendees;

    return Padding(
      padding: const EdgeInsets.only(bottom: RS.x12),
      child: RCard(
        onTap: () => _showEventDetail(event, index),
        child: Row(
          children: [
            IconBubble(Icons.event_outlined, tint: RC.teal, size: 44),
            const SizedBox(width: RS.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: RT.title),
                  const SizedBox(height: 2),
                  Text('${event.schedule} • ${event.place}',
                      style: RT.captionSm),
                  const SizedBox(height: 4),
                  Text(
                    spotsLeft > 0 ? '$spotsLeft spots left' : 'Fully booked',
                    style: RT.captionSm.copyWith(
                      color: spotsLeft > 0 ? RC.teal : RC.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            RButton(
              isRsvpd ? 'Going' : 'RSVP',
              kind: isRsvpd ? RButtonKind.navy : RButtonKind.soft,
              compact: true,
              icon: isRsvpd ? Icons.check_circle_outline : null,
              onPressed: () {
                setState(() {
                  if (_rsvpEvents.contains(index)) {
                    _rsvpEvents.remove(index);
                    toast(context, 'RSVP cancelled for ${event.title}',
                        icon: Icons.event_busy_outlined);
                  } else {
                    _rsvpEvents.add(index);
                    toast(context, 'RSVP sent for ${event.title}',
                        icon: Icons.event_available_outlined);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetail(CommunityEvent event, int index) {
    final spotsLeft = event.maxAttendees - event.attendees;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isRsvpd = _rsvpEvents.contains(index);
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
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
                    const IconBubble(Icons.event_outlined,
                        tint: RC.teal, size: 44),
                    const SizedBox(width: RS.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: RT.h2),
                          const SizedBox(height: 2),
                          Text(event.schedule, style: RT.captionSm),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RS.x16),
                const ThinDivider(),
                const SizedBox(height: RS.x12),
                KeyValueRow('Location', event.place),
                KeyValueRow('Time', event.schedule),
                KeyValueRow(
                    'Capacity', '${event.attendees}/${event.maxAttendees}'),
                KeyValueRow('Available', '$spotsLeft spots',
                    valueColor: spotsLeft > 0 ? RC.teal : RC.danger),
                const SizedBox(height: RS.x12),
                if (event.description.isNotEmpty) ...[
                  Text('About', style: RT.title),
                  const SizedBox(height: RS.x6),
                  Text(event.description, style: RT.body),
                  const SizedBox(height: RS.x16),
                ],

                // RSVP status banner
                Container(
                  padding: const EdgeInsets.all(RS.x12),
                  decoration: BoxDecoration(
                    color: isRsvpd ? RC.tealSoft : RC.surface,
                    borderRadius: RR.chip,
                    border: Border.all(
                      color: isRsvpd ? RC.teal : RC.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isRsvpd
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: isRsvpd ? RC.teal : RC.textTertiary,
                      ),
                      const SizedBox(width: RS.x10),
                      Expanded(
                        child: Text(
                          isRsvpd
                              ? "You're going to this event"
                              : 'Not yet registered',
                          style: RT.bodyStrong.copyWith(
                            color: isRsvpd ? RC.tealDark : RC.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RS.x16),

                RButton(
                  isRsvpd ? 'Cancel RSVP' : 'RSVP Now',
                  expanded: true,
                  kind: isRsvpd ? RButtonKind.danger : RButtonKind.primary,
                  icon: isRsvpd
                      ? Icons.event_busy_outlined
                      : Icons.event_available_outlined,
                  onPressed: spotsLeft <= 0 && !isRsvpd
                      ? null
                      : () {
                          setSheetState(() {
                            if (_rsvpEvents.contains(index)) {
                              _rsvpEvents.remove(index);
                            } else {
                              _rsvpEvents.add(index);
                            }
                          });
                          setState(() {});
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // FACILITIES – with booking flow for bookable, info for open, disabled for closed
  // -------------------------------------------------------------------------

  List<Widget> _facilitiesTab() => [
        Padding(
          padding: RS.page,
          child: RCard(
            padding: const EdgeInsets.symmetric(horizontal: RS.x16),
            child: Column(
              children: [
                for (var i = 0; i < _facilities.length; i++) ...[
                  _buildFacilityRow(_facilities[i]),
                  if (i != _facilities.length - 1) const ThinDivider(inset: 52),
                ],
              ],
            ),
          ),
        ),
      ];

  Widget _buildFacilityRow(CommunityFacility facility) {
    final isClosed = facility.status == FacilityStatus.closed;
    final isBookable = facility.status == FacilityStatus.bookable;

    String subtitle;
    switch (facility.status) {
      case FacilityStatus.open:
        subtitle = 'Open • ${facility.hours}';
        break;
      case FacilityStatus.bookable:
        subtitle = 'Bookable • ${facility.availableSlots} slots today';
        break;
      case FacilityStatus.closed:
        subtitle = facility.hours;
        break;
    }

    return RowItem(
      title: facility.name,
      subtitle: subtitle,
      leading: IconBubble(facility.icon, tint: facility.color, size: 40),
      trailing: isBookable
          ? RButton(
              'Book',
              kind: RButtonKind.soft,
              compact: true,
              onPressed: () => _showFacilityBooking(facility),
            )
          : isClosed
              ? RBadge('closed'.tr(), color: RC.warning)
              : null,
      onTap: isClosed
          ? () => toast(context, '${facility.name} is currently closed',
              icon: Icons.info_outline_rounded)
          : isBookable
              ? () => _showFacilityBooking(facility)
              : () => toast(context, '${facility.name} is open',
                  icon: Icons.info_outline_rounded),
    );
  }

  void _showFacilityBooking(CommunityFacility facility) {
    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.add(Duration(days: i)));
    final slots = [
      ('9:00 AM – 10:00 AM', true),
      ('10:00 AM – 11:00 AM', true),
      ('11:00 AM – 12:00 PM', true),
      ('2:00 PM – 3:00 PM', false),
      ('3:00 PM – 4:00 PM', true),
      ('4:00 PM – 5:00 PM', true),
    ];

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
              initialChildSize: 0.8,
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
                      IconBubble(facility.icon, tint: facility.color, size: 44),
                      const SizedBox(width: RS.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(facility.name, style: RT.h2),
                            const SizedBox(height: 2),
                            Text('Book a time slot', style: RT.captionSm),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RS.x16),
                  const ThinDivider(),

                  const SizedBox(height: RS.x12),
                  Text('Select Date', style: RT.title),
                  const SizedBox(height: RS.x8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: RS.x8),
                      itemBuilder: (_, i) {
                        final d = dates[i];
                        final isSelected = i == selectedDate;
                        const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final dayName = i == 0 ? 'Today' : (i == 1 ? 'Tmrw' : dayNames[d.weekday - 1]);
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedDate = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 64,
                            decoration: BoxDecoration(
                              color: isSelected ? RC.teal : RC.surface,
                              borderRadius: RR.chip,
                              border: Border.all(
                                color: isSelected ? RC.teal : RC.border,
                              ),
                              boxShadow: isSelected ? RShadow.teal : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayName,
                                  style: RT.captionSm.copyWith(
                                    color: isSelected ? Colors.white70 : RC.textTertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: RS.x4),
                                Text(
                                  '${d.day}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : RC.navy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _monthShort(d.month),
                                  style: RT.captionSm.copyWith(
                                    color: isSelected ? Colors.white70 : RC.textTertiary,
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
                  Text('Available Time Slots', style: RT.title),
                  const SizedBox(height: RS.x8),
                  for (var s = 0; s < slots.length; s++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: RS.x8),
                      child: GestureDetector(
                        onTap: slots[s].$2
                            ? () => setSheetState(() => selectedSlot = s)
                            : null,
                        child: _TimeSlotChip(
                          label: slots[s].$1,
                          available: slots[s].$2,
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
                          Text('Booking Summary', style: RT.title),
                          const SizedBox(height: RS.x8),
                          KeyValueRow('Facility', facility.name),
                          KeyValueRow('Date', _formatDate(dates[selectedDate])),
                          KeyValueRow('Time', slots[selectedSlot].$1),
                        ],
                      ),
                    ),
                    const SizedBox(height: RS.x16),
                  ],

                  RButton(
                    selectedSlot >= 0 ? 'Confirm Booking' : 'Select a time slot',
                    expanded: true,
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: selectedSlot >= 0
                        ? () {
                            Navigator.pop(ctx);
                            _showBookingConfirmed(
                              facility,
                              dates[selectedDate],
                              slots[selectedSlot].$1,
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
      CommunityFacility facility, DateTime date, String timeSlot) {
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
            Center(
              child: Text('Booking Confirmed!', style: RT.h2),
            ),
            const SizedBox(height: RS.x8),
            Center(
              child: Text(
                'Your booking has been successfully confirmed.',
                style: RT.body.copyWith(color: RC.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: RS.x20),
            const ThinDivider(),
            const SizedBox(height: RS.x12),
            _BookingDetailRow(Icons.location_on_outlined, 'Facility', facility.name),
            const SizedBox(height: RS.x8),
            _BookingDetailRow(Icons.calendar_today_rounded, 'Date', _formatDate(date)),
            const SizedBox(height: RS.x8),
            _BookingDetailRow(Icons.access_time_rounded, 'Time', timeSlot),
            const SizedBox(height: RS.x8),
            _BookingDetailRow(Icons.confirmation_num_outlined, 'Booking ID',
                'BK-${DateTime.now().millisecondsSinceEpoch % 100000}'),
            const SizedBox(height: RS.x20),
            RButton(
              'Done',
              expanded: true,
              kind: RButtonKind.navy,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  String _formatDate(DateTime d) {
    return '${_monthShort(d.month)} ${d.day}, ${d.year}';
  }

  // -------------------------------------------------------------------------
  // NEIGHBOURS – with chat screen
  // -------------------------------------------------------------------------

  List<Widget> _neighboursTab() => [
        Padding(
          padding: RS.page,
          child: RCard(
            padding: const EdgeInsets.symmetric(horizontal: RS.x16),
            child: Column(
              children: [
                for (var i = 0; i < MockData.inquiries.length; i++) ...[
                  RowItem(
                    title: MockData.inquiries[i].name,
                    subtitle: _neighbourSubtitle(i),
                    leading: ResivynAvatar(
                      url: MockData.inquiries[i].avatarUrl,
                      name: MockData.inquiries[i].name,
                      size: 40,
                    ),
                    trailing: RButton(
                      'Message',
                      kind: RButtonKind.soft,
                      compact: true,
                      onPressed: () => _openNeighbourChat(
                        MockData.inquiries[i].name,
                        MockData.inquiries[i].avatarUrl,
                      ),
                    ),
                    onTap: () => _openNeighbourChat(
                      MockData.inquiries[i].name,
                      MockData.inquiries[i].avatarUrl,
                    ),
                  ),
                  if (i != MockData.inquiries.length - 1)
                    const ThinDivider(inset: 52),
                ],
              ],
            ),
          ),
        ),
      ];

  String _neighbourSubtitle(int index) {
    const subtitles = [
      'Resident • Tower A, Unit 1204',
      'Resident • Tower B, Unit 803',
      'Resident • Tower A, Unit 506',
    ];
    return index < subtitles.length ? subtitles[index] : 'Resident';
  }

  void _openNeighbourChat(String name, String? avatarUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NeighbourChatScreen(
          neighbourName: name,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feed action button with active state
// ---------------------------------------------------------------------------

class _FeedAction extends StatelessWidget {
  const _FeedAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 15, color: active ? RC.teal : RC.textSecondary),
          const SizedBox(width: RS.x6),
          Text(
            label,
            style: RT.captionSm.copyWith(
              color: active ? RC.teal : RC.textSecondary,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time slot picker chip
// ---------------------------------------------------------------------------

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
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

// ---------------------------------------------------------------------------
// Booking detail row
// ---------------------------------------------------------------------------

class _BookingDetailRow extends StatelessWidget {
  const _BookingDetailRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: RC.teal),
        const SizedBox(width: RS.x10),
        Text(label, style: RT.caption.copyWith(color: RC.textSecondary)),
        const Spacer(),
        Text(value, style: RT.bodyStrong),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Neighbour chat screen
// ---------------------------------------------------------------------------

class NeighbourChatScreen extends StatefulWidget {
  const NeighbourChatScreen({
    super.key,
    required this.neighbourName,
    this.avatarUrl,
  });

  final String neighbourName;
  final String? avatarUrl;

  @override
  State<NeighbourChatScreen> createState() => _NeighbourChatScreenState();
}

class _NeighbourChatScreenState extends State<NeighbourChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <NeighbourMessage>[];

  @override
  void initState() {
    super.initState();
    _messages.add(NeighbourMessage(
      text: 'Hey! How can I help you?',
      isUser: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(NeighbourMessage(text: text, isUser: true, time: DateTime.now()));
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate reply
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(NeighbourMessage(
          text: _autoReply(text),
          isUser: false,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _autoReply(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      return 'Hey there! Nice to hear from you.';
    }
    if (lower.contains('parking')) {
      return 'I think visitor parking is on Level B2. You can check with management for a pass.';
    }
    if (lower.contains('noise') || lower.contains('loud')) {
      return 'Sorry to hear that. You can raise a noise complaint through the support section.';
    }
    if (lower.contains('thank')) {
      return "You're welcome! Let me know if you need anything else.";
    }
    return "Thanks for your message! I'll get back to you soon.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: RC.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            ResivynAvatar(
              url: widget.avatarUrl ?? '',
              name: widget.neighbourName,
              size: 32,
            ),
            const SizedBox(width: RS.x10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.neighbourName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Online',
                    style: TextStyle(color: Colors.white70, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(RS.x16, RS.x16, RS.x16, RS.x8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isUser = msg.isUser;
                final timeStr =
                    '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: RS.x10),
                  child: Row(
                    mainAxisAlignment:
                        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) ...[
                        ResivynAvatar(
                          url: widget.avatarUrl ?? '',
                          name: widget.neighbourName,
                          size: 28,
                        ),
                        const SizedBox(width: RS.x8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(
                              RS.x14, RS.x10, RS.x14, RS.x8),
                          decoration: BoxDecoration(
                            color: isUser ? RC.teal : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isUser ? 18 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 18),
                            ),
                            boxShadow: RShadow.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: RT.body.copyWith(
                                  color: isUser ? Colors.white : RC.navy,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: RS.x4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isUser ? Colors.white60 : RC.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: RS.x8),
                        const ResivynAvatar(
                          url: Img.avatarAlex,
                          name: 'Alex',
                          size: 28,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              RS.x12,
              RS.x8,
              RS.x12,
              RS.x8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: RC.surface,
              border: Border(top: BorderSide(color: RC.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: RR.inner,
                      border: Border.all(color: RC.border),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: RT.bodyStrong,
                      cursorColor: RC.teal,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: RT.body.copyWith(color: RC.textTertiary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: RS.x14,
                          vertical: RS.x12,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: RS.x8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: RC.teal,
                      borderRadius: RR.button,
                      boxShadow: RShadow.teal,
                    ),
                    child: const Icon(Icons.send_rounded,
                        size: 20, color: Colors.white),
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

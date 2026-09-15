import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';
import '../widgets/detail_parts.dart';

/// SCREEN 01 — PROPERTY FLOOR PLAN / PROPERTY DETAILS
class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key, this.property});

  final Property? property;

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  int _mediaTab = 1; // Floor Plan is active by default.
  int _planIndex = 0;
  bool _imperial = true;

  static const _mediaTabs = ['Photos', 'Floor Plan', 'Video', '360 Tour'];

  static const _quickFacts = <(IconData, String)>[
    (Icons.bed_outlined, '5 Bedrooms'),
    (Icons.bathtub_outlined, '6 Bathrooms'),
    (Icons.local_parking_outlined, '2 Parking'),
    (Icons.pool_outlined, 'Private Pool'),
    (Icons.layers_outlined, '2 Levels'),
  ];

  Property get _property => widget.property ?? MockData.luxuryVilla;
  FloorPlan get _plan => MockData.floorPlans[_planIndex];

  /// The room list is authored in metres; convert on the fly for imperial.
  String _dimensions(RoomSpec room) {
    if (!_imperial) return room.dimensions;

    final matches = RegExp(r'([\d.]+)m x ([\d.]+)m').firstMatch(room.dimensions);
    if (matches == null) return room.dimensions;

    final w = double.parse(matches.group(1)!) * 3.28084;
    final h = double.parse(matches.group(2)!) * 3.28084;
    return "${w.toStringAsFixed(1)}ft x ${h.toStringAsFixed(1)}ft";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          PropertyHero(
            property: _property,
            height: 280,
            showGalleryButton: true,
          ),

          const SizedBox(height: RS.x16),
          RUnderlineTabs(
            items: _mediaTabs,
            selectedIndex: _mediaTab,
            onChanged: (i) {
              setState(() => _mediaTab = i);
              if (i == 0) {
                Navigator.pushNamed(context, Routes.gallery,
                    arguments: _property);
              } else if (i != 1) {
                toast(context, '${_mediaTabs[i]} coming from the media server',
                    icon: Icons.play_circle_outline_rounded);
              }
            },
          ),

          // ---- Floor plans ----
          Padding(
            padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, RS.x12),
            child: Row(
              children: [
                const Expanded(child: Text('Floor Plans', style: RT.h2)),
                GestureDetector(
                  onTap: () => setState(() => _imperial = !_imperial),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: RS.x12, vertical: RS.x8),
                    decoration: BoxDecoration(
                      color: RC.surface,
                      borderRadius: RR.chip,
                      border: Border.all(color: RC.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.straighten_outlined,
                            size: 14, color: RC.navy),
                        const SizedBox(width: RS.x6),
                        Text(
                          _imperial ? 'Imperial (ft)' : 'Metric (m)',
                          style: RT.captionSm.copyWith(
                            color: RC.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(Icons.swap_horiz_rounded,
                            size: 14, color: RC.textTertiary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: RS.page,
              itemCount: MockData.floorPlans.length,
              separatorBuilder: (_, __) => const SizedBox(width: RS.x12),
              itemBuilder: (context, i) {
                final plan = MockData.floorPlans[i];
                final active = i == _planIndex;
                return GestureDetector(
                  onTap: () => setState(() => _planIndex = i),
                  child: SizedBox(
                    width: 152,
                    child: RCard(
                      selected: active,
                      padding: const EdgeInsets.all(RS.x14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconBubble(
                                Icons.architecture_outlined,
                                tint: RC.teal,
                                size: 30,
                                solid: active,
                              ),
                              const Spacer(),
                              if (active)
                                const Icon(Icons.check_circle_rounded,
                                    size: 16, color: RC.teal),
                            ],
                          ),
                          const Spacer(),
                          Text(plan.name,
                              style: RT.title.copyWith(fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(plan.areaSqft, style: RT.captionSm),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ---- Schematic ----
          Padding(
            padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, 0),
            child: _PlanSchematic(plan: _plan),
          ),

          // ---- Room list ----
          SectionTitle('${_plan.name} Details',
              subtitle: '${_plan.rooms.length} rooms • ${_plan.areaSqft}'),
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.symmetric(horizontal: RS.x16),
              child: Column(
                children: [
                  for (var i = 0; i < _plan.rooms.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: RS.x12),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: RC.tealSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: RT.captionSm.copyWith(
                                  color: RC.tealDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: RS.x12),
                          Expanded(
                            child: Text(_plan.rooms[i].name, style: RT.bodyStrong),
                          ),
                          Text(
                            _dimensions(_plan.rooms[i]),
                            style: RT.captionSm.copyWith(
                              color: RC.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != _plan.rooms.length - 1) const ThinDivider(inset: 38),
                  ],
                ],
              ),
            ),
          ),

          // ---- Area summary ----
          const SectionTitle('Area Summary'),
          Padding(
            padding: RS.page,
            child: RCard(
              child: Column(
                children: [
                  for (final entry in MockData.areaSummary.entries)
                    KeyValueRow(entry.key, entry.value),
                ],
              ),
            ),
          ),

          // ---- Finishes ----
          const SectionTitle('Furnishing & Finishes'),
          const Padding(
            padding: RS.page,
            child: RCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBubble(Icons.auto_awesome_outlined,
                      tint: RC.warning),
                  SizedBox(width: RS.x12),
                  Expanded(
                    child: Text(MockData.finishesBlurb, style: RT.body),
                  ),
                ],
              ),
            ),
          ),

          // ---- Quick facts ----
          const SectionTitle('Quick Facts'),
          Padding(
            padding: RS.page,
            child: Wrap(
              spacing: RS.x8,
              runSpacing: RS.x8,
              children: [
                for (final (icon, label) in _quickFacts)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: RS.x12, vertical: RS.x10),
                    decoration: BoxDecoration(
                      color: RC.surface,
                      borderRadius: RR.chip,
                      border: Border.all(color: RC.border),
                      boxShadow: RShadow.soft,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 15, color: RC.teal),
                        const SizedBox(width: RS.x6),
                        Text(
                          label,
                          style: RT.captionSm.copyWith(
                            color: RC.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ---- Property CTA ----
          Padding(
            padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, 0),
            child: RCard(
              color: RC.navy,
              showBorder: false,
              padding: const EdgeInsets.all(RS.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AED 8,200,000',
                      style: RT.price.copyWith(color: Colors.white)),
                  const SizedBox(height: RS.x4),
                  Text('Luxury Villa',
                      style: RT.title.copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Property ID: RV-9842',
                      style: RT.captionSm.copyWith(color: Colors.white60)),
                  const SizedBox(height: RS.x20),
                  Row(
                    children: [
                      Expanded(
                        child: RButton(
                          '3D Tour',
                          icon: Icons.view_in_ar_outlined,
                          compact: true,
                          expanded: true,
                          onPressed: () {
                            toast(context, '3D tour is not available in the local build',
                                icon: Icons.info_outline_rounded);
                          },
                        ),
                      ),
                      const SizedBox(width: RS.x8),
                      Expanded(
                        child: RButton(
                          'Brochure',
                          kind: RButtonKind.outline,
                          icon: Icons.picture_as_pdf_outlined,
                          compact: true,
                          expanded: true,
                          onPressed: () => toast(context, 'Brochure downloading',
                              icon: Icons.download_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RS.x8),
                  RButton(
                    'Book Viewing',
                    kind: RButtonKind.outline,
                    icon: Icons.event_available_outlined,
                    expanded: true,
                    onPressed: () => showBookViewingSheet(context),
                  ),
                ],
              ),
            ),
          ),

          const BottomGutter(),
        ],
      ),
    );
  }
}

/// Simple proportional schematic so the floor plan tab shows a real drawing
/// rather than a stock image.
class _PlanSchematic extends StatelessWidget {
  const _PlanSchematic({required this.plan});

  final FloorPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: RC.surface,
        borderRadius: RR.card,
        border: Border.all(color: RC.border),
        boxShadow: RShadow.card,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(RS.x16),
              child: CustomPaint(painter: _SchematicPainter(plan.rooms.length)),
            ),
          ),
          Positioned(
            top: RS.x12,
            left: RS.x16,
            child: RBadge(plan.name, color: RC.navy),
          ),
          Positioned(
            bottom: RS.x12,
            right: RS.x12,
            child: Row(
              children: [
                RIconButton(
                  icon: Icons.zoom_out_map_rounded,
                  tooltip: 'Expand plan',
                  onTap: () => toast(context, 'Opening full-screen plan',
                      icon: Icons.zoom_out_map_rounded),
                ),
                const SizedBox(width: RS.x8),
                RIconButton(
                  icon: Icons.download_outlined,
                  tooltip: 'Download plan',
                  onTap: () => toast(context, 'Floor plan PDF downloading',
                      icon: Icons.download_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchematicPainter extends CustomPainter {
  _SchematicPainter(this.roomCount);

  final int roomCount;

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()
      ..color = RC.navy.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fill = Paint()..color = RC.tealSoft.withOpacity(0.55);

    // Outer envelope.
    final outer = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(outer, fill);
    canvas.drawRect(outer, wall);

    // Deterministic partition layout that scales with the room count.
    final cols = roomCount <= 4 ? 2 : 3;
    final rows = (roomCount / cols).ceil();
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final thin = Paint()
      ..color = RC.navy.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 1; i < cols; i++) {
      canvas.drawLine(
        Offset(cellW * i, 0),
        Offset(cellW * i, size.height),
        thin,
      );
    }
    for (var i = 1; i < rows; i++) {
      canvas.drawLine(
        Offset(0, cellH * i),
        Offset(size.width, cellH * i),
        thin,
      );
    }

    // Room number markers.
    for (var i = 0; i < roomCount; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final center = Offset(cellW * (col + 0.5), cellH * (row + 0.5));

      canvas.drawCircle(center, 11, Paint()..color = RC.teal);
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_SchematicPainter old) => old.roomCount != roomCount;
}

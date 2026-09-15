import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';

/// Saved searches — saved criteria with alerts when matches are found.
class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key});

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  late final List<_SavedSearch> _searches;

  @override
  void initState() {
    super.initState();
    _searches = [
      _SavedSearch(
        id: 1,
        query: 'Villas in Dubai Marina',
        filters: '3+ beds • Under \$2M • With pool',
        alerts: true,
        matches: 12,
        lastChecked: '2 hours ago',
      ),
      _SavedSearch(
        id: 2,
        query: 'Apartments in Business Bay',
        filters: '2 beds • \$80K–\$120K/yr • High floor',
        alerts: true,
        matches: 8,
        lastChecked: '1 day ago',
      ),
      _SavedSearch(
        id: 3,
        query: 'Penthouses in Palm Jumeirah',
        filters: '4+ beds • Sea view • Furnished',
        alerts: false,
        matches: 3,
        lastChecked: '3 days ago',
      ),
      _SavedSearch(
        id: 4,
        query: 'Offices in DIFC',
        filters: '1000+ sqft • Fitted • Parking',
        alerts: true,
        matches: 5,
        lastChecked: '5 days ago',
      ),
    ];
  }

  void _toggleAlert(int id) {
    setState(() {
      final idx = _searches.indexWhere((s) => s.id == id);
      _searches[idx].alerts = !_searches[idx].alerts;
    });
    toast(
      context,
      _searches.firstWhere((s) => s.id == id).alerts
          ? 'Alerts enabled'
          : 'Alerts disabled',
      icon: Icons.notifications_outlined,
    );
  }

  void _deleteSearch(int id) {
    setState(() => _searches.removeWhere((s) => s.id == id));
    toast(context, 'Search removed', icon: Icons.delete_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, matchTextDirection: true,
              size: 18, color: RC.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('saved_searches'.tr(), style: RT.h2),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, Routes.search),
            icon: const Icon(Icons.add_rounded, size: 18, color: RC.teal),
            label:
                Text('new_label'.tr(), style: RT.bodyStrong.copyWith(color: RC.teal)),
          ),
          const SizedBox(width: RS.x4),
        ],
      ),
      body: _searches.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(RS.x40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 56, color: RC.textTertiary),
                    const SizedBox(height: RS.x16),
                    Text('no_saved_searches'.tr(), style: RT.h2),
                    const SizedBox(height: RS.x6),
                    Text(
                      'Search for properties and save your criteria to get alerts when new matches are found.',
                      style: RT.body.copyWith(color: RC.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: RS.x24),
                    RButton(
                      'Start Searching',
                      expanded: true,
                      icon: Icons.search_rounded,
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.search),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: RS.x8),

                // ---- Info banner ----
                Padding(
                  padding: RS.page,
                  child: InfoBanner(
                    title: 'Property alerts',
                    body:
                        'When alerts are enabled, we will notify you when new properties match your saved search.',
                    icon: Icons.notifications_active_outlined,
                  ),
                ),

                const SizedBox(height: RS.x16),

                // ---- Search list ----
                Padding(
                  padding: RS.page,
                  child: Column(
                    children: [
                      for (final search in _searches)
                        Padding(
                          padding: const EdgeInsets.only(bottom: RS.x12),
                          child: RCard(
                            padding: const EdgeInsets.all(RS.x16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IconBubble(
                                      Icons.bookmark_rounded,
                                      tint: search.alerts ? RC.teal : RC.textSecondary,
                                      size: 38,
                                    ),
                                    const SizedBox(width: RS.x12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(search.query, style: RT.title),
                                          const SizedBox(height: 2),
                                          Text(search.filters,
                                              style: RT.captionSm),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                          Icons.more_vert_rounded,
                                          size: 20,
                                          color: RC.textTertiary),
                                      onSelected: (v) {
                                        if (v == 'alert') _toggleAlert(search.id);
                                        if (v == 'delete') _deleteSearch(search.id);
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'alert',
                                          child: Text(search.alerts
                                              ? 'Pause alerts'
                                              : 'Resume alerts'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('delete'.tr(),
                                              style:
                                                  TextStyle(color: RC.danger)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: RS.x12),
                                Row(
                                  children: [
                                    RBadge(
                                      '${search.matches} matches',
                                      color: RC.teal,
                                      icon: Icons.home_outlined,
                                    ),
                                    const SizedBox(width: RS.x8),
                                    RBadge(
                                      search.alerts ? 'Alerts on' : 'Alerts off',
                                      color: search.alerts
                                          ? RC.success
                                          : RC.textSecondary,
                                      icon: search.alerts
                                          ? Icons.notifications_active_outlined
                                          : Icons.notifications_off_outlined,
                                    ),
                                    const Spacer(),
                                    Text(
                                      search.lastChecked,
                                      style: RT.captionSm,
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

                const SizedBox(height: RS.x32),
              ],
            ),
    );
  }
}

class _SavedSearch {
  _SavedSearch({
    required this.id,
    required this.query,
    required this.filters,
    required this.alerts,
    required this.matches,
    required this.lastChecked,
  });

  final int id;
  final String query;
  final String filters;
  bool alerts;
  final int matches;
  final String lastChecked;
}

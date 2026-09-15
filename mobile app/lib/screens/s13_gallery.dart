import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:video_player/video_player.dart';

import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';
import '../widgets/resivyn_image.dart';

/// SCREEN 13 — PROPERTY GALLERY
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, this.property});

  final Property? property;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _tab = 0;
  int _featuredIndex = 0;

  Property get _property => widget.property ?? MockData.luxuryVilla;

  List<GalleryItem> get _photos =>
      _property.gallery.isEmpty
          ? [GalleryItem(label: _property.title, url: _property.imageUrl)]
          : _property.gallery;

  static const _videos = [
    GalleryItem(
        label: 'Cinematic Walkthrough',
        url: Img.villaDusk,
        isVideo: true,
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
    GalleryItem(
        label: 'Drone Exterior Tour',
        url: Img.dubaiSkyline,
        isVideo: true,
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
    GalleryItem(
        label: 'Community Overview',
        url: Img.pool,
        isVideo: true,
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
  ];

  void _openPhotoViewer(GalleryItem item) {
    showDialog<void>(
      context: context,
      barrierColor: RC.navy.withOpacity(0.92),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(RS.x16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: RR.card,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ResivynImage(url: item.url),
              ),
            ),
            const SizedBox(height: RS.x16),
            Text(item.label, style: RT.title.copyWith(color: Colors.white)),
            const SizedBox(height: RS.x16),
            RButton(
              'Close',
              kind: RButtonKind.outline,
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoPlayer(GalleryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _VideoViewer(item: item),
      ),
    );
  }

  void _openViewer(GalleryItem item) {
    if (item.isVideo) {
      _openVideoPlayer(item);
    } else {
      _openPhotoViewer(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'Photos (${_property.photoCount})',
      'Videos (${_videos.length})',
      '360° Tour',
    ];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ResivynHeader(
            showBack: true,
            trailing: [
              RIconButton(
                icon: Icons.ios_share_rounded,
                tooltip: 'Share gallery',
                onTap: () {
                  toast(context, 'Gallery link copied to clipboard',
                      icon: Icons.check_circle_outline_rounded);
                },
              ),
            ],
          ),

          PageTitle('Property Gallery', subtitle: _property.location),

          RUnderlineTabs(
            items: tabs,
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),

          const SizedBox(height: RS.x20),

          if (_tab == 0) ..._photosTab(),
          if (_tab == 1) ..._videosTab(),
          if (_tab == 2) ..._tourTab(),

          const BottomGutter(extra: RS.x8),
        ],
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(RS.x20, RS.x8, RS.x20, RS.x12),
          child: RButton(
            'View 360° Tour',
            expanded: true,
            icon: Icons.threesixty_rounded,
            onPressed: () {
              setState(() => _tab = 2);
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _photosTab() {
    final featured = _photos[_featuredIndex.clamp(0, _photos.length - 1)];

    return [
      // Large featured image.
      Padding(
        padding: RS.page,
        child: GestureDetector(
          onTap: () => _openViewer(featured),
          child: ClipRRect(
            borderRadius: RR.card,
            child: Stack(
              children: [
                ResivynImage(url: featured.url, height: 220),
                Positioned(
                  left: RS.x16,
                  bottom: RS.x16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: RS.x12, vertical: RS.x6),
                    decoration: BoxDecoration(
                      color: RC.navy.withOpacity(0.7),
                      borderRadius: RR.chip,
                    ),
                    child: Text(
                      featured.label,
                      style: RT.captionSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: RS.x12,
                  top: RS.x12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: RS.x10, vertical: RS.x6),
                    decoration: BoxDecoration(
                      color: RC.navy.withOpacity(0.7),
                      borderRadius: RR.chip,
                    ),
                    child: Text(
                      '${_featuredIndex + 1} / ${_property.photoCount}',
                      style: RT.captionSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      const SectionTitle('All Photos'),

      // Two-column grid.
      Padding(
        padding: RS.page,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: RS.x12,
            crossAxisSpacing: RS.x12,
            childAspectRatio: 1.15,
          ),
          itemCount: _photos.length,
          itemBuilder: (context, i) {
            final item = _photos[i];
            final active = i == _featuredIndex;
            return GestureDetector(
              onTap: () => setState(() => _featuredIndex = i),
              onLongPress: () => _openViewer(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  borderRadius: RR.image,
                  border: Border.all(
                    color: active ? RC.teal : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: RR.image,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ResivynImage(url: item.url),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(RS.x8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                RC.navy.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RT.captionSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _videosTab() {
    return [
      Padding(
        padding: RS.page,
        child: Column(
          children: [
            for (final video in _videos)
              Padding(
                padding: const EdgeInsets.only(bottom: RS.x12),
                child: GestureDetector(
                  onTap: () => _openViewer(video),
                  child: ClipRRect(
                    borderRadius: RR.card,
                    child: Stack(
                      children: [
                        ResivynImage(url: video.url, height: 170),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: RC.navy.withOpacity(0.32),
                            ),
                          ),
                        ),
                        const Positioned.fill(
                          child: Center(
                            child: Icon(Icons.play_circle_fill_rounded,
                                size: 52, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          left: RS.x16,
                          bottom: RS.x14,
                          child: Text(
                            video.label,
                            style: RT.title.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _tourTab() {
    return [
      const Padding(
        padding: RS.page,
        child: Text('drag_property'.tr(),
            style: RT.caption),
      ),
      Padding(
        padding: RS.page,
        child: ClipRRect(
          borderRadius: RR.card,
          child: SizedBox(
            height: 300,
            child: PanoramaViewer(
              child: Image.network(
                _property.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: RC.navy,
                  alignment: Alignment.center,
                  child: const Icon(Icons.threesixty_rounded,
                      size: 48, color: Colors.white54),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: RS.x12),
      const Padding(
        padding: RS.page,
        child: InfoBanner(
          title: 'Interactive 360° view',
          body: 'Drag anywhere on the image to look around. '
              'Use two fingers to zoom in and out.',
          icon: Icons.threesixty_rounded,
        ),
      ),
      const SectionTitle('Tour Stops'),
      Padding(
        padding: RS.page,
        child: RCard(
          padding: const EdgeInsets.symmetric(horizontal: RS.x16),
          child: Column(
            children: [
              for (var i = 0; i < _photos.length; i++) ...[
                RowItem(
                  title: _photos[i].label,
                  subtitle: 'Stop ${i + 1}',
                  leading: const IconBubble(Icons.threesixty_rounded,
                      tint: RC.teal, size: 38),
                  onTap: () => _openViewer(_photos[i]),
                ),
                if (i != _photos.length - 1) const ThinDivider(inset: 50),
              ],
            ],
          ),
        ),
      ),
    ];
  }
}

/// Fullscreen video player for a property video.
class _VideoViewer extends StatefulWidget {
  const _VideoViewer({required this.item});

  final GalleryItem item;

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = widget.item.videoUrl;
    if (url == null) {
      setState(() => _failed = true);
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RC.navy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x8, RS.x8, RS.x8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: RS.x8),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RT.h2.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RS.x8),
            Expanded(
              child: Center(
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_failed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_outlined,
              size: 56, color: Colors.white38),
          const SizedBox(height: RS.x12),
          Text(
            'Video unavailable',
            style: RT.title.copyWith(color: Colors.white),
          ),
          const SizedBox(height: RS.x4),
          Text(
            'Please check your connection and try again.',
            style: RT.captionSm.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: RS.x20),
          RButton(
            'Retry',
            kind: RButtonKind.outline,
            onPressed: () {
              setState(() {
                _failed = false;
                _ready = false;
              });
              _init();
            },
          ),
        ],
      );
    }

    if (!_ready) {
      return const CircularProgressIndicator(color: RC.teal);
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          GestureDetector(
            onTap: _toggle,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (context, value, _) {
                final playing = value.isPlaying;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: playing ? 0.0 : 1.0,
                  child: const Icon(Icons.play_circle_fill,
                      size: 72, color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggle() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
      } else {
        c.play();
      }
    });
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/music_list.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/album_cover.dart';
import '../widgets/misc.dart';
import '../widgets/sheet.dart';

/// Buscar un disco en Spotify y agregarlo a la lista (si es de discos) o
/// elegir sus canciones (si es de canciones). Se pueden agregar varias
/// cosas sin cerrar la hoja; al cerrar, devuelve cuántos elementos entraron.
Future<int> showAddToList(BuildContext context, MusicList list) async {
  final added = await showVSheet<int>(context, (_) => _AddToList(list: list));
  return added ?? 0;
}

class _AddToList extends StatefulWidget {
  const _AddToList({required this.list});

  final MusicList list;

  @override
  State<_AddToList> createState() => _AddToListState();
}

class _AddToListState extends State<_AddToList> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  AlbumPage? _page;
  bool _loading = false;
  Object? _error;

  /// Ids que ya están en la lista (los iniciales más lo agregado aquí).
  late final Set<String> _present = {for (final i in widget.list.items) i.id};
  int _totalAdded = 0;
  String? _notice;
  Timer? _noticeTimer;

  // Segundo paso (listas de canciones): el disco elegido y sus canciones.
  Album? _picked;
  AlbumDetail? _detail;
  Object? _detailError;
  final Set<String> _selected = {};
  bool _adding = false;

  bool get _tracks => widget.list.itemType == ListItemType.tracks;

  @override
  void dispose() {
    _debounce?.cancel();
    _noticeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      _requestId++;
      setState(() {
        _page = null;
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 380), () => _search(q));
  }

  Future<void> _search(String q) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ServicesScope.of(context).spotify.search(q);
      if (id != _requestId || !mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } catch (e) {
      if (id != _requestId || !mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _showNotice(String text) {
    _noticeTimer?.cancel();
    setState(() => _notice = text);
    _noticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  Future<void> _add(List<ListItem> items) async {
    if (items.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      final outcome = await ServicesScope.of(context).lists.addTo(widget.list.id, items);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      // Solo lo que de verdad quedó en la lista (lo que no cupo por el tope
      // no se marca como presente).
      _present.addAll(outcome.items.map((i) => i.id));
      _totalAdded += outcome.added;
      _showNotice(outcome.message(widget.list.itemType, context.l10n));
    } catch (e) {
      if (mounted) _showNotice(context.l10n.addFailed(describeError(e, context.l10n)));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _pickAlbum(Album album) async {
    if (!_tracks) {
      await _add([ListItem.fromAlbum(album)]);
      return;
    }
    setState(() {
      _picked = album;
      _detail = ServicesScope.of(context).spotify.cachedAlbum(album.id);
      _detailError = null;
      _selected.clear();
    });
    if (_detail != null) return;
    try {
      final detail = await ServicesScope.of(context).spotify.album(album.id);
      if (!mounted || _picked?.id != album.id) return;
      setState(() => _detail = detail);
    } catch (e) {
      if (mounted) setState(() => _detailError = e);
    }
  }

  Future<void> _addSelected() async {
    final detail = _detail;
    if (detail == null) return;
    final items = [
      for (final t in detail.tracks)
        if (_selected.contains(t.id)) ListItem.fromTrack(t, detail),
    ];
    await _add(items);
    if (mounted) setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final picked = _picked;
    return SheetScaffold(
      title: picked == null ? context.l10n.addToListTitle : picked.name,
      subtitle: picked == null
          ? widget.list.name
          : context.l10n.addPickTracksSubtitle(picked.artist),
      height: 0.9,
      scrollable: false,
      trailing: picked == null
          ? null
          : IconButton(
              key: const ValueKey('add-back'),
              tooltip: context.l10n.addBackToResults,
              onPressed: () => setState(() {
                _picked = null;
                _detail = null;
                _selected.clear();
              }),
              icon: Icon(Icons.arrow_back_rounded, color: c.text),
            ),
      child: Column(
        children: [
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: Container(
                key: const ValueKey('add-notice'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _notice!,
                  style: VText.ui(13, weight: 700, color: c.accent),
                ),
              ),
            ),
          Expanded(
            child: picked == null ? _searchStep(c) : _tracksStep(c, picked),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
            child: picked == null || !_tracks
                ? SecondaryDone(
                    onTap: () => Navigator.of(context).pop(_totalAdded),
                  )
                : FilledButton(
                    key: const ValueKey('add-selected-tracks'),
                    onPressed: _selected.isEmpty || _adding ? null : _addSelected,
                    child: Text(
                      _selected.isEmpty
                          ? context.l10n.addChooseTracks
                          : context.l10n.addSelected(ListItemType.tracks.count(_selected.length, context.l10n)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchStep(ViniloPalette c) {
    final page = _page;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
          child: TextField(
            key: const ValueKey('add-search'),
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (q) => _search(q.trim()),
            style: VText.ui(16, weight: 600),
            decoration: InputDecoration(
              hintText: _tracks ? context.l10n.addSearchTrackAlbum : context.l10n.addSearchAlbum,
              prefixIcon: Icon(Icons.search_rounded, color: c.text3),
            ),
          ),
        ),
        Expanded(
          child: _error != null
              ? EmptyState(
                  title: context.l10n.spotifyNoResponse,
                  message: describeError(_error, context.l10n),
                  labelColor: c.danger,
                  action: TextButton(
                    onPressed: () => _search(_controller.text.trim()),
                    child: Text(context.l10n.retry),
                  ),
                )
              : _loading && page == null
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                      itemCount: 5,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, _) => const Skeleton(height: 66, radius: 16),
                    )
                  : page == null
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
                          child: Text(
                            _tracks
                                ? context.l10n.addPromptTracks
                                : context.l10n.addPromptAlbums,
                            textAlign: TextAlign.center,
                            style: VText.ui(14, color: c.text3, height: 1.4),
                          ),
                        )
                      : page.items.isEmpty
                          ? EmptyState(
                              title: context.l10n.searchNothingTitle,
                              message: context.l10n.addNothingBody,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
                              physics: const BouncingScrollPhysics(),
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: page.items.length,
                              itemBuilder: (context, i) {
                                final album = page.items[i];
                                final present = !_tracks && _present.contains(album.id);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: c.surface2,
                                    borderRadius: BorderRadius.circular(18),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: ValueKey('add-result-$i'),
                                      onTap: _adding ? null : () => _pickAlbum(album),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            AlbumCover(url: album.smallCover, size: 50, radius: 10),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    album.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: VText.ui(15, weight: 700),
                                                  ),
                                                  Text(
                                                    album.subtitle,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: VText.ui(12, color: c.text2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(
                                              _tracks
                                                  ? Icons.chevron_right_rounded
                                                  : present
                                                      ? Icons.check_circle_rounded
                                                      : Icons.add_circle_outline_rounded,
                                              color: present ? c.accent : c.text3,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
        ),
      ],
    );
  }

  Widget _tracksStep(ViniloPalette c, Album album) {
    final detail = _detail;
    if (_detailError != null) {
      return EmptyState(
        title: context.l10n.albumLoadFailed,
        message: describeError(_detailError, context.l10n),
        labelColor: c.danger,
        action: TextButton(
          onPressed: () => _pickAlbum(album),
          child: Text(context.l10n.retry),
        ),
      );
    }
    if (detail == null) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, _) => const Skeleton(height: 18, radius: 6),
      );
    }
    final all = detail.tracks.every((t) => _selected.contains(t.id));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 14, 0),
          child: Row(
            children: [
              AlbumCover(url: album.smallCover, size: 44, radius: 9),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.countTracks(detail.tracks.length),
                  style: VText.ui(13, color: c.text2),
                ),
              ),
              TextButton(
                key: const ValueKey('select-all-tracks'),
                onPressed: () => setState(() {
                  if (all) {
                    _selected.clear();
                  } else {
                    _selected.addAll(detail.tracks.map((t) => t.id));
                  }
                }),
                child: Text(
                  all ? context.l10n.selectNone : context.l10n.filterAll,
                  style: VText.ui(13, weight: 700, color: c.accent),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
            physics: const BouncingScrollPhysics(),
            itemCount: detail.tracks.length,
            itemBuilder: (context, i) {
              final t = detail.tracks[i];
              final present = _present.contains(t.id);
              final selected = _selected.contains(t.id);
              return InkWell(
                key: ValueKey('add-track-$i'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  if (selected) {
                    _selected.remove(t.id);
                  } else {
                    _selected.add(t.id);
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 22,
                        color: selected ? c.accent : c.text3,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(15, weight: 600),
                        ),
                      ),
                      if (present)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(context.l10n.addAlreadyHere, style: VText.label(9, color: c.text3)),
                        ),
                      const SizedBox(width: 10),
                      Text(t.duration, style: VText.ui(13, color: c.text3)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Botón "Listo" sobre la segunda superficie, para cerrar la hoja.
class SecondaryDone extends StatelessWidget {
  const SecondaryDone({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Material(
      key: const ValueKey('add-done'),
      color: c.surface2,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(context.l10n.done, style: VText.ui(16, weight: 700, color: c.text)),
          ),
        ),
      ),
    );
  }
}

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
import '../widgets/line_field.dart';
import '../widgets/sheet.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';

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
    final l10n = context.l10n;
    final picked = _picked;
    return SheetScaffold(
      overline: widget.list.name,
      title: picked == null ? l10n.addToListTitle : picked.name,
      subtitle: picked == null ? null : l10n.addPickTracksSubtitle(picked.artist),
      titleSize: 40,
      height: 0.9,
      scrollable: false,
      trailing: picked == null
          ? null
          : VIconButton(
              key: const ValueKey('add-back'),
              icon: VIcon.back,
              tooltip: l10n.addBackToResults,
              onTap: () => setState(() {
                _picked = null;
                _detail = null;
                _selected.clear();
              }),
            ),
      footer: picked == null || !_tracks
          ? VSecondaryButton(
              key: const ValueKey('add-done'),
              label: l10n.done,
              center: true,
              onPressed: () => Navigator.of(context).pop(_totalAdded),
            )
          : VPrimaryButton.accent(
              key: const ValueKey('add-selected-tracks'),
              label: _selected.isEmpty
                  ? l10n.addChooseTracks
                  : l10n.addSelected(ListItemType.tracks.count(_selected.length, l10n)),
              busy: _adding,
              onPressed: _selected.isEmpty ? null : _addSelected,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 0),
              child: VMono(
                _notice!,
                key: const ValueKey('add-notice'),
                color: c.accentText,
                maxLines: 2,
              ),
            ),
          Expanded(
            child: picked == null ? _searchStep(c) : _tracksStep(c, picked),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _searchStep(ViniloPalette c) {
    final l10n = context.l10n;
    final page = _page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
          child: LineField(
            fieldKey: const ValueKey('add-search'),
            controller: _controller,
            autofocus: true,
            hint: _tracks ? l10n.addSearchTrackAlbum : l10n.addSearchAlbum,
            leading: VIconView(VIcon.search, size: 20, color: c.ink),
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (q) => _search(q.trim()),
          ),
        ),
        Expanded(
          child: _error != null
              ? SingleChildScrollView(
                  child: VEmptyState(
                    title: l10n.spotifyNoResponse,
                    message: describeError(_error, l10n),
                    action: VTextLink(
                      l10n.retry,
                      onTap: () => _search(_controller.text.trim()),
                    ),
                  ),
                )
              : _loading && page == null
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 0),
                      itemCount: 5,
                      itemBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            VSkeleton(width: 48, height: 48),
                            SizedBox(width: 12),
                            Expanded(child: VSkeleton(height: 30)),
                          ],
                        ),
                      ),
                    )
                  : page == null
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(VSpace.page, 22, VSpace.page, 0),
                          child: Text(
                            _tracks ? l10n.addPromptTracks : l10n.addPromptAlbums,
                            style: VText.ui(14, color: c.ink2, height: 1.45),
                          ),
                        )
                      : page.items.isEmpty
                          ? SingleChildScrollView(
                              child: VEmptyState(
                                title: l10n.searchNothingTitle,
                                message: l10n.addNothingBody,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 12),
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: page.items.length,
                              itemBuilder: (context, i) {
                                final album = page.items[i];
                                final present = !_tracks && _present.contains(album.id);
                                return Pressable(
                                  key: ValueKey('add-result-$i'),
                                  onTap: _adding ? null : () => _pickAlbum(album),
                                  builder: (context, pressed) => Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: pressed ? c.inkA(0.04) : null,
                                      border: Border(bottom: BorderSide(color: c.lineSoft)),
                                    ),
                                    child: Row(
                                      children: [
                                        AlbumCover(url: album.smallCover, size: 48),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                album.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: VText.ui(15, weight: 600),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                album.subtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: VText.ui(13, color: c.ink3),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (_tracks)
                                          VIconView(VIcon.chevronRight, size: 16, color: c.ink4)
                                        else
                                          Container(
                                            width: 36,
                                            height: 36,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: present ? c.accent : null,
                                              border: present ? null : Border.all(color: c.lineStrong),
                                            ),
                                            child: VIconView(
                                              present ? VIcon.check : VIcon.plus,
                                              size: present ? 12 : 14,
                                              color: present ? c.onAccent : c.ink,
                                            ),
                                          ),
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

  Widget _tracksStep(ViniloPalette c, Album album) {
    final l10n = context.l10n;
    final detail = _detail;
    if (_detailError != null) {
      return SingleChildScrollView(
        child: VEmptyState(
          title: l10n.albumLoadFailed,
          message: describeError(_detailError, l10n),
          action: VTextLink(l10n.retry, onTap: () => _pickAlbum(album)),
        ),
      );
    }
    if (detail == null) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
        itemCount: 8,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: VSkeleton(height: 14),
        ),
      );
    }
    final all = detail.tracks.every((t) => _selected.contains(t.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
          child: VSectionHeader(
            l10n.countTracks(detail.tracks.length),
            action: all ? l10n.selectNone : l10n.filterAll,
            actionKey: const ValueKey('select-all-tracks'),
            onAction: () => setState(() {
              if (all) {
                _selected.clear();
              } else {
                _selected.addAll(detail.tracks.map((t) => t.id));
              }
            }),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 0, VSpace.page, 12),
            itemCount: detail.tracks.length,
            itemBuilder: (context, i) {
              final t = detail.tracks[i];
              final present = _present.contains(t.id);
              final selected = _selected.contains(t.id);
              return Pressable(
                key: ValueKey('add-track-$i'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _selected.remove(t.id);
                    } else {
                      _selected.add(t.id);
                    }
                  });
                },
                builder: (context, pressed) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: pressed ? c.inkA(0.04) : null,
                    border: Border(top: BorderSide(color: c.lineSoft)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? c.accentText : null,
                          border: selected ? null : Border.all(color: c.lineStrong),
                        ),
                        child: selected ? VIconView(VIcon.check, size: 9, color: c.onAccent) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(15),
                        ),
                      ),
                      if (present)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: VMono(l10n.addAlreadyHere, size: 9.5, color: c.ink4),
                        ),
                      const SizedBox(width: 12),
                      Text(t.duration, style: VText.mono(12, tracking: 0, color: c.ink3)),
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

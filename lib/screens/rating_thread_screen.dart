import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../models/rating.dart';
import '../models/reply.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/format.dart';
import '../util/share_links.dart';
import '../theme/oklch.dart';
import '../widgets/album_cover.dart';
import '../widgets/comment_card.dart';
import '../widgets/line_field.dart';
import '../widgets/mention_text.dart';
import '../widgets/share_button.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

/// El hilo de una nota: el disco y la nota arriba, las respuestas debajo y
/// el campo para responder fijo abajo. Las respuestas son de un solo nivel:
/// "Responder" en una respuesta se la dirige a su autora con su @ al
/// principio. Mantener pulsada una respuesta propia (o cualquiera, si la
/// nota es mía) ofrece borrarla.
class RatingThreadScreen extends StatefulWidget {
  const RatingThreadScreen({
    super.key,
    required this.ratingId,
    this.initial,
    this.compose = false,
  });

  final String ratingId;
  final RatingEntry? initial;

  /// Abre el teclado al entrar (desde "Responder").
  final bool compose;

  @override
  State<RatingThreadScreen> createState() => _RatingThreadScreenState();
}

class _RatingThreadScreenState extends State<RatingThreadScreen> {
  Stream<RatingEntry?>? _rating;
  Stream<List<Reply>>? _replies;
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// A quién se le responde dentro del hilo (null = a la nota).
  PersonInfo? _replyingTo;
  bool _sending = false;

  /// Pendiente de abrir el teclado en cuanto aparezca el campo.
  late bool _wantsFocus = widget.compose;

  /// Las respuestas que se vieron la última vez: si llega una mía, baja al
  /// final; y sus autoras son a quienes se puede mencionar.
  List<Reply> _seen = const [];

  /// El color de la portada del disco (la nota va en su tono).
  Color? _coverColor;
  bool _paletteAsked = false;

  void _askPalette(RatingEntry entry) {
    if (_paletteAsked) return;
    _paletteAsked = true;
    ServicesScope.of(context)
        .palette
        .dominant(entry.album.smallCover ?? entry.album.bestCover)
        .then((color) {
      if (color != null && mounted) setState(() => _coverColor = color);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rating != null) return;
    final replies = ServicesScope.of(context).replies;
    _rating = replies.watchRating(widget.ratingId);
    _replies = replies.watch(widget.ratingId);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// "Responder": a la nota (`person` null) o a alguien del hilo, con su @
  /// al principio del texto.
  void _replyTo(PersonInfo? person) {
    HapticFeedback.selectionClick();
    final me = CurrentUser.of(context);
    final target = person == null || person.uid == me.uid ? null : person;
    final previous = _replyingTo;
    setState(() => _replyingTo = target);
    var text = _text.text;
    if (previous != null && text.startsWith(replyPrefix(previous))) {
      text = text.substring(replyPrefix(previous).length);
    }
    if (target != null) text = '${replyPrefix(target)}$text';
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _focus.requestFocus();
  }

  void _cancelReplyTo() {
    final previous = _replyingTo;
    setState(() => _replyingTo = null);
    if (previous == null) return;
    final prefix = replyPrefix(previous);
    if (prefix.isNotEmpty && _text.text.startsWith(prefix)) {
      final text = _text.text.substring(prefix.length);
      _text.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  Future<void> _send(RatingEntry entry) async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    final me = CurrentUser.of(context);
    final repo = ServicesScope.of(context).replies;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    // Se avisa a quien se le respondió y a cualquier persona del hilo cuyo @
    // aparezca en el texto.
    final people = <String, PersonInfo>{
      for (final p in [..._seen.map((r) => r.user), ?_replyingTo]) p.uid: p,
    };
    setState(() => _sending = true);
    try {
      await repo.add(entry: entry, me: me, text: text, mentioned: people.values);
      HapticFeedback.lightImpact();
      _text.clear();
      if (mounted) setState(() => _replyingTo = null);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.replySendFailed(describeError(e, l10n)))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _askDelete(Reply reply) async {
    final me = CurrentUser.of(context);
    if (!reply.canDelete(me.uid)) return;
    HapticFeedback.mediumImpact();
    final repo = ServicesScope.of(context).replies;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirmSheet(
      context,
      title: l10n.replyDelete,
      message: '“${replySnippet(reply.text, max: 70)}”\n${l10n.replyDeleteHint}',
      confirmLabel: l10n.replyDelete,
      danger: true,
      confirmKey: const ValueKey('reply-delete'),
    );
    if (!ok) return;
    try {
      await repo.delete(reply, me: me.uid);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.replyDeleted), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.replyDeleteFailed(describeError(e, l10n)))),
      );
    }
  }

  /// Llamado al pintar la lista: si llegó una respuesta mía, baja al final.
  void _onReplies(List<Reply> replies, String me) {
    final grew = replies.length > _seen.length;
    final mineLast = replies.isNotEmpty && replies.last.uid == me;
    final first = _seen.isEmpty;
    _seen = replies;
    if (!grew || !mineLast || first) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final me = CurrentUser.of(context);
    final cover = _coverColor;
    final tone = cover == null ? c.accent : coverTone(cover);
    return Scaffold(
      body: StreamBuilder<RatingEntry?>(
        stream: _rating,
        initialData: widget.initial,
        builder: (context, ratingSnap) {
          final entry = ratingSnap.data;
          final gone = entry == null &&
              ratingSnap.connectionState == ConnectionState.active;
          if (entry != null) _askPalette(entry);
          if (entry != null && _wantsFocus) {
            _wantsFocus = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _focus.requestFocus();
            });
          }
          return Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: StreamBuilder<List<Reply>>(
                    stream: _replies,
                    builder: (context, repliesSnap) {
                      final replies = repliesSnap.data;
                      if (replies != null) _onReplies(replies, me.uid);
                      return CustomScrollView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverToBoxAdapter(
                            child: VPageHeader(
                              title: l10n.threadTitle,
                              titleKey: const ValueKey('thread-title'),
                              subtitle: replies == null ? l10n.loading : l10n.countReplies(replies.length),
                              subtitleKey: const ValueKey('thread-count'),
                              topTrailing: entry == null
                                  ? null
                                  : ShareButton(
                                      key: const ValueKey('share-rating'),
                                      style: VIconButtonStyle.bordered,
                                      message: (l) => shareRatingMessage(entry, l, mine: entry.uid == me.uid),
                                    ),
                            ),
                          ),
                          if (entry != null)
                            SliverToBoxAdapter(
                              child: _ThreadNote(
                                entry: entry,
                                tone: tone,
                                onReply: () => _replyTo(null),
                              ),
                            )
                          else if (gone)
                            SliverToBoxAdapter(
                              child: _Lined(
                                child: VEmptyState(
                                  key: const ValueKey('thread-gone'),
                                  title: l10n.threadRatingGoneTitle,
                                  message: l10n.threadRatingGoneBody,
                                ),
                              ),
                            )
                          else
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: VSpace.page),
                                child: VSkeleton(height: 170),
                              ),
                            ),
                          if (entry != null) ...[
                            if (replies == null)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                                sliver: SliverList.builder(
                                  itemCount: 3,
                                  itemBuilder: (_, _) => const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        VSkeleton(width: 36, height: 36, circle: true),
                                        SizedBox(width: 12),
                                        Expanded(child: VSkeleton(height: 40)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else if (replies.isEmpty)
                              SliverToBoxAdapter(
                                child: _Lined(
                                  child: VEmptyState(
                                    key: const ValueKey('thread-empty'),
                                    title: l10n.threadEmptyTitle,
                                    message: l10n.threadEmptyBody(entry.user.name),
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                                sliver: SliverList.builder(
                                  itemCount: replies.length,
                                  itemBuilder: (context, i) => _ReplyTile(
                                    key: ValueKey('reply-$i'),
                                    index: i,
                                    reply: replies[i],
                                    onReply: () => _replyTo(replies[i].user),
                                    onLongPress: replies[i].canDelete(me.uid)
                                        ? () => _askDelete(replies[i])
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (entry != null)
                _Composer(
                  controller: _text,
                  focus: _focus,
                  replyingTo: _replyingTo,
                  hint: _replyingTo != null
                      ? l10n.replyHintTo(_replyingTo!.name)
                      : entry.uid == me.uid
                          ? l10n.replyHint
                          : l10n.replyHintTo(entry.user.name),
                  sending: _sending,
                  onCancelReplyTo: _cancelReplyTo,
                  onSend: () => _send(entry),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Un bloque con una línea arriba (los estados vacíos del hilo).
class _Lined extends StatelessWidget {
  const _Lined({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: child,
    );
  }
}

/// La nota del hilo: el disco (portada de 48, título y "Artista · año"; abre
/// su pantalla) y la nota como un comentario destacado, con "♥" y
/// "Responder", que escribe aquí mismo.
class _ThreadNote extends StatelessWidget {
  const _ThreadNote({required this.entry, required this.tone, required this.onReply});

  final RatingEntry entry;
  final Color tone;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final heroTag = 'thread-${entry.id}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            key: const ValueKey('thread-album'),
            onTap: () => openAlbum(context, entry.album, heroTag: heroTag),
            builder: (context, pressed) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: pressed ? c.inkA(0.04) : null,
                border: Border.symmetric(horizontal: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  AlbumCover(url: entry.album.smallCover, size: 48, heroTag: heroTag),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(16, weight: 600),
                        ),
                        Text(
                          entry.album.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(13, color: c.ink3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  VIconView(VIcon.chevronRight, size: 16, color: c.ink4),
                ],
              ),
            ),
          ),
          CommentCard(
            key: const ValueKey('thread-note'),
            entry: entry,
            maxLines: null,
            tone: tone,
            // Tocar la nota es responderle (ya se está en su hilo).
            onTap: onReply,
            onReply: onReply,
            replyKey: const ValueKey('thread-reply-note'),
          ),
          Container(height: 1, color: c.line),
        ],
      ),
    );
  }
}

/// Una respuesta: foto de 36, nombre, @usuario y hora en mono, el texto
/// (con las menciones en énfasis) y "Responder". Mantenerla pulsada ofrece
/// borrarla, si se puede.
class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    super.key,
    required this.index,
    required this.reply,
    required this.onReply,
    this.onLongPress,
  });

  final int index;
  final Reply reply;
  final VoidCallback onReply;

  /// Solo si se puede borrar.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final user = reply.user;
    return Pressable(
      onTap: null,
      onLongPress: onLongPress,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border(bottom: BorderSide(color: c.lineSoft)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => openUser(context, user.uid),
              child: UserAvatar(
                name: user.name,
                color: Color(user.colorValue),
                url: user.avatarUrl,
                size: 36,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => openUser(context, user.uid),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VText.ui(14, weight: 600),
                          ),
                        ),
                        if (user.handle.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: VMono(user.handle, size: 10, tracking: 0.06, color: c.ink4, uppercase: false, maxLines: 1),
                          ),
                        ],
                        const Spacer(),
                        const SizedBox(width: 8),
                        VMono(timeAgo(reply.createdAt, l10n), size: 10, tracking: 0.06, color: c.ink4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  MentionText(reply.text, style: VText.ui(14.5, height: 1.4, color: c.ink)),
                  Pressable(
                    key: ValueKey('reply-to-$index'),
                    onTap: onReply,
                    builder: (context, pressed) => Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
                      child: VMono(l10n.replyAction, tracking: 0.06, color: pressed ? c.ink : c.ink3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El campo para responder, fijo abajo: "Respondiendo a @x" con su × cuando
/// va para alguien del hilo, el texto con línea debajo y enviar. Cerca del
/// límite aparece cuántos caracteres quedan.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focus,
    required this.replyingTo,
    required this.hint,
    required this.sending,
    required this.onCancelReplyTo,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final PersonInfo? replyingTo;
  final String hint;
  final bool sending;
  final VoidCallback onCancelReplyTo;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final to = replyingTo;
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(VSpace.page, 8, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (to != null)
                Row(
                  children: [
                    Expanded(
                      child: VMono(
                        l10n.replyingTo(to.handle.isEmpty ? to.name : to.handle),
                        key: const ValueKey('replying-to'),
                        size: 10,
                        maxLines: 1,
                      ),
                    ),
                    Pressable(
                      key: const ValueKey('replying-cancel'),
                      onTap: onCancelReplyTo,
                      builder: (context, pressed) => Padding(
                        padding: const EdgeInsets.all(6),
                        child: VIconView(VIcon.close, size: 14, color: pressed ? c.ink : c.ink3),
                      ),
                    ),
                  ],
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: LineField(
                      fieldKey: const ValueKey('reply-field'),
                      controller: controller,
                      focusNode: focus,
                      hint: hint,
                      fontSize: 15,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [LengthLimitingTextInputFormatter(replyMaxLength)],
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final enabled = value.text.trim().isNotEmpty && !sending;
                      return Pressable(
                        key: const ValueKey('reply-send'),
                        onTap: enabled ? onSend : null,
                        builder: (context, pressed) => Semantics(
                          label: l10n.replySend,
                          button: true,
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: enabled ? (pressed ? c.ink : c.accent) : null,
                              border: enabled ? null : Border.all(color: c.buttonLine),
                            ),
                            child: sending
                                ? SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(strokeWidth: 1.6, color: c.ink2),
                                  )
                                : VIconView(VIcon.send, size: 18, color: enabled ? c.onAccent : c.ink4),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Cuántos caracteres quedan, solo cerca del límite.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final left = replyMaxLength - value.text.characters.length;
                  if (left >= 40) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, right: 52),
                    child: VMono(
                      '$left',
                      key: const ValueKey('reply-left'),
                      size: 10,
                      color: left <= 0 ? c.danger : c.ink4,
                      align: TextAlign.right,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

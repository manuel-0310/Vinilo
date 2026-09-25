import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../models/rating.dart';
import '../models/reply.dart';
import '../services/services.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/format.dart';
import '../util/share_links.dart';
import '../widgets/album_cover.dart';
import '../widgets/feed_card.dart';
import '../widgets/mention_text.dart';
import '../widgets/misc.dart';
import '../widgets/score_widgets.dart';
import '../widgets/share_button.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
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
    final ok = await showVSheet<bool>(
      context,
      (ctx) => SheetScaffold(
        title: l10n.replyDelete,
        subtitle: replySnippet(reply.text, max: 70),
        child: SheetAction(
          key: const ValueKey('reply-delete'),
          icon: Icons.delete_outline_rounded,
          label: l10n.replyDelete,
          hint: l10n.replyDeleteHint,
          danger: true,
          onTap: () => Navigator.of(ctx).pop(true),
        ),
      ),
    );
    if (ok != true) return;
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
    final me = CurrentUser.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: StreamBuilder<RatingEntry?>(
        stream: _rating,
        initialData: widget.initial,
        builder: (context, ratingSnap) {
          final entry = ratingSnap.data;
          final gone = entry == null &&
              ratingSnap.connectionState == ConnectionState.active;
          if (entry != null && _wantsFocus) {
            _wantsFocus = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _focus.requestFocus();
            });
          }
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    StreamBuilder<List<Reply>>(
                      stream: _replies,
                      builder: (context, repliesSnap) {
                        final replies = repliesSnap.data;
                        if (replies != null) _onReplies(replies, me.uid);
                        return CustomScrollView(
                          controller: _scroll,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(VSpace.page, topPad + 62, VSpace.page, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.threadTitle,
                                      key: const ValueKey('thread-title'),
                                      style: VText.display(38, height: 1),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      replies == null
                                          ? context.l10n.loading
                                          : context.l10n.countReplies(replies.length),
                                      key: const ValueKey('thread-count'),
                                      style: VText.ui(13, color: c.text2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 18)),
                            if (entry != null)
                              SliverToBoxAdapter(
                                child: _ThreadNote(
                                  entry: entry,
                                  onReply: () => _replyTo(null),
                                ),
                              )
                            else if (gone)
                              SliverToBoxAdapter(
                                child: EmptyState(
                                  key: const ValueKey('thread-gone'),
                                  title: context.l10n.threadRatingGoneTitle,
                                  message: context.l10n.threadRatingGoneBody,
                                ),
                              )
                            else
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: VSpace.page),
                                  child: Skeleton(height: 170, radius: 22),
                                ),
                              ),
                            if (entry != null) ...[
                              const SliverToBoxAdapter(child: SizedBox(height: 10)),
                              if (replies == null)
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(VSpace.page, 8, VSpace.page, 0),
                                  sliver: SliverList.separated(
                                    itemCount: 3,
                                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                                    itemBuilder: (_, _) => const Skeleton(height: 52, radius: 14),
                                  ),
                                )
                              else if (replies.isEmpty)
                                SliverToBoxAdapter(
                                  child: EmptyState(
                                    key: const ValueKey('thread-empty'),
                                    title: context.l10n.threadEmptyTitle,
                                    message: context.l10n.threadEmptyBody(entry.user.name),
                                  ),
                                )
                              else
                                SliverList.builder(
                                  itemCount: replies.length,
                                  itemBuilder: (context, i) => _ReplyTile(
                                    key: ValueKey('reply-$i'),
                                    index: i,
                                    reply: replies[i],
                                    onReply: () => _replyTo(replies[i].user),
                                    onLongPress: replies[i].canDelete(me.uid)
                                        ? () => _askDelete(replies[i])
                                        : null,
                                  ).animate().fadeIn(duration: 260.ms),
                                ),
                            ],
                            const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          ],
                        );
                      },
                    ),
                    Positioned(
                      top: topPad + 8,
                      left: 16,
                      child: GlassIconButton(
                        key: const ValueKey('back'),
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    if (entry != null)
                      Positioned(
                        top: topPad + 8,
                        right: 16,
                        child: ShareButton(
                          key: const ValueKey('share-rating'),
                          message: (l) => shareRatingMessage(entry, l, mine: entry.uid == me.uid),
                        ),
                      ),
                  ],
                ),
              ),
              if (entry != null)
                _Composer(
                  controller: _text,
                  focus: _focus,
                  replyingTo: _replyingTo,
                  hint: _replyingTo != null
                      ? context.l10n.replyHintTo(_replyingTo!.name)
                      : entry.uid == me.uid
                          ? context.l10n.replyHint
                          : context.l10n.replyHintTo(entry.user.name),
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

/// La nota del hilo: el disco (abre su pantalla), quién la escribió, cuándo,
/// su nota y su comentario, con "me gusta" y "Responder".
class _ThreadNote extends StatelessWidget {
  const _ThreadNote({required this.entry, required this.onReply});

  final RatingEntry entry;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final heroTag = 'thread-${entry.id}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: const ValueKey('thread-album'),
            behavior: HitTestBehavior.opaque,
            onTap: () => openAlbum(context, entry.album, heroTag: heroTag),
            child: Row(
              children: [
                AlbumCover(url: entry.album.smallCover, size: 52, radius: 10, heroTag: heroTag),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.album.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VText.display(22, height: 1.05),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.album.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.ui(13, color: c.text2),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.text3),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('thread-note'),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => openUser(context, entry.user.uid),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: entry.user.name,
                        color: entry.user.color,
                        url: entry.user.avatarUrl,
                        size: 34,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VText.ui(14, weight: 700),
                            ),
                            Text(
                              timeAgo(entry.updatedAt, context.l10n),
                              style: VText.ui(11, color: c.text3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ScoreNumeral(score: entry.score, size: 34),
                    ],
                  ),
                ),
                if (entry.hasNote) ...[
                  const SizedBox(height: 10),
                  Text(
                    entry.note,
                    style: VText.display(20, italic: true, height: 1.22),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    LikeButton(entry: entry),
                    const SizedBox(width: 8),
                    Pill(
                      key: const ValueKey('thread-reply-note'),
                      onTap: onReply,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mode_comment_outlined, size: 15, color: c.text3),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.replyAction,
                            style: VText.ui(12, weight: 700, color: c.text2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una respuesta: foto, nombre, @, hace cuánto, el texto (con las menciones
/// en color) y "Responder".
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
    final user = reply.user;
    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(VSpace.page, 10, VSpace.page, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => openUser(context, user.uid),
              child: UserAvatar(
                name: user.name,
                color: Color(user.colorValue),
                url: user.avatarUrl,
                size: 34,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => openUser(context, user.uid),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: user.name, style: VText.ui(13.5, weight: 800)),
                          if (user.handle.isNotEmpty)
                            TextSpan(
                              text: '  ${user.handle}',
                              style: VText.ui(12.5, color: c.text3),
                            ),
                          TextSpan(
                            text: '  ·  ${timeAgo(reply.createdAt, context.l10n)}',
                            style: VText.ui(12, color: c.text3),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3),
                  MentionText(reply.text, style: VText.ui(14.5, height: 1.4)),
                  GestureDetector(
                    key: ValueKey('reply-to-$index'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onReply,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 4, right: 12),
                      child: Text(
                        context.l10n.replyAction,
                        style: VText.ui(12, weight: 700, color: c.text3),
                      ),
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

/// El campo para responder, fijo abajo: "Respondiendo a @x" cuando va para
/// alguien del hilo, el texto y el botón de enviar.
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
    final me = CurrentUser.of(context);
    final to = replyingTo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (to != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
                  child: Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 16, color: c.text3),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.l10n.replyingTo(to.handle.isEmpty ? to.name : to.handle),
                          key: const ValueKey('replying-to'),
                          style: VText.ui(12, weight: 600, color: c.text2),
                        ),
                      ),
                      GestureDetector(
                        key: const ValueKey('replying-cancel'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onCancelReplyTo,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, size: 18, color: c.text3),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: UserAvatar(
                      name: me.name,
                      color: Color(me.colorValue),
                      url: me.avatarUrl,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('reply-field'),
                      controller: controller,
                      focusNode: focus,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: replyMaxLength,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: VText.ui(15, height: 1.35),
                      // El contador solo aparece cerca del límite.
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                          currentLength > replyMaxLength - 40
                              ? Text(
                                  '${replyMaxLength - currentLength}',
                                  style: VText.ui(11, color: c.text3),
                                )
                              : null,
                      decoration: InputDecoration(
                        hintText: hint,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final enabled = value.text.trim().isNotEmpty && !sending;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Material(
                          color: enabled ? c.accent : c.surface2,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: const ValueKey('reply-send'),
                            onTap: enabled ? onSend : null,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: sending
                                  ? Padding(
                                      padding: const EdgeInsets.all(11),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: c.text2),
                                    )
                                  : Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 22,
                                      semanticLabel: context.l10n.replySend,
                                      color: enabled ? c.onAccent : c.text3,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

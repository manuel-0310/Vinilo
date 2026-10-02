import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/follow.dart';
import '../models/moderation.dart';
import '../models/rating.dart';
import '../models/reply.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../share_cards/share_card_data.dart';
import '../share_cards/share_specs.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../util/format.dart';
import '../util/share_links.dart';
import '../widgets/album_cover.dart';
import '../widgets/feed_card.dart';
import '../widgets/line_field.dart';
import '../widgets/mention_text.dart';
import '../widgets/share_button.dart';
import '../widgets/share_sheet.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'moderation_actions.dart';
import 'routes.dart';

/// El detalle de una nota: la portada del disco arriba (con su título y
/// "Artista · año →", que abren el disco), quién calificó con la nota en
/// grande y su comentario, "Respuestas · N" debajo y el campo para
/// responder fijo abajo. Las respuestas son de un solo nivel:
/// "Responder" en una respuesta se la dirige a su autora con su @ al
/// principio. Mantener pulsada una respuesta propia (o cualquiera, si la
/// nota es mía) ofrece borrarla. Las notas y respuestas ajenas llevan "···"
/// (ocultar, reportar, bloquear); lo oculto y lo de las cuentas bloqueadas
/// no se ve.
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

  /// La dueña de una nota ajena, para poner su @usuario en la imagen que
  /// se comparte (la nota solo guarda su nombre).
  UserProfile? _owner;
  bool _ownerAsked = false;

  void _askOwner(RatingEntry entry, String myUid) {
    if (_ownerAsked || entry.uid == myUid) return;
    _ownerAsked = true;
    ServicesScope.of(context).users.fetch(entry.uid).then((p) {
      if (mounted) setState(() => _owner = p);
    }, onError: (_) {});
  }

  List<ShareCardSpec> _shareCards(RatingEntry entry, UserProfile me) {
    final owner = entry.uid == me.uid ? me : _owner;
    final person = owner == null ? null : CardPerson.fromProfile(owner);
    return ShareSpecs.rating(entry, person: person ?? AlbumCardData.fromRating(entry).person, accent: ShareSpecs.accentOf(context));
  }

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

  /// El "···" de la nota de otra persona. Si la oculté, la reporté o bloqueé
  /// a su autora, aquí ya no queda nada que ver: se vuelve atrás.
  Future<void> _noteMenu(RatingEntry entry) async {
    final owner = _owner;
    final author = owner != null && owner.uid == entry.uid
        ? owner.person
        : PersonInfo(
            uid: entry.uid,
            name: entry.user.name,
            colorValue: entry.user.colorValue,
            avatarUrl: entry.user.avatarUrl,
          );
    final result = await showContentMenu(
      context,
      author: author,
      kind: ReportTarget.rating,
      contentId: entry.id,
      ratingId: entry.id,
      excerpt: entry.note,
    );
    if (result != null && mounted) Navigator.of(context).maybePop();
  }

  Future<void> _replyMenu(Reply reply) {
    return showContentMenu(
      context,
      author: reply.user,
      kind: ReportTarget.reply,
      contentId: reply.id,
      ratingId: reply.ratingId,
      excerpt: reply.text,
    );
  }

  void _likeReply(Reply reply) {
    HapticFeedback.lightImpact();
    ServicesScope.of(context).replies.toggleLike(reply, CurrentUser.of(context).uid);
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
    final moderation = Moderation.of(context);
    final cover = _coverColor;
    final tone = cover == null ? c.accentText : c.coverTone(cover);
    return Scaffold(
      body: StreamBuilder<RatingEntry?>(
        stream: _rating,
        initialData: widget.initial,
        builder: (context, ratingSnap) {
          final loaded = ratingSnap.data;
          // La nota de alguien con bloqueo de por medio no existe para mí;
          // la que oculté se ve como oculta, con la forma de volver a verla.
          final blockedOwner = loaded != null && moderation.hidesUser(loaded.uid);
          final hiddenByMe =
              loaded != null && !blockedOwner && moderation.hidesContent(loaded.id);
          final entry = blockedOwner || hiddenByMe ? null : loaded;
          final gone = blockedOwner ||
              (loaded == null && ratingSnap.connectionState == ConnectionState.active);
          if (entry != null) {
            _askPalette(entry);
            _askOwner(entry, me.uid);
          }
          if (entry != null && _wantsFocus) {
            _wantsFocus = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _focus.requestFocus();
            });
          }
          return Column(
            children: [
              Expanded(
                // Sin SafeArea arriba: la portada llega al borde y sus botones
                // se apartan de la barra de estado por su cuenta.
                child: Builder(
                  builder: (context) => StreamBuilder<List<Reply>>(
                    stream: _replies,
                    builder: (context, repliesSnap) {
                      final allReplies = repliesSnap.data;
                      final replies = allReplies == null ? null : moderation.replies(allReplies);
                      if (replies != null) _onReplies(replies, me.uid);
                      return CustomScrollView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          if (entry != null) ...[
                            SliverToBoxAdapter(
                              child: _ThreadCover(
                                entry: entry,
                                share: ShareButton(
                                  key: const ValueKey('share-rating'),
                                  style: VIconButtonStyle.filled,
                                  message: (l) => shareRatingMessage(entry, l, mine: entry.uid == me.uid),
                                  cards: () => _shareCards(entry, me),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _ThreadNote(
                                entry: entry,
                                tone: tone,
                                onReply: () => _replyTo(null),
                                onMore: entry.uid == me.uid ? null : () => _noteMenu(entry),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(VSpace.page, 12, VSpace.page, 8),
                                child: VMono(
                                  replies == null ? l10n.loading : l10n.threadRepliesCount(replies.length),
                                  key: const ValueKey('thread-count'),
                                ),
                              ),
                            ),
                          ] else ...[
                            SliverToBoxAdapter(
                              child: SafeArea(
                                bottom: false,
                                child: VPageHeader(
                                  title: l10n.threadTitle,
                                  titleKey: const ValueKey('thread-title'),
                                ),
                              ),
                            ),
                            if (hiddenByMe)
                              SliverToBoxAdapter(
                                child: _Lined(
                                  child: VEmptyState(
                                    key: const ValueKey('thread-hidden'),
                                    title: l10n.commentHidden,
                                    message: l10n.commentHiddenBody,
                                    action: VTextLink(
                                      l10n.commentShowAgain,
                                      key: const ValueKey('thread-unhide'),
                                      onTap: () => ServicesScope.of(context)
                                          .moderation
                                          .unhide(me: me.uid, contentId: widget.ratingId),
                                    ),
                                  ),
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
                          ],
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
                                        VSkeleton(width: 32, height: 32, circle: true),
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
                                    liked: replies[i].likedByMe(me.uid),
                                    onLike: () => _likeReply(replies[i]),
                                    onReply: () => _replyTo(replies[i].user),
                                    onMore: replies[i].uid == me.uid
                                        ? null
                                        : () => _replyMenu(replies[i]),
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

/// Arriba del detalle: la portada a todo lo ancho (300 con la barra de
/// estado), volver y compartir encima y, abajo, una franja con el título en
/// 40 y "Artista · año →". Tocarla abre el disco.
class _ThreadCover extends StatelessWidget {
  const _ThreadCover({required this.entry, required this.share});

  final RatingEntry entry;
  final Widget share;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final heroTag = 'thread-${entry.id}';
    final album = entry.album;
    void open() => openAlbum(context, album, heroTag: heroTag);
    return SizedBox(
      height: math.max(300, topPad + 246),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            key: const ValueKey('thread-album'),
            onTap: open,
            child: AlbumCover(url: album.bestCover, heroTag: heroTag),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: open,
              child: Container(
                constraints: const BoxConstraints(minHeight: 120),
                color: c.overButton,
                padding: const EdgeInsets.fromLTRB(VSpace.page, 18, VSpace.page, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.name,
                      key: const ValueKey('thread-title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VText.display(40, weight: 800, stretch: 65, height: 0.9, tracking: 0),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${album.subtitle} →',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.ui(15, weight: 500, color: c.inkA(0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: topPad + 4,
            left: 16,
            right: 16,
            child: Row(
              children: [
                VIconButton(
                  key: const ValueKey('back'),
                  icon: VIcon.back,
                  style: VIconButtonStyle.filled,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                share,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La nota: quién calificó (foto de 28 y nombre, abren su perfil) y
/// "Calificó hace N" a la izquierda; la nota en 112 con "Bueno · de 10" a la
/// derecha, en el tono de la portada; el comentario en cita y "♡ Me gusta ·
/// N" y "Responder", que escribe aquí mismo. En la nota de otra persona,
/// "···" junto al nombre abre el menú (ocultar, reportar, bloquear).
class _ThreadNote extends StatelessWidget {
  const _ThreadNote({
    required this.entry,
    required this.tone,
    required this.onReply,
    this.onMore,
  });

  final RatingEntry entry;
  final Color tone;
  final VoidCallback onReply;

  /// Null en mi propia nota.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l10n = context.l10n;
    final user = entry.user;
    void openProfile() => openUser(context, user.uid);
    final note = Moderation.of(context).text(entry.note.trim());
    return Container(
      key: const ValueKey('thread-note'),
      margin: const EdgeInsets.symmetric(horizontal: VSpace.page),
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: openProfile,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                UserAvatar(
                                  name: user.name,
                                  color: user.color,
                                  url: user.avatarUrl,
                                  size: 28,
                                  initialSize: 12,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: VText.ui(16, weight: 600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (onMore != null)
                          MoreDots(
                            key: const ValueKey('thread-more'),
                            onTap: onMore!,
                            padding: const EdgeInsets.fromLTRB(6, 7, 10, 7),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    VMono(
                      l10n.threadRatedWhen(timeAgo(entry.updatedAt, l10n)),
                      color: c.inkA(0.55),
                      tracking: 0.06,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.score}',
                    key: ValueKey('thread-score-${entry.score}'),
                    style: VText.display(112, weight: 800, height: 0.78, tracking: 0, color: tone),
                  ),
                  const SizedBox(height: 8),
                  VMono(
                    l10n.threadScoreOutOf(Score.label(entry.score, l10n)),
                    size: 9.5,
                    tracking: 0.1,
                    color: tone,
                  ),
                ],
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '“', style: TextStyle(color: tone)),
                  TextSpan(text: note),
                  TextSpan(text: '”', style: TextStyle(color: tone)),
                ],
              ),
              style: VText.quote(21, height: 1.3, color: c.ink),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              LikeButton(entry: entry, showLabel: true, showCount: true),
              const SizedBox(width: 18),
              Pressable(
                key: const ValueKey('thread-reply-note'),
                onTap: onReply,
                builder: (context, pressed) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: VMono(l10n.replyAction, tracking: 0.06, color: pressed ? c.ink : c.ink3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Una respuesta: foto de 32, nombre, @usuario y hora en mono, el texto
/// (con las menciones en énfasis), el ♡ con cuántos tiene y "Responder".
/// Mantenerla pulsada ofrece borrarla, si se puede; en las ajenas, "···"
/// abre el menú (ocultar, reportar, bloquear).
class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    super.key,
    required this.index,
    required this.reply,
    required this.liked,
    required this.onLike,
    required this.onReply,
    this.onMore,
    this.onLongPress,
  });

  final int index;
  final Reply reply;

  /// Si me gusta.
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onReply;

  /// Null en mis propias respuestas.
  final VoidCallback? onMore;

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
                size: 32,
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
                  MentionText(
                    Moderation.of(context).text(reply.text),
                    style: VText.ui(14.5, height: 1.4, color: c.ink),
                  ),
                  Row(
                    children: [
                      Pressable(
                        key: ValueKey('reply-like-$index'),
                        onTap: onLike,
                        builder: (context, pressed) {
                          final color = liked ? c.accentText : (pressed ? c.ink : c.ink3);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 18),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VIconView(
                                  liked ? VIcon.heartFilled : VIcon.heart,
                                  size: 10,
                                  color: color,
                                ),
                                if (reply.likes > 0) ...[
                                  const SizedBox(width: 6),
                                  VMono('${reply.likes}', tracking: 0.06, color: color),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      Pressable(
                        key: ValueKey('reply-to-$index'),
                        onTap: onReply,
                        builder: (context, pressed) => Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
                          child: VMono(l10n.replyAction, tracking: 0.06, color: pressed ? c.ink : c.ink3),
                        ),
                      ),
                      const Spacer(),
                      if (onMore != null)
                        MoreDots(
                          key: ValueKey('reply-more-$index'),
                          onTap: onMore!,
                          padding: const EdgeInsets.fromLTRB(10, 7, 0, 7),
                        ),
                    ],
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
                              color: enabled ? (pressed ? c.ink : c.accentText) : null,
                              border: enabled ? null : Border.all(color: c.buttonLine),
                            ),
                            child: sending
                                ? VSpinner(color: c.ink2)
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

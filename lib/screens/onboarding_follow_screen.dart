import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/follow.dart';
import '../models/moderation.dart';
import '../models/onboarding.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../services/user_repo.dart';
import '../theme/vinilo_theme.dart';
import '../util/errors.dart';
import '../widgets/line_field.dart';
import '../widgets/person_row.dart';
import '../widgets/sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_choices.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';
import 'routes.dart';

/// "Encontrar gente" fuera del onboarding (desde el inicio vacío): las
/// mismas sugerencias, con volver arriba y "Listo" abajo.
Future<void> openFindPeople(BuildContext context) {
  return Navigator.of(context).push(
    CupertinoPageRoute(builder: (_) => const FollowSuggestionsScreen(onboarding: false)),
  );
}

/// Paso 2 de 2 del onboarding, opcional: "Sigue a gente con tu oído". La
/// fila de contactos, las sugerencias según los discos elegidos (con su
/// afinidad y el motivo) y "Empezar". "Saltar" y el botón terminan el
/// onboarding.
class OnboardingFollowScreen extends StatelessWidget {
  const OnboardingFollowScreen({super.key});

  @override
  Widget build(BuildContext context) => const FollowSuggestionsScreen(onboarding: true);
}

class FollowSuggestionsScreen extends StatefulWidget {
  const FollowSuggestionsScreen({super.key, required this.onboarding});

  /// True en el onboarding ("Paso 2 de 2", "Saltar", "Empezar"); false
  /// cuando se abre desde el inicio (volver y "Listo").
  final bool onboarding;

  @override
  State<FollowSuggestionsScreen> createState() => _FollowSuggestionsScreenState();
}

class _FollowSuggestionsScreenState extends State<FollowSuggestionsScreen> {
  /// Las sugerencias y con cuántos discos se armaron ("Por tus 3 discos").
  Future<({int tastes, List<PeopleSuggestion> people})>? _suggestions;
  Stream<List<String>>? _followingIds;
  bool _finishing = false;

  /// A quién se le está cambiando el seguimiento ahora mismo.
  final Set<String> _pending = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_suggestions != null) return;
    final services = ServicesScope.of(context);
    final me = CurrentUser.of(context);
    _followingIds = services.follows.followingIds(me.uid);
    _suggestions = _load(services, me, Moderation.of(context), skipFollowed: !widget.onboarding);
  }

  /// Las sugerencias: quien calificó bien mis discos (con su afinidad) y,
  /// para completar, las cuentas con más seguidores. Nunca yo ni nadie con
  /// un bloqueo de por medio; fuera del onboarding, tampoco a quien ya sigo.
  static Future<({int tastes, List<PeopleSuggestion> people})> _load(
    Services services,
    UserProfile me,
    ModerationState moderation, {
    required bool skipFollowed,
  }) async {
    var tastes = me.tastes.isNotEmpty ? me.tastes : me.favorites;
    if (tastes.isEmpty) {
      // Una cuenta de antes del onboarding: sus discos mejor calificados.
      try {
        final mine = await services.ratings.fetchUserRatings(me.uid);
        final best = [for (final r in mine) if (r.score >= 8) r]
          ..sort((a, b) => b.score.compareTo(a.score));
        tastes = <Album>[for (final r in best.take(UserRepo.maxTastes)) r.album];
      } catch (_) {
        // Sin mis notas quedan las cuentas populares.
      }
    }

    final exclude = <String>{me.uid, ...moderation.blocked.keys, ...moderation.blockedBy};
    if (skipFollowed) {
      try {
        exclude.addAll(await services.follows.followingIds(me.uid).first);
      } catch (_) {}
    }

    var byTaste = const <PeopleSuggestion>[];
    try {
      final ratings = await services.ratings.ratingsForAlbums([for (final a in tastes) a.id]);
      byTaste = suggestByTastes(
        ratings,
        tasteIds: {for (final a in tastes) a.id},
        exclude: exclude,
      );
    } catch (_) {
      // Sin esa consulta quedan las cuentas populares.
    }
    // La nota solo guarda el nombre y la foto: su @usuario sale del perfil.
    byTaste = await Future.wait(byTaste.map((s) async {
      try {
        final profile = await services.users.fetch(s.person.uid);
        return profile == null
            ? s
            : s.withPerson(profile.person, followers: profile.followersCount);
      } catch (_) {
        return s;
      }
    }));

    var popular = const <UserProfile>[];
    try {
      popular = await services.users.popularPeople();
    } catch (_) {}
    return (
      tastes: tastes.length,
      people: fillWithPopular(
        byTaste,
        [for (final p in popular) (person: p.person, followers: p.followersCount)],
        exclude: exclude,
      ),
    );
  }

  Future<void> _toggle(PersonInfo person, bool following) async {
    if (_pending.contains(person.uid)) return;
    final me = CurrentUser.of(context);
    final follows = ServicesScope.of(context).follows;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.lightImpact();
    setState(() => _pending.add(person.uid));
    try {
      await follows.setFollowing(me: me, other: person, follow: !following);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.couldNotSave(describeError(e, l)))));
    } finally {
      if (mounted) setState(() => _pending.remove(person.uid));
    }
  }

  /// "Saltar", "Empezar" o "Listo".
  Future<void> _finish() async {
    if (!widget.onboarding) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_finishing) return;
    final me = CurrentUser.of(context);
    final users = ServicesScope.of(context).users;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _finishing = true);
    try {
      // El perfil sale del onboarding y `main.dart` pasa a la app.
      await users.finishOnboarding(me.uid);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.couldNotSave(describeError(e, l)))));
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final onboarding = widget.onboarding;
    final bottomPad = math.max(38.0, MediaQuery.paddingOf(context).bottom + 4);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<String>>(
          stream: _followingIds,
          builder: (context, followingSnap) {
            final following = followingSnap.data?.toSet() ?? const <String>{};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (!onboarding)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: VIconButton(
                              key: const ValueKey('back'),
                              icon: VIcon.back,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (onboarding)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: c.line)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: VMono(l.onboardStep2, maxLines: 1),
                                      ),
                                    ),
                                    Pressable(
                                      key: const ValueKey('onboard-skip'),
                                      onTap: _finish,
                                      builder: (context, pressed) => Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
                                        child: VMono(
                                          l.onboardSkip,
                                          color: pressed ? c.ink2 : c.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 18),
                            Text(
                              l.onboardFollowTitle,
                              key: const ValueKey('follow-title'),
                              style: VText.display(52, weight: 800, height: 0.88, tracking: 0),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              onboarding ? l.onboardFollowBody : l.findPeopleBody,
                              style: VText.ui(15, height: 1.45, color: c.ink2),
                            ),
                            const SizedBox(height: 18),
                            _ContactsRow(onTap: () => showFindPeopleSheet(context)),
                            FutureBuilder<({int tastes, List<PeopleSuggestion> people})>(
                              future: _suggestions,
                              builder: (context, snap) {
                                final all = snap.data?.people;
                                final tasteCount = snap.data?.tastes ?? 0;
                                if (all == null) return const _SuggestionsSkeleton();
                                // Quien ya no debe verse (se bloqueó mientras tanto).
                                final moderation = Moderation.of(context);
                                final people = [
                                  for (final s in all)
                                    if (!moderation.hidesUser(s.person.uid)) s,
                                ];
                                if (people.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 22),
                                    child: Text(
                                      l.onboardNoSuggestions,
                                      key: const ValueKey('suggestions-empty'),
                                      style: VText.ui(15, height: 1.45, color: c.ink2),
                                    ),
                                  );
                                }
                                final byTaste = people.any((s) => s.percent != null);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                                      child: VMono(
                                        byTaste && tasteCount > 0
                                            ? l.onboardByTastes(tasteCount)
                                            : l.onboardPopularPeople,
                                        key: const ValueKey('suggestions-label'),
                                      ),
                                    ),
                                    for (final (i, s) in people.indexed)
                                      _SuggestionRow(
                                        key: ValueKey('suggestion-$i'),
                                        index: i,
                                        suggestion: s,
                                        following: following.contains(s.person.uid),
                                        busy: _pending.contains(s.person.uid),
                                        onToggle: () =>
                                            _toggle(s.person, following.contains(s.person.uid)),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, bottomPad),
                  decoration: BoxDecoration(
                    color: c.bg,
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: VPrimaryButton(
                    key: const ValueKey('follow-done'),
                    label: !onboarding
                        ? l.done
                        : following.isEmpty
                            ? l.onboardStartAlone
                            : l.onboardStartFollowing(following.length),
                    busy: _finishing,
                    onPressed: _finish,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Buscar en tus contactos": el cuadro punteado con "+" en énfasis, el
/// título, la explicación y la flecha, entre dos líneas.
class _ContactsRow extends StatelessWidget {
  const _ContactsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    return Pressable(
      key: const ValueKey('onboard-contacts'),
      onTap: onTap,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? c.inkA(0.04) : null,
          border: Border.symmetric(horizontal: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            DashedBox(
              size: 40,
              color: c.accentText,
              child: Text('+', style: VText.ui(18, weight: 500, color: c.accentText, height: 1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.onboardContacts, style: VText.ui(15, weight: 600)),
                  const SizedBox(height: 2),
                  Text(l.onboardContactsHint, style: VText.ui(12.5, color: c.inactive)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('→', style: VText.ui(16, color: c.ink4)),
          ],
        ),
      ),
    );
  }
}

/// Una sugerencia: avatar de 44, el nombre con su afinidad en énfasis, el
/// motivo en una línea y el botón "Seguir" / "Siguiendo". Tocar a la persona
/// abre su perfil.
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    super.key,
    required this.index,
    required this.suggestion,
    required this.following,
    required this.busy,
    required this.onToggle,
  });

  final int index;
  final PeopleSuggestion suggestion;
  final bool following;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final person = suggestion.person;
    final percent = suggestion.percent;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.lineSoft))),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => openUser(context, person.uid),
              child: Row(
                children: [
                  UserAvatar(
                    name: person.name,
                    color: Color(person.colorValue),
                    url: person.avatarUrl,
                    size: 44,
                    initialSize: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                person.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: VText.ui(15, weight: 600),
                              ),
                            ),
                            if (percent != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '$percent%',
                                style: VText.mono(12, weight: 600, tracking: 0, color: c.accentText),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          suggestion.reasonText(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.ui(12.5, color: c.inactive),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Con 4 de aire arriba y abajo el toque llega a 44.
          Pressable(
            key: ValueKey('suggestion-follow-$index'),
            onTap: busy ? null : onToggle,
            builder: (context, pressed) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: busy ? 0.5 : 1,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: following ? null : (pressed ? c.accent : c.ink),
                    border: Border.all(
                      color: following ? (pressed ? c.ink : c.lineStrong) : (pressed ? c.accent : c.ink),
                    ),
                  ),
                  child: Text(
                    following ? l.followingPlain : l.followPlain,
                    key: ValueKey(following ? 'suggestion-following-$index' : 'suggestion-not-following-$index'),
                    maxLines: 1,
                    style: VText.ui(13, weight: 600, color: following ? c.ink : c.bg),
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

class _SuggestionsSkeleton extends StatelessWidget {
  const _SuggestionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return VShimmer(
      child: Column(
        key: const ValueKey('suggestions-loading'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 18, bottom: 8),
            child: Align(alignment: Alignment.centerLeft, child: VSkeleton(width: 120, height: 10)),
          ),
          for (var i = 0; i < 5; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.lineSoft))),
              child: const Row(
                children: [
                  VSkeleton(width: 44, height: 44, circle: true),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(widthFactor: 0.55, child: VSkeleton(height: 12)),
                        SizedBox(height: 8),
                        FractionallySizedBox(widthFactor: 0.8, child: VSkeleton(height: 9, soft: true)),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  VSkeleton(width: 72, height: 36),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Buscar a alguien por su nombre o su @usuario (lo que abre "Buscar en tus
/// contactos": la app no lee la agenda del teléfono).
Future<void> showFindPeopleSheet(BuildContext context) {
  return showVSheet<void>(context, (_) => const _FindPeopleSheet());
}

class _FindPeopleSheet extends StatefulWidget {
  const _FindPeopleSheet();

  @override
  State<_FindPeopleSheet> createState() => _FindPeopleSheetState();
}

class _FindPeopleSheetState extends State<_FindPeopleSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _request = 0;
  List<PersonInfo>? _people;
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      _request++;
      setState(() {
        _people = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () => _search(q));
  }

  Future<void> _search(String q) async {
    final id = ++_request;
    final me = CurrentUser.maybeOf(context);
    final users = ServicesScope.of(context).users;
    setState(() => _loading = true);
    List<PersonInfo> found;
    try {
      found = await users.searchPeople(q, excludeUid: me?.uid);
    } catch (_) {
      found = const [];
    }
    if (id != _request || !mounted) return;
    setState(() {
      _people = found;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final people = _people == null ? null : Moderation.of(context).people(_people!);
    return SheetScaffold(
      key: const ValueKey('find-people-sheet'),
      title: l.findPeopleTitle,
      titleSize: 40,
      height: 0.85,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 8),
            child: LineField(
              fieldKey: const ValueKey('find-people-field'),
              controller: _controller,
              hint: l.findPeopleHint,
              autofocus: true,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              padding: const EdgeInsets.symmetric(vertical: 12),
              leading: VIconView(VIcon.search, size: 20, color: c.ink),
              trailing: _loading ? VSpinner(color: c.ink3) : null,
              onChanged: _onChanged,
            ),
          ),
          Expanded(
            child: people == null
                ? const SizedBox.shrink()
                : people.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(VSpace.page, 16, VSpace.page, 0),
                        child: Text(
                          l.findPeopleEmpty,
                          key: const ValueKey('find-people-empty'),
                          style: VText.ui(14, color: c.ink4),
                        ),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
                        itemCount: people.length,
                        itemBuilder: (context, i) => PersonRow(
                          key: ValueKey('find-person-$i'),
                          person: people[i],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

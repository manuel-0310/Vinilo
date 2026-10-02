import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/stats.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../services/share_image.dart';
import '../services/share_service.dart';
import '../theme/score.dart';
import '../theme/vinilo_theme.dart';
import '../util/share_links.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';

/// Lo que lleva la tarjeta "Mi año en discos": de quién es, el periodo,
/// cuántos discos y con qué promedio, el histograma con la nota más común,
/// el artista con más discos y el enlace al perfil.
class StatsCardData {
  const StatsCardData({
    required this.handle,
    required this.period,
    required this.date,
    required this.since,
    required this.total,
    required this.average,
    required this.hist,
    required this.mode,
    required this.artist,
    required this.link,
  });

  factory StatsCardData.from({
    required UserProfile profile,
    required ProfileStats stats,
    required StatsPeriod period,
    required DateTime now,
  }) {
    final url = ShareLinks.profile(username: profile.username, uid: profile.uid);
    return StatsCardData(
      handle: profile.handle.isEmpty ? profile.name : profile.handle,
      period: period,
      date: now,
      since: profile.createdAt.year,
      total: stats.total,
      average: stats.average,
      hist: [for (var k = 1; k <= 10; k++) stats.hist[k] ?? 0],
      mode: stats.mode,
      artist: stats.artists.firstOrNull?.name,
      link: url,
    );
  }

  /// "@manuel".
  final String handle;
  final StatsPeriod period;

  /// Cuándo se armó (de aquí salen el año o el mes de la esquina).
  final DateTime date;

  /// Desde qué año tiene cuenta ("Siempre").
  final int since;
  final int total;
  final double? average;

  /// Cuántos discos con cada nota, del 1 al 10.
  final List<int> hist;
  final int? mode;
  final String? artist;
  final Uri link;

  /// El enlace como se lee en la tarjeta: sin "https://".
  String get linkLabel => '${link.host}${link.path}';

  /// "Mi año\nen discos".
  String title(AppLocalizations l) => switch (period) {
        StatsPeriod.month => l.shareStatsTitleMonth,
        StatsPeriod.year => l.shareStatsTitleYear,
        StatsPeriod.all => l.shareStatsTitleAll,
      };

  /// La esquina de arriba: "2026", "oct 2026" o "Desde 2025".
  String corner(AppLocalizations l) => switch (period) {
        StatsPeriod.month =>
          DateFormat('MMM y', l.localeName).format(date).replaceAll('.', ''),
        StatsPeriod.year => '${date.year}',
        StatsPeriod.all => l.shareStatsSince('$since'),
      };

  String artistLabel(AppLocalizations l) => switch (period) {
        StatsPeriod.month => l.shareStatsArtistMonth,
        StatsPeriod.year => l.shareStatsArtistYear,
        StatsPeriod.all => l.shareStatsArtistAll,
      };
}

/// Los tres fondos de la tarjeta: énfasis, claro y oscuro.
enum StatsCardTheme { accent, light, dark }

/// Los colores de la tarjeta en un tema. Es una imagen: no sigue el tema de
/// la app, así que sale de los tokens oscuros (papel `ink`, casi negro `bg`,
/// hoja `sheet`) más el énfasis de quien comparte.
class StatsCardColors {
  const StatsCardColors({
    required this.background,
    required this.foreground,
    required this.line,
    required this.highlight,
    required this.bar,
    required this.dimBar,
  });

  factory StatsCardColors.of(StatsCardTheme theme, Color accent) {
    const p = ViniloPalette.dark;
    return switch (theme) {
      StatsCardTheme.accent => StatsCardColors(
          background: accent,
          foreground: p.bg,
          line: p.bg.withValues(alpha: 0.25),
          highlight: p.bg,
          bar: p.bg,
          dimBar: p.bg.withValues(alpha: 0.3),
        ),
      StatsCardTheme.light => StatsCardColors(
          background: p.ink,
          foreground: p.bg,
          line: p.bg.withValues(alpha: 0.18),
          highlight: accent,
          bar: accent,
          dimBar: p.bg.withValues(alpha: 0.2),
        ),
      StatsCardTheme.dark => StatsCardColors(
          background: p.sheet,
          foreground: p.ink,
          line: p.ink.withValues(alpha: 0.18),
          highlight: accent,
          bar: accent,
          dimBar: p.ink.withValues(alpha: 0.25),
        ),
    };
  }

  final Color background;
  final Color foreground;
  final Color line;

  /// El promedio.
  final Color highlight;

  /// La barra de la nota más común y las demás.
  final Color bar;
  final Color dimBar;
}

/// La tarjeta de 270×480 (9:16, para historias; se exporta a 1080×1920).
class StatsShareCard extends StatelessWidget {
  const StatsShareCard({
    super.key,
    required this.data,
    required this.theme,
    required this.accent,
  });

  final StatsCardData data;
  final StatsCardTheme theme;
  final Color accent;

  static const Size size = Size(270, 480);

  /// Escala de la exportación: 270 × 4 = 1080.
  static const double pixelRatio = 4;

  /// Alto de una barra del mini histograma: 2 sin discos; con discos, de 4
  /// a 68 según la nota más común.
  static double barHeight(int count, int most) =>
      count <= 0 || most <= 0 ? 2 : 4 + (64 * count / most).roundToDouble();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = StatsCardColors.of(theme, accent);
    final fg = colors.foreground;
    final soft = fg.withValues(alpha: 0.75);
    final most = data.hist.fold<int>(0, math.max);
    final average = data.average;
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    TextStyle label([double tracking = 0.08]) => VText.mono(8.5, tracking: tracking, color: soft);

    return MediaQuery(
      // Es una imagen: el texto no cambia con el tamaño de letra del teléfono.
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox.fromSize(
        size: size,
        child: ColoredBox(
          color: colors.background,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: DefaultTextStyle(
              style: VText.ui(14, color: fg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.handle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VText.mono(9.5, color: soft),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(data.corner(l).toUpperCase(), style: VText.mono(9.5, color: soft)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Siempre en dos líneas: si una no cabe a lo ancho (en
                  // inglés), se achica.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data.title(l).toUpperCase(),
                      softWrap: false,
                      style: VText.display(38, weight: 900, height: 0.86, color: fg),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(horizontal: BorderSide(color: colors.line)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _CardNumber(
                              value: '${data.total}',
                              label: l.shareStatsAlbums,
                              color: fg,
                              labelStyle: label(),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: colors.line)),
                              ),
                              child: _CardNumber(
                                value: average == null ? '—' : Score.formatAverage(average, l.localeName),
                                label: l.shareStatsAverage,
                                color: colors.highlight,
                                labelStyle: label(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 70,
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.line))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 10; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Expanded(
                            child: Container(
                              height: barHeight(data.hist[i], most),
                              color: i + 1 == data.mode ? colors.bar : colors.dimBar,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (data.mode != null) ...[
                    const SizedBox(height: 5),
                    Text(l.shareStatsMode(data.mode!).toUpperCase(), style: label()),
                  ],
                  if (data.artist != null) ...[
                    const SizedBox(height: 16),
                    Text(data.artistLabel(l).toUpperCase(), style: label()),
                    const SizedBox(height: 4),
                    Text(
                      data.artist!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VText.display(24, weight: 700, stretch: 70, height: 1, tracking: 0, color: fg),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l.appName.toUpperCase(),
                        style: VText.display(22, weight: 900, height: 0.86, color: fg),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.linkLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: label(0.06),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardNumber extends StatelessWidget {
  const _CardNumber({
    required this.value,
    required this.label,
    required this.color,
    required this.labelStyle,
  });

  final String value;
  final String label;
  final Color color;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: VText.display(54, weight: 800, height: 0.8, tracking: 0, color: color),
            ),
          ),
          const SizedBox(height: 6),
          Text(label.toUpperCase(), maxLines: 1, style: labelStyle),
        ],
      ),
    );
  }
}

Future<void> openShareStats(BuildContext context, StatsCardData data) {
  return Navigator.of(context).push(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (_) => ShareStatsScreen(data: data),
    ),
  );
}

/// "Compartir estadísticas": la tarjeta, los tres fondos para elegir y los
/// cuatro destinos (Historias de Instagram, WhatsApp, Guardar imagen y
/// Copiar link).
class ShareStatsScreen extends StatefulWidget {
  const ShareStatsScreen({super.key, required this.data});

  final StatsCardData data;

  @override
  State<ShareStatsScreen> createState() => _ShareStatsScreenState();
}

class _ShareStatsScreenState extends State<ShareStatsScreen> {
  StatsCardTheme _theme = StatsCardTheme.accent;
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;
  String? _notice;
  bool _noticeError = false;
  Timer? _noticeTimer;

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  void _say(String text, {bool error = false}) {
    _noticeTimer?.cancel();
    setState(() {
      _notice = text;
      _noticeError = error;
    });
    _noticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  Future<Uint8List> _png() => ShareImage.capture(_cardKey, pixelRatio: StatsShareCard.pixelRatio);

  Future<void> _run(Future<void> Function(AppLocalizations l) action) async {
    if (_busy) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await action(l);
    } on ShareImageException catch (e) {
      _say(
        switch (e.error) {
          ShareImageError.denied => l.shareSaveDenied,
          ShareImageError.unsupported => l.shareImageUnsupported,
          ShareImageError.failed => l.shareImageFailed,
        },
        error: true,
      );
    } catch (_) {
      _say(l.shareImageFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stories() => _run((l) async {
        final png = await _png();
        if (await ShareService.instagramStory(png)) return;
        await ShareService.shareImage(png, l.shareStatsMine, widget.data.link);
      });

  Future<void> _whatsapp() => _run((l) async {
        await ShareService.shareImage(await _png(), l.shareStatsMine, widget.data.link);
      });

  Future<void> _save() => _run((l) async {
        await ShareService.saveImage(await _png());
        HapticFeedback.lightImpact();
        _say(l.shareImageSaved);
      });

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: '${widget.data.link}'));
    HapticFeedback.selectionClick();
    if (mounted) _say(context.l10n.linkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    // Las tarjetas no usan la versión clara de la tinta como énfasis.
    final me = CurrentUser.maybeOf(context);
    final accent = me == null ? ViniloPalette.defaultAccent : VColors.nearest(me.color);
    final bottomPad = math.max(38.0, MediaQuery.paddingOf(context).bottom + 4);
    final themes = <(StatsCardTheme, Color)>[
      (StatsCardTheme.accent, accent),
      (StatsCardTheme.light, ViniloPalette.dark.ink),
      (StatsCardTheme.dark, ViniloPalette.dark.sheet),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  VIconButton(
                    key: const ValueKey('share-stats-close'),
                    icon: VIcon.close,
                    iconSize: 16,
                    tooltip: l.cancel,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(child: VMono(l.shareAction, align: TextAlign.center)),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // La tarjeta a su tamaño (270×480) o más chica si la pantalla es
            // baja; se captura siempre a tamaño completo.
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: StatsShareCard(
                      key: const ValueKey('share-stats-card'),
                      data: widget.data,
                      theme: _theme,
                      accent: accent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (i, (theme, color)) in themes.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _ThemeSwatch(
                    key: ValueKey('share-stats-theme-${theme.name}'),
                    color: color,
                    selected: theme == _theme,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _theme = theme);
                    },
                  ),
                ],
              ],
            ),
            SizedBox(
              height: 40,
              child: _notice == null
                  ? null
                  : Center(
                      key: const ValueKey('share-stats-notice'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: VSpace.page),
                        child: _noticeError
                            ? Text(
                                _notice!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: VText.ui(12.5, color: c.danger, height: 1.3),
                              )
                            : VMono(_notice!, size: 10, color: c.accentText, maxLines: 1),
                      ),
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(VSpace.page, 14, VSpace.page, bottomPad),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Target(
                    keyName: 'share-stats-stories',
                    glyph: 'IG',
                    label: l.shareStatsStories,
                    onTap: _busy ? null : _stories,
                  ),
                  const SizedBox(width: 8),
                  _Target(
                    keyName: 'share-stats-whatsapp',
                    glyph: 'WA',
                    label: l.shareStatsWhatsapp,
                    onTap: _busy ? null : _whatsapp,
                  ),
                  const SizedBox(width: 8),
                  _Target(
                    keyName: 'share-stats-save',
                    icon: VIcon.download,
                    label: l.shareStatsSave,
                    onTap: _busy ? null : _save,
                  ),
                  const SizedBox(width: 8),
                  _Target(
                    keyName: 'share-stats-copy',
                    icon: VIcon.copy,
                    label: l.shareStatsCopy,
                    onTap: _copy,
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

/// Un fondo para elegir: cuadro de 28 con borde suave y, elegido, un
/// contorno de 1 a 3 de distancia.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({super.key, required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // 28 de cuadro, 3 de aire y 1 de contorno por lado; con 4 más de
      // relleno el toque llega a 44.
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? c.ink : Colors.transparent),
          ),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: c.inkA(0.2)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un destino: caja de 52 con borde, sus letras (o su ícono) y el nombre.
class _Target extends StatelessWidget {
  const _Target({
    required this.keyName,
    required this.label,
    required this.onTap,
    this.glyph,
    this.icon,
  });

  final String keyName;
  final String label;
  final VoidCallback? onTap;
  final String? glyph;
  final VIcon? icon;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final color = onTap == null ? c.ink4 : c.ink;
    return Expanded(
      child: Pressable(
        key: ValueKey(keyName),
        onTap: onTap,
        builder: (context, pressed) => Column(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: pressed ? c.ink : c.inkA(0.22)),
              ),
              child: icon != null
                  ? VIconView(icon!, size: 20, color: color)
                  : Text(glyph ?? '', style: VText.mono(13, weight: 600, tracking: 0, color: color)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: VText.ui(12, weight: 500, color: c.inkA(0.75)),
            ),
          ],
        ),
      ),
    );
  }
}

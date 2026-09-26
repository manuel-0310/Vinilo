import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/vinilo_theme.dart';
import '../util/auth_errors.dart';
import '../widgets/line_field.dart';
import '../widgets/photo_picker.dart';
import '../widgets/user_avatar.dart';
import '../widgets/username_field.dart';
import '../widgets/v_buttons.dart';
import '../widgets/v_icons.dart';
import '../widgets/v_sections.dart';

/// Lo que devuelve el formulario al guardar.
class ProfileEdit {
  const ProfileEdit({
    required this.name,
    required this.colorValue,
    this.username,
    this.avatar,
    this.removeAvatar = false,
    this.banner,
    this.removeBanner = false,
    this.bio,
  });

  final String name;
  final int colorValue;

  /// @usuario válido y (según la última consulta) libre; null si el
  /// formulario no lo pedía.
  final String? username;
  final Uint8List? avatar;
  final bool removeAvatar;
  final Uint8List? banner;
  final bool removeBanner;

  /// Biografía (hasta [bioMaxLength]); null si el formulario no la pedía.
  final String? bio;
}

typedef ProfileSubmit = Future<void> Function(ProfileEdit edit);

/// Tamaños con los que se exportan las fotos antes de subirlas a Storage.
const int avatarSize = 512;
const int bannerWidth = 1600;

/// Proporción del banner: la del encabezado del perfil (ancho completo por
/// ~210 pt de alto en un iPhone), redondeada a 2:1.
const double bannerAspect = 2;

/// Largo máximo de la biografía del perfil.
const int bioMaxLength = 160;

/// Formulario compartido por el onboarding y la edición de perfil.
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initialName = '',
    this.initialColor,
    this.initialAvatarUrl,
    this.initialBannerUrl,
    this.showBanner = false,
    this.showColor = false,
    this.showUsername = false,
    this.initialUsername,
    this.forUid,
    this.autofocus = false,
    this.showBio = false,
    this.initialBio,
  });

  final String submitLabel;
  final ProfileSubmit onSubmit;
  final String initialName;
  final int? initialColor;
  final String? initialAvatarUrl;
  final String? initialBannerUrl;

  /// Muestra el selector de foto de fondo (solo al editar el perfil).
  final bool showBanner;

  /// Muestra el selector de color. Solo en el onboarding: después el color
  /// vive en Configuración, porque es el énfasis de toda la app.
  final bool showColor;

  /// Muestra el campo del @usuario (onboarding y edición del perfil).
  final bool showUsername;
  final String? initialUsername;

  /// Uid de la persona, para que su propio @usuario cuente como libre.
  final String? forUid;
  final bool autofocus;

  /// Muestra el campo de biografía (solo al editar el perfil).
  final bool showBio;
  final String? initialBio;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  late int _color = widget.initialColor ?? VColors.accentPalette.first.toARGB32();
  late String? _username = widget.initialUsername;
  late final TextEditingController _bio =
      TextEditingController(text: widget.initialBio ?? '');
  Uint8List? _picked;
  bool _removed = false;
  Uint8List? _pickedBanner;
  bool _removedBanner = false;
  bool _busy = false;

  bool get _hasAvatar =>
      _picked != null || (!_removed && widget.initialAvatarUrl != null);

  bool get _hasBanner =>
      _pickedBanner != null || (!_removedBanner && widget.initialBannerUrl != null);

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// Pregunta "Tomar foto" o "Elegir de la galería" (y "Quitar foto" si ya
  /// hay una) y pasa por el recortador.
  Future<void> _pick() async {
    final pick = await pickPhoto(
      context,
      aspectRatio: 1,
      outputWidth: avatarSize,
      circle: true,
      title: context.l10n.profilePhotoTitle,
      canRemove: _hasAvatar,
    );
    if (pick == null || !mounted) return;
    setState(() {
      _picked = pick.bytes;
      _removed = pick.remove;
    });
  }

  Future<void> _pickBanner() async {
    final pick = await pickPhoto(
      context,
      aspectRatio: bannerAspect,
      outputWidth: bannerWidth,
      title: context.l10n.bannerPhotoTitle,
      canRemove: _hasBanner,
      removeLabel: context.l10n.bannerRemove,
    );
    if (pick == null || !mounted) return;
    setState(() {
      _pickedBanner = pick.bytes;
      _removedBanner = pick.remove;
    });
  }

  bool get _usernameReady => !widget.showUsername || _username != null;

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 2 || _busy || !_usernameReady) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        ProfileEdit(
          name: name,
          colorValue: _color,
          username: widget.showUsername ? _username : null,
          avatar: _picked,
          removeAvatar: _removed,
          banner: _pickedBanner,
          removeBanner: _removedBanner,
          bio: widget.showBio ? _bio.text.trim() : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(e, context.l10n),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final l = context.l10n;
    final color = Color(_color);
    final name = _name.text.trim();

    Widget action(String key, String label, VoidCallback onTap) => Pressable(
          key: ValueKey(key),
          onTap: onTap,
          builder: (context, pressed) => Opacity(
            opacity: pressed ? 0.6 : 1,
            child: VMono(label, color: c.accentText),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showBanner) ...[
          _BannerField(
            key: const ValueKey('banner-field'),
            color: color,
            bytes: _pickedBanner,
            url: _removedBanner ? null : widget.initialBannerUrl,
            onTap: _pickBanner,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: action('banner-change', _hasBanner ? l.bannerChange : l.bannerChoose, _pickBanner),
          ),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            GestureDetector(
              onTap: _pick,
              child: UserAvatar(
                name: name.isEmpty ? '?' : name,
                color: color,
                bytes: _picked,
                url: _removed ? null : widget.initialAvatarUrl,
                size: 72,
              ),
            ),
            const SizedBox(width: 16),
            action('photo-change', _hasAvatar ? l.photoChange : l.photoChoose, _pick),
          ],
        ),
        const SizedBox(height: 24),
        LineField(
          label: l.authNameLabel,
          hint: l.nameHint,
          fieldKey: const ValueKey('name-field'),
          controller: _name,
          autofocus: widget.autofocus,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        if (widget.showBio) ...[
          const SizedBox(height: 14),
          LineField(
            label: l.bioLabel,
            hint: l.bioHint,
            fieldKey: const ValueKey('bio-field'),
            controller: _bio,
            maxLength: bioMaxLength,
            minLines: 2,
            maxLines: 4,
            fontSize: 15,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
        if (widget.showUsername) ...[
          const SizedBox(height: 14),
          UsernameField(
            label: l.authUsernameLabel,
            initial: widget.initialUsername ?? '',
            forUid: widget.forUid,
            onChanged: (v) => setState(() => _username = v),
          ),
        ],
        if (widget.showColor) ...[
          const SizedBox(height: 20),
          VMono(l.yourColorLabel),
          const SizedBox(height: 12),
          ColorSwatches(
            selected: _color,
            onChanged: (v) => setState(() => _color = v),
          ),
        ],
        const SizedBox(height: 28),
        VPrimaryButton.accent(
          key: const ValueKey('profile-submit'),
          label: widget.submitLabel,
          busy: _busy,
          onPressed: name.length < 2 || !_usernameReady ? null : _submit,
        ),
      ],
    );
  }
}

/// Los 14 colores de énfasis en cuadros, en filas de 7 con separación 6.
/// El elegido (el más parecido de la paleta al color guardado) lleva un
/// contorno de tinta de 2 px separado 2, que no ocupa sitio.
class ColorSwatches extends StatelessWidget {
  const ColorSwatches({
    super.key,
    required this.selected,
    required this.onChanged,
    this.columns = 7,
    this.gap = 6,
  });

  final int selected;
  final ValueChanged<int> onChanged;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final chosen = VColors.nearest(Color(selected)).toARGB32();
    const palette = VColors.accentPalette;
    final rows = (palette.length + columns - 1) ~/ columns;

    Widget swatch(Color color) {
      final isChosen = color.toARGB32() == chosen;
      return GestureDetector(
        key: ValueKey('color-${color.toARGB32()}'),
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(color.toARGB32());
        },
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              ColoredBox(color: c.swatch(color)),
              if (isChosen)
                Positioned(
                  left: -4,
                  top: -4,
                  right: -4,
                  bottom: -4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(color: c.ink, width: 2)),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) SizedBox(height: gap),
          Row(
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: r * columns + i < palette.length
                      ? swatch(palette[r * columns + i])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Vista previa de la foto de fondo (2:1, como el banner del perfil); sin
/// foto, la franja del color de la persona con "Foto de fondo" en mono.
class _BannerField extends StatelessWidget {
  const _BannerField({
    super.key,
    required this.color,
    required this.bytes,
    required this.url,
    required this.onTap,
  });

  final Color color;
  final Uint8List? bytes;
  final String? url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    final hasImage = bytes != null || url != null;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: bannerAspect,
        child: ColoredBox(
          color: c.coverShade(color, lightness: 0.35),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null)
                Image.memory(bytes!, fit: BoxFit.cover)
              else if (url != null)
                Image.network(url!, fit: BoxFit.cover),
              if (!hasImage)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VIconView(VIcon.image, size: 18, color: c.ink),
                      const SizedBox(width: 8),
                      VMono(context.l10n.bannerPlaceholder, color: c.ink),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

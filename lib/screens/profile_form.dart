import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/user_repo.dart';
import '../theme/vinilo_theme.dart';
import '../widgets/image_cropper.dart';
import '../widgets/user_avatar.dart';
import '../widgets/username_field.dart';

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
}

typedef ProfileSubmit = Future<void> Function(ProfileEdit edit);

/// Tamaños con los que se exportan las fotos antes de subirlas a Storage.
const int avatarSize = 512;
const int bannerWidth = 1600;

/// Proporción del banner: la del encabezado del perfil (ancho completo por
/// ~210 pt de alto en un iPhone), redondeada a 2:1.
const double bannerAspect = 2;

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

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  late int _color = widget.initialColor ?? VColors.accentPalette.first.toARGB32();
  late String? _username = widget.initialUsername;
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
    super.dispose();
  }

  /// Abre la galería y luego el recortador. La galería entrega una copia
  /// ya reducida (para que el recortador no cargue una foto de 12 MP) y el
  /// recortador devuelve el JPEG final, listo para subir.
  Future<Uint8List?> _pickImage({
    required double aspectRatio,
    required int outputWidth,
    required bool circle,
    required String title,
  }) async {
    Uint8List bytes;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (file == null) return null;
      bytes = await file.readAsBytes();
    } on PlatformException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la galería: ${e.message}')),
      );
      return null;
    }
    if (!mounted) return null;
    return showImageCropper(
      context,
      bytes: bytes,
      aspectRatio: aspectRatio,
      outputWidth: outputWidth,
      circle: circle,
      title: title,
    );
  }

  Future<void> _pick() async {
    final bytes = await _pickImage(
      aspectRatio: 1,
      outputWidth: avatarSize,
      circle: true,
      title: 'Tu foto de perfil',
    );
    if (bytes == null || !mounted) return;
    setState(() {
      _picked = bytes;
      _removed = false;
    });
  }

  Future<void> _pickBanner() async {
    final bytes = await _pickImage(
      aspectRatio: bannerAspect,
      outputWidth: bannerWidth,
      circle: false,
      title: 'Tu foto de fondo',
    );
    if (bytes == null || !mounted) return;
    setState(() {
      _pickedBanner = bytes;
      _removedBanner = false;
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
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is UsernameTakenException ? e.message : 'Algo falló: $e',
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
    final color = Color(_color);
    final name = _name.text.trim();
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
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _hasBanner
                  ? () => setState(() {
                        _pickedBanner = null;
                        _removedBanner = true;
                      })
                  : _pickBanner,
              child: Text(_hasBanner ? 'Quitar fondo' : 'Elegir foto de fondo'),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Center(
          child: GestureDetector(
            onTap: _pick,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  name: name.isEmpty ? '?' : name,
                  color: color,
                  bytes: _picked,
                  url: _removed ? null : widget.initialAvatarUrl,
                  size: 104,
                  ring: true,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 3),
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: 16,
                      color: c.onAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: _hasAvatar
                ? () => setState(() {
                      _picked = null;
                      _removed = true;
                    })
                : _pick,
            child: Text(_hasAvatar ? 'Quitar foto' : 'Elegir una foto'),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey('name-field'),
          controller: _name,
          autofocus: widget.autofocus,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          style: VText.ui(17, weight: 600),
          decoration: InputDecoration(
            hintText: '¿Cómo te llamamos?',
            counterStyle: VText.label(10, color: c.text3),
          ),
        ),
        if (widget.showUsername) ...[
          const SizedBox(height: 14),
          Text('TU @USUARIO', style: VText.label(11, color: c.text3)),
          const SizedBox(height: 10),
          UsernameField(
            initial: widget.initialUsername ?? '',
            forUid: widget.forUid,
            onChanged: (v) => setState(() => _username = v),
          ),
        ],
        if (widget.showColor) ...[
          const SizedBox(height: 14),
          Text('TU COLOR', style: VText.label(11, color: c.text3)),
          const SizedBox(height: 12),
          ColorSwatches(
            selected: _color,
            onChanged: (v) => setState(() => _color = v),
          ),
        ],
        const SizedBox(height: 30),
        FilledButton(
          key: const ValueKey('profile-submit'),
          onPressed: name.length < 2 || _busy || !_usernameReady ? null : _submit,
          child: _busy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.onAccent,
                  ),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}

/// Los colores que puede elegir la persona, en círculos; el elegido lleva
/// un anillo y una sombra de su propio color.
class ColorSwatches extends StatelessWidget {
  const ColorSwatches({
    super.key,
    required this.selected,
    required this.onChanged,
    this.size = 34,
  });

  final int selected;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = VColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final swatch in VColors.accentPalette)
          GestureDetector(
            key: ValueKey('color-${swatch.toARGB32()}'),
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(swatch.toARGB32());
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(
                  color: swatch.toARGB32() == selected ? c.text : Colors.transparent,
                  width: 3,
                ),
                // Siempre una sombra (aunque invisible) para que la
                // interpolación nunca produzca un radio negativo.
                boxShadow: [
                  BoxShadow(
                    color: swatch.withValues(
                      alpha: swatch.toARGB32() == selected ? 0.5 : 0,
                    ),
                    blurRadius: swatch.toARGB32() == selected ? 14 : 0,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Vista previa de la foto de fondo (2:1, como en el perfil); sin foto muestra el degradado
/// del color del perfil, igual que el encabezado.
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
    final hasImage = bytes != null || url != null;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: bannerAspect,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.55),
                      color.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
              if (bytes != null)
                Image.memory(bytes!, fit: BoxFit.cover)
              else if (url != null)
                Image.network(url!, fit: BoxFit.cover),
              if (!hasImage)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text('Foto de fondo', style: VText.ui(14, weight: 700)),
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

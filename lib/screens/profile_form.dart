
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/vinilo_theme.dart';
import '../widgets/user_avatar.dart';

typedef ProfileSubmit = Future<void> Function(
  String name,
  int colorValue,
  Uint8List? newAvatar,
  bool removeAvatar,
);

/// Formulario compartido por el onboarding y la edición de perfil.
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initialName = '',
    this.initialColor,
    this.initialAvatarUrl,
    this.autofocus = false,
  });

  final String submitLabel;
  final ProfileSubmit onSubmit;
  final String initialName;
  final int? initialColor;
  final String? initialAvatarUrl;
  final bool autofocus;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  late int _color = widget.initialColor ?? VColors.avatarPalette.first.toARGB32();
  Uint8List? _picked;
  bool _removed = false;
  bool _busy = false;

  bool get _hasAvatar =>
      _picked != null || (!_removed && widget.initialAvatarUrl != null);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _picked = bytes;
        _removed = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la galería: ${e.message}')),
      );
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 2 || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(name, _color, _picked, _removed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Algo falló: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_color);
    final name = _name.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      color: VColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: VColors.bg, width: 3),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 16,
                      color: VColors.onAccent,
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
            counterStyle: VText.label(10),
          ),
        ),
        const SizedBox(height: 14),
        Text('TU COLOR', style: VText.label(11)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in VColors.avatarPalette)
              GestureDetector(
                key: ValueKey('color-${c.toARGB32()}'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _color = c.toARGB32());
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.toARGB32() == _color
                          ? VColors.text
                          : Colors.transparent,
                      width: 3,
                    ),
                    // Siempre una sombra (aunque invisible) para que la
                    // interpolación nunca produzca un radio negativo.
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(
                          alpha: c.toARGB32() == _color ? 0.5 : 0,
                        ),
                        blurRadius: c.toARGB32() == _color ? 14 : 0,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 30),
        FilledButton(
          key: const ValueKey('profile-submit'),
          onPressed: name.length < 2 || _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VColors.onAccent,
                  ),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}

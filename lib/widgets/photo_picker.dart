import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'image_cropper.dart';
import 'sheet.dart';
import 'v_icons.dart';

import '../l10n/l10n.dart';

/// Lo que eligió la persona: una foto ya recortada o quitar la que había.
class PhotoPick {
  const PhotoPick.bytes(Uint8List this.bytes) : remove = false;
  const PhotoPick.remove()
      : bytes = null,
        remove = true;

  final Uint8List? bytes;
  final bool remove;
}

/// Pregunta de dónde sale la foto ("Tomar foto" o "Elegir de la galería", y
/// "Quitar foto" si `canRemove`), la trae ya reducida (para no cargar una
/// foto de 12 MP en el recortador) y la pasa por el recortador. Devuelve
/// null si se cancela en cualquier paso.
Future<PhotoPick?> pickPhoto(
  BuildContext context, {
  required double aspectRatio,
  required int outputWidth,
  required String title,
  bool circle = false,
  bool canRemove = false,
  String? removeLabel,
}) async {
  final source = await showVSheet<_Source>(
    context,
    (ctx) => SheetScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetAction(
            key: const ValueKey('photo-camera'),
            vicon: VIcon.camera,
            label: context.l10n.photoCamera,
            onTap: () => Navigator.of(ctx).pop(_Source.camera),
          ),
          SheetAction(
            key: const ValueKey('photo-gallery'),
            vicon: VIcon.image,
            label: context.l10n.photoGallery,
            onTap: () => Navigator.of(ctx).pop(_Source.gallery),
          ),
          if (canRemove)
            SheetAction(
              key: const ValueKey('photo-remove'),
              vicon: VIcon.trash,
              label: removeLabel ?? context.l10n.photoRemove,
              danger: true,
              onTap: () => Navigator.of(ctx).pop(_Source.remove),
            ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;
  if (source == _Source.remove) return const PhotoPick.remove();

  Uint8List bytes;
  try {
    final file = await ImagePicker().pickImage(
      source: source == _Source.camera ? ImageSource.camera : ImageSource.gallery,
      // La cámara de selfis para la foto de perfil.
      preferredCameraDevice: circle ? CameraDevice.front : CameraDevice.rear,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 92,
    );
    if (file == null) return null;
    bytes = await file.readAsBytes();
  } on PlatformException catch (e) {
    if (!context.mounted) return null;
    final camera = source == _Source.camera;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          camera
              ? context.l10n.photoNoCamera
              : context.l10n.photoGalleryFailed(e.message ?? e.code),
        ),
      ),
    );
    return null;
  }
  if (!context.mounted) return null;
  final cropped = await showImageCropper(
    context,
    bytes: bytes,
    aspectRatio: aspectRatio,
    outputWidth: outputWidth,
    circle: circle,
    title: title,
  );
  return cropped == null ? null : PhotoPick.bytes(cropped);
}

enum _Source { camera, gallery, remove }

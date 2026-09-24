import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';
import '../services/services.dart';
import '../widgets/sheet.dart';
import 'profile_form.dart';

/// "Tu perfil": nombre, @usuario, foto y fondo. Se abre desde Configuración.
/// Guarda primero el @usuario (si ya lo tomó alguien, falla ahí y no se
/// guarda nada más), luego sube las fotos y al final actualiza el perfil,
/// que propaga nombre, color y foto a las notas, seguimientos y listas.
Future<void> showEditProfile(BuildContext context, UserProfile profile) {
  final services = ServicesScope.of(context);
  return showVSheet<void>(
    context,
    (ctx) => SheetScaffold(
      title: context.l10n.editProfileTitle,
      child: ProfileForm(
        submitLabel: context.l10n.save,
        showBanner: true,
        showUsername: true,
        initialName: profile.name,
        initialColor: profile.colorValue,
        initialUsername: profile.username,
        forUid: profile.uid,
        initialAvatarUrl: profile.avatarUrl,
        initialBannerUrl: profile.bannerUrl,
        showBio: true,
        initialBio: profile.bio,
        onSubmit: (edit) async {
          if (edit.username != null && edit.username != profile.username) {
            await services.users.setUsername(
              profile.uid,
              edit.username!,
              previous: profile.username,
            );
          }
          String? avatarUrl = edit.removeAvatar ? null : profile.avatarUrl;
          if (edit.avatar != null) {
            avatarUrl = await services.users.uploadAvatar(profile.uid, edit.avatar!);
          }
          String? bannerUrl = edit.removeBanner ? null : profile.bannerUrl;
          if (edit.banner != null) {
            bannerUrl = await services.users.uploadBanner(profile.uid, edit.banner!);
          }
          await services.users.updateProfile(
            RaterInfo(
              uid: profile.uid,
              name: edit.name,
              colorValue: edit.colorValue,
              avatarUrl: avatarUrl,
            ),
            bannerUrl: bannerUrl,
            updateBanner: edit.banner != null || edit.removeBanner,
            username: edit.username ?? profile.username,
            bio: edit.bio,
          );
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    ),
  );
}

package com.manuelcastillo.vinilo

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import java.io.File
import java.io.FileNotFoundException

/// Sirve, solo para leer, las imágenes para compartir que MainActivity deja
/// en la caché (`cache/share/`). Es un FileProvider mínimo, para no sumar
/// androidx.core; los permisos se dan por URI al compartir.
class ShareImageProvider : ContentProvider() {
    companion object {
        const val DIR = "share"

        fun authority(context: Context) = "${context.packageName}.shareimages"

        fun uriFor(context: Context, name: String): Uri =
            Uri.parse("content://${authority(context)}/$name")
    }

    private fun fileFor(uri: Uri): File {
        val name = uri.lastPathSegment ?: throw FileNotFoundException()
        // Solo nombres simples dentro de la carpeta (nada de "../").
        if (name.contains('/') || name.startsWith(".")) throw FileNotFoundException()
        val file = File(File(context!!.cacheDir, DIR), name)
        if (!file.exists()) throw FileNotFoundException()
        return file
    }

    override fun onCreate() = true

    override fun getType(uri: Uri) = "image/png"

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor =
        ParcelFileDescriptor.open(fileFor(uri), ParcelFileDescriptor.MODE_READ_ONLY)

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor {
        val file = fileFor(uri)
        val columns: Array<String> =
            projection?.map { it }?.toTypedArray() ?: arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        return MatrixCursor(columns).apply {
            addRow(columns.map {
                when (it) {
                    OpenableColumns.DISPLAY_NAME -> file.name
                    OpenableColumns.SIZE -> file.length()
                    else -> null
                }
            })
        }
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?) = 0
}

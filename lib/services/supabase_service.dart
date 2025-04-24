import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static final supabase = Supabase.instance.client;
  static const String bucketName = 'guerrerobarberapp';
  static const String projectId = 'sevejjaoodnjhzrjthuv';
  static const String baseUrl = 'https://sevejjaoodnjhzrjthuv.supabase.co';

  // Subir imagen de perfil
  static Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/$timestamp.jpg';

      print('Iniciando subida de archivo: $fileName'); // Debug

      // Subir el archivo a Supabase Storage
      final storageResponse = await supabase
          .storage
          .from(bucketName)
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      print('Archivo subido exitosamente: $storageResponse'); // Debug

      // Obtener la URL pública usando el método de Supabase
      final imageUrl = supabase
          .storage
          .from(bucketName)
          .createSignedUrl(fileName, 60 * 60 * 24 * 365); // URL válida por 1 año

      print('URL firmada creada: $imageUrl'); // Debug

      return imageUrl;
    } catch (e) {
      print('Error en Supabase Storage: $e');
      return null;
    }
  }

  // Eliminar imagen de perfil
  static Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extraer el nombre del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = '${pathSegments[pathSegments.length - 2]}/${pathSegments.last}';

      print('Intentando eliminar archivo: $fileName'); // Debug

      await supabase
          .storage
          .from(bucketName)
          .remove([fileName]);
      
      print('Archivo eliminado exitosamente'); // Debug
      return true;
    } catch (e) {
      print('Error al eliminar imagen: $e');
      return false;
    }
  }

  // Actualizar imagen de perfil
  static Future<String?> updateProfileImage(String oldImageUrl, File newImageFile, String userId) async {
    try {
      // Primero intentamos eliminar la imagen anterior
      await deleteProfileImage(oldImageUrl);
      
      // Luego subimos la nueva imagen
      final newImageUrl = await uploadProfileImage(userId, newImageFile);
      
      print('Nueva imagen subida con URL: $newImageUrl'); // Debug
      return newImageUrl;
    } catch (e) {
      print('Error al actualizar imagen: $e');
      return null;
    }
  }

  // Obtener URL pública de una imagen
  static Future<String?> getPublicUrl(String fileName) async {
    try {
      return await supabase
          .storage
          .from(bucketName)
          .createSignedUrl(fileName, 60 * 60 * 24 * 365); // URL válida por 1 año
    } catch (e) {
      print('Error al obtener URL pública: $e');
      return null;
    }
  }
} 
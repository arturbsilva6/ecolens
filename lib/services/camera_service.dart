
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _imagePicker = ImagePicker();

  // Captura uma imagem utilizando a câmera
  Future<XFile?> takePhoto() async {
    return await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
  }

  // Seleciona uma imagem da galeria
  Future<XFile?> pickFromGallery() async {
    return await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }
}

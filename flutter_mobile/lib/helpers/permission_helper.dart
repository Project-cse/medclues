import 'package:image_picker/image_picker.dart';

class PermissionHelper {
  PermissionHelper._();

  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickProfilePhoto() async {
    return _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
  }
}

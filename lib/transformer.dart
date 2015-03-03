library test_trans.transformer;

import "dart:io";

import "package:barback/barback.dart";
import "package:file_utils/file_utils.dart";
import "package:path/path.dart" as lib_path;
import "package:unsafe_extension/src/installer.dart";

class NativeExtensionBuilder extends Transformer {
  static const String EXT = ".inf";

  static const String PACKAGE = "unsafe_extension";

  final BarbackSettings _settings;

  NativeExtensionBuilder.asPlugin(this._settings);

  String get allowedExtensions => EXT;

  dynamic apply(Transform transform) {
    var id = transform.primaryInput.id;
    if (id.package != PACKAGE) {
      return null;
    }

    var path = id.path;
    if (lib_path.basename(path) != "$PACKAGE$EXT") {
      return null;
    }

    var cwd = Directory.current.path;
    try {
      FileUtils.chdir(lib_path.dirname(path));
      var installer = new Installer();
      installer.install([]);
    } finally {
      FileUtils.chdir(cwd);
    }

    return null;
  }
}

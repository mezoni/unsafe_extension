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

  dynamic apply(Transform transform) async {
    var id = transform.primaryInput.id;
    if (id.package != PACKAGE) {
      return null;
    }

    var filepath = id.path;
    if (lib_path.basename(filepath) != "$PACKAGE$EXT") {
      return null;
    }

    var cwd = Directory.current.path;
    try {
      var path = _resolvePackagePath(filepath);
      FileUtils.chdir(path);
      var installer = new Installer();
      await installer.install([]);
    } finally {
      FileUtils.chdir(cwd);
    }

    return null;
  }

  // This is incorrect but there is no other way
  String _resolvePackagePath(String filepath) {
    var cwd = Directory.current.path;
    var path = lib_path.join(cwd, "packages", PACKAGE);
    path = new Link(path).resolveSymbolicLinksSync();
    path = lib_path.dirname(path);
    return path;
  }
}

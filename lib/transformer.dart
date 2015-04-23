library unsafe_extension.transformer;

import "dart:io";

import "package:barback/barback.dart";
import "package:file_utils/file_utils.dart";
import "package:path/path.dart" as lib_path;
import "package:unsafe_extension/src/installer.dart";

class NativeExtensionBuilder extends Transformer {
  static const String EXT = ".inf";

  static const String PACKAGE = "unsafe_extension";

  final BarbackSettings _settings;

  String _workingDirectory;

  NativeExtensionBuilder.asPlugin(this._settings) {
    _workingDirectory = Directory.current.path;
  }

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

    try {
      var path = _resolvePackagePath(filepath);
      FileUtils.chdir(path);
      var installer = new Installer();
      await installer.install([]);
    } finally {
      FileUtils.chdir(_workingDirectory);
    }

    return null;
  }

  // This is incorrect but there is no other way
  String _resolvePackagePath(String filepath) {
    var path = lib_path.join(_workingDirectory, "packages", PACKAGE);
    path = new Link(path).resolveSymbolicLinksSync();
    path = lib_path.dirname(path);
    return path;
  }
}

library unsafe_extension.transformer;

import "dart:io";

import "package:barback/barback.dart";
import "package:file_utils/file_utils.dart";
import "package:package_config/discovery_analysis.dart";
import "package:path/path.dart" as lib_path;
import "package:semaphore/semaphore.dart";
import "package:unsafe_extension/src/installer.dart";

class NativeExtensionBuilder extends Transformer {
  static const String EXT = ".inf";

  static const String PACKAGE = "unsafe_extension";

  final BarbackSettings _settings;

  Directory _workingDirectory;

  NativeExtensionBuilder.asPlugin(this._settings) {
    _workingDirectory = Directory.current;
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

    var semaphore = new GlobalSemaphore();
    try {
      await semaphore.acquire();
      var path = _resolvePackagePath();
      // This is not safe but there is no other way
      FileUtils.chdir(path);
      var installer = new Installer();
      await installer.install([]);
    } finally {
      FileUtils.chdir(_workingDirectory.path);
      semaphore.release();
    }

    return null;
  }

  String _resolvePackagePath() {
    var context = PackageContext.findAll(_workingDirectory);
    var packages = context.packages;
    var map = packages.asMap();
    var path = map[PACKAGE];
    path = lib_path.dirname(path.toFilePath());
    return path;
  }
}

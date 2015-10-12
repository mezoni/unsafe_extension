library unsafe_extension.transformer;

import "dart:io";

import "package:barback/barback.dart";
import "package:file_utils/file_utils.dart";
import "package:path/path.dart" as lib_path;
import "package:pub_cache/pub_cache.dart";
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

    var content = await transform.primaryInput.readAsString();
    var version = content.trim();
    var semaphore = new GlobalSemaphore();
    try {
      await semaphore.acquire();
      var path = _resolvePackagePath(version);
      // This is not safe but there is no other way
      print("Working directory: ${_workingDirectory.path}");
      print("Change directory to: $path");
      FileUtils.chdir(path);
      var installer = new Installer();
      await installer.install([]);
    } finally {
      print("Change directory back: ${_workingDirectory.path}");
      FileUtils.chdir(_workingDirectory.path);
      semaphore.release();
    }

    return null;
  }

  String _resolvePackagePath(String version) {
    String path;
    var pubCache = new PubCache();
    var packageRefs = pubCache.getAllPackageVersions(PACKAGE);
    for (var packageRef in packageRefs) {
      if (packageRef.version.toString() == version) {
        var package = packageRef.resolve();
        path = package.location.path;
        break;
      }
    }

    if (path == null) {
      throw new StateError("Unable to find package '$PACKAGE-$version' in pub-cache");
    }

    return path;
  }
}

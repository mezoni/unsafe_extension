library unsafe_extension.transformer;

import "dart:io";

import "package:barback/barback.dart";
import "package:file_utils/file_utils.dart";
import "package:package_config/discovery_analysis.dart";
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
    _temp(version);
    var semaphore = new GlobalSemaphore();
    try {
      await semaphore.acquire();
      var path = _resolvePackagePath();
      path = _temp(version);
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

  String _resolvePackagePath() {
    var context = PackageContext.findAll(_workingDirectory);
    var packages = context.packages;
    var map = packages.asMap();
    var uri = map[PACKAGE];
    var file = new File(uri.toFilePath());
    var path = file.resolveSymbolicLinksSync();
    path = lib_path.dirname(path);
    return path;
  }

  String _temp(String version) {
    var pubCache = new PubCache();
    Package package;
    var packageRefs = pubCache.getAllPackageVersions(PACKAGE);
    for (var packageRef in packageRefs) {
      if (packageRef.version.toString() == version) {
        package = packageRef.resolve();
        break;
      }
    }

    if (package == null) {
      throw new StateError("Unable to find package '$PACKAGE-$version' in pub-cache");
    }

    return package.location.path;
  }
}

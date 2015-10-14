library unsafe_extension.transformer;

import "dart:io";

import "package:barback/barback.dart";
import "package:path/path.dart" as lib_path;
import "package:pub_cache/pub_cache.dart";
import "package:sandbox/sandbox.dart";

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
    var name = "$PACKAGE-$version";
    var path = _resolvePackagePath(version);
    print("Create sandbox for package '$name' at '$path'");
    var sandbox = new Sandbox(path);
    var script = "bin/setup.dart";
    print("Run '$name/$script' in sandbox...");
    var result = sandbox.runSync(script, [], workingDirectory: path);
    if (result.stdout is List) {
      print(new String.fromCharCodes(result.stdout));
    } else if (result.stdout is String) {
      print(result.stdout);
    }

    if (result.stderr is List) {
      print(new String.fromCharCodes(result.stderr));
    } else if (result.stderr is String) {
      print(result.stderr);
    }

    print("Terminated '$name/$script'");
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

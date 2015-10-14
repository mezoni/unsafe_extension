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
    print("Create sandbox for '$name'");
    var sandbox = new Sandbox(path);
    print("Sandbox created at ${sandbox.environmentPath}");
    var executable = "bin/setup.dart";
    var arguments = <String>[];
    print("Run script '$name/$executable' in sandbox");
    print("================");
    try {
      var dart = lib_path.join(sandbox.sdkPath, "bin", "dart");
      var args = <String>[];
      var path = lib_path.join(sandbox.environmentPath, "packages");
      args.add("--package-root=$path");
      path = lib_path.join(sandbox.applicationPath, executable);
      args.add(path);
      args.addAll(arguments);
      var result = Process.runSync(dart, args,
          runInShell: true, workingDirectory: sandbox.applicationPath);
      _displayOutput(result);
    } finally {
      sandbox.destroy();
      print("================");
      print("Script '$name/$executable' terminated");
      print("");
    }

    return null;
  }

  void _displayOutput(ProcessResult result) {
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
      throw new StateError(
          "Unable to find package '$PACKAGE-$version' in pub-cache");
    }

    return path;
  }
}

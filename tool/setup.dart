import "dart:io";

import "package:unsafe_extension/src/installer.dart";

void main() {
  var cwd = Directory.current.path;
  try {
    var installer = new Installer();
    installer.install([]);
  } finally {
    Directory.current = new Directory(cwd);
  }
}

library unsafe_exetnsion.src.installer;

import "dart:async";
import "dart:io";

import "package:build_tools/build_shell.dart";
import "package:build_tools/build_tools.dart";
import "package:ccompilers/ccompilers.dart";
import "package:file_utils/file_utils.dart";
import "package:path/path.dart" as pathos;
import "package:patsubst/patsubst.dart";
import "package:system_info/system_info.dart";

class Installer {
  Future install(List<String> arguments) async {
    if (arguments == null) {
      throw new ArgumentError.notNull("arguments");
    }

    var cwd = FileUtils.getcwd();
    try {
      FileUtils.chdir("lib/src");
      await _install(arguments);
    } finally {
      FileUtils.chdir(cwd);
    }
  }

  Future _install(List<String> args) async {
    const String PROJECT_NAME = "unsafe_extension";
    const String LIBNAME_LINUX = "lib$PROJECT_NAME.so";
    const String LIBNAME_MACOS = "lib$PROJECT_NAME.dylib";
    const String LIBNAME_WINDOWS = "$PROJECT_NAME.dll";

    // Reset because can be used multiple times (by transformers)
    Builder.reset();

    // Determine operating system
    var operatingSystem = Platform.operatingSystem;

    // Setup Dart SDK bitness for native extension
    var bits = DartSDK.getVmBits();

    // Defaults to processor architecture
    var arch = SysInfo.processors.first.architecture.toString();

    // Compiler options
    var compilerDefine = {};
    var compilerInclude = ["$DART_SDK/include"];

    // Linker options
    var linkerLibpath = [];

    // OS dependent parameters
    var libname = "";
    var objExtension = "";
    switch (operatingSystem) {
      case "android":
      case "linux":
        libname = LIBNAME_LINUX;
        objExtension = ".o";
        break;
      case "macos":
        libname = LIBNAME_MACOS;
        objExtension = ".o";
        break;
      case "windows":
        libname = LIBNAME_WINDOWS;
        compilerDefine["DART_SHARED_LIB"] = null;
        linkerLibpath.add("$DART_SDK/bin");
        objExtension = ".obj";
        break;
      default:
        print("Unsupported operating system: $operatingSystem");
        exit(1);
    }

    // C++ files
    var cppFiles = FileUtils.glob("*.cc");
    if (operatingSystem != "windows") {
      cppFiles = FileUtils.exclude(cppFiles, "${PROJECT_NAME}_dllmain_win.cc");
    }

    // Object files
    var objFiles = patsubst("%.cc", "%${objExtension}").replaceAll(cppFiles);

    // Makefile
    // Target: default
    target("default", ["setup"], null, description: "setup");

    // Setup
    target("setup", [], (t, args) async {
      print("Setup $libname.");
      var compiled = pathos.join("compiled", arch, operatingSystem, libname);
      if (FileUtils.testfile(compiled, "file")) {
        var compiledFile = new File(compiled);
        var foundFile = new File(libname);
        if (foundFile.existsSync()) {
          var bytes1 = compiledFile.readAsBytesSync();
          var bytes2 = foundFile.readAsBytesSync();
          var length = bytes1.length;
          if (bytes2.length == length) {
            var equal = true;
            for (var i = 0; i < length; i++) {
              if (bytes1[i] != bytes2[i]) {
                equal = false;
                break;
              }
            }

            if (equal) {
              print("Already installed binary '$compiled'");
              print("The ${t.name} successful.");
              return 0;
            }
          }
        }

        print("Copying compiled binary '$compiled'");
        new File(compiled).copySync(libname);
        print("The ${t.name} successful.");
        return 0;
      }

      var result = await Builder.current.build("build", arguments: args);
      if (result != 0) {
        return result;
      }

      var file = new File(libname);
      new File(compiled).createSync(recursive: true);
      file.copySync(compiled);
      print("The ${t.name} successful.");
    }, description: "Setup '$PROJECT_NAME'");

    // Target: build
    target("build", ["clean_all", "compile_link", "clean"], (t, args) {
      print("The ${t.name} successful.");
    }, description: "Build '$PROJECT_NAME'");

    // Target: compile_link
    target("compile_link", [libname], (t, args) {
      print("The ${t.name} successful.");
    }, description: "Compile and link '$PROJECT_NAME'");

    before(["setup", "compile_link"], (t, args) {
      var arg = args["bits"];
      if (arg != null) {
        bits = int.parse("$arg", onError: null);
      }

      switch (bits) {
        case 32:
        case 64:
          break;
        default:
          if (bits != null) {
            print("Unsupported 'bits': $bits");
            return -1;
          }
      }

      var architecture = SysInfo.processors.first.architecture;
      arg = args["arch"];
      // Parse argument 'arch'
      if (arg != null) {
        arg = "$arg".toUpperCase().trim();
        switch (arg) {
          case "AARCH64":
            architecture = ProcessorArchitecture.AARCH64;
            break;
          case "ARM":
            architecture = ProcessorArchitecture.ARM;
            break;
          case "IA64":
            architecture = ProcessorArchitecture.IA64;
            break;
          case "MIPS":
            architecture = ProcessorArchitecture.MIPS;
            break;
          case "X86":
            architecture = ProcessorArchitecture.X86;
            break;
          case "X86_64":
            architecture = ProcessorArchitecture.X86_64;
            break;
          default:
            print("Unsupported 'arch': $arg");
            return -1;
        }
      }

      switch (architecture) {
        case ProcessorArchitecture.X86:
          switch (bits) {
            case 32:
              arch = "X86";
              break;
            case 64:
              arch = "X86_64";
              break;
            default:
              arch = "X86";
              bits = 32;
          }

          break;

        case ProcessorArchitecture.X86_64:
          switch (bits) {
            case 32:
              arch = "X86";
              break;
            case 64:
              arch = "X86_64";
              break;
            default:
              arch = "X86_64";
              bits = 64;
          }

          break;
        case ProcessorArchitecture.ARM:
          switch (bits) {
            case 32:
            case 64:
              arch = "ARM";
              bits = null;
              break;
            default:
              arch = "ARM";
              bits = null;
          }

          break;
        default:
          // Other platforms are not yet supported
          print("Unsupported processor architecture: $architecture");
          return -1;
      }
    });

    // Target: clean
    target("clean", [], (t, args) {
      FileUtils.rm(["*.exp", "*.lib", "*.o", "*.obj"], force: true);
    }, description: "Deletes all intermediate files", reusable: true);

    // Target: clean_all
    target("clean_all", ["clean"], (Target t, Map args) {
      FileUtils.rm([libname], force: true);
    }, description: "Deletes all intermediate and output files", reusable: true);

    // Compile on Posix
    rule("%.o", ["%.cc"], (Target t, Map args) {
      var compiler = new GnuCppCompiler(bits: bits);
      var args = ['-fPIC', '-Wall'];

      return compiler.compile(t.sources,
          arguments: args, define: compilerDefine, include: compilerInclude, output: t.name).exitCode;
    });

    // Compile on Windows
    rule("%.obj", ["%.cc"], (Target t, Map args) {
      var compiler = new MsCppCompiler(bits: bits);
      return compiler.compile(t.sources, define: compilerDefine, include: compilerInclude, output: t.name).exitCode;
    });

    // Link on Linux
    file(LIBNAME_LINUX, objFiles, (Target t, Map args) {
      var linker = new GnuLinker(bits: bits);
      var args = ['-shared'];
      return linker.link(t.sources, arguments: args, libpaths: linkerLibpath, output: t.name).exitCode;
    });

    // Link on Macos
    file(LIBNAME_MACOS, objFiles, (Target t, Map args) {
      var linker = new GnuLinker(bits: bits);
      var args = ['-dynamiclib', '-undefined', 'suppress', '-flat_namespace'];
      return linker.link(t.sources, arguments: args, libpaths: linkerLibpath, output: t.name).exitCode;
    });

    // Link on Windows
    file(LIBNAME_WINDOWS, objFiles, (Target t, Map targs) {
      var linker = new MsLinker(bits: bits);
      var args = ['/DLL', 'dart.lib'];
      return linker.link(t.sources, arguments: args, libpaths: linkerLibpath, output: t.name).exitCode;
    });

    return new BuildShell().run(args);
  }
}

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

  Future _install(List<String> margs) async {
    const String PROJECT_NAME = "unsafe_extension";
    const String LIBNAME_LINUX = "lib$PROJECT_NAME.so";
    const String LIBNAME_MACOS = "lib$PROJECT_NAME.dylib";
    const String LIBNAME_WINDOWS = "$PROJECT_NAME.dll";

    // Determine operating system
    var os = Platform.operatingSystem;

    // Setup Dart SDK bitness for native extension
    var bits = DartSDK.getVmBits();

    if (Platform.environment.containsKey("BUILD_BITS")) {
      bits = int.parse(Platform.environment["BUILD_BITS"]);
    }

    // Compiler options
    var compilerDefine = {};
    var compilerInclude = ["$DART_SDK/include"];

    // Linker options
    var linkerLibpath = [];

    // OS dependent parameters
    var libname = "";
    var objExtension = "";
    switch (os) {
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
        print("Unsupported operating system: $os");
        exit(1);
    }

    // C++ files
    var cppFiles = FileUtils.glob("*.cc");
    if (os != "windows") {
      cppFiles = FileUtils.exclude(cppFiles, "${PROJECT_NAME}_dllmain_win.cc");
    }

    // Object files
    var objFiles = patsubst("%.cc", "%${objExtension}").replaceAll(cppFiles);

    // Makefile
    // Target: default
    target("default", ["setup"], null, description: "setup");

    // Setup
    target("setup", [], (Target t, Map args) async {
      print("Setup $libname.");
      var architecture = SysInfo.processors.first.architecture;
      var bitness = SysInfo.userSpaceBitness;

      if (Platform.environment.containsKey("BUILD_BITS")) {
        bitness = int.parse(Platform.environment["BUILD_BITS"]);
      }

      switch (architecture) {
        case ProcessorArchitecture.X86_64:
          if (bitness == 32) {
            architecture = ProcessorArchitecture.X86;
          }

          break;
        case ProcessorArchitecture.X86:
          break;
        default:
          print("Unsupported processor architecture: $architecture");
          return -1;
      }

      var operatingSystem = Platform.operatingSystem;
      var compiled = pathos.join("compiled", architecture.toString(), operatingSystem, libname);
      if (FileUtils.testfile(compiled, "file")) {
        print("Copying compiled binary '$compiled'");
        new File(compiled).copySync(libname);
        print("The ${t.name} successful.");
        return 0;
      }

      var result = await Builder.current.build("build");
      if (result != 0) {
        return result;
      }

      FileUtils.mkdir([pathos.dirname(compiled)], recursive: true);
      var file = new File(libname);
      file.copySync(compiled);
      print("The ${t.name} successful.");
    }, description: "Setup '$PROJECT_NAME'");

    // Target: build
    target("build", ["clean_all", "compile_link", "clean"], (Target t, Map args) {
      print("The ${t.name} successful.");
    }, description: "Build '$PROJECT_NAME'");

    // Target: compile_link
    target("compile_link", [libname], (Target t, Map args) {
      print("The ${t.name} successful.");
    }, description: "Compile and link '$PROJECT_NAME'");

    // Target: clean
    target("clean", [], (Target t, Map args) {
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

      if (SysInfo.userSpaceBitness != bits) {
        args.add("-m${bits}");
      }

      return compiler.compile(t.sources,
          arguments: args, define: compilerDefine, include: compilerInclude, output: t.name).exitCode;
    });

    // Compile on Windows
    rule("%.obj", ["%.cc"], (Target t, Map args) {
      var compiler = new MsCppCompiler(bits: bits);
      var args = ["/EHsc"];
      return compiler.compile(t.sources,
          arguments: args, define: compilerDefine, include: compilerInclude, output: t.name).exitCode;
    });

    // Link on Linux
    file(LIBNAME_LINUX, objFiles, (Target t, Map args) {
      var linker = new GnuLinker(bits: bits);
      var args = ['-shared'];
      if (SysInfo.userSpaceBitness != bits) {
        args.add("-m${bits}");
      }
      return linker.link(t.sources, arguments: args, libpaths: linkerLibpath, output: t.name).exitCode;
    });

    // Link on Macos
    file(LIBNAME_MACOS, objFiles, (Target t, Map args) {
      var linker = new GnuLinker(bits: bits);
      var args = ['-dynamiclib', '-undefined', 'suppress', '-flat_namespace'];
      if (SysInfo.userSpaceBitness != bits) {
        args.add("-m${bits}");
      }
      return linker.link(t.sources, arguments: args, libpaths: linkerLibpath, output: t.name).exitCode;
    });

    // Link on Windows
    file(LIBNAME_WINDOWS, objFiles, (Target t, Map args) {
      var linker = new MsLinker(bits: bits);
      var args = ['/DLL', 'dart.lib'];
      return linker.link(t.sources, arguments: args, libpaths: linkerLibpath, output: t.name).exitCode;
    });

    return new BuildShell().run(margs);
  }
}

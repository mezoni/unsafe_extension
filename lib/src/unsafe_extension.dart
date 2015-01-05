library unsafe_extension.unsafe_extension;

import 'dart-ext:unsafe_extension';

/**
 * Wrapper to "libffi" dynamic library.
 */
class ForeignFucntionInterface {
  static void call(int addr, int cif, int fn, int rvalue, int avalue) {
    if (addr == null) {
      throw new ArgumentError.notNull("addr");
    }

    if (cif == null) {
      throw new ArgumentError.notNull("cif");
    }

    if (fn == null) {
      throw new ArgumentError.notNull("fn");
    }

    if (rvalue == null) {
      throw new ArgumentError.notNull("rvalue");
    }

    if (avalue == null) {
      throw new ArgumentError.notNull("avalue");
    }

    _ffiCall(addr, cif, fn, rvalue, avalue);
  }

  static int prepareCallInterface(int addr, int cif, int abi, int nargs, int rtype, int atypes) {
    if (addr == null) {
      throw new ArgumentError.notNull("addr");
    }

    if (cif == null) {
      throw new ArgumentError.notNull("cif");
    }

    if (abi == null) {
      throw new ArgumentError.notNull("abi");
    }

    if (nargs == null) {
      throw new ArgumentError.notNull("nargs");
    }

    if (rtype == null) {
      throw new ArgumentError.notNull("rtype");
    }

    if (atypes == null) {
      throw new ArgumentError.notNull("atypes");
    }

    return _ffiPrepCif(addr, cif, abi, nargs, rtype, atypes);
  }

  static int prepareCallInterfaceVariadic(int addr, int cif, int abi, int nfixedargs, int ntotalargs, int rtype, int atypes) {
    if (addr == null) {
      throw new ArgumentError.notNull("addr");
    }

    if (cif == null) {
      throw new ArgumentError.notNull("cif");
    }

    if (abi == null) {
      throw new ArgumentError.notNull("abi");
    }

    if (nfixedargs == null) {
      throw new ArgumentError.notNull("nfixedargs");
    }

    if (ntotalargs == null) {
      throw new ArgumentError.notNull("ntotalargs");
    }

    if (rtype == null) {
      throw new ArgumentError.notNull("rtype");
    }

    if (atypes == null) {
      throw new ArgumentError.notNull("atypes");
    }

    return _ffiPrepCifVar(addr, cif, abi, nfixedargs, ntotalargs, rtype, atypes);
  }

  static void _ffiCall(int addr, int cif, int fn, int rvalue, int avalue) native "Unsafe_FfiCall";

  static int _ffiPrepCif(int addr, int cif, int abi, int nargs, int rtype, int atypes) native "Unsafe_FfiPrepCif";

  static int _ffiPrepCifVar(int addr,int cif, int abi, int nfixedargs, int ntotalargs, int rtype, int atypes) native "Unsafe_FfiPrepCifVar";
}

/**
 * Memory block. Allocates memory when creating, frees memory when destroying.
 */
class MemoryBlock {
  /**
   * Size of memory block in bytes.
   */
  final int size;

  int _address;

  MemoryBlock(this.size) {
    if (size == null || size <= 0) {
      throw new ArgumentError('size: $size');
    }

    _address = Unsafe.memoryAllocate(size);
    if (_address == 0) {
      throw new StateError("Cannot allocate memory");
    }

    Unsafe.memoryPeer(this, _address, size);
  }

  /**
   * Returns the address of memory block.
   */
  int get address => _address;
}

/**
 * Unsafe operations helper.
 */
class Unsafe {
  /**
   * Indicates when the endianness is little endian.
   */
  static final bool isLittleEndian = _isLittleEndian();

  /**
   * Size of the "pointer" type.
   */
  static final int sizeOfPointer = _getSizeOfPointer();

  /**
   * Page size of physical memory.
   */
  static final int pageSize = _getPageSize();

  /**
   * Frees the dynamic library.
   *
   * Parameters:
   *   [int] handle
   *   Handle of dynamic library.
   */
  static int libraryFree(int handle) {
    if (handle == null) {
      throw new ArgumentError('handle: $handle');
    }

    return _libraryFree(handle);
  }

  /**
   * Loads the dynamic library.
   *
   * Parameters:
   *   [String] filename
   *   File name of the dynamic library.
   */
  static int libraryLoad(String filename) {
    if (filename == null || filename.isEmpty) {
      throw new ArgumentError('name: $filename');
    }

    return _libraryLoad(filename);
  }

  /**
   * Obtains the address of a symbol from a dynamic library.
   *
   * Parameters:
   *   [int] handle
   *   Handle of dynamic library.
   *
   *   [String] symbol
   *   Symbol to obtain an address.
   */
  static int librarySymbol(int handle, String symbol) {
    if (handle == null || handle == 0) {
      throw new ArgumentError('handle: $handle');
    }

    if (symbol == null || symbol.isEmpty) {
      throw new ArgumentError('symbol: $symbol');
    }

    return _librarySymbol(handle, symbol);
  }

  static int memoryAllocate(int size) {
    if (size == null) {
      throw new ArgumentError('size: $size');
    }

    return _memoryAllocate(size);
  }

  /**
   * Copies the values of num bytes from the source to the destionation.
   * Does not allows the destination and source to overlap.
   *
   * Parameters:
   *   [int] dest
   *   Address of destination.
   *
   *   [int] src
   *   Address of source.
   *
   *   [int] num
   *   Numbers of bytes to copy.
   */
  static void memoryCopy(int dest, int src, int num) {
    if (dest == null || dest == 0) {
      throw new ArgumentError('dest: $dest');
    }

    if (src == null || src == 0) {
      throw new ArgumentError('src: $src');
    }

    if (num == null || num <= 0) {
      throw new ArgumentError('num: $num');
    }

    _memoryCopy(dest, src, num);
  }

  /**
   * Frees the allocated memory.
   *
   * Parameters:
   *   [int] handle
   *   Address of allocated memory.
   */
  static void memoryFree(int handle) {
    if (handle == null || handle == 0) {
      throw new ArgumentError('handle: $handle');
    }

    _memoryFree(handle);
  }

  /**
   * Copies the values of num bytes from the source to the destionation.
   * Allows the destination and source to overlap.
   *
   * Parameters:
   *   [int] dest
   *   Address of destination.
   *
   *   [int] src
   *   Address of source.
   *
   *   [int] num
   *   Numbers of bytes to copy.
   */
  static void memoryMove(int dest, int src, int num) {
    if (dest == null || dest == 0) {
      throw new ArgumentError('dest: $dest');
    }

    if (src == null || src == 0) {
      throw new ArgumentError('src: $src');
    }

    if (num == null) {
      throw new ArgumentError('num: $num');
    }

    _memoryMove(dest, src, num);
  }

  /**
   * Registers the peer with the specified object.
   *
   * Parameters:
   *   [Object] object
   *
   *   [int] peer
   *   Address of peer.
   *
   *   [int] size
   *   Size of the peer.
   */
  static void memoryPeer(Object object, int peer, int size) {
    if (object == null || object is bool || object is num || object is String) {
      throw new ArgumentError('object: $object');
    }

    if (peer == null || peer == 0) {
      throw new ArgumentError('peer: $peer');
    }

    if (size == null || size == 0) {
      throw new ArgumentError('size: $size');
    }

    _peerRegister(object, peer, size);
  }

  /**
   * Sets the first num bytes of the memory the specified value.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to set.
   *
   *   [int] num
   *   Number of bytes to be set to the value.
   */
  static void memorySet(int base, int offset, int value, int num) {
    if (base == null || base == 0) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    if (num == null || num < 0) {
      throw new ArgumentError('num: $num');
    }

    value &= 0xff;
    if (value < 0) {
      value = 255 + value + 1;
    }

    _memorySet(base, offset, value, num);
  }

  /**
   * Reads the 32-bit float value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [double] value
   *   Value to read.
   */
  static double readFloat32(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    return _readFloat32(base, offset);
  }

  /**
   * Reads the 64-bit float value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [double] value
   *   Value to read.
   */
  static double readFloat64(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    return _readFloat64(base, offset);
  }

  /**
   * Reads the 16-bit signed int value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to read.
   */
  static int readInt16(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    return _readInt16(base, offset);
  }

  /**
   * Reads the 32-bit signed int value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to read.
   */
  static int readInt32(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    return _readInt32(base, offset);
  }

  /**
   * Reads the 64-bit signed int value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to read.
   */
  static int readInt64(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    return _readInt64(base, offset);
  }

  /**
   * Reads the 8-bit signed int value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to read.
   */
  static int readInt8(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    return _readInt8(base, offset);
  }

  /**
   * Reads the integer pointer value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to read.
   */
  static int readIntPtr(int base, int offset) {
    switch (Unsafe.sizeOfPointer) {
      case 4:
        return readInt32(base, offset);
      case 8:
        return readInt64(base, offset);
      default:
        throw ('Illegal size (${Unsafe.sizeOfPointer}) of IntPtr');
    }
  }

  /**
   * Reads the 16-bit unsigned int value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to read.
   */
  static int readUint16(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    return _readUint16(base, offset);
  }

  /**
   * Reads the 32-bit unsigned int value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to read.
   */
  static int readUint32(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    return _readUint32(base, offset);
  }

  /**
   * Reads the 64-bit unsigned int value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to read.
   */
  static int readUint64(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    var value = _readUint64(base, offset);
    // Dart API limitation does not allow to create an unsigned 64-bit integers
    if (value < 0) {
      value = 18446744073709551615 + value + 1;
    }

    return value;
  }

  /**
   * Reads the 8-bit unsigned int value from memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to read.
   */
  static int readUint8(int base, int offset) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    return _readUint8(base, offset);
  }

  /**
   * Writes the 32-bit float value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [double] value
   *   Value to write.
   */
  static void writeFloat32(int base, int offset, double value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    _writeFloat32(base, offset, value);
  }

  /**
   * Writes the 64-bit float value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [double] value
   *   Value to write.
   */
  static void writeFloat64(int base, int offset, double value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    _writeFloat64(base, offset, value);
  }

  /**
   * Writes the 16-bit signed integer value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to write.
   */
  static void writeInt16(int base, int offset, int value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    value &= 0xffff;
    _writeInt16(base, offset, value);
  }

  /**
   * Writes the 32-bit signed integer value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to write.
   */
  static void writeInt32(int base, int offset, int value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    value &= 0xffffffff;
    _writeInt32(base, offset, value);
  }

  /**
   * Writes the 64-bit signed integer value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to write.
   */
  static void writeInt64(int base, int offset, int value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    value &= 0xffffffffffffffff;
    if (value > 9223372036854775807) {
      value = value - 0x10000000000000000;
    }

    _writeInt64(base, offset, value);
  }

  /**
   * Writes the 8-bit signed integer value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to write.
   */
  static void writeInt8(int base, int offset, int value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    value &= 0xff;
    _writeInt8(base, offset, value);
  }

  static void writeIntPtr(int base, int offset, int ptr) {
    if (ptr == null) {
      throw new ArgumentError('ptr: $ptr');
    }

    switch (Unsafe.sizeOfPointer) {
      case 4:
        writeInt32(base, offset, ptr);
        break;
      case 8:
        writeInt64(base, offset, ptr);
        break;
      default:
        throw ('Illegal size (${Unsafe.sizeOfPointer}) of IntPtr');
    }
  }

  /**
   * Writes the 16-bit unsigned integer value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to write.
   */
  static void writeUint16(int base, int offset, int value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    value &= 0xffff;
    _writeUint16(base, offset, value);
  }

  /**
   * Writes the 32-bit unsigned integer value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to write.
   */
  static void writeUint32(int base, int offset, int value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    value &= 0xffffffff;
    _writeUint32(base, offset, value);
  }

  /**
   * Writes the 64-bit unsigned integer value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to write.
   */
  static void writeUint64(int base, int offset, int value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    value &= 0xffffffffffffffff;
    _writeUint64(base, offset, value);
  }

  /**
   * Writes the 8-bit unsigned integer value in memory.
   *
   * Parameters:
   *   [int] base
   *   Base of memory address.
   *
   *   [int] offset
   *   Offset of memory address.
   *
   *   [int] value
   *   Value to write.
   */
  static void writeUint8(int base, int offset, int value) {
    if (base == null) {
      throw new ArgumentError('base: $base');
    }

    if (offset == null) {
      throw new ArgumentError('offset: $offset');
    }

    if (value == null) {
      throw new ArgumentError('value: $value');
    }

    value &= 0xff;
    _writeUint8(base, offset, value);
  }

  static int _getSizeOfPointer() native 'Unsafe_GetSizeOfPointer';

  static int _getPageSize() native 'Unsafe_GetPageSize';

  static bool _isLittleEndian() native 'Unsafe_IsLittleEndian';

  static int _libraryFree(int handle) native 'Unsafe_LibraryFree';

  static int _libraryLoad(String name) native 'Unsafe_LibraryLoad';

  static int _librarySymbol(int handle, String symbol) native 'Unsafe_LibrarySymbol';

  static int _memoryAllocate(int size) native 'Unsafe_MemoryAllocate';

  static void _memoryCopy(int dest, int src, int num) native 'Unsafe_MemoryCopy';

  static void _memoryFree(int handle) native 'Unsafe_MemoryFree';

  static void _memoryMove(int dest, int src, int num) native 'Unsafe_MemoryMove';

  static void _memorySet(int base, int offset, int value, int num) native 'Unsafe_MemorySet';

  static void _peerRegister(Object object, int peer, int size) native 'Unsafe_PeerRegister';

  static double _readFloat32(int base, int offset) native 'Unsafe_ReadFloat32';

  static double _readFloat64(int base, int offset) native 'Unsafe_ReadFloat64';

  static int _readInt16(int base, int offset) native 'Unsafe_ReadInt16';

  static int _readInt32(int base, int offset) native 'Unsafe_ReadInt32';

  static int _readInt64(int base, int offset) native 'Unsafe_ReadInt64';

  static int _readInt8(int base, int offset) native 'Unsafe_ReadInt8';

  static int _readUint16(int base, int offset) native 'Unsafe_ReadUInt16';

  static int _readUint32(int base, int offset) native 'Unsafe_ReadUInt32';

  static int _readUint64(int base, int offset) native 'Unsafe_ReadUInt64';

  static int _readUint8(int base, int offset) native 'Unsafe_ReadUInt8';

  static void _writeFloat32(int base, int offset, double value) native 'Unsafe_WriteFloat32';

  static void _writeFloat64(int base, int offset, double value) native 'Unsafe_WriteFloat64';

  static void _writeInt16(int base, int offset, int value) native 'Unsafe_WriteInt16';

  static void _writeInt32(int base, int offset, int value) native 'Unsafe_WriteInt32';

  static void _writeInt64(int base, int offset, int value) native 'Unsafe_WriteInt64';

  static void _writeInt8(int base, int offset, int value) native 'Unsafe_WriteInt8';

  static void _writeUint16(int base, int offset, int value) native 'Unsafe_WriteUInt16';

  static void _writeUint32(int base, int offset, int value) native 'Unsafe_WriteUInt32';

  static void _writeUint64(int base, int offset, int value) native 'Unsafe_WriteUInt64';

  static void _writeUint8(int base, int offset, int value) native 'Unsafe_WriteUInt8';
}

// TODO: Remove
class _VirtualMemory {
  static const int NO_ACCESS = 1;

  static const int READ_ONLY = 2;

  static const int READ_WRITE = 3;

  static const int READ_EXECUTE = 4;

  static const int READ_WRITE_EXECUTE = 5;

  final int size;

  int _address;

  bool _auto;

  _VirtualMemory(this.size, [bool auto]) {
    if (size == null || size == 0) {
      throw new ArgumentError('size: $size');
    }

    if (auto == null) {
      auto = false;
    }

    _auto = auto;
    _address = _allocate(size);
    if (auto) {
      _peer(this, address, size);
    }
  }

  int get address => _address;

  void free() {
    if (_auto) {
      throw new StateError("Cannot free auto memory");
    }

    if (_address == null) {
      throw new StateError("Cannot free not allocated memory");
    }

    _free(_address, size);
    _address = null;
  }

  bool protect(int protection) {
    if (protection == null || protection < NO_ACCESS || protection > READ_WRITE_EXECUTE) {
      throw new ArgumentError('protection: $protection');
    }

    return _protect(_address, size, protection);
  }

  static int _allocate(int size) native 'Unsafe_VirtualMemoryAllocate';

  static void _free(int address, int size) native 'Unsafe_VirtualMemoryFree';

  static bool _peer(Object object, int address, int size) native 'Unsafe_VirtualMemoryPeer';

  static bool _protect(int address, int size, int protection) native 'Unsafe_VirtualMemoryProtect';
}

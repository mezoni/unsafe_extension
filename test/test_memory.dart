import 'package:unsafe_extension/unsafe_extension.dart';
import 'package:unittest/unittest.dart';

void main() {
  testLimits();
  testRelativeMemoryAccess();
  print("Done");
}

void testLimits() {
  var limits = <List<int>>[];
  limits.add([-128, 127, 255]);
  limits.add([-32768, 32767, 65535]);
  limits.add([-2147483648, 2147483647, 4294967295]);
  limits.add([-9223372036854775808, 9223372036854775807, 18446744073709551615]);
  var memoryBlock = new MemoryBlock(8);
  var length = 4;
  for (var test = 0; test < 4; test++) {
    var values = limits[test];
    var minSigned = values[0];
    var maxSigned = values[1];
    var minUnsigned = 0;
    var maxUnsigned = values[2];
    // Signed
    var signedValues = <List<int>>[];
    signedValues.add([minSigned, minSigned]);
    signedValues.add([minSigned - 1, maxSigned]);
    signedValues.add([minSigned - 2, maxSigned - 1]);
    signedValues.add([maxSigned, maxSigned]);
    signedValues.add([maxSigned + 1, minSigned]);
    signedValues.add([maxSigned + 2, minSigned + 1]);
    signedValues.add([minUnsigned, minUnsigned]);
    signedValues.add([minUnsigned - 1, -1]);
    signedValues.add([minUnsigned - 2, -2]);
    signedValues.add([maxUnsigned, -1]);
    signedValues.add([maxUnsigned + 1, 0]);
    signedValues.add([maxUnsigned + 2, 1]);
    var length = signedValues.length;
    for (var i = 0; i < length; i++) {
      var input = signedValues[i][0];
      var output = signedValues[i][1];
      String reason;
      int actual;
      switch (test) {
        case 0:
          Unsafe.writeInt8(memoryBlock.address, 0, input);
          actual = Unsafe.readInt8(memoryBlock.address, 0);
          reason = "writeInt8: $input, readInt8: $output";
          break;
        case 1:
          Unsafe.writeInt16(memoryBlock.address, 0, input);
          actual = Unsafe.readInt16(memoryBlock.address, 0);
          reason = "writeInt16: $input, readInt16: $output";
          break;
        case 2:
          Unsafe.writeInt32(memoryBlock.address, 0, input);
          actual = Unsafe.readInt32(memoryBlock.address, 0);
          reason = "writeInt32: $input, readInt32: $output";
          break;
        case 3:
          Unsafe.writeInt64(memoryBlock.address, 0, input);
          actual = Unsafe.readInt64(memoryBlock.address, 0);
          reason = "writeInt64: $input, readInt64: $output";
          break;
      }

      expect(actual, output, reason: reason);
    }

    // Unsigned
    var unsignedValues = <List<int>>[];
    unsignedValues.add([minSigned, -minSigned]);
    unsignedValues.add([minSigned - 1, maxSigned]);
    unsignedValues.add([minSigned - 2, maxSigned - 1]);
    unsignedValues.add([maxSigned, maxSigned]);
    unsignedValues.add([maxSigned + 1, maxSigned + 1]);
    unsignedValues.add([maxSigned + 2, maxSigned + 2]);
    unsignedValues.add([minUnsigned, minUnsigned]);
    unsignedValues.add([minUnsigned - 1, maxUnsigned]);
    unsignedValues.add([minUnsigned - 2, maxUnsigned - 1]);
    unsignedValues.add([maxUnsigned, maxUnsigned]);
    unsignedValues.add([maxUnsigned + 1, 0]);
    unsignedValues.add([maxUnsigned + 2, 1]);
    length = unsignedValues.length;
    for (var i = 0; i < length; i++) {
      var input = unsignedValues[i][0];
      var output = unsignedValues[i][1];
      String reason;
      int actual;
      switch (test) {
        case 0:
          Unsafe.writeUint8(memoryBlock.address, 0, input);
          actual = Unsafe.readUint8(memoryBlock.address, 0);
          reason = "writeUInt8: $input, readUInt8: $output";
          break;
        case 1:
          Unsafe.writeUint16(memoryBlock.address, 0, input);
          actual = Unsafe.readUint16(memoryBlock.address, 0);
          reason = "writeUInt16: $input, readUInt16: $output";
          break;
        case 2:
          Unsafe.writeUint32(memoryBlock.address, 0, input);
          actual = Unsafe.readUint32(memoryBlock.address, 0);
          reason = "writeUInt32: $input, readUInt32: $output";
          break;
        case 3:
          Unsafe.writeUint64(memoryBlock.address, 0, input);
          actual = Unsafe.readUint64(memoryBlock.address, 0);
          reason = "writeUInt64: $input, readUInt64: $output";
          break;
      }

      expect(actual, output, reason: reason);
    }
  }

  // Free memory
  memoryBlock = null;
}

void testRelativeMemoryAccess() {
  var offsets = [-1, 0, 1];
  var count = 3;
  var memoryBlock = new MemoryBlock(count * 8);
  var address = memoryBlock.address + 1;
  for (var i in offsets) {
    var expected = i;
    Unsafe.writeInt8(address + i, 0, i);
    var value = Unsafe.readInt8(address + i, 0);
    expect(value, expected, reason: "read/write int8 $i");
    Unsafe.writeInt16(address + i, 0, i);
    value = Unsafe.readInt16(address + i, 0);
    expect(value, expected, reason: "read/write int16 $i");
    Unsafe.writeInt32(address + i, 0, i);
    value = Unsafe.readInt32(address + i, 0);
    expect(value, expected, reason: "read/write int32 $i");
    Unsafe.writeInt64(address + i, 0, i);
    value = Unsafe.readInt64(address + i, 0);
    expect(value, expected, reason: "read/write int64 $i");
  }

  // Free memory
  memoryBlock = null;
}

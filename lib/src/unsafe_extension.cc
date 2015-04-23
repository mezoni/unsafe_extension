#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <signal.h>

#ifdef _WIN32
#include "windows.h"
#else
#include <dlfcn.h>
#include <unistd.h>
#endif

#include "dart_api.h"

Dart_Handle HandleError(Dart_Handle handle);

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope);

#ifdef __cplusplus
extern "C" {
#endif

void sigsegv_signal(int signum) {
  Dart_Handle error;

  error = Dart_NewUnhandledExceptionError(Dart_NewStringFromCString("Segmentation fault"));
  HandleError(error);
  signal(signum, SIG_DFL);
  exit(139);
}

#ifdef __cplusplus
}
#endif

DART_EXPORT Dart_Handle unsafe_extension_Init(Dart_Handle parent_library) {
  Dart_Handle result_code;

  if(Dart_IsError(parent_library)) {
    return parent_library;
  }

  result_code = Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if(Dart_IsError(result_code)) {
    return result_code;
  }

  signal(SIGSEGV, sigsegv_signal);

  return Dart_Null();
}

Dart_Handle HandleError(Dart_Handle handle) {
  if (Dart_IsError(handle)) {
    Dart_PropagateError(handle);
  }

  return handle;
}

void ArgumentError(const char* message) {
  Dart_Handle dh_class;
  Dart_Handle dh_instance;
  Dart_Handle dh_library;
  Dart_Handle list[1];

  dh_library = Dart_LookupLibrary(Dart_NewStringFromCString("dart:core"));
  dh_class = Dart_GetClass(dh_library, Dart_NewStringFromCString("ArgumentError"));
  list[0] = Dart_NewStringFromCString(message);
  dh_instance = Dart_New(dh_class, Dart_Null(), 1, list);
  Dart_ThrowException(dh_instance);
}

/*---------------------------------------------------------------------------*/

void Unsafe_GetPageSize(Dart_NativeArguments arguments) {
  Dart_Handle dh_result;
#if _WIN32
  SYSTEM_INFO si;
#endif

#if _WIN32
  GetSystemInfo(&si);
  dh_result = Dart_NewInteger(si.dwPageSize);
#else
  dh_result = Dart_NewInteger(sysconf(_SC_PAGESIZE));
#endif
  Dart_SetReturnValue(arguments, dh_result);
}

void Unsafe_GetSizeOfPointer(Dart_NativeArguments arguments) {
  Dart_Handle dh_result;

  dh_result = Dart_NewInteger(sizeof(intptr_t));
  Dart_SetReturnValue(arguments, dh_result);
}

void Unsafe_IsLittleEndian(Dart_NativeArguments arguments) {
  uint8_t* bytes;
  uint16_t word = 1;
  Dart_Handle dh_result;

  bytes = (uint8_t*)&word;
  dh_result = Dart_NewBoolean((bool)*bytes);
  Dart_SetReturnValue(arguments, dh_result);
}

/*---------------------------------------------------------------------------*/

void Unsafe_MemoryAllocate(Dart_NativeArguments arguments) {
  void* buffer;
  Dart_Handle dh_result;
  int64_t size;

  Dart_GetNativeIntegerArgument(arguments, 0, &size);
  buffer = malloc(size);
  dh_result = Dart_NewInteger((int64_t)(intptr_t)buffer);
  Dart_SetReturnValue(arguments, dh_result);
}

void Unsafe_MemoryFree(Dart_NativeArguments arguments) {
  int64_t handle;

  Dart_GetNativeIntegerArgument(arguments, 0, &handle);
  free((void*)handle);
}

#define UNSAFE_MEMMOVE(NAME, OPERATION) \
void Unsafe_Memory##NAME(Dart_NativeArguments arguments) { \
  int64_t dest; \
  int64_t src; \
  int64_t num; \
  Dart_GetNativeIntegerArgument(arguments, 0, &dest); \
  Dart_GetNativeIntegerArgument(arguments, 1, &src); \
  Dart_GetNativeIntegerArgument(arguments, 2, &num); \
  OPERATION((void*)(intptr_t)dest, (void*)(intptr_t)src, num); \
}

UNSAFE_MEMMOVE(Copy, memcpy)
UNSAFE_MEMMOVE(Move, memmove)

#undef UNSAFE_MEMMOVE

void Unsafe_MemorySet(Dart_NativeArguments arguments) {
  int64_t base;
  int64_t offset;
  int64_t size;
  int64_t value;

  Dart_GetNativeIntegerArgument(arguments, 0, &base);
  Dart_GetNativeIntegerArgument(arguments, 1, &offset);
  Dart_GetNativeIntegerArgument(arguments, 2, &value);
  Dart_GetNativeIntegerArgument(arguments, 3, &size);
  memset((void*)(base + offset), value, size);
}

/*---------------------------------------------------------------------------*/

void Unsafe__ObjectPeerFinalizer(void* isolate_callback_data, Dart_WeakPersistentHandle handle, void *peer) {
  if (peer != NULL) {
    free(peer);
  }  
}

void Unsafe_PeerRegister(Dart_NativeArguments arguments) {
  Dart_WeakPersistentHandle dh_handle;
  Dart_Handle dh_object;
  int64_t peer;
  int64_t size;

  dh_object = Dart_GetNativeArgument(arguments, 0);
  Dart_GetNativeIntegerArgument(arguments, 1, &peer);
  Dart_GetNativeIntegerArgument(arguments, 2, &size);
  dh_handle = Dart_NewWeakPersistentHandle(dh_object, (void*)peer, size, Unsafe__ObjectPeerFinalizer);
  Dart_SetReturnValue(arguments, Dart_NewInteger((int64_t)dh_handle));
}

/*---------------------------------------------------------------------------*/

#define UNSAFE_READ_INT(SIZE, TYPE) \
void Unsafe_ReadInt##SIZE(Dart_NativeArguments arguments) { \
  int64_t base; \
  Dart_Handle dh_result; \
  int64_t offset; \
  TYPE value; \
  Dart_GetNativeIntegerArgument(arguments, 0, &base); \
  Dart_GetNativeIntegerArgument(arguments, 1, &offset); \
  value = *((TYPE*)(intptr_t)(base + offset)); \
  dh_result = Dart_NewInteger((int64_t)value); \
  Dart_SetReturnValue(arguments, dh_result); \
}

UNSAFE_READ_INT(8, int8_t)
UNSAFE_READ_INT(16, int16_t)
UNSAFE_READ_INT(32, int32_t)
UNSAFE_READ_INT(64, int64_t)

#undef UNSAFE_READ_INT

/*---------------------------------------------------------------------------*/

#define UNSAFE_READ_UINT(SIZE, TYPE) \
void Unsafe_ReadUInt##SIZE(Dart_NativeArguments arguments) { \
  int64_t base; \
  Dart_Handle dh_result; \
  int64_t offset; \
  TYPE value; \
  Dart_GetNativeIntegerArgument(arguments, 0, &base); \
  Dart_GetNativeIntegerArgument(arguments, 1, &offset); \
  value = *((TYPE*)(intptr_t)(base + offset)); \
  dh_result = Dart_NewInteger((uint64_t)value); \
  Dart_SetReturnValue(arguments, dh_result); \
}

UNSAFE_READ_UINT(8, uint8_t)
UNSAFE_READ_UINT(16, uint16_t)
UNSAFE_READ_UINT(32, uint32_t)
UNSAFE_READ_UINT(64, uint64_t)

#undef UNSAFE_READ_UINT

/*---------------------------------------------------------------------------*/

#define UNSAFE_WRITE_INT(SIZE, TYPE) \
void Unsafe_WriteInt##SIZE(Dart_NativeArguments arguments) { \
  int64_t base; \
  Dart_Handle dh_value; \
  int64_t offset; \
  int64_t value; \
  Dart_GetNativeIntegerArgument(arguments, 0, &base); \
  Dart_GetNativeIntegerArgument(arguments, 1, &offset); \
  dh_value = Dart_GetNativeArgument(arguments, 2); \
  Dart_IntegerToInt64(dh_value, &value); \
  *((TYPE*)(intptr_t)(base + offset)) = (TYPE)value; \
}

UNSAFE_WRITE_INT(8, int8_t)
UNSAFE_WRITE_INT(16, int16_t)
UNSAFE_WRITE_INT(32, int32_t)
UNSAFE_WRITE_INT(64, int64_t)

#undef UNSAFE_WRITE_INT

/*---------------------------------------------------------------------------*/

#define UNSAFE_WRITE_UINT(SIZE, TYPE) \
void Unsafe_WriteUInt##SIZE(Dart_NativeArguments arguments) { \
  int64_t base; \
  Dart_Handle dh_value; \
  int64_t offset; \
  uint64_t value; \
  Dart_GetNativeIntegerArgument(arguments, 0, &base); \
  Dart_GetNativeIntegerArgument(arguments, 1, &offset); \
  dh_value = Dart_GetNativeArgument(arguments, 2); \
  Dart_IntegerToUint64(dh_value, &value); \
  *((TYPE*)(intptr_t)(base + offset)) = (TYPE)value; \
}

UNSAFE_WRITE_UINT(8, uint8_t)
UNSAFE_WRITE_UINT(16, uint16_t)
UNSAFE_WRITE_UINT(32, uint32_t)
UNSAFE_WRITE_UINT(64, uint64_t)

#undef UNSAFE_WRITE_UINT

/*---------------------------------------------------------------------------*/

#define UNSAFE_READ_FLOAT(SIZE, TYPE) \
void Unsafe_ReadFloat##SIZE(Dart_NativeArguments arguments) { \
  int64_t base; \
  Dart_Handle dh_result; \
  int64_t offset; \
  TYPE value; \
  Dart_GetNativeIntegerArgument(arguments, 0, &base); \
  Dart_GetNativeIntegerArgument(arguments, 1, &offset); \
  value = *((TYPE*)(intptr_t)(base + offset)); \
  dh_result = Dart_NewDouble((double)value); \
  Dart_SetReturnValue(arguments, dh_result); \
}

UNSAFE_READ_FLOAT(32, float)
UNSAFE_READ_FLOAT(64, double)

#undef UNSAFE_READ_FLOAT

/*---------------------------------------------------------------------------*/

#define UNSAFE_WRITE_FLOAT(SIZE, TYPE) \
void Unsafe_WriteFloat##SIZE(Dart_NativeArguments arguments) { \
  int64_t base; \
  Dart_Handle dh_value; \
  int64_t offset; \
  double value; \
  Dart_GetNativeIntegerArgument(arguments, 0, &base); \
  Dart_GetNativeIntegerArgument(arguments, 1, &offset); \
  dh_value = Dart_GetNativeArgument(arguments, 2); \
  Dart_DoubleValue(dh_value, &value); \
  *((TYPE*)(intptr_t)(base + offset)) = (TYPE)value; \
}

UNSAFE_WRITE_FLOAT(32, float)
UNSAFE_WRITE_FLOAT(64, double)

#undef UNSAFE_WRITE_FLOAT

/*---------------------------------------------------------------------------*/

int Unsafe_LibraryFreeInternal(void* handle) {
  int result;

#ifdef _WIN32
  result = FreeLibrary((HMODULE)handle);
  if(result == 0) {
    result = 1;
  } else {
    result = 0;
  }
#else
  result = dlclose(handle);
#endif
  return result;
}

void* Unsafe_LibraryLoadInternal(const char* path) {
#ifdef _WIN32
  HMODULE handle;
#else
  void* handle;
#endif
#ifdef _WIN32
  handle = LoadLibrary(path);
#else
  handle = dlopen(path, RTLD_LAZY);
#endif
  return handle;
}

void Unsafe_LibraryFree(Dart_NativeArguments arguments) {
  Dart_Handle dh_result;
  int64_t handle;

  Dart_GetNativeIntegerArgument(arguments, 0, &handle);
  dh_result = Dart_NewInteger(Unsafe_LibraryFreeInternal((void*)handle));
  Dart_SetReturnValue(arguments, dh_result);
}

void Unsafe_LibraryLoad(Dart_NativeArguments arguments) {
  Dart_Handle dh_path;
  Dart_Handle dh_result;
  void* handle;
  const char* path;

  dh_path = Dart_GetNativeArgument(arguments, 0);
  Dart_StringToCString(dh_path, &path);
  handle = Unsafe_LibraryLoadInternal(path);
  dh_result = HandleError(Dart_NewInteger((uint64_t)(intptr_t)handle));
  Dart_SetReturnValue(arguments, dh_result);
}

void Unsafe_LibrarySymbol(Dart_NativeArguments arguments) {
  void* address;
  Dart_Handle dh_symbol;
  Dart_Handle dh_result;
  int64_t handle;
  const char* symbol;

  Dart_GetNativeIntegerArgument(arguments, 0, &handle);
  dh_symbol = Dart_GetNativeArgument(arguments, 1);
  Dart_StringToCString(dh_symbol, &symbol);
#ifdef _WIN32
  address = GetProcAddress((HMODULE)(intptr_t)handle, symbol);
#else
  address = dlsym((void*)(intptr_t)handle, symbol);
#endif
  dh_result = Dart_NewInteger((int64_t)address);
  Dart_SetReturnValue(arguments, dh_result);
}

/*---------------------------------------------------------------------------*/

struct FunctionLookup {
  const char* name;
  Dart_NativeFunction function;
};

struct FunctionLookup function_list[] = {
  {"Unsafe_GetPageSize", Unsafe_GetPageSize},
  {"Unsafe_GetSizeOfPointer", Unsafe_GetSizeOfPointer},
  {"Unsafe_IsLittleEndian", Unsafe_IsLittleEndian},

  {"Unsafe_MemoryAllocate", Unsafe_MemoryAllocate},
  {"Unsafe_MemoryFree", Unsafe_MemoryFree},
  {"Unsafe_MemorySet", Unsafe_MemorySet},

  {"Unsafe_PeerRegister", Unsafe_PeerRegister},

  {"Unsafe_LibraryLoad", Unsafe_LibraryLoad},
  {"Unsafe_LibraryFree", Unsafe_LibraryFree},
  {"Unsafe_LibrarySymbol", Unsafe_LibrarySymbol},

  {"Unsafe_MemoryCopy", Unsafe_MemoryCopy},
  {"Unsafe_MemoryMove", Unsafe_MemoryMove},

  {"Unsafe_ReadInt8", Unsafe_ReadInt8},
  {"Unsafe_ReadInt16", Unsafe_ReadInt16},
  {"Unsafe_ReadInt32", Unsafe_ReadInt32},
  {"Unsafe_ReadInt64", Unsafe_ReadInt64},

  {"Unsafe_ReadUInt8", Unsafe_ReadUInt8},
  {"Unsafe_ReadUInt16", Unsafe_ReadUInt16},
  {"Unsafe_ReadUInt32", Unsafe_ReadUInt32},
  {"Unsafe_ReadUInt64", Unsafe_ReadUInt64},

  {"Unsafe_WriteInt8", Unsafe_WriteInt8},
  {"Unsafe_WriteInt16", Unsafe_WriteInt16},
  {"Unsafe_WriteInt32", Unsafe_WriteInt32},
  {"Unsafe_WriteInt64", Unsafe_WriteInt64},

  {"Unsafe_WriteUInt8", Unsafe_WriteUInt8},
  {"Unsafe_WriteUInt16", Unsafe_WriteUInt16},
  {"Unsafe_WriteUInt32", Unsafe_WriteUInt32},
  {"Unsafe_WriteUInt64", Unsafe_WriteUInt64},

  {"Unsafe_ReadFloat32", Unsafe_ReadFloat32},
  {"Unsafe_ReadFloat64", Unsafe_ReadFloat64},
  {"Unsafe_WriteFloat32", Unsafe_WriteFloat32},
  {"Unsafe_WriteFloat64", Unsafe_WriteFloat64},

  {NULL, NULL}};

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope) {
  const char* cname;
  Dart_NativeFunction dh_result;
  int i;

  if (!Dart_IsString(name)) {
    return NULL;
  }  

  dh_result = NULL;
  HandleError(Dart_StringToCString(name, &cname));
  for(i = 0; function_list[i].name != NULL; ++i) {
    if(strcmp(function_list[i].name, cname) == 0) {
      dh_result = function_list[i].function;
      break;
    }
  }

  return dh_result;
}

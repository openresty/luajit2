local ffi = require "ffi"

ffi.cdef[[
typedef struct { int a; char b; } __attribute__((packed)) myty1;
typedef struct { int a; char b; } __attribute__((aligned(16))) myty2;
typedef int __attribute__ ((vector_size (32))) myty3;
typedef int __attribute__ ((mode(DI))) myty4;
]]

assert(ffi.sizeof("myty1") == 5 and
       ffi.alignof("myty2") == 16 and
       ffi.sizeof("myty3") == 32 and
       ffi.sizeof("myty4") == 8)

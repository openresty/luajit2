# vim:ft=

use lib '.';
use t::TestLJ;

plan tests => 3 * blocks();

run_tests();

__DATA__

=== TEST 1: unpack(t) - recorded, not stitched
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local a, b, c
for i = 1, 10 do
    a, b, c = unpack(t)
end
print(a, b, c)

--- jv
--- out
10	20	30
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 2: unpack(t, 2) - constant start index
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local n
for i = 1, 10 do
    n = select('#', unpack(t, 2))
end
print(n)

--- jv
--- out
2
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 3: unpack(t, 2, 3) - constant start index and constant end index
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30, 40}
local a, b
for i = 1, 10 do
    a, b = unpack(t, 2, 3)
end
print(a, b)

--- jv
--- out
20	30
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 4: unpack(t, 3, 3) - same constant start index and constant end index
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30, 40}
local a
for i = 1, 10 do
    a = unpack(t, 3, 3)
end
print(a)

--- jv
--- out
30
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 5: unpack(t, a) - non-constant start index
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30, 40, 50}
local a = 42
for i = 1, 100 do
    unpack(t, a)
end
print(a)

--- jv
--- out
42
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 6: unpack(t, 1, j) - non-constant end index
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local j = 3
local a, b, c
for i = 1, 10 do
    a, b, c = unpack(t, 1, j)
end
print(a, b, c)

--- jv
--- out
10	20	30
--- err
[TRACE   1 test.lua:5 loop]



=== TEST 7: unpack(t, i, i + 1) - non-constant start index and non-constant end index, ascending
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30, 40, 50}
local a, b
for i = 1, 5 do
    a, b = unpack(t, i, i + 1)
end
print(a, b)

--- jv
--- out
50	nil
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 8: unpack(t, 1, 6 - i) - non-constant end index, descending
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30, 40, 50}
local a, b
for i = 1, 5 do
    a, b = unpack(t, 1, 6 - i)
end
print(a, b)

--- jv
--- out
10	nil
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 9: unpack(t, 3, 3) - same non-constant start index and non-constant end index
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30, 40, 50}
local a
for i = 1, 5 do
    a = unpack(t, i, i)
end
print(a)

--- jv
--- out
50
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 10: pcall(empty_fn, unpack(t)) - recorded, not NYI
--- lua
require "jit.opt".start("hotloop=3")
local function empty_fn() end
local function run_unpack()
    pcall(empty_fn, unpack({}))
end
for i = 1, 10 do
    run_unpack()
end
print("done")

--- jv
--- out
done
--- err eval
qr/\[TRACE\s+1 test\.lua:6 loop\]/



=== TEST 11: unpack(t, nil) - explicit nil start index is treated as omitted
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local a, b, c
for i = 1, 10 do
    a, b, c = unpack(t, nil)
end
print(a, b, c)

--- jv
--- out
10	20	30
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 12: unpack(t, nil, 3) - explicit nil start index is treated as omitted, even with a constant end index
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local a, b, c
for i = 1, 10 do
    a, b, c = unpack(t, nil, 3)
end
print(a, b, c)

--- jv
--- out
10	20	30
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 13: unpack(t, 1, nil) - explicit nil end index is treated as omitted
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local a, b, c
for i = 1, 10 do
    a, b, c = unpack(t, 1, nil)
end
print(a, b, c)

--- jv
--- out
10	20	30
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 14: unpack(t, 5, 4) - backward range via explicit constants yields zero results
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local n
for i = 1, 10 do
    n = select('#', unpack(t, 5, 4))
end
print(n)

--- jv
--- out
0
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 15: pcall(unpack, t, -2000000000, 2000000000) - integer-overflow range is rejected, not miscompiled
--- lua
require "jit.opt".start("hotloop=3")
local t = {1, 2, 3}
local ok, err
for i = 1, 10 do
    ok, err = pcall(unpack, t, -2000000000, 2000000000)
end
print(ok, err)

--- jv
--- out
false	too many results to unpack
--- err
[TRACE --- test.lua:4 -- trace too deep at test.lua:5]



=== TEST 16: unpack(t, 1, 300) - range exceeding LJ_MAX_JSLOTS falls back cleanly
--- lua
require "jit.opt".start("hotloop=3")
local t = {}
for i = 1, 300 do t[i] = i end
local n
for i = 1, 10 do
    n = select('#', unpack(t, 1, 300))
end
print(n)

--- jv
--- out
300
--- err
[TRACE   1 test.lua:3 loop]
[TRACE --- test.lua:5 -- trace too deep at test.lua:6]



=== TEST 17: pcall(unpack, 5) - unpack() on a non-table throws
--- lua
require "jit.opt".start("hotloop=3")
local ok, err
for i = 1, 10 do
    ok, err = pcall(unpack, 5)
end
print(ok, err)

--- jv
--- out
false	bad argument #1 to '?' (table expected, got number)
--- err
[TRACE --- test.lua:3 -- error thrown or hook called during recording at test.lua:4]



=== TEST 18: unpack(t, 10, 1) - i far past e (not just i = e+1) must still compile cleanly
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local n
for i = 1, 10 do
    n = select('#', unpack(t, 10, 1))
end
print(n)

--- jv
--- out
0
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 19: unpack(t) - length-inference must re-guard when the table grows after the trace compiles
--- lua
require "jit.opt".start("hotloop=3")
local t = {1, 2, 3}
local out = {}
for i = 1, 20 do
    if i == 10 then
        t[4] = 4
    end
    out[i] = select('#', unpack(t))
end
print(table.concat(out, ","))

--- jv
--- out
3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4
--- err
[TRACE   1 test.lua:4 loop]
[TRACE   2 (1/2) test.lua:8 -> 1]



=== TEST 20: unpack(t, 5, 1) - with i > e (empty range) must report nres = 0 in a fixed-arity context
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local out = {}
for i = 1, 10 do
    local x = unpack(t, 5, 1)
    out[i] = tostring(x)
end
print(table.concat(out, ","))

--- jv
--- out
nil,nil,nil,nil,nil,nil,nil,nil,nil,nil
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 21: unpack(t) - length guard prevents side-exit storm
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local a, b, c
for i = 1, 200 do
    a, b, c = unpack(t)
end
print(a, b, c)

--- jv
--- out
10	20	30
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 22: a, b, c, d = unpack(t, 1, 3) - does not leak t[4]
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30, 40}
local out = {}
for i = 1, 10 do
    local a, b, c, d = unpack(t, 1, 3)
    out[i] = tostring(d)
end
print(table.concat(out, ","))

--- jv
--- out
nil,nil,nil,nil,nil,nil,nil,nil,nil,nil
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 23: unpack(t, -1) - constant negative start index
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local n
for i = 1, 10 do
    n = select('#', unpack(t, -1))
end
print(n)

--- jv
--- out
5
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 24: unpack(t, 1, -1) - constant negative end index
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local n
for i = 1, 10 do
    n = select('#', unpack(t, 1, -1))
end
print(n)

--- jv
--- out
0
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 25: pcall(unpack, t, -2147483647, 2147483647) - n wraps to -1
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local ok, err
for i = 1, 10 do
    ok, err = pcall(unpack, t, -2147483647, 2147483647)
end
print(ok, err)

--- jv
--- out
false	too many results to unpack
--- err
[TRACE --- test.lua:4 -- trace too deep at test.lua:5]



=== TEST 26: pcall(unpack, t, -2147483648, 2147483647) - n wraps to 0
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local ok, err
for i = 1, 10 do
    ok, err = pcall(unpack, t, -2147483648, 2147483647)
end
print(ok, err)

--- jv
--- out
false	too many results to unpack
--- err
[TRACE --- test.lua:4 -- trace too deep at test.lua:5]



=== TEST 27: unpack(t, -2147483648, -2147483646) - extreme negative constants, legitimate small range, must not falsely trigger overflow guard
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local n
for i = 1, 10 do
    n = select('#', unpack(t, -2147483648, -2147483646))
end
print(n)

--- jv
--- out
3
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 28: unpack(t, 1, 237) - n exactly at LJ_MAX_JSLOTS (250) minus baseslot (13)
--- lua
require "jit.opt".start("hotloop=3")
local t = {}
local n
for i = 1, 10 do
    n = select('#', unpack(t, 1, 237))
end
print(n)

--- jv
--- out
237
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 29: unpack(t, 1, 238) - n one past LJ_MAX_JSLOTS (250) minus baseslot (13)
--- lua
require "jit.opt".start("hotloop=3")
local t = {}
local n
for i = 1, 10 do
    n = select('#', unpack(t, 1, 238))
end
print(n)

--- jv
--- out
238
--- err
[TRACE --- test.lua:4 -- trace too deep at test.lua:5]



=== TEST 30: unpack(t, 1, 3) with __index metamethod - must stay raw, not follow __index
--- lua
require "jit.opt".start("hotloop=3")
local t = setmetatable({10, 20}, { __index = function() return 999 end })
local a, b, c
for i = 1, 10 do
    a, b, c = unpack(t, 1, 3)
end
print(a, b, c)

--- jv
--- out
10	20	nil
--- err
[TRACE   1 test.lua:4 loop]



=== TEST 31: pcall(unpack, t, {}) - non-numeric start index must throw a real error, not corrupt state
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local ok, err
for i = 1, 10 do
    ok, err = pcall(unpack, t, {})
end
print(ok, err)

--- jv
--- out
false	bad argument #2 to '?' (number expected, got table)
--- err
[TRACE --- test.lua:4 -- bad argument type at test.lua:5]



=== TEST 32: pcall(unpack, t, 1, {}) - non-numeric end index must throw a real error, not corrupt state
--- lua
require "jit.opt".start("hotloop=3")
local t = {10, 20, 30}
local ok, err
for i = 1, 10 do
    ok, err = pcall(unpack, t, 1, {})
end
print(ok, err)

--- jv
--- out
false	bad argument #3 to '?' (number expected, got table)
--- err
[TRACE --- test.lua:4 -- bad argument type at test.lua:5]

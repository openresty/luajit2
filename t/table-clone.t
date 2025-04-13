# vim:ft=

use lib '.';
use t::TestLJ;

plan tests => 3 * blocks();

run_tests();

__DATA__

=== TEST 1: clone table
--- lua
jit.off()
local clone = require "table.clone"
local t = {
  k = {
    a = 1,
    b = 2,
  },
}

local t1 = clone(t)
assert(type(t1.k) == "table")
print("ok")

--- jv
--- out
ok
--- err



=== TEST 2: empty tables - JIT
--- lua
jit.on()
require "jit.opt".start("hotloop=3")
local clone = require "table.clone"
local t = {
  k = {
    a = 1,
    b = 2,
  },
}

for i = 1, 10 do
    local t1 = clone(t)
    assert(type(t1) == "table")
end
print("ok")

--- jv
--- out
ok
--- err
[TRACE   1 test.lua:11 loop]

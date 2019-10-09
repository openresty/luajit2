# vim:set ts=4 sts=4 sw=4 et ft=:

use lib '.';
use t::TestLJ;

plan tests => 3 * blocks();

run_tests();

__DATA__

=== TEST 1: interpreted (sanity)
flag.
--- lua
jit.off()

jit.crc32()

print("ok")
--- out
ok
--- err



=== TEST 2: JIT (sanity)
--- lua
jit.opt.start("minstitch=100000", "hotloop=2")

for i = 1, 50 do
    jit.crc32()
end

print("ok")
--- out
ok
--- jv
--- err eval
qr/trace too short at jit\.crc32/

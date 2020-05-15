# vim:set ts=4 sts=4 sw=4 et ft=:

use lib '.';
use t::TestLJ;

plan tests => 3 * blocks();

run_tests();

__DATA__

=== TEST 1: interpreted (sanity)
--- lua
jit.off()

if os.getenv("NO_STRHASHCRC32") == "1" then
    assert(jit.strhashcrc32() == false, "strhashcrc32 should be disabled (LJ_OR_DISABLE_STRHASHCRC32)")
elseif jit.crc32() then
    assert(jit.strhashcrc32() == true, "strhashcrc32 should be enabled")
else
    assert(jit.strhashcrc32() == false, "strhashcrc32 should be disabled")
end

print("ok")
--- out
ok
--- err



=== TEST 2: JIT (sanity)
--- lua
jit.opt.start("minstitch=100000", "hotloop=2")

for i = 1, 50 do
    jit.strhashcrc32()
end

print("ok")
--- out
ok
--- jv
--- err eval
qr/trace too short at jit\.strhashcrc32/

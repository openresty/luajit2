# vim: set ss=4 ft= sw=4 et sts=4 ts=4:

use lib '.';
use t::TestLJ;

plan tests => 3 * blocks();

run_tests();

__DATA__

=== TEST 1: interpreted (sanity)
--- lua
jit.off()

print(jit.prngstate())
print(jit.prngstate(32))
print(jit.prngstate(5617))
print(jit.prngstate())
--- out
0
0
32
5617
--- jv
--- err



=== TEST 2: JIT (set)
--- lua
jit.opt.start("minstitch=100000", "hotloop=2")

for i = 1, 50 do
  jit.prngstate(i)
end
print('ok')
--- out
ok
--- jv
--- err eval
qr/trace too short at jit\.prngstate/

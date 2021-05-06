# vim: set ss=4 ft= sw=4 et sts=4 ts=4:

use lib '.';
use t::TestLJ;

plan tests => 3 * blocks();

run_tests();

__DATA__

=== TEST 1: fixed order of table output
--- lua
jit.off()
math.randomseed(os.time())

local val = math.random(1, 100)
if val % 2 == 1 then
    local t1 = {a=1, b= 2, c= 3, d= 4, e= 5}
end

local t2 = {A=1, B= 2, C= 3, D= 4, E= 5}
local ret = ""
local first = true
for k, v in pairs(t2)
do
    if not first then
        ret = ret .. " "
    end
    first = false
    ret = ret .. k .. "=" .. v
end
print(ret)

--- jv
--- out
C=3 B=2 D=4 A=1 E=5
--- err

.PHONY: default test benchmark clean

default: test benchmark

COMMON_OBJ := test_util.o

TEST_PROGRAM := ht_test
BENCHMARK_PROGRAM := ht_benchmark

TEST_PROGRAM_OBJ := $(COMMON_OBJ) test.o
BENCHMARK_PROGRAM_OBJ := $(COMMON_OBJ) benchmark.o

ifeq ($(WITH_VALGRIND), 1)
    VALGRIND := valgrind --leak-check=full
else
    VALGRIND :=
endif

CXXFLAGS := -O3 -MD -g -Wall -msse4.2 -I../..
LDFLAGS := ../../libluajit.a -ldl -lm

%.o: %.cxx
	$(CXX) $(CXXFLAGS) -MD -c $<

test: $(TEST_PROGRAM)
	@echo "some unit test"
	$(VALGRIND) ./$(TEST_PROGRAM)
	./unit_test.sh

	@echo "smoke test"
	../../luajit test_str_comp.lua

benchmark: $(BENCHMARK_PROGRAM)
	# micro benchmark
	./$(BENCHMARK_PROGRAM)

$(TEST_PROGRAM): $(TEST_PROGRAM_OBJ)
	cat $(TEST_PROGRAM_OBJ:.o=.d) > dep1.txt
	$(CXX) $+ $(LDFLAGS) -o $@

$(BENCHMARK_PROGRAM): $(BENCHMARK_PROGRAM_OBJ)
	cat $(BENCHMARK_PROGRAM_OBJ:.o=.d) > dep2.txt
	$(CXX) $+ $(LDFLAGS) -o $@

-include dep1.txt
-include dep2.txt

clean:
	-rm -f *.o *.d dep*.txt $(BENCHMARK_PROGRAM) $(TEST_PROGRAM)

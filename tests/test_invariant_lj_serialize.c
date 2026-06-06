#include <check.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <setjmp.h>

/* Test deserialization bounds checking via LuaJIT subprocess */

START_TEST(test_deserialize_bounds_check)
{
    /* Invariant: Deserialization must not read beyond provided buffer bounds */
    
    /* Payloads: truncated serialized data that would trigger OOB reads */
    struct {
        const unsigned char *data;
        size_t len;
        const char *desc;
    } payloads[] = {
        /* Truncated: header suggests 8-byte read but only 3 bytes provided */
        {(const unsigned char *)"\x0b\x41\x42", 3, "truncated_8byte"},
        /* Truncated: header suggests 16-byte read but only 7 bytes provided */
        {(const unsigned char *)"\x0c\x01\x02\x03\x04\x05\x06", 7, "truncated_16byte"},
        /* Boundary: exactly at minimum valid size */
        {(const unsigned char *)"\x00", 1, "minimal_valid"},
        /* Valid: proper 8-byte number serialization */
        {(const unsigned char *)"\x0b\x00\x00\x00\x00\x00\x00\x00\x01", 9, "valid_8byte"},
    };
    int num_payloads = sizeof(payloads) / sizeof(payloads[0]);

    for (int i = 0; i < num_payloads; i++) {
        /* Write payload to temp file and test via luajit subprocess */
        char tmpfile[64];
        snprintf(tmpfile, sizeof(tmpfile), "/tmp/lj_test_%d.bin", i);
        FILE *f = fopen(tmpfile, "wb");
        ck_assert_ptr_nonnull(f);
        fwrite(payloads[i].data, 1, payloads[i].len, f);
        fclose(f);

        /* Attempt deserialization - should not crash or leak memory */
        char cmd[256];
        snprintf(cmd, sizeof(cmd),
            "timeout 2 luajit -e \"local f=io.open('%s','rb') "
            "local d=f:read('*a') f:close() "
            "pcall(function() return string.buffer.decode(d) end)\" 2>/dev/null",
            tmpfile);
        
        int ret = system(cmd);
        /* Process should complete without SIGSEGV/SIGBUS (signal 11/7) */
        if (WIFSIGNALED(ret)) {
            int sig = WTERMSIG(ret);
            ck_assert_msg(sig != SIGSEGV && sig != SIGBUS,
                "Payload '%s' caused memory access violation (signal %d)",
                payloads[i].desc, sig);
        }
        unlink(tmpfile);
    }
}
END_TEST

Suite *security_suite(void)
{
    Suite *s;
    TCase *tc_core;

    s = suite_create("Security");
    tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_deserialize_bounds_check);
    suite_add_tcase(s, tc_core);

    return s;
}

int main(void)
{
    int number_failed;
    Suite *s;
    SRunner *sr;

    s = security_suite();
    sr = srunner_create(s);

    srunner_run_all(sr, CK_NORMAL);
    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);

    return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
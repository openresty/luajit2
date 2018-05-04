/*
 * This file defines string hash function using CRC32. It takes advantage of
 * Arm64 hardware support (crc32 instruction) to speedup the CRC32
 * computation. The hash functions try to compute CRC32 of length and up
 * to 128 bytes of given string.
 */

#ifndef _LJ_STR_HASH_ARM64_H_
#define _LJ_STR_HASH_ARM64_H_

#if defined(__aarch64__) && defined(__GNUC__)

#include <stdint.h>
#include <sys/types.h>
#include <unistd.h>
#include <time.h>
#include <sys/auxv.h>
#include <stdio.h>
#include <arm_acle.h>

#include "../../lj_def.h"

#ifndef HWCAP_CRC32
#define HWCAP_CRC32             (1 << 7)
#endif /* HWCAP for crc32 */

#ifndef LJ_AINLINE
#define LJ_AINLINE   inline __attribute__((always_inline))
#endif

#ifdef __MINGW32__
#define random()  ((long) rand())
#define srandom(seed)  srand(seed)
#endif

extern uint32_t lj_str_original_hash(const char *str, size_t lenx);
static LJ_AINLINE uint32_t lj_str_hash(const char* str, size_t len);
/* lj_str hash function determined at runtime */
typedef uint32_t (*lj_str_hash_func)(const char *str, size_t lenx);
lj_str_hash_func LJ_STR_HASH;

static const uint64_t* cast_uint64p(const char* str)
{
  return (const uint64_t*)(void*)str;
}

static const uint32_t* cast_uint32p(const char* str)
{
  return (const uint32_t*)(void*)str;
}

static LJ_AINLINE uint32_t lj_str_hash_1_4(const char* str, uint32_t len)
{
  uint32_t v = str[0], h = 0;
  v = (v << 8) | str[len >> 1];
  v = (v << 8) | str[len - 1];
  v = (v << 8) | len;
  return __crc32cw(h, v);
}

static LJ_AINLINE uint32_t lj_str_hash_4_16(const char* str, size_t len)
{
  uint64_t v1, v2, h = 0;

  if (len >= 8) {
	v1 = *cast_uint64p(str);
	v2 = *cast_uint64p(str + len - 8);
  } else {
	v1 = *cast_uint32p(str);
	v2 = *cast_uint32p(str + len - 4);
  }

  h = __crc32cw(h, len);
  h = __crc32cd(h, v1);
  h = __crc32cd(h, v2);

  return h;
}

static LJ_AINLINE uint32_t lj_str_hash_16_128(const char* str, size_t len)
{
  uint64_t h1 = 0, h2 = 0;
  uint32_t i;

  h1 = __crc32cw(h1, len);

  for (i = 0; i < len - 16; i += 16) {
	h1 += __crc32cd(h1, *cast_uint64p(str + i));
	h2 += __crc32cd(h2, *cast_uint64p(str + i + 8));
  }

  h1 = __crc32cd(h1, *cast_uint64p(str + len - 16));
  h2 = __crc32cd(h2, *cast_uint64p(str + len - 8));

  return __crc32cw(h1, h2);
}

/* **************************************************************************
 *
 *  Following is code about hashing string with length >= 128
 *
 * **************************************************************************
 */

static uint32_t random_pos[32][2];
static const int8_t log2_tab[128] = { -1,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3,4,4,
  4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
  5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6 };

/* return floor(log2(n)) */
static LJ_AINLINE uint32_t log2_floor(uint32_t n)
{
  if (n <= 127) {
    return log2_tab[n];
  }

  if ((n >> 8) <= 127) {
    return log2_tab[n >> 8] + 8;
  }

  if ((n >> 16) <= 127) {
    return log2_tab[n >> 16] + 16;
  }

  if ((n >> 24) <= 127) {
    return log2_tab[n >> 24] + 24;
  }

  return 31;
}

#define POW2_MASK(n) ((1L << (n)) - 1)
/* This function is to populate `random_pos` such that random_pos[i][*]
 * contains random value in the range of [2**i, 2**(i+1)).
 */
static void arm64_init_random(void)
{
  int i, seed, rml;

  /* Calculate the ceil(log2(RAND_MAX)) */
  rml = log2_floor(RAND_MAX);
  if (RAND_MAX & (RAND_MAX - 1)) {
    rml += 1;
  }

  /* Init seed */
  seed = 0;
  seed = __crc32cw(seed, getpid());
  seed = __crc32cw(seed, time(NULL));
  srandom(seed);

  /* Now start to populate the random_pos[][]. */
  for (i = 0; i < 3; i++) {
    /* No need to provide random value for chunk smaller than 8 bytes */
    random_pos[i][0] = random_pos[i][1] = 0;
  }

  for (; i < rml; i++) {
    random_pos[i][0] = random() & POW2_MASK(i+1);
    random_pos[i][1] = random() & POW2_MASK(i+1);
  }

  for (; i < 31; i++) {
    int j;
    for (j = 0; j < 2; j++) {
      uint32_t v, scale;
      scale = random_pos[i - rml][0];
      if (scale == 0) {
         scale = 1;
      }
      v = (random() * scale) & POW2_MASK(i+1);
      random_pos[i][j] = v;
    }
  }
}
#undef POW2_MASK

void __attribute__((constructor)) arm64_init_constructor()
{
    // Check if crc32 supported.
    unsigned long hwcap;
    hwcap = getauxval(AT_HWCAP);
    if (hwcap & HWCAP_CRC32) {
	LJ_STR_HASH = lj_str_hash;
    }
    else {
	LJ_STR_HASH = lj_str_original_hash;
    }

    // init random
    arm64_init_random();
}

/* Return a pre-computed random number in the range of [1**chunk_sz_order,
 * 1**(chunk_sz_order+1)). It is "unsafe" in the sense that the return value
 * may be greater than chunk-size; it is up to the caller to make sure
 * "chunk-base + return-value-of-this-func" has valid virtual address.
 */
static LJ_AINLINE uint32_t get_random_pos_unsafe(uint32_t chunk_sz_order,
       uint32_t idx)
{
  uint32_t pos = random_pos[chunk_sz_order][idx & 1];
  return pos;
}

static LJ_NOINLINE uint32_t lj_str_hash_128_above(const char* str,
  uint32_t len)
{
  uint32_t chunk_num, chunk_sz, chunk_sz_log2, i, pos1, pos2;
  uint32_t h1, h2, v;
  const char* chunk_ptr;

  chunk_num = 16;
  chunk_sz = len / chunk_num;
  chunk_sz_log2 = log2_floor(chunk_sz);

  pos1 = get_random_pos_unsafe(chunk_sz_log2, 0);
  pos2 = get_random_pos_unsafe(chunk_sz_log2, 1);

  h1 = 0;
  h1 = __crc32cw(h1, len);
  h2 = 0;

  /* loop over 14 chunks, 2 chunks at a time */
  for (i = 0, chunk_ptr = str; i < (chunk_num / 2 - 1);
       chunk_ptr += chunk_sz, i++) {

    v = *cast_uint64p(chunk_ptr + pos1);
    h1 = __crc32cd(h1, v);

    v = *cast_uint64p(chunk_ptr + chunk_sz + pos2);
    h2 = __crc32cd(h2, v);
  }

  /* the last two chunks */
  v = *cast_uint64p(chunk_ptr + pos1);
  h1 = __crc32cd(h1, v);

  v = *cast_uint64p(chunk_ptr + chunk_sz - 8 - pos2);
  h2 = __crc32cd(h2, v);

  /* process the trailing part */
  h1 = __crc32cd(h1, *cast_uint64p(str));
  h2 = __crc32cd(h2, *cast_uint64p(str + len - 8));

  h1 = __crc32cw(h1, h2);
  return h1;
}


/* NOTE: the "len" should not be zero */
static LJ_AINLINE uint32_t lj_str_hash(const char* str, size_t len)
{
  if (len < 128) {
    if (len >= 16) { 
      return lj_str_hash_16_128(str, len);
    }

    if ((len >= 4) && (len < 16)) { 
      return lj_str_hash_4_16(str, len);
    }

    return lj_str_hash_1_4(str, len);
  }
  return lj_str_hash_128_above(str, len);
}

#endif // defined(__aarch64__)
#endif // _LJ_STR_HASH_ARM64_H_

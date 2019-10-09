#ifndef _LJ_STR_HASH_H
#define _LJ_STR_HASH_H

#include "lj_obj.h"

LJ_FUNC MSize lj_str_hash_orig(const char *str, size_t lenx);

#if LJ_OR_STRHASHCRC32
LJ_FUNC unsigned char lj_check_crc32_support();
LJ_FUNC void lj_init_strhashfn(global_State *g);
#endif

#endif

// https://stackoverflow.com/a/50845780/662618

#ifndef _FIXMINMAX_H_
#define _FIXMINMAX_H_

#ifdef max
    #undef max
#endif

#ifdef min
    #undef min
#endif

#ifdef MAX
    #undef MAX
#endif
#define MAX max

#ifdef MIN
   #undef MIN
#endif
#define MIN min

#include <algorithm>

#endif
#include <stdint.h>

// See http://akaros.cs.berkeley.edu/lxr/akaros/kern/arch/x86/rdtsc_test.c
// See https://stackoverflow.com/questions/38994549/is-intels-timestamp-reading-asm-code-example-using-two-more-registers-than-are

#ifdef __i386__
#  define RDTSC_DIRTY "%eax", "%edx"
#elif __x86_64__
#  define RDTSC_DIRTY "%rax", "%rdx"
#else
# error unknown platform
#endif

#define RDTSC(cycles)                                      \
    do {                                                   \
        unsigned cyc_high, cyc_low;                        \
        asm volatile("LFENCE\n\t"                          \
                     "RDTSC\n\t"                           \
                     : "=d" (cyc_high), "=a" (cyc_low)     \
                     :: RDTSC_DIRTY);                      \
        (cycles) = ((uint64_t)cyc_high << 32) | cyc_low;   \
    } while (0)


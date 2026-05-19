#include "policy.h"
#include <stdio.h>

int main(void) {
  for (unsigned owner = 0; owner < 2; ++owner)
    for (unsigned table = 0; table < 2; ++table)
      for (unsigned cached = 0; cached < 2; ++cached)
        for (unsigned phase = 0; phase < 5; ++phase)
          for (unsigned operation = 0; operation < 6; ++operation) {
            struct policy before = { owner, table, cached, phase };
            struct policy after = policy_step(before, operation);
            printf("%u %u %u %u %u %u %u %u %u %u\n", owner, table, cached,
                   phase, operation, after.owner, after.table, after.cached,
                   after.phase, policy_write(after));
          }
  return 0;
}

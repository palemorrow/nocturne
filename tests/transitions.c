#include "policy.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
  struct policy state = { OWNER_GUEST, true, true, STABLE };
  assert(!policy_try_step(&state, SYNCHRONIZE) && policy_write(state));
  assert(!policy_try_step(&state, INVALIDATE) && state.phase == STABLE);
  assert(policy_try_step(&state, REVOKE) && policy_write(state));
  assert(!policy_try_step(&state, GRANT) && !state.table);
  assert(!policy_try_step(&state, SYNCHRONIZE) && state.cached);
  assert(policy_try_step(&state, ORDER));
  assert(policy_try_step(&state, INVALIDATE) && policy_write(state));
  assert(policy_try_step(&state, SYNCHRONIZE) && !policy_write(state));
  assert(policy_try_step(&state, GRANT) && policy_write(state));
  state.owner = OWNER_MONITOR;
  assert(!policy_try_step(&state, GRANT) && !policy_write(state));
  puts("checked revocation order and rejected private grant");
  return 0;
}

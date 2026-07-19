#include "policy.h"

bool policy_try_step(struct policy *state, enum operation operation) {
  bool valid = false;
  switch (operation) {
    case GRANT:
      valid = state->owner == OWNER_GUEST &&
              (state->phase == STABLE || state->phase == SYNCHRONIZED);
      break;
    case REVOKE:
      valid = state->phase == STABLE || state->phase == SYNCHRONIZED;
      break;
    case ORDER: valid = state->phase == STAGED; break;
    case INVALIDATE: valid = state->phase == ORDERED; break;
    case SYNCHRONIZE: valid = state->phase == INVALIDATED; break;
    case RESET: valid = state->phase == SYNCHRONIZED; break;
  }
  if (valid) *state = policy_step(*state, operation);
  return valid;
}

bool policy_write(struct policy state) {
  return state.owner == OWNER_GUEST && (state.table || state.cached);
}

struct policy policy_step(struct policy state, enum operation operation) {
  switch (operation) {
    case GRANT:
      if (state.owner == OWNER_GUEST &&
          (state.phase == STABLE || state.phase == SYNCHRONIZED)) {
        state.table = true;
        state.cached = true;
        state.phase = STABLE;
      }
      break;
    case REVOKE:
      state.table = false;
      state.phase = STAGED;
      break;
    case ORDER:
      if (state.phase == STAGED) state.phase = ORDERED;
      break;
    case INVALIDATE:
      if (state.phase == ORDERED) state.phase = INVALIDATED;
      break;
    case SYNCHRONIZE:
      if (state.phase == INVALIDATED) {
        state.cached = false;
        state.phase = SYNCHRONIZED;
      }
      break;
    case RESET:
      if (state.phase == SYNCHRONIZED) state.phase = STABLE;
      break;
  }
  return state;
}

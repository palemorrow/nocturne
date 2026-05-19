#include "policy.h"

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

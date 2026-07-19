#ifndef NOCTURNE_POLICY_H
#define NOCTURNE_POLICY_H

#include <stdbool.h>

enum owner { OWNER_MONITOR, OWNER_GUEST };
enum phase { STABLE, STAGED, ORDERED, INVALIDATED, SYNCHRONIZED };
enum operation { GRANT, REVOKE, ORDER, INVALIDATE, SYNCHRONIZE, RESET };

struct policy {
  enum owner owner;
  bool table;
  bool cached;
  enum phase phase;
};

struct policy policy_step(struct policy state, enum operation operation);
bool policy_try_step(struct policy *state, enum operation operation);
bool policy_write(struct policy state);

#endif

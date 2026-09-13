#include "nocturne.h"
#include "policy.h"
#include "descriptor.h"

static uint64_t s2_l1[512] __attribute__((aligned(PAGE_SIZE)));
static uint64_t s2_l2[512] __attribute__((aligned(PAGE_SIZE)));
static uint64_t s2_l3[512] __attribute__((aligned(PAGE_SIZE)));
static struct policy target_policy;

static uint64_t page_descriptor(uint64_t address, bool writable, bool execute) {
  uint64_t descriptor;
  require(stage2_descriptor(address, true, writable, execute, &descriptor), "stage-2 descriptor");
  return descriptor;
}

void stage2_init(bool writable) {
  s2_l1[1] = (uintptr_t)s2_l2 | 3;
  s2_l2[1] = (uintptr_t)s2_l3 | 3;
  for (size_t i = 0; i < 512; ++i) {
    uint64_t address = GUEST_BASE + i * PAGE_SIZE;
    bool text = address < (uintptr_t)guest_text_end;
    s2_l3[i] = page_descriptor(address, !text, text);
  }
  target_policy = (struct policy){ OWNER_GUEST, writable, writable, STABLE };
  s2_l3[(TARGET - GUEST_BASE) / PAGE_SIZE] = page_descriptor(TARGET, writable, false);
  WRITE_REG(vtcr_el2, 32UL | (1UL << 6) | (1UL << 8) | (1UL << 10) | (3UL << 12));
  WRITE_REG(vttbr_el2, (uintptr_t)s2_l1);
  BARRIER("dsb sy\n\tisb");
}

void stage2_access(bool read, bool writable, bool execute) {
  size_t index = (TARGET - GUEST_BASE) / PAGE_SIZE;
  s2_l3[index] = 0;
  require(policy_try_step(&target_policy, REVOKE), "revoke phase");
  BARRIER("dsb ishst");
  require(policy_try_step(&target_policy, ORDER), "order phase");
  uint64_t operand = TARGET >> 12;
  __asm__ volatile("tlbi ipas2e1is, %0" :: "r"(operand) : "memory");
  require(policy_try_step(&target_policy, INVALIDATE), "invalidate phase");
  BARRIER("dsb ish\n\ttlbi vmalle1is\n\tdsb ish\n\tisb");
  require(policy_try_step(&target_policy, SYNCHRONIZE), "synchronize phase");
  require(!policy_write(target_policy), "revocation model");
  require(stage2_descriptor(TARGET, read, writable, execute, &s2_l3[index]), "stage-2 permission update");
  BARRIER("dsb ishst\n\tisb");
  if (writable) require(policy_try_step(&target_policy, GRANT), "grant phase");
  require(policy_write(target_policy) == writable, "permission model");
}

void stage2_permission(bool writable) {
  stage2_access(true, writable, false);
}

#include "nocturne.h"

uint64_t guest_l1[512] __attribute__((aligned(PAGE_SIZE)));
uint64_t guest_l2[512] __attribute__((aligned(PAGE_SIZE)));
uint64_t guest_l3[512] __attribute__((aligned(PAGE_SIZE)));
static unsigned svc_count;

static uint64_t call(uint64_t service, uint64_t value) {
  register uint64_t x0 __asm__("x0") = service;
  register uint64_t x1 __asm__("x1") = value;
  register uint64_t x2 __asm__("x2") = 0;
  register uint64_t x3 __asm__("x3") = 0;
  register uint64_t x4 __asm__("x4") = 0;
  register uint64_t x5 __asm__("x5") = 0;
  register uint64_t x6 __asm__("x6") = 0;
  register uint64_t x7 __asm__("x7") = 0;
  __asm__ volatile("hvc #0x4e" : "+r"(x0), "+r"(x1), "+r"(x2), "+r"(x3), "+r"(x4), "+r"(x5), "+r"(x6), "+r"(x7) :: "memory");
  return x0;
}

static void setup_translation(bool block) {
  guest_l1[1] = (uintptr_t)guest_l2 | 3;
  guest_l2[1] = (uintptr_t)guest_l3 | 3;
  if (block) guest_l2[1] = GUEST_BASE | 1 | (3UL << 8) | (1UL << 10);
  for (size_t i = 0; i < 512; ++i) {
    uint64_t address = GUEST_BASE + i * PAGE_SIZE;
    uint64_t access = address < (uintptr_t)guest_text_end ? (3UL << 6) : 0;
    guest_l3[i] = address | 3 | access | (3UL << 8) | (1UL << 10);
  }
  WRITE_REG(mair_el1, 0x44);
  WRITE_REG(ttbr0_el1, (uintptr_t)guest_l1);
  WRITE_REG(tcr_el1, 32UL | (1UL << 23));
  BARRIER("dsb sy\n\ttlbi vmalle1\n\tdsb sy\n\tisb");
  WRITE_REG(sctlr_el1, 0x30d00801UL);
  BARRIER("isb");
}

void guest_sync(struct frame *frame) {
  uint64_t esr = READ_REG(esr_el1);
  if ((esr >> 26) == 0x25 && (esr & 127) == (15 | 64) &&
      frame->elr == (uintptr_t)probe_store && (frame->spsr & 15) == 5) {
    frame->elr = (uintptr_t)probe_store_resume;
    call(SVC_LOCAL_FAULT, esr);
    return;
  }
  bool valid = (esr >> 26) == 0x15 && (frame->spsr & 15) == 0;
  if ((esr & 0xffff) == 77 && svc_count == 0) {
    valid = valid && frame->elr == (uintptr_t)el0_after_svc;
    ++svc_count;
  } else if ((esr & 0xffff) == 78 && svc_count == 1) {
    ++svc_count;
    frame->elr = (uintptr_t)enter_el0_return;
    frame->spsr = 0x3c5;
  } else valid = false;
  call(SVC_CHECK, valid);
}

void guest_main(uint64_t experiment) {
  WRITE_REG(vbar_el1, (uintptr_t)guest_vectors);
  setup_translation(experiment == CASE_L2_BLOCK);
  switch (experiment) {
    case CASE_TRACE_FULL:
      for (unsigned i = 0; i < 65; ++i) call(SVC_CHECK, 1);
      break;
    case CASE_CANARY:
      call(SVC_CORRUPT_CANARY, 0);
      break;
    case CASE_STACK_GUARD:
      probe_store((uintptr_t)guest_stack_guard, CHANGED);
      break;
    case CASE_VMID_REUSE:
      call(SVC_CHECK, probe_load(TARGET) == INITIAL);
      call(SVC_SWITCH_ROOT, 1);
      call(SVC_CHECK, probe_load(TARGET) == 0x9977);
      call(SVC_SWITCH_ROOT, 0);
      call(SVC_CHECK, probe_load(TARGET) == INITIAL);
      break;
    case CASE_TLBI_NEIGHBOR:
      probe_store(TARGET + PAGE_SIZE, 0xabc);
      probe_store(TARGET, 0x55);
      call(SVC_REVOKE, 0);
      probe_store(TARGET + PAGE_SIZE, 0xdef);
      call(SVC_CHECK, probe_load(TARGET + PAGE_SIZE) == 0xdef);
      probe_store(TARGET, CHANGED);
      break;
    case CASE_EXEC_TRANSITION:
      (void)probe_execute(TARGET);
      call(SVC_PREPARE_EXEC, 0);
      call(SVC_CHECK, probe_execute(TARGET) == 42);
      break;
    case CASE_READ_REVOKE:
      call(SVC_CHECK, probe_load(TARGET) == INITIAL);
      call(SVC_REVOKE_READ, 0);
      (void)probe_load(TARGET);
      break;
    case CASE_S1_DENY:
      guest_l3[(TARGET - GUEST_BASE) / PAGE_SIZE] = TARGET | 3 | (2UL << 6) | (3UL << 8) | (1UL << 10);
      BARRIER("dsb ishst\n\ttlbi vmalle1\n\tdsb ish\n\tisb");
      probe_store(TARGET, CHANGED);
      break;
    case CASE_HVC:
      call(SVC_CHECK, probe_hvc());
      break;
    case CASE_SVC:
      enter_el0();
      call(SVC_EL0, svc_count);
      break;
    case CASE_L2_BLOCK:
    case CASE_WRITE:
      probe_store(TARGET, CHANGED);
      break;
    case CASE_EXECUTE:
      probe_execute(TARGET);
      break;
    case CASE_REMAP:
      probe_store(TARGET, CHANGED);
      guest_l3[(ALIAS - GUEST_BASE) / PAGE_SIZE] = 0;
      BARRIER("dsb ishst\n\ttlbi vmalle1\n\tdsb ish\n\tisb");
      guest_l3[(ALIAS - GUEST_BASE) / PAGE_SIZE] = TARGET | 3 | (3UL << 8) | (1UL << 10);
      BARRIER("dsb ishst\n\ttlbi vmalle1\n\tdsb ish\n\tisb");
      probe_store(ALIAS, CHANGED);
      for (unsigned i = 0; i < 3; ++i) {
        uint64_t alias = ALIAS + i * PAGE_SIZE;
        size_t index = (alias - GUEST_BASE) / PAGE_SIZE;
        guest_l3[index] = 0;
        BARRIER("dsb ishst\n\ttlbi vmalle1\n\tdsb ish\n\tisb");
        guest_l3[index] = TARGET | 3 | (3UL << 8) | (1UL << 10);
        BARRIER("dsb ishst\n\tisb");
        probe_store(alias + (i + 1) * 8, CHANGED);
      }
      break;
    case CASE_S1_OFF:
      WRITE_REG(sctlr_el1, READ_REG(sctlr_el1) & ~1UL);
      BARRIER("isb");
      probe_store(TARGET, CHANGED);
      break;
    case CASE_PRIVATE:
      WRITE_REG(sctlr_el1, READ_REG(sctlr_el1) & ~1UL);
      BARRIER("isb");
      (void)probe_load(PRIVATE);
      break;
    case CASE_REVOKE:
      probe_store(TARGET, 0x55);
      call(SVC_REVOKE, 0);
      probe_store(TARGET, CHANGED);
      break;
    case CASE_SYSREG: {
      uint64_t direct = probe_sysreg();
      call(SVC_TRAP_ID, direct);
      call(SVC_CHECK, probe_sysreg() == direct);
      break;
    }
    case CASE_TIMER: {
      call(SVC_TIMER, 0);
      uint64_t start = READ_REG(cntpct_el0);
      uint64_t duration = READ_REG(cntfrq_el0) / 20;
      while (READ_REG(cntpct_el0) - start < duration) BARRIER("yield");
      break;
    }
    default:
      call(SVC_CHECK, false);
  }
  call(SVC_DONE, 0);
  for (;;) BARRIER("wfe");
}

#ifndef NOCTURNE_REGISTERS_H
#define NOCTURNE_REGISTERS_H

#include <stdint.h>

static inline uint64_t read_cntfrq_el0(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, cntfrq_el0" : "=r"(value));
  return value;
}

static inline uint64_t read_cntpct_el0(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, cntpct_el0" : "=r"(value));
  return value;
}

static inline uint64_t read_esr_el1(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, esr_el1" : "=r"(value));
  return value;
}

static inline uint64_t read_esr_el2(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, esr_el2" : "=r"(value));
  return value;
}

static inline uint64_t read_far_el2(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, far_el2" : "=r"(value));
  return value;
}

static inline uint64_t read_hcr_el2(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, hcr_el2" : "=r"(value));
  return value;
}

static inline uint64_t read_hpfar_el2(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, hpfar_el2" : "=r"(value));
  return value;
}

static inline uint64_t read_sctlr_el1(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, sctlr_el1" : "=r"(value));
  return value;
}

static inline uint64_t read_tcr_el1(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, tcr_el1" : "=r"(value));
  return value;
}

static inline uint64_t read_ttbr0_el1(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, ttbr0_el1" : "=r"(value));
  return value;
}

#endif
static inline uint64_t read_vtcr_el2(void) {
  uint64_t value;
  __asm__ volatile("mrs %0, vtcr_el2" : "=r"(value));
  return value;
}

#ifndef NOCTURNE_H
#define NOCTURNE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "registers.h"

#define PAGE_SIZE 4096UL
#define GUEST_BASE 0x40200000UL
#define GUEST_END 0x40400000UL
#define TARGET 0x40300000UL
#define ALIAS 0x40302000UL
#define PRIVATE 0x40100000UL
#define CONFIG 0x401ff000UL
#define INITIAL 0x1122334455667788UL
#define CHANGED 0xaabbccddeeff0099UL
#define READ_REG(name) read_##name()
#define WRITE_REG(name, value) __asm__ volatile("msr " #name ", %0" :: "r"((uint64_t)(value)) : "memory")
#define BARRIER(text) __asm__ volatile(text ::: "memory")

enum experiment {
  CASE_HVC, CASE_SVC, CASE_WRITE, CASE_EXECUTE, CASE_REMAP,
  CASE_S1_OFF, CASE_PRIVATE, CASE_REVOKE, CASE_SYSREG, CASE_TIMER,
  CASE_TRACE_FULL, CASE_L2_BLOCK, CASE_S1_DENY, CASE_READ_REVOKE,
  CASE_COUNT
};

enum service {
  SVC_PING, SVC_DONE, SVC_CHECK, SVC_REVOKE, SVC_TRAP_ID, SVC_TIMER,
  SVC_EL0, SVC_LOCAL_FAULT, SVC_REVOKE_READ
};

struct frame {
  uint64_t x[31];
  uint64_t elr;
  uint64_t spsr;
  uint64_t reserved;
};

_Static_assert(offsetof(struct frame, elr) == 248, "frame elr offset");
_Static_assert(offsetof(struct frame, spsr) == 256, "frame spsr offset");
_Static_assert(sizeof(struct frame) == 272, "frame size");
_Static_assert(sizeof(struct frame) % 16 == 0, "frame alignment");

extern void guest_entry(void);
extern void guest_vectors(void);
extern void el2_vectors(void);
extern void enter_guest(uint64_t entry, uint64_t stack, uint64_t experiment);
extern void probe_store(uint64_t address, uint64_t value);
extern void probe_store_resume(void);
extern uint64_t probe_load(uint64_t address);
extern void probe_load_resume(void);
extern void probe_execute(uint64_t address);
extern void probe_execute_resume(void);
extern uint64_t probe_sysreg(void);
extern void probe_sysreg_resume(void);
extern uint64_t probe_hvc(void);
extern void probe_hvc_return(void);
extern void enter_el0(void);
extern void enter_el0_return(void);
extern void el0_payload(void);
extern void el0_after_svc(void);
extern uint64_t guest_l1[512];
extern uint64_t guest_l2[512];
extern uint64_t guest_l3[512];
extern char guest_stack_top[];
extern char guest_user_stack_top[];
extern char guest_text_end[];

_Noreturn void monitor_alignment_failure(void);
bool hypercall_valid(const struct frame *frame);
void monitor_main(void);
void monitor_sync(struct frame *frame);
void monitor_irq(struct frame *frame);
void monitor_bad(struct frame *frame);
void guest_main(uint64_t experiment);
void guest_sync(struct frame *frame);
void stage2_init(bool writable);
void stage2_permission(bool writable);
void stage2_access(bool read, bool writable, bool execute);
void timer_arm(void);
bool timer_ack(void);
void serial_puts(const char *text);
void serial_hex(uint64_t value);
void require(bool condition, const char *message);
_Noreturn void finish(bool success);

#endif

#include "nocturne.h"

#define STACK_CANARY 0x4e4f435455524e45UL

void monitor_stack_init(void) {
  monitor_stack_guard[0] = STACK_CANARY;
  monitor_stack_guard[1] = ~STACK_CANARY;
  monitor_stack_top[0] = STACK_CANARY;
  monitor_stack_top[1] = ~STACK_CANARY;
}

void monitor_stack_check(void) {
  uintptr_t stack;
  __asm__ volatile("mov %0, sp" : "=r"(stack));
  require(monitor_stack_guard[0] == STACK_CANARY && monitor_stack_guard[1] == ~STACK_CANARY &&
          monitor_stack_top[0] == STACK_CANARY && monitor_stack_top[1] == ~STACK_CANARY,
          "monitor stack canary");
  require(stack >= (uintptr_t)monitor_stack_bottom && stack <= (uintptr_t)monitor_stack_top &&
          !(stack & 15), "monitor stack bounds");
}

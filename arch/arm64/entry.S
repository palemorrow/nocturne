.section .text.boot, "ax"
.global _start
_start:
  msr daifset, #15
  mrs x0, CurrentEL
  cmp x0, #8
  b.ne boot_wrong_el
  ldr x0, =monitor_stack_top
  mov sp, x0
  ldr x0, =__bss_start
  ldr x1, =__bss_end
1:
  cmp x0, x1
  b.hs 2f
  str xzr, [x0], #8
  b 1b
2:
  ldr x0, =__guest_bss_start
  ldr x1, =__guest_bss_end
3:
  cmp x0, x1
  b.hs 4f
  str xzr, [x0], #8
  b 3b
4:
  ldr x0, =el2_vectors
  msr vbar_el2, x0
  isb
  bl monitor_main
boot_wrong_el:
  mov x0, #0x09000000
  mov w1, #33
  str w1, [x0]
5:
  wfe
  b 5b

.global enter_guest
enter_guest:
  msr elr_el2, x0
  msr sp_el1, x1
  mov x0, x2
  mov x1, #0x3c5
  msr spsr_el2, x1
  eret

.section .bss.stack, "aw", %nobits
.balign 16
.global monitor_stack_guard
monitor_stack_guard:
.skip 16
.global monitor_stack_bottom
monitor_stack_bottom:
.skip 16384
.global monitor_stack_top
monitor_stack_top:
.skip 16
.section .note.GNU-stack, "", %progbits

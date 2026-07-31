#include "frame-offsets.h"
.section .text, "ax"
.global guest_entry
guest_entry:
  bl guest_main
1:
  wfe
  b 1b

.global probe_store
.global probe_store_resume
probe_store:
  str x1, [x0]
probe_store_resume:
  ret

.global probe_load
.global probe_load_resume
probe_load:
  ldr x0, [x0]
probe_load_resume:
  ret

.global probe_execute
.global probe_execute_resume
probe_execute:
  mov x16, x30
  adr x30, probe_execute_resume
  br x0
probe_execute_resume:
  mov x30, x16
  ret

.global probe_sysreg
.global probe_sysreg_resume
probe_sysreg:
  mrs x0, id_aa64pfr0_el1
probe_sysreg_resume:
  ret

.global probe_hvc
.global probe_hvc_return
probe_hvc:
  mov x0, #0
  mov x1, #0x1234
  mov x2, #0x5678
  hvc #0x4e
probe_hvc_return:
  mov x3, #0x1234
  cmp x1, x3
  b.ne 2f
  mov x3, #0x5678
  cmp x2, x3
  b.ne 2f
  mov x3, #0xfeed
  cmp x0, x3
  cset x0, eq
  ret
2:
  mov x0, #0
  ret

.global enter_el0
.global enter_el0_return
enter_el0:
  ldr x0, =guest_user_stack_top
  msr sp_el0, x0
  adr x0, el0_payload
  msr elr_el1, x0
  mov x0, #0x3c0
  msr spsr_el1, x0
  eret
enter_el0_return:
  ret

.global el0_payload
.global el0_after_svc
el0_payload:
  svc #77
el0_after_svc:
  svc #78
3:
  b 3b

.balign 2048
.global guest_vectors
guest_vectors:
  .rept 8
  b guest_bad
  .balign 128
  .endr
  b guest_sync_entry
  .balign 128
  .rept 7
  b guest_bad
  .balign 128
  .endr

guest_sync_entry:
  sub sp, sp, #FRAME_SIZE
  stp x0, x1, [sp, #FRAME_X0]
  stp x2, x3, [sp, #FRAME_X2]
  stp x4, x5, [sp, #FRAME_X4]
  stp x6, x7, [sp, #FRAME_X6]
  stp x8, x9, [sp, #FRAME_X8]
  stp x10, x11, [sp, #FRAME_X10]
  stp x12, x13, [sp, #FRAME_X12]
  stp x14, x15, [sp, #FRAME_X14]
  stp x16, x17, [sp, #FRAME_X16]
  stp x18, x19, [sp, #FRAME_X18]
  stp x20, x21, [sp, #FRAME_X20]
  stp x22, x23, [sp, #FRAME_X22]
  stp x24, x25, [sp, #FRAME_X24]
  stp x26, x27, [sp, #FRAME_X26]
  stp x28, x29, [sp, #FRAME_X28]
  str x30, [sp, #FRAME_X30]
  mrs x1, elr_el1
  mrs x2, spsr_el1
  stp x1, x2, [sp, #FRAME_ELR]
  mov x0, sp
  bl guest_sync
  ldp x1, x2, [sp, #FRAME_ELR]
  msr elr_el1, x1
  msr spsr_el1, x2
  ldp x0, x1, [sp, #FRAME_X0]
  ldp x2, x3, [sp, #FRAME_X2]
  ldp x4, x5, [sp, #FRAME_X4]
  ldp x6, x7, [sp, #FRAME_X6]
  ldp x8, x9, [sp, #FRAME_X8]
  ldp x10, x11, [sp, #FRAME_X10]
  ldp x12, x13, [sp, #FRAME_X12]
  ldp x14, x15, [sp, #FRAME_X14]
  ldp x16, x17, [sp, #FRAME_X16]
  ldp x18, x19, [sp, #FRAME_X18]
  ldp x20, x21, [sp, #FRAME_X20]
  ldp x22, x23, [sp, #FRAME_X22]
  ldp x24, x25, [sp, #FRAME_X24]
  ldp x26, x27, [sp, #FRAME_X26]
  ldp x28, x29, [sp, #FRAME_X28]
  ldr x30, [sp, #FRAME_X30]
  add sp, sp, #FRAME_SIZE
  eret

guest_bad:
  mov x0, #2
  mov x1, #0
  hvc #0x4e
4:
  b 4b

.section .bss, "aw", %nobits
.balign 16
.skip 16384
.global guest_stack_top
guest_stack_top:
.skip 4096
.global guest_user_stack_top
guest_user_stack_top:
.section .note.GNU-stack, "", %progbits

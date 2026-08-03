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
  sub sp, sp, #112
  stp x19, x20, [sp, #0]
  stp x21, x22, [sp, #16]
  stp x23, x24, [sp, #32]
  stp x25, x26, [sp, #48]
  stp x27, x28, [sp, #64]
  stp x29, x30, [sp, #80]
  mov x1, #1
  mov x2, #2
  mov x3, #3
  mov x4, #4
  mov x5, #5
  mov x6, #6
  mov x7, #7
  mov x8, #8
  mov x9, #9
  mov x10, #10
  mov x11, #11
  mov x12, #12
  mov x13, #13
  mov x14, #14
  mov x15, #15
  mov x16, #16
  mov x17, #17
  mov x18, #18
  mov x19, #19
  mov x20, #20
  mov x21, #21
  mov x22, #22
  mov x23, #23
  mov x24, #24
  mov x25, #25
  mov x26, #26
  mov x27, #27
  mov x28, #28
  mov x29, #29
  mov x30, #0x3030
  mov x0, #0xa0000000
  msr nzcv, x0
  mov x0, #0
  hvc #0x4e
probe_hvc_return:
  str x0, [sp, #96]
  mrs x0, nzcv
  str x0, [sp, #104]
  cmp x1, #1
  b.ne hvc_register_failure
  cmp x2, #2
  b.ne hvc_register_failure
  cmp x3, #3
  b.ne hvc_register_failure
  cmp x4, #4
  b.ne hvc_register_failure
  cmp x5, #5
  b.ne hvc_register_failure
  cmp x6, #6
  b.ne hvc_register_failure
  cmp x7, #7
  b.ne hvc_register_failure
  cmp x8, #8
  b.ne hvc_register_failure
  cmp x9, #9
  b.ne hvc_register_failure
  cmp x10, #10
  b.ne hvc_register_failure
  cmp x11, #11
  b.ne hvc_register_failure
  cmp x12, #12
  b.ne hvc_register_failure
  cmp x13, #13
  b.ne hvc_register_failure
  cmp x14, #14
  b.ne hvc_register_failure
  cmp x15, #15
  b.ne hvc_register_failure
  cmp x16, #16
  b.ne hvc_register_failure
  cmp x17, #17
  b.ne hvc_register_failure
  cmp x18, #18
  b.ne hvc_register_failure
  cmp x19, #19
  b.ne hvc_register_failure
  cmp x20, #20
  b.ne hvc_register_failure
  cmp x21, #21
  b.ne hvc_register_failure
  cmp x22, #22
  b.ne hvc_register_failure
  cmp x23, #23
  b.ne hvc_register_failure
  cmp x24, #24
  b.ne hvc_register_failure
  cmp x25, #25
  b.ne hvc_register_failure
  cmp x26, #26
  b.ne hvc_register_failure
  cmp x27, #27
  b.ne hvc_register_failure
  cmp x28, #28
  b.ne hvc_register_failure
  cmp x29, #29
  b.ne hvc_register_failure
  mov x0, #0x3030
  cmp x30, x0
  b.ne hvc_register_failure
  ldr x0, [sp, #96]
  mov x1, #0xfeed
  cmp x0, x1
  b.ne hvc_register_failure
  ldr x0, [sp, #104]
  mov x1, #0xa0000000
  cmp x0, x1
  b.ne hvc_register_failure
  mov x0, #1
  b hvc_register_restore
hvc_register_failure:
  mov x0, #0
hvc_register_restore:
  ldp x19, x20, [sp, #0]
  ldp x21, x22, [sp, #16]
  ldp x23, x24, [sp, #32]
  ldp x25, x26, [sp, #48]
  ldp x27, x28, [sp, #64]
  ldp x29, x30, [sp, #80]
  add sp, sp, #112
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
  mov x0, sp
  tst x0, #15
  b.ne guest_bad
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

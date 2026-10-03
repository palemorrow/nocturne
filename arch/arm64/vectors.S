#include "frame-offsets.h"
.macro slot target
  b \target
  .balign 128
.endm

.macro save_frame
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
.endm

.macro restore_frame
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
.endm

.section .text, "ax"
.balign 2048
.global el2_vectors
el2_vectors:
  .rept 8
  slot bad_entry
  .endr
  slot sync_entry
  slot irq_entry
  slot bad_entry
  slot bad_entry
  .rept 4
  slot bad_entry
  .endr

.macro handler name, function
\name:
  save_frame
  mov x0, sp
  tst x0, #15
  b.ne vector_alignment_failure
  mrs x1, elr_el2
  mrs x2, spsr_el2
  stp x1, x2, [sp, #FRAME_ELR]
  mov x0, sp
  bl \function
  bl monitor_stack_check
  ldp x1, x2, [sp, #FRAME_ELR]
  msr elr_el2, x1
  msr spsr_el2, x2
  restore_frame
.endm
handler sync_entry, monitor_sync
handler irq_entry, monitor_irq
handler bad_entry, monitor_bad
vector_alignment_failure:
  bic x0, x0, #15
  mov sp, x0
  bl monitor_alignment_failure
  b .
.section .note.GNU-stack, "", %progbits

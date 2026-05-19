.macro slot target
  b \target
  .balign 128
.endm

.macro save_frame
  sub sp, sp, #272
  stp x0, x1, [sp, #0]
  stp x2, x3, [sp, #16]
  stp x4, x5, [sp, #32]
  stp x6, x7, [sp, #48]
  stp x8, x9, [sp, #64]
  stp x10, x11, [sp, #80]
  stp x12, x13, [sp, #96]
  stp x14, x15, [sp, #112]
  stp x16, x17, [sp, #128]
  stp x18, x19, [sp, #144]
  stp x20, x21, [sp, #160]
  stp x22, x23, [sp, #176]
  stp x24, x25, [sp, #192]
  stp x26, x27, [sp, #208]
  stp x28, x29, [sp, #224]
  str x30, [sp, #240]
.endm

.macro restore_frame
  ldp x0, x1, [sp, #0]
  ldp x2, x3, [sp, #16]
  ldp x4, x5, [sp, #32]
  ldp x6, x7, [sp, #48]
  ldp x8, x9, [sp, #64]
  ldp x10, x11, [sp, #80]
  ldp x12, x13, [sp, #96]
  ldp x14, x15, [sp, #112]
  ldp x16, x17, [sp, #128]
  ldp x18, x19, [sp, #144]
  ldp x20, x21, [sp, #160]
  ldp x22, x23, [sp, #176]
  ldp x24, x25, [sp, #192]
  ldp x26, x27, [sp, #208]
  ldp x28, x29, [sp, #224]
  ldr x30, [sp, #240]
  add sp, sp, #272
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
  mrs x1, elr_el2
  mrs x2, spsr_el2
  stp x1, x2, [sp, #248]
  mov x0, sp
  bl \function
  ldp x1, x2, [sp, #248]
  msr elr_el2, x1
  msr spsr_el2, x2
  restore_frame
.endm
handler sync_entry, monitor_sync
handler irq_entry, monitor_irq
handler bad_entry, monitor_bad
.section .note.GNU-stack, "", %progbits

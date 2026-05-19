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
  mrs x1, elr_el1
  mrs x2, spsr_el1
  stp x1, x2, [sp, #248]
  mov x0, sp
  bl guest_sync
  ldp x1, x2, [sp, #248]
  msr elr_el1, x1
  msr spsr_el1, x2
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

#include "nocturne.h"
#include "fault.h"
#include "routing.h"
#include "trace.h"

static struct trace trace;
static enum experiment experiment;
static unsigned abort_count, irq_count, sysreg_count, svc_count, local_fault_count;
static uint64_t sysreg_value;
static bool revoked;
static uint64_t backing_snapshot[PAGE_SIZE / sizeof(uint64_t)];

static bool guest_page(uint64_t address) {
  return address >= GUEST_BASE && address <= GUEST_END - PAGE_SIZE &&
         (address & (PAGE_SIZE - 1)) == 0;
}

static bool read_guest_table(uint64_t table, unsigned index, uint64_t *descriptor) {
  if (!guest_page(table) || index >= 512) return false;
  *descriptor = ((volatile uint64_t *)(uintptr_t)table)[index];
  return true;
}

static bool architectural_ipa(uint64_t va, uint64_t *ipa) {
  uint64_t saved = READ_REG(par_el1);
  __asm__ volatile("at s1e1r, %0\n\tisb" :: "r"(va) : "memory");
  uint64_t result = READ_REG(par_el1);
  WRITE_REG(par_el1, saved);
  if (result & 1) return false;
  *ipa = (result & 0x0000fffffffff000UL) | (va & 4095);
  return true;
}

static struct trace_event *record(struct frame *frame, bool abort, bool synchronous) {
  struct trace_event *event = trace_reserve(&trace, synchronous ? TRACE_SYNC : TRACE_IRQ);
  require(event != NULL, "trace capacity");
  event->esr_valid = synchronous;
  event->esr = synchronous ? READ_REG(esr_el2) : 0;
  event->elr = frame->elr;
  event->spsr = frame->spsr;
  event->far = abort ? READ_REG(far_el2) : 0;
  event->hpfar = abort ? READ_REG(hpfar_el2) : 0;
  if (abort) {
    struct fault_input input = { event->esr, event->far, event->hpfar,
      READ_REG(sctlr_el1), READ_REG(tcr_el1), READ_REG(ttbr0_el1), READ_REG(vtcr_el2) };
    struct fault_address address = fault_decode(input, read_guest_table);
    event->far_valid = address.far_valid;
    event->ipa_valid = address.ipa_valid;
    event->ipa = address.ipa;
    if (address.ipa_valid && (input.sctlr & 1) && (input.esr & 0x3c) == 12) {
      uint64_t hardware_ipa;
      require(architectural_ipa(input.far, &hardware_ipa) && hardware_ipa == address.ipa,
              "architectural translation agreement");
      serial_puts("translation at=software\n");
    }
  }
  serial_puts("event seq="); serial_hex(event->sequence);
  serial_puts(synchronous ? " kind=sync esr-valid=1 esr=" : " kind=irq esr-valid=0 esr=");
  serial_hex(event->esr);
  serial_puts(" elr="); serial_hex(event->elr);
  serial_puts(" spsr="); serial_hex(event->spsr);
  if (abort) {
    serial_puts(" far="); serial_hex(event->far);
    serial_puts(event->far_valid ? " far-valid=1" : " far-valid=0");
    serial_puts(" hpfar="); serial_hex(event->hpfar);
    serial_puts(event->ipa_valid ? " ipa=" : " ipa-unknown=");
    serial_hex(event->ipa);
  }
  serial_puts("\n");
  return event;
}

static void abort_handler(struct frame *frame, unsigned ec) {
  struct trace_event *event = record(frame, true, true);
  require(event->ipa_valid, "fixture fault ipa");
  ++abort_count;
  if (experiment == CASE_PRIVATE) {
    require(ec == 0x24 && !(event->esr & (1UL << 6)), "private read abort");
    require(event->ipa == PRIVATE && (event->esr & 0x3c) == 4, "private translation fault");
    require(frame->elr == (uintptr_t)probe_load, "private probe pc");
    frame->elr = (uintptr_t)probe_load_resume;
    return;
  }
  require(event->ipa == TARGET || (experiment == CASE_REMAP &&
          event->ipa >= TARGET && event->ipa < TARGET + PAGE_SIZE), "target ipa");
  require((event->esr & 63) == 15, "stage-2 permission level 3");
  if (experiment == CASE_READ_REVOKE) {
    require(ec == 0x24 && !(event->esr & (1UL << 6)), "read permission fault");
    require(frame->elr == (uintptr_t)probe_load, "read probe pc");
    require(*(volatile uint64_t *)TARGET == INITIAL, "read backing unchanged");
    frame->elr = (uintptr_t)probe_load_resume;
    serial_puts("read denied after revocation\n");
  } else if ((experiment == CASE_EXECUTE || experiment == CASE_EXEC_TRANSITION)) {
    require(ec == 0x20 && frame->elr == TARGET, "execute probe pc");
    require(frame->x[30] == (uintptr_t)probe_execute_resume, "execute continuation");
    frame->elr = (uintptr_t)probe_execute_resume;
  } else {
    require(ec == 0x24 && (event->esr & (1UL << 6)), "write permission fault");
    require(frame->elr == (uintptr_t)probe_store, "store probe pc");
    uint64_t expected = (experiment == CASE_REVOKE || experiment == CASE_TLBI_NEIGHBOR) ? 0x55 : INITIAL;
    require(*(volatile uint64_t *)TARGET == expected, "backing unchanged");
    if (experiment == CASE_REMAP)
      for (size_t i = 0; i < PAGE_SIZE / sizeof(uint64_t); ++i)
        require(((volatile uint64_t *)TARGET)[i] == backing_snapshot[i], "aliased backing page unchanged");
    serial_puts("backing unchanged\n");
    if (experiment == CASE_REVOKE || experiment == CASE_TLBI_NEIGHBOR) {
      require(revoked && abort_count == 1, "revocation fault");
      stage2_permission(true);
      serial_puts("resume retry\n");
    } else frame->elr = (uintptr_t)probe_store_resume;
  }
}

static void done(void) {
  unsigned expected_aborts = (experiment >= CASE_WRITE && experiment <= CASE_REVOKE) ? 1 : 0;
  if (experiment == CASE_REMAP) expected_aborts = 5;
  if (experiment == CASE_L2_BLOCK || experiment == CASE_READ_REVOKE || experiment == CASE_EXEC_TRANSITION || experiment == CASE_TLBI_NEIGHBOR) expected_aborts = 1;
  require(abort_count == expected_aborts, "abort count");
  require(irq_count == (experiment == CASE_TIMER ? 1U : 0U), "irq count");
  require(sysreg_count == (experiment == CASE_SYSREG ? 1U : 0U), "sysreg count");
  require(local_fault_count == (experiment == CASE_S1_DENY ? 1U : 0U), "local fault count");
  require(svc_count == (experiment == CASE_SVC ? 2U : 0U), "svc count");
  uint64_t expected = (experiment == CASE_REVOKE || experiment == CASE_TLBI_NEIGHBOR) ? CHANGED :
    experiment == CASE_EXEC_TRANSITION ? EXEC_PAYLOAD : INITIAL;
  require(*(volatile uint64_t *)TARGET == expected, "final backing");
  if (experiment == CASE_TLBI_NEIGHBOR) {
    require(*(volatile uint64_t *)(TARGET + PAGE_SIZE) == 0xdef, "neighbor mapping preserved");
    serial_puts("neighbor writable after target revoke\n");
  }
  finish(true);
}

void monitor_sync(struct frame *frame) {
  uint64_t esr = READ_REG(esr_el2);
  unsigned ec = esr >> 26;
  struct controls controls = { (READ_REG(hcr_el2) >> 4) & 1, (READ_REG(hcr_el2) >> 18) & 1 };
  enum exception exception = ec == 0x18 ? EX_ID : ec == 0x16 ? EX_HVC : EX_STAGE2;
  require(exception_route(controls, (frame->spsr >> 7) & 1, exception) == DEST_EL2, "routing policy");
  if (ec == 0x24 || ec == 0x20) {
    abort_handler(frame, ec);
    return;
  }
  record(frame, false, true);
  if (ec == 0x18 && experiment == CASE_SYSREG) {
    require(frame->elr == (uintptr_t)probe_sysreg, "sysreg probe pc");
    uint64_t iss = esr & 0x1ffffff;
    uint64_t expected = 1 | (3UL << 20) | (4UL << 1);
    require(iss == expected, "id register encoding");
    ++sysreg_count;
    frame->x[0] = sysreg_value;
    frame->elr = (uintptr_t)probe_sysreg_resume;
    return;
  }
  require(ec == 0x16 && (esr & 0xffff) == 0x4e, "hvc class and immediate");
  require(hypercall_valid(frame), "hypercall abi");
  require(frame->elr >= GUEST_BASE + 4 && frame->elr < (uintptr_t)guest_text_end &&
          !(frame->elr & 3), "hvc return range");
  switch (frame->x[0]) {
    case SVC_PING:
      require(experiment == CASE_HVC && frame->elr == (uintptr_t)probe_hvc_return, "hvc following pc");
      require(frame->x[1] == 1 && frame->x[2] == 2, "hvc arguments");
      frame->x[0] = 0xfeed;
      break;
    case SVC_DONE:
      done();
      break;
    case SVC_CHECK:
      require(frame->x[1] == 1, "guest assertion");
      break;
    case SVC_PREPARE_EXEC:
      require(experiment == CASE_EXEC_TRANSITION && abort_count == 1, "execute transition request");
      *(volatile uint64_t *)TARGET = EXEC_PAYLOAD;
      BARRIER("dsb ish\n\tic ialluis\n\tdsb ish\n\tisb");
      stage2_access(true, false, true);
      serial_puts("instruction cache synchronized and rx installed\n");
      break;
    case SVC_REVOKE_READ:
      require(experiment == CASE_READ_REVOKE && !revoked, "read revocation request");
      stage2_access(false, false, false);
      revoked = true;
      serial_puts("read permission revoked\n");
      break;
    case SVC_REVOKE:
      require((experiment == CASE_REVOKE || experiment == CASE_TLBI_NEIGHBOR) && !revoked, "revocation request");
      require(*(volatile uint64_t *)TARGET == 0x55, "primed writable translation");
      stage2_permission(false);
      revoked = true;
      serial_puts("permission revoked\n");
      break;
    case SVC_TRAP_ID:
      require(experiment == CASE_SYSREG && sysreg_count == 0, "id trap request");
      sysreg_value = frame->x[1];
      WRITE_REG(hcr_el2, READ_REG(hcr_el2) | (1UL << 18));
      BARRIER("isb");
      break;
    case SVC_TIMER:
      require(experiment == CASE_TIMER && irq_count == 0, "timer request");
      timer_arm();
      break;
    case SVC_LOCAL_FAULT:
      require(experiment == CASE_S1_DENY && (frame->x[1] >> 26) == 0x25, "guest stage-1 abort");
      ++local_fault_count;
      serial_puts("guest stage1 write denied at el1\n");
      break;
    case SVC_EL0:
      require(experiment == CASE_SVC && frame->x[1] == 2, "el0 svc delivery");
      svc_count = 2;
      serial_puts("el0 svc handled at el1\n");
      break;
    default:
      require(false, "unknown service");
  }
}

void monitor_irq(struct frame *frame) {
  record(frame, false, false);
  require(experiment == CASE_TIMER, "unexpected irq");
  require((frame->spsr & (1UL << 7)) && (frame->spsr & 15) == 5, "guest irq mask");
  require(timer_ack(), "hypervisor physical timer ppi");
  ++irq_count;
  serial_puts("irq physical-timer guest-i=1 target=el2\n");
}

void monitor_bad(struct frame *frame) {
  record(frame, false, true);
  require(false, "unexpected vector");
}

_Noreturn void monitor_alignment_failure(void) {
  serial_puts("failure exception stack alignment\n");
  finish(false);
}

void monitor_main(void) {
  uint64_t selected = *(volatile uint64_t *)CONFIG;
  require(selected < CASE_COUNT, "experiment selection");
  experiment = (enum experiment)selected;
  serial_puts("nocturne el2 case="); serial_hex(selected); serial_puts("\n");
  for (size_t i = 0; i < PAGE_SIZE / sizeof(uint64_t); ++i)
    backing_snapshot[i] = ((volatile uint64_t *)TARGET)[i];
  stage2_init(experiment == CASE_REVOKE || experiment == CASE_S1_DENY || experiment == CASE_TLBI_NEIGHBOR);
  WRITE_REG(cptr_el2, 0);
  WRITE_REG(cnthctl_el2, 3);
  WRITE_REG(cntvoff_el2, 0);
  WRITE_REG(hcr_el2, (1UL << 31) | (1UL << 4) | 1UL);
  WRITE_REG(sctlr_el1, 0x30d00800UL);
  BARRIER("isb");
  enter_guest((uintptr_t)guest_entry, (uintptr_t)guest_stack_top, experiment);
  require(false, "guest returned to monitor");
}

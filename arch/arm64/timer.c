#include "nocturne.h"

static volatile uint32_t *const distributor = (void *)0x08000000;
static volatile uint32_t *const cpu = (void *)0x08010000;

void timer_arm(void) {
  distributor[0x080 / 4] |= 1U << 26;
  ((volatile uint8_t *)distributor)[0x400 + 26] = 0x80;
  distributor[0x100 / 4] = 1U << 26;
  distributor[0] = 3;
  cpu[4 / 4] = 0xff;
  cpu[8 / 4] = 0;
  cpu[0] = 7;
  BARRIER("dsb sy");
  WRITE_REG(cnthp_tval_el2, READ_REG(cntfrq_el0) / 100);
  WRITE_REG(cnthp_ctl_el2, 1);
  BARRIER("isb");
}

bool timer_ack(void) {
  uint32_t acknowledge = cpu[0x0c / 4];
  WRITE_REG(cnthp_ctl_el2, 0);
  cpu[0x10 / 4] = acknowledge;
  BARRIER("dsb sy\n\tisb");
  return (acknowledge & 0x3ff) == 26;
}

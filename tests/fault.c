#include "fault.h"
#include <assert.h>
#include <stdio.h>

static unsigned reads;
static bool bad_table, block_descriptor;

static bool read_table(uint64_t table, unsigned index, uint64_t *descriptor) {
  ++reads;
  if (bad_table || table < 0x40310000 || table > 0x40312000 || (table & 4095)) return false;
  if (table == 0x40310000) {
    assert(index == 1);
    *descriptor = 0x40311003;
  } else if (table == 0x40311000) {
    assert(index == 1);
    *descriptor = 0x40312000 | (block_descriptor ? 1 : 3);
  } else {
    assert(index == 258);
    *descriptor = 0x40300003;
  }
  return true;
}

int main(void) {
  struct fault_input input = { .esr = 15 | (1UL << 6), .far = 0x40302008,
    .hpfar = 0xdeadbeef, .sctlr = 1, .tcr = 32 | (1UL << 23), .ttbr = 0x40310000 };
  struct fault_address result = fault_decode(input, read_table);
  assert(result.far_valid && result.ipa_valid && result.ipa == 0x40300008 && reads == 3);
  const uint64_t invalid_controls[] = {16, 32 | (1UL << 14), 32 | (1UL << 7),
    32 | (1UL << 37), 32 | (1UL << 32), 32 | (1UL << 59)};
  for (unsigned i = 0; i < sizeof(invalid_controls) / sizeof(invalid_controls[0]); ++i) {
    struct fault_input unsupported = input;
    unsupported.tcr = invalid_controls[i];
    assert(!fault_translation_supported(unsupported));
    assert(!fault_decode(unsupported, read_table).ipa_valid);
  }
  input.esr |= 1UL << 10;
  result = fault_decode(input, read_table);
  assert(!result.far_valid && !result.ipa_valid && reads == 3);
  input.esr = 15 | (1UL << 7);
  assert(!fault_decode(input, read_table).ipa_valid && reads == 3);
  input.esr = 15;
  bad_table = true;
  assert(!fault_decode(input, read_table).ipa_valid);
  bad_table = false;
  block_descriptor = true;
  assert(!fault_decode(input, read_table).ipa_valid);
  block_descriptor = false;
  input.tcr |= 1UL << 7;
  assert(!fault_decode(input, read_table).ipa_valid);
  input.tcr = 16;
  assert(!fault_decode(input, read_table).ipa_valid);
  input.sctlr = 0;
  result = fault_decode(input, read_table);
  assert(result.ipa_valid && result.ipa == input.far);
  input.far = 1UL << 40;
  assert(!fault_decode(input, read_table).ipa_valid);
  input.esr = 6;
  input.far = 0x40100008;
  input.hpfar = 0x401000;
  result = fault_decode(input, read_table);
  assert(result.ipa_valid && result.ipa == 0x40100008);
  input.hpfar = 0xfffffffff0UL;
  assert(!fault_decode(input, read_table).ipa_valid);
  input.esr = 0x10;
  assert(!fault_decode(input, read_table).ipa_valid);
  puts("12 fault-address checks passed");
  return 0;
}

#include "fault.h"

unsigned fault_ipa_width(uint64_t vtcr) {
  unsigned size = vtcr & 63;
  if (size < 25 || size > 32 || (vtcr & (3UL << 14)) ||
      ((vtcr >> 6) & 3) != 1) return 0;
  return 64 - size;
}

bool fault_translation_supported(struct fault_input input) {
  uint64_t unsupported = (3UL << 14) | (1UL << 7) | (1UL << 37) |
                         (7UL << 32) | (1UL << 59);
  return (input.tcr & 63) == 32 && !(input.tcr & unsupported);
}

struct fault_address fault_decode(struct fault_input input, table_reader read_table) {
  struct fault_address address = {0, !(input.esr & (1UL << 10)), false};
  if (!address.far_valid || (input.esr & (1UL << 7))) return address;
  unsigned ipa_width = fault_ipa_width(input.vtcr);
  if (!ipa_width) return address;
  unsigned fsc = input.esr & 63;
  if ((fsc & 0x3c) == 4) {
    address.ipa = ((input.hpfar & 0xfffffffff0UL) << 8) | (input.far & 4095);
    address.ipa_valid = !(address.ipa >> ipa_width);
    return address;
  }
  if ((fsc & 0x3c) != 12 || input.far >> 32) return address;
  if (!(input.sctlr & 1)) {
    address.ipa = input.far;
    address.ipa_valid = !(address.ipa >> ipa_width);
    return address;
  }
  if (!fault_translation_supported(input)) return address;
  if (input.ttbr & 0x0000ffff00000000UL) return address;
  uint64_t table = input.ttbr & 0x0000fffffffff000UL;
  for (unsigned level = 1; level <= 3; ++level) {
    unsigned shift = 12 + 9 * (3 - level);
    uint64_t descriptor;
    if (!read_table(table, (input.far >> shift) & 511, &descriptor) ||
        !(descriptor & 1)) return address;
    if (descriptor & 0x000fffff00000000UL) return address;
    if (level == 2 && (descriptor & 3) == 1) {
      if (descriptor & 0x1ff000UL) return address;
      address.ipa = (descriptor & 0x0000ffffffe00000UL) | (input.far & 0x1fffffUL);
      address.ipa_valid = !(address.ipa >> ipa_width);
      return address;
    }
    if ((descriptor & 3) != 3) return address;
    table = descriptor & 0x0000fffffffff000UL;
    if (level == 3) {
      address.ipa = table | (input.far & 4095);
      address.ipa_valid = !(address.ipa >> ipa_width);
    }
  }
  return address;
}

#ifndef NOCTURNE_FAULT_H
#define NOCTURNE_FAULT_H

#include <stdbool.h>
#include <stdint.h>

struct fault_input {
  uint64_t esr, far, hpfar, sctlr, tcr, ttbr;
};

struct fault_address {
  uint64_t ipa;
  bool far_valid, ipa_valid;
};

typedef bool (*table_reader)(uint64_t table, unsigned index, uint64_t *descriptor);

struct fault_address fault_decode(struct fault_input input, table_reader read_table);
bool fault_translation_supported(struct fault_input input);

#endif

#ifndef NOCTURNE_TRACE_H
#define NOCTURNE_TRACE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define TRACE_CAPACITY 64

enum trace_kind { TRACE_SYNC, TRACE_IRQ };

struct trace_event {
  uint64_t sequence, esr, elr, spsr, far, hpfar, ipa;
  enum trace_kind kind;
  bool far_valid, ipa_valid, esr_valid;
};

struct trace {
  size_t count;
  struct trace_event events[TRACE_CAPACITY];
};

struct trace_event *trace_reserve(struct trace *trace, enum trace_kind kind);

#endif

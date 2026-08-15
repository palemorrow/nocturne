#include "trace.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
  struct trace trace = {0};
  for (size_t i = 0; i < TRACE_CAPACITY; ++i) {
    struct trace_event *event = trace_reserve(&trace, TRACE_SYNC);
    assert(event && event->sequence == i && !event->esr_valid && !event->ipa_valid);
    event->elr = i + 0x1000;
  }
  for (unsigned i = 0; i < 10; ++i) assert(!trace_reserve(&trace, TRACE_IRQ));
  assert(trace.count == TRACE_CAPACITY);
  for (size_t i = 0; i < TRACE_CAPACITY; ++i) {
    assert(trace.events[i].elr == i + 0x1000);
    assert(trace.events[i].sequence == i);
  }
  trace.count = TRACE_CAPACITY + 1;
  assert(!trace_reserve(&trace, TRACE_IRQ));
  puts("trace exhaustion preserves every committed record");
}

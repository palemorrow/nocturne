#include "trace.h"

struct trace_event *trace_reserve(struct trace *trace, enum trace_kind kind) {
  if (trace->count >= TRACE_CAPACITY) return NULL;
  struct trace_event *event = &trace->events[trace->count];
  *event = (struct trace_event){ .sequence = trace->count, .kind = kind };
  ++trace->count;
  return event;
}

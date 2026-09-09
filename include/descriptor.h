#ifndef NOCTURNE_DESCRIPTOR_H
#define NOCTURNE_DESCRIPTOR_H

#include <stdbool.h>
#include <stdint.h>

bool stage2_descriptor(uint64_t address, bool read, bool write, bool execute, uint64_t *descriptor);

#endif

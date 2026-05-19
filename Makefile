CROSS_COMPILE ?= aarch64-linux-gnu-
CC := $(CROSS_COMPILE)gcc
HOSTCC ?= cc
AGDA ?= agda
CASE ?= s2-write
CFLAGS := -std=c11 -O2 -g -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -mgeneral-regs-only -mno-outline-atomics -march=armv8-a -Wall -Wextra -Werror -ffile-prefix-map=$(CURDIR)=. -Iinclude
SOURCES := $(wildcard arch/arm64/*.c core/*.c guest/*.c arch/arm64/*.S guest/*.S)
OBJECTS := $(addprefix build/,$(patsubst %.S,%.o,$(patsubst %.c,%.o,$(SOURCES))))
AGDAFLAGS := --no-default-libraries --library-file=.deps/libraries

.PHONY: all doctor run debug proof oracle test test-qemu test-refinement test-host test-image test-reproducible deps clean
all: build/nocturne.elf

build/%.o: %.c include/nocturne.h include/policy.h include/fault.h
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

build/%.o: %.S
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

build/nocturne.elf: $(OBJECTS) arch/arm64/link.ld
	$(CC) -nostdlib -static -no-pie -Wl,--build-id=none,-T,arch/arm64/link.ld,-Map,build/nocturne.map $(OBJECTS) -o $@
	@test -z "$$($(CROSS_COMPILE)nm -u $@)"

run: all
	python3 tools/run.py $(CASE)

debug: all
	python3 tools/run.py $(CASE) --debug

doctor:
	@$(CC) --version | head -n 1
	@qemu-system-aarch64 --version | head -n 1
	@$(AGDA) --version
	@python3 --version
	@$(HOSTCC) --version | head -n 1

deps:
	sh tools/stdlib.sh

.deps/libraries:
	@mkdir -p .deps
	@test -f .deps/agda-stdlib-2.3/standard-library.agda-lib || { echo 'run make deps'; exit 1; }
	@printf '%s\n' '.deps/agda-stdlib-2.3/standard-library.agda-lib' > $@

proof: .deps/libraries
	@test "$$($(AGDA) --version | head -n 1)" = 'Agda version 2.8.0'
	$(AGDA) $(AGDAFLAGS) --safe proof/Nocturne/Properties.agda
	$(AGDA) $(AGDAFLAGS) proof/Oracle.agda

oracle: proof
	$(AGDA) $(AGDAFLAGS) --compile --compile-dir=build/oracle proof/Oracle.agda

build/policy-host: tests/policy.c core/policy.c include/policy.h
	@mkdir -p build
	$(HOSTCC) -std=c11 -Wall -Wextra -Werror -O2 -Iinclude tests/policy.c core/policy.c -o $@

test-refinement: oracle build/policy-host
	python3 tests/refinement.py

test-qemu: all
	python3 tests/qemu.py

build/fault-host: tests/fault.c core/fault.c include/fault.h
	@mkdir -p build
	$(HOSTCC) -std=c11 -Wall -Wextra -Werror -O2 -Iinclude tests/fault.c core/fault.c -o $@

test-host: build/fault-host
	./build/fault-host

test-image: all
	python3 tests/elf.py

test-reproducible:
	python3 tests/reproducible.py

test: test-refinement test-host test-image test-qemu

clean:
	rm -rf build _build

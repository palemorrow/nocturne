ENTRY(_start)
PHDRS {
  monitor_rx PT_LOAD FLAGS(5);
  monitor_rw PT_LOAD FLAGS(6);
  guest_rx PT_LOAD FLAGS(5);
  guest_rw PT_LOAD FLAGS(6);
}
SECTIONS {
  . = 0x40100000;
  .text : { build/arch/arm64/entry.o(.text.boot) build/arch/arm64/*.o(.text*) build/core/*.o(.text*) } :monitor_rx
  .rodata : { build/arch/arm64/*.o(.rodata*) build/core/*.o(.rodata*) } :monitor_rx
  . = ALIGN(4096);
  .data : { build/arch/arm64/*.o(.data*) build/core/*.o(.data*) } :monitor_rw
  .bss (NOLOAD) : {
    __bss_start = .;
    build/arch/arm64/*.o(.bss* COMMON) build/core/*.o(.bss* COMMON)
    . = ALIGN(8);
    __bss_end = .;
  } :monitor_rw
  ASSERT(. < 0x401ff000, "monitor overlaps boot configuration")
  . = 0x40200000;
  .guest_text : { build/guest/*.o(.text*) build/guest/*.o(.rodata*) . = ALIGN(4096); guest_text_end = .; } :guest_rx
  ASSERT(. < 0x40300000, "guest text overlaps test target")
  . = 0x40300000;
  .guest_data : { QUAD(0x1122334455667788) . = ALIGN(4096); } :guest_rw
  . = 0x40310000;
  .guest_bss (NOLOAD) : {
    __guest_bss_start = .;
    build/guest/*.o(.bss* COMMON)
    . = ALIGN(8);
    __guest_bss_end = .;
  } :guest_rw
  ASSERT(. < 0x40400000, "guest exceeds stage-2 window")
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

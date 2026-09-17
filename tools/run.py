import argparse
import subprocess
from pathlib import Path

CASES = ["hvc", "svc", "s2-write", "s2-execute", "guest-remap", "s1-off",
         "private", "tlb-revoke", "sysreg", "timer", "trace-full", "l2-block", "s1-deny", "read-revoke", "exec-transition"]
NEGATIVE = {"trace-full": "trace capacity"}
ROOT = Path(__file__).resolve().parent.parent


def command(case, debug=False):
    result = ["qemu-system-aarch64", "-machine",
              "virt,virtualization=on,secure=off,gic-version=2", "-cpu", "cortex-a57",
              "-accel", "tcg", "-smp", "1", "-m", "128M", "-display", "none",
              "-serial", "stdio", "-monitor", "none", "-no-reboot",
              "-semihosting-config", "enable=on,target=native", "-device",
              f"loader,file={ROOT / 'build/nocturne.elf'},cpu-num=0", "-device",
              f"loader,addr=0x401ff000,data={CASES.index(case)},data-len=8"]
    if debug:
        result += ["-S", "-gdb", "tcp:127.0.0.1:1234"]
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("case", choices=CASES)
    parser.add_argument("--debug", action="store_true")
    arguments = parser.parse_args()
    try:
        raise SystemExit(subprocess.run(command(arguments.case, arguments.debug),
                                        timeout=None if arguments.debug else 15).returncode)
    except subprocess.TimeoutExpired:
        parser.exit(1, "qemu timed out after 15 seconds\n")

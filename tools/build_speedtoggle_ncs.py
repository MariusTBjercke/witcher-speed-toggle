"""Rebuilds the preset table in speedtoggle.ncs and speedtoggle_down.ncs without the game.

Reads SPEEDTOGGLE_LEVELS and the `if (nLevel == N) return P;` lines of GetPresetPercent from
inc_speedtoggle.nss, then rewrites the two places in each .ncs that depend on them:
- the two `CONST int <levels>` in StepSpeedPreset's `% SPEEDTOGGLE_LEVELS` expression
- GetPresetPercent itself (the last function in the file), emitted block by block in exactly the
  layout the game's compiler produces for it.

Any other change to the .nss still needs the game's compiler (see AGENTS.md).
Usage: python -I tools/build_speedtoggle_ncs.py [--nss <inc_speedtoggle.nss>] [--check]
--check only reports whether the .ncs files already match the .nss, and writes nothing.
"""
import argparse
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT_DIR = ROOT / "mod" / "Data" / "Override" / "SpeedToggle"
NCS_FILES = ["speedtoggle.ncs", "speedtoggle_down.ncs"]
HEADER = b"NCS V1.0B"


def cptopsp(off, size=4): return b"\x03\x01" + struct.pack(">iH", off, size)
def cpdownsp(off, size=4): return b"\x01\x01" + struct.pack(">iH", off, size)
def const_int(v): return b"\x04\x03" + struct.pack(">i", v)
def movsp(v): return b"\x1b\x00" + struct.pack(">i", v)
def jmp(rel): return b"\x1d\x00" + struct.pack(">i", rel)
def jz(rel): return b"\x1f\x00" + struct.pack(">i", rel)
EQUAL_II = b"\x0b\x20"
ADD_II = b"\x14\x20"
MOD_II = b"\x18\x20"
RETN = b"\x20\x00"

BLOCK_LEN = 60  # one `if (nLevel == N) return P;`
TAIL_LEN = 32   # `return 0;` plus the dead MOVSP the compiler leaves after it


def build_get_preset_percent(presets):
    """GetPresetPercent(int nLevel): one block per preset, then `return 0;`, then the epilogue."""
    end = len(presets) * BLOCK_LEN + TAIL_LEN  # offset of the epilogue's MOVSP
    out = b""
    for level, percent in presets:
        here = len(out)
        out += cptopsp(-4) + const_int(level) + EQUAL_II
        out += jz(BLOCK_LEN - 16)                            # not this level -> next block
        out += const_int(percent) + cpdownsp(-12) + movsp(-4)
        out += jmp(end - (here + 42))                        # return -> epilogue
        out += movsp(-4) + jmp(6)
        assert len(out) - here == BLOCK_LEN
    here = len(out)
    out += const_int(0) + cpdownsp(-12) + movsp(-4) + jmp(12) + movsp(-4)
    assert len(out) - here == TAIL_LEN
    return out + movsp(-4) + RETN


def parse_nss(path):
    text = Path(path).read_text(encoding="utf-8")
    levels = int(re.search(r"const\s+int\s+SPEEDTOGGLE_LEVELS\s*=\s*(\d+)\s*;", text).group(1))
    body = re.search(r"int\s+GetPresetPercent\s*\(\s*int\s+nLevel\s*\)\s*\{(.*?)\}", text, re.S).group(1)
    presets = [(int(n), int(p)) for n, p in
               re.findall(r"if\s*\(\s*nLevel\s*==\s*(\d+)\s*\)\s*return\s+(\d+)\s*;", body)]
    if [n for n, _ in presets] != list(range(1, levels)):
        sys.exit(f"GetPresetPercent must handle levels 1..{levels - 1} in order, got {[n for n, _ in presets]}")
    if not re.search(r"return\s+0\s*;\s*$", body.strip()):
        sys.exit("GetPresetPercent must end with `return 0;`")
    return levels, presets


def rebuild(ncs, levels, presets):
    if not ncs.startswith(HEADER) or struct.unpack(">I", ncs[9:13])[0] != len(ncs):
        raise ValueError("not an NCS V1.0 file")

    # GetPresetPercent starts with the first `if`: CPTOPSP -4 4; CONST int 1; EQUAL int,int.
    start = ncs.find(cptopsp(-4) + const_int(1) + EQUAL_II)
    if start < 0 or ncs[start - 2:start] != RETN:
        raise ValueError("GetPresetPercent not found")
    jsr = b"\x1e\x00"
    calls = [i for i in range(13, start) if ncs[i:i + 2] == jsr
             and i + struct.unpack(">i", ncs[i + 2:i + 6])[0] == start]
    if len(calls) != 1:
        raise ValueError("expected exactly one call to GetPresetPercent")

    # `(nLevel + nStep + LEVELS) % LEVELS`: ADD; CONST L; ADD; CONST L; MOD.
    m = re.search(re.escape(ADD_II) + b"\x04\x03(....)" + re.escape(ADD_II) + b"\x04\x03(....)" + re.escape(MOD_II),
                  ncs[:start], re.S)
    if not m or m.group(1) != m.group(2):
        raise ValueError("SPEEDTOGGLE_LEVELS expression not found")
    head = bytearray(ncs[:start])
    for g in (1, 2):
        head[m.start(g):m.end(g)] = struct.pack(">i", levels)

    out = bytes(head) + build_get_preset_percent(presets)
    return out[:9] + struct.pack(">I", len(out)) + out[13:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--nss", default=SCRIPT_DIR / "inc_speedtoggle.nss")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    levels, presets = parse_nss(args.nss)
    print(f"levels={levels} presets={', '.join(f'{n}:+{p}%' for n, p in presets)}")
    stale = False
    for name in NCS_FILES:
        path = SCRIPT_DIR / name
        old = path.read_bytes()
        new = rebuild(old, levels, presets)
        if new == old:
            print(f"{name}: up to date ({len(old)} bytes)")
        elif args.check:
            print(f"{name}: OUT OF DATE")
            stale = True
        else:
            path.write_bytes(new)
            print(f"{name}: wrote {len(new)} bytes (was {len(old)})")
    sys.exit(1 if stale else 0)


if __name__ == "__main__":
    main()

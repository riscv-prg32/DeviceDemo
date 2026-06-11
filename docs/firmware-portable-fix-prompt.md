# Task: Fix PRG32 firmware portable cartridge loading

We need to fix PRG32 firmware so portable ABI-table cartridges are actually accepted and run portably.

## Context

DeviceDemo now builds a portable cartridge using:

```bash
scripts/build.sh
```

The generated cartridge header shows:

- `flags = 4`
- `import_model = abi-table`
- `load_addr = 0x40800000`

But upload to a physical board fails:

```text
upload failed: HTTP 500: cartridge linked for a different runtime address
```

The board runtime endpoint reports a different runtime cartridge address, for example:

```json
{
  "cart_load_addr": 1082139552
}
```

That is `0x40802400`, while the portable cartridge is linked for `0x40800000`.

## Root Cause

In firmware, `components/prg32/prg32_cart.c` still rejects cartridges whose header `load_addr` differs from `prg32_cart_exec`, even when the cartridge is a portable ABI-table cartridge.

The problematic logic is in `validate_header()`:

```c
if (h->load_addr != (uint32_t)(uintptr_t)prg32_cart_exec) {
    set_error(import_model == PRG32_IMPORT_MODEL_LEGACY_ABSOLUTE
                  ? "legacy cartridge uses firmware-specific absolute imports; rebuild it with --portable"
                  : "cartridge linked for a different runtime address");
    return -1;
}
```

This defeats the portable option.

## Desired Behavior

Legacy absolute-import cartridges should still require exact runtime address matching.

Portable ABI-table cartridges should not be rejected only because `h->load_addr` differs from `prg32_cart_exec`.

Fix the firmware so portable cartridges built by `tools/prg32_game.py build --portable` can be uploaded and run on boards whose firmware places `prg32_cart_exec` at a different address.

## Requirements

1. Modify firmware, not DeviceDemo.
2. Keep legacy absolute-import cartridge validation strict.
3. Preserve ABI hash and required feature validation for portable cartridges.
4. Ensure portable cartridges receive the ABI table pointer correctly through the generated portable entry stubs.
5. Ensure entry offsets are interpreted correctly after loading.
6. Add or update tests if PRG32 has cartridge loader tests.
7. Verify by building DeviceDemo portable and uploading to hardware.

## Suggested Fix Direction

In `components/prg32/prg32_cart.c`:

- Keep the address equality check for `PRG32_IMPORT_MODEL_LEGACY_ABSOLUTE`.
- For `PRG32_IMPORT_MODEL_ABI_TABLE`, either:
  - load the cartridge at the portable base address expected by the tool, or
  - support relocation/copying so code linked at `h->load_addr` can execute at `prg32_cart_exec`, or
  - revise the portable build/runtime contract so the firmware exposes the canonical portable address used by the builder.

A minimal validation change might look conceptually like:

```c
if (import_model == PRG32_IMPORT_MODEL_LEGACY_ABSOLUTE &&
    h->load_addr != (uint32_t)(uintptr_t)prg32_cart_exec) {
    set_error("legacy cartridge uses firmware-specific absolute imports; rebuild it with --portable");
    return -1;
}
```

But do not stop there unless execution is still correct. If portable code contains absolute addresses or linker-generated assumptions based on `h->load_addr`, then relocation or fixed-address loading is required.

## Verification Steps

1. Build and flash PRG32 firmware with the fix.
2. In DeviceDemo, build the portable cartridge:

```bash
export PRG32_REPO=/path/to/PRG32
export PRG32_ARCHITECTURE=esp32c6
unset PRG32_PORTABLE
scripts/build.sh
```

3. Inspect the cartridge:

```bash
python3 "$PRG32_REPO/tools/prg32_game.py" inspect-metadata \
  dist/devicedemo-esp32c6.prg32
```

Confirm:

```text
import_model: abi-table
flags includes PRG32_CART_FLAG_ABI_TABLE
```

4. Upload to the board:

```bash
python3 "$PRG32_REPO/tools/prg32_game.py" upload \
  dist/devicedemo-esp32c6.prg32 \
  --url http://192.168.1.37 \
  --slot cart0
```

Expected result: upload succeeds and DeviceDemo runs.

## Important Note

DeviceDemo has already been adjusted to avoid non-portable audio asset registration APIs. It now uses portable ABI calls only. The remaining failure is firmware-side address handling for portable ABI-table cartridges.

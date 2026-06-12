# PRG32 Device Demo

DeviceDemo is the PRG32 hardware and runtime smoke test packaged as a normal
cartridge. It exercises display drawing, input, audio samples, tracker-style
tracks, 8x8 and 24x24 multicolor sprites, playfields, status bands, and several
classroom game sketches from the cartridge ABI.

The demo was formerly launched from PRG32 setup mode. It now lives here so it
can be built, uploaded, versioned, and published through CartridgeStore like the
teaching games.

## Controls

| Button | Action |
|---|---|
| `SELECT` or `B` | Advance to the next demo page |
| Direction buttons | Drive the interactive sketches on pages that use input |

## Build

Keep the PRG32 firmware repository next to this repository, or set
`PRG32_REPO`. Builds are portable ABI-table cartridges by default, so they do
not need a firmware ELF from a specific board build:

```bash
export PRG32_REPO=/path/to/PRG32
export PRG32_ARCHITECTURE=esp32c6
scripts/build.sh
```

The output cartridge is written to `dist/devicedemo-esp32c6.prg32`.

To build the legacy firmware-specific absolute-import format, set
`PRG32_PORTABLE=0` and pass or configure the matching firmware ELF:

```bash
export PRG32_PORTABLE=0
scripts/build.sh "$PRG32_REPO/build/PRG32.elf"
```

## Deploy to a Physical Device

Build the ESP32-C6 cartridge, connect your computer to the PRG32 device network
or the same classroom Wi-Fi, then upload the cartridge with the PRG32 tool:

```bash
export PRG32_REPO=/path/to/PRG32
export PRG32_ARCHITECTURE=esp32c6
scripts/build.sh

python3 "$PRG32_REPO/tools/prg32_game.py" upload \
  dist/devicedemo-esp32c6.prg32 \
  --url http://192.168.4.1
```

Use `http://192.168.4.1` when the board is running its setup access point. If
the board is joined to classroom Wi-Fi, replace it with the IP address shown in
PRG32 setup mode.

If upload fails with `cartridge linked for a different runtime address`, the
cartridge and the firmware currently running on the board disagree about the
cartridge RAM address. Use one of these paths:

- Rebuild and flash the PRG32 firmware from the same portable ABI-table branch,
  then rebuild this cartridge with the default portable build.
- Or build the legacy firmware-specific cartridge from the exact
  `PRG32.elf` that was flashed to the board.

For the legacy path:

```bash
export PRG32_REPO=/path/to/PRG32
export PRG32_PORTABLE=0
export PRG32_ARCHITECTURE=esp32c6
scripts/build.sh "$PRG32_REPO/build-esp32c6/PRG32.elf"

python3 "$PRG32_REPO/tools/prg32_game.py" upload \
  dist/devicedemo-esp32c6.prg32 \
  --url http://192.168.1.37 \
  --slot cart0
```

## Publish

Build the `esp32c6` and `qemu` variants, pack the bundle, then publish it to a
CartridgeStore instance:

```bash
export PRG32_ARCHITECTURE=esp32c6
scripts/build.sh

export PRG32_ARCHITECTURE=qemu
scripts/build.sh

scripts/pack-store-bundle.sh

python3 "$PRG32_REPO/tools/prg32_game.py" publish-bundle \
  dist/devicedemo-store-bundle.zip \
  --store-url http://192.168.1.42:5080 \
  --token "$PRG32_STORE_TOKEN"
```

See [docs/build-and-publish.md](docs/build-and-publish.md) for the complete
build, upload, QEMU, and Store workflow.

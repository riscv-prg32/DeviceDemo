# PRG32 Device Demo

DeviceDemo is the PRG32 hardware and runtime smoke test packaged as a normal
cartridge. It exercises display drawing, input, audio, sprites, playfields,
status bands, and several classroom game sketches from the cartridge ABI.

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
`PRG32_REPO`:

```bash
export PRG32_REPO=/path/to/PRG32
export PRG32_ARCHITECTURE=esp32c6
scripts/build.sh "$PRG32_REPO/build/PRG32.elf"
```

The output cartridge is written to `dist/devicedemo-esp32c6.prg32`.

## Publish

Build the `esp32c6` and `qemu` variants, pack the bundle, then publish it to a
CartridgeStore instance:

```bash
export PRG32_ARCHITECTURE=esp32c6
scripts/build.sh "$PRG32_REPO/build/PRG32.elf"

export PRG32_ARCHITECTURE=qemu
scripts/build.sh "$PRG32_REPO/build-qemu/PRG32.elf"

scripts/pack-store-bundle.sh

python3 "$PRG32_REPO/tools/prg32_game.py" publish-bundle \
  dist/devicedemo-store-bundle.zip \
  --store-url http://192.168.1.42:5080 \
  --token "$PRG32_STORE_TOKEN"
```

See [docs/build-and-publish.md](docs/build-and-publish.md) for the complete
build, upload, QEMU, and Store workflow.

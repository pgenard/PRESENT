# PRESENT 128-bits

## About

This **Avalon** Crypto-Accelerator is based on a **DMA** IP and implements **PRESENT** (by Orange Labs).

## Verilator Testbench

```bash
make clean
```

```bash
make build
```

### Waveforms

```bash
make waves
```

## Test Vectors
| K                                  | P                  | C                  |
| :----------------:                 | :------:           | :-----:            |
| 0x00000000000000000000000000000000 | 0x0000000000000000 | 0x96db702a2e6900af |
| 0xffffffffffffffffffffffffffffffff | 0x0000000000000000 | 0x13238c710272a5d8 |
| 0x00000000000000000000000000000000 | 0xffffffffffffffff | 0x3c6019e5e5edd563 |
| 0xffffffffffffffffffffffffffffffff | 0xffffffffffffffff | 0x628d9fbd4218e5b4 |

## Author
**Pierre GENARD**

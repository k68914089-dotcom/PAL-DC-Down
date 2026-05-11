# PAL DC Down

This project implements a synthesizable FPGA module that removes the constant component from a PAL signal and shifts the result into the unsigned range 0..4096, together with a testbench for simulation and waveform capture [file:5][file:1][file:4].

## Theory
PAL (Phase Alternating Line) is an analog television standard designed to carry video information as a composite waveform. In a PAL signal, brightness, color, sync, and other components are encoded together, so the waveform can include a noticeable constant or slowly varying DC offset depending on the source and processing chain.

For digital processing, this offset is a problem because it shifts the signal away from its intended center level. If the baseline is not corrected, later stages may clip, misinterpret the waveform amplitude, or lose headroom for valid video content.

This project addresses that by first passing the input through two low-pass filters. The 5 MHz branch produces the main filtered signal, while the 1 MHz branch gives a smoother version that is better suited for estimating the signal baseline.

To measure the offset, the design observes the filtered signal over a 128 us window and tracks the minimum value during that interval. That minimum is then compared with a fixed reference level, and the difference is used as a correction value for the main signal path.

Once the correction is calculated, it is added to the main filtered signal. The result is clamped to the signed 12-bit range to prevent overflow, and then shifted into the unsigned range 0..4096 for downstream use.

This method is well suited to an FPGA implementation because it is simple, deterministic, and synthesizable. It corrects the signal baseline while preserving the shape of the useful video waveform.

## What the project does

The task is to process 12-bit signed input samples at 15.36 MHz, apply two low-pass filters, estimate the DC offset over a 128 us window, subtract that offset, clamp overflow, and convert the final signed output to an unsigned 12-bit value [file:5][file:1].  
The repository contains the main module `pal_dc_down`, a simple low-pass filter module `lpf`, a testbench, and a helper compile script [file:1][file:2][file:4][file:3].

## Repository contents

- `pal_dc_down.v` — top-level processing module implementing the PAL DC removal pipeline [file:1].
- `lpf.v` — simple low-pass filter used for `Filter_A` and `Filter_B` [file:2].
- `pal_dc_down_test.v` — testbench that reads input samples and writes a VCD waveform [file:4].
- `compile-4.sh` — Icarus Verilog build-and-run script [file:3].
- `PAL_15.36MSPS_video_frames.hex` — input sample file referenced by the testbench [file:4][file:5].

## Algorithm

The design follows the task logic:
1. Run the input through a 5 MHz low-pass filter to form `Filter_A` and a 1 MHz low-pass filter to form `Filter_B` [file:1][file:5].
2. Track the minimum of `Filter_B` over a 128 us interval [file:5][file:1].
3. Every 128 us, compute correction `K = Ref_level - Min`, with `Ref_level = 100` [file:5][file:1].
4. Add `K` to `Filter_A`, clamp the result to the signed 12-bit range, then shift it into the unsigned range [file:5][file:1].

For 15.36 MHz sampling, 128 us corresponds to about 1966 input clocks, which is the interval used in the implementation [file:1].

## Simulation flow

The provided testbench loads the hex input file, truncates the 16-bit signed samples to 12 bits, and produces a VCD file named `pal_dc_down_test.vcd` for inspection [file:4].  
The compile script builds the design with Icarus Verilog and then runs the simulation [file:3].

## Build and run

For Icarus Verilog:
```bash
chmod +x compile-4.sh
./compile-4.sh
```
The simulation should generate `pal_dc_down_test.vcd` in the working directory [file:3][file:4].

## Notes

The task requires the design to be synthesizable in Vivado 2022 or newer, and the implementation is structured as synthesizable RTL rather than a pure behavioral model [file:5][file:1].  
The testbench is intended for simulation only and is written to be compatible with common Verilog flows such as Icarus Verilog and Vivado simulation [file:5][file:4].

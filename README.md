# Racing Lap Time Analyzer

A **MIPS assembly** application that analyzes Formula 1 lap times for four drivers across five laps. The program computes totals and averages, identifies the fastest and slowest individual laps, ranks drivers using selection sort, and prints a formatted race report in **MARS 4.5**.

## What It Demonstrates

- MIPS assembly programming
- Row-major 2D array traversal
- Pointer arrays and address arithmetic
- Selection sort
- Procedure calls and stack frames
- Callee-saved register management
- MARS syscalls
- Integer-based fixed-point time formatting
- Cache-locality analysis
- Basic parallel-performance analysis with Amdahl's Law

## Project Results

| Rank | Driver | Total Time | Average Lap |
| ---: | --- | ---: | ---: |
| 1 | Hamilton | 418.3 s | 83.6 s |
| 2 | Leclerc | 418.7 s | 83.7 s |
| 3 | Verstappen | 424.3 s | 84.8 s |
| 4 | Norris | 426.0 s | 85.2 s |

**Fastest lap:** Hamilton — 82.9 s, Lap 3  
**Slowest lap:** Norris — 85.8 s, Lap 4

## Architecture

The program uses two main data structures:

1. A pointer array containing the addresses of the four driver-name strings.
2. A flat 4 × 5 lap-time array stored in row-major order.

Lap times are stored as integers in tenths of a second, so `845` represents `84.5 s`. This avoids floating-point instructions while still preserving one decimal place.

The program is organized into 11 procedures, including:

- `computeTotals`
- `computeAverages`
- `findFastestLap`
- `findSlowestLap`
- `sortDrivers`
- `printReport`
- `printHighlights`
- helper output procedures

## Run It

1. Open **MARS 4.5**.
2. Open `src/racing_analyzer.asm`.
3. Assemble with **F3**.
4. Run with **F5**.
5. View the formatted output in the Run I/O panel.

## Repository Structure

```text
racing-lap-time-analyzer/
├── README.md
├── src/
│   └── racing_analyzer.asm
└── docs/
    ├── Racing_Lap_Time_Analyzer_Technical_Report.pdf
    └── Racing_Lap_Time_Analyzer_Capstone_Presentation.pptx
```

## Performance Notes

The project also evaluates memory behavior and potential optimization. The row-major layout gives sequential access during lap aggregation, and the technical analysis discusses cache locality, SIMD potential, procedure overhead, and a theoretical **1.95× speedup on four cores** using Amdahl's Law.

## About

Originally developed as a CIS126 Computer Architecture & Organization capstone project and reorganized here as a portfolio project.

**Author:** Vatsal Sagar

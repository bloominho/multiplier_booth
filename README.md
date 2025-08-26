# Fast Multiplier (Verilog) with Kogge–Stone Adder and Radix-4 Booth Encoding

A hardware multiplier implemented in Verilog, using:
- **Radix-4 Booth encoding** for partial product reduction,
- **Kogge–Stone parallel prefix adder** for fast carry-propagation.

Includes a self-checking testbench and large test vectors for automated verification.

---

## Features
- Radix-4 Booth encoded multiplier (`multiplier.v`)
- Kogge–Stone adder (`koggie_stone_adder.v`) for the final summation stage
- Self-checking testbench (`testbench_multiplier.v`)
- Large test vector files (A, B, expected R) for automated pass/fail checks
- Reproducible simulation log (`Result_Multiplier.txt`)

---

## Repository Structure
```
.
├─ rtl
|   ├─ multiplier.v                 # Main multiplier RTL with Booth encoding
|   └─ koggie_stone_adder.v         # Kogge–Stone adder (final add stage)
└─ testbench
    ├─ testbench_multiplier.v       # Self-checking testbench
    ├─ MultiplierTestVectorA        # Operand A test vectors (binary/hex per line)
    ├─ MultiplierTestVectorB        # Operand B test vectors
    ├─ MultiplierTestVectorR        # Expected result vectors
    ├─ Result_Multiplier.txt        # Sample simulation output (all Passed)
    └─ tb_generator_adder.py        # generator script for tests
```

---

## Radix-4 Booth Encoding

### How Booth Encoding Works
Booth encoding is a method to reduce the number of partial products in multiplication by encoding **two bits of the multiplier at a time** (plus one overlapping bit).  
- **Radix-2** Booth encodes one bit at a time → generates `n` partial products.  
- **Radix-4** Booth encodes two bits at a time → reduces to roughly `n/2` partial products.  

The decision table for Radix-4 is:

| Multiplier Bits (b[i+1:i-1]) | Operation         |
|------------------------------|-------------------|
| 000, 111                     | 0 × Multiplicand  |
| 001, 010                     | +1 × Multiplicand |
| 011                          | +2 × Multiplicand |
| 100                          | -2 × Multiplicand |
| 101, 110                     | -1 × Multiplicand |

This reduces the number of additions and improves speed at the cost of slightly more complex encoding logic.

---

### My Implementation
- In `multiplier.v`, the multiplier is scanned in **overlapping groups of 3 bits** (`[b[i+1], b[i], b[i-1]]`).
- Based on the table above:
  - Partial products are generated as `0`, `±M`, or `±2M` (where `M` = multiplicand, shifted appropriately).
  - The encoding logic is written in combinational Verilog (`case` or conditional statements).
- All partial products are then summed using a **tree structure**, with the final carry-propagation handled by the **Kogge–Stone adder**.

Effectively:
1. Booth encoding halves the number of partial products.  
2. The reduction network (CSA tree) combines them.  
3. Kogge–Stone adder performs the final fast addition.  

---

## Design Notes
- **Architecture:**
  - Radix-4 Booth encoder generates signed partial products.
  - Partial product reduction via adders/CSA tree.
  - Final stage: Kogge–Stone adder for logarithmic depth carry-propagation.
- **Parameterization:** typical use is 32×32→64-bit; adjust widths in the RTL/top/testbench if required.
- **Synthesis:** modules are written to be synthesizable; verify constraints/tech mapping in your target flow.

---

## Regenerating / Extending Tests
- `tb_generator_adder.py` can be adapted to generate additional operands/expected results,
  or to emit randomized/regression suites.
- Ensure the testbench file paths and data radix match your generated vectors.

---

## Credits
Andrew Park, April 2025

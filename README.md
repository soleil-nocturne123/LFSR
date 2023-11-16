# LFSR
AFU (Acceleration FPGA Unit) with LFSR (Linear Feedback Shift Register) as the application logic unit to generate random integers.
- The AFU communicates with the FIU (FPGA Interface Unit) using CCI-P (Core Cache Interface Protocol).
- The AFU is downloaded into a target FPGA device using the Arria 10 Development Stack on the Intel DevCloud.
- The FPGA Interface Manager (AFU + FIU) communicates with the host processor via a PCIe port.

 Directory Hierachy\
 docs: Documents related to this project, including:
  - Application logic block diagram and detailed design
  - Host Processor <-> FIM block diagram
  - Summary of steps on DevCloud
  - Summary of how CCI-P works

lfsr_afu
 - hw: Application logic unit design and its testbench
 - hw/rtl: Required files to run the AFU
 - sw: Software applications to run on the AFU

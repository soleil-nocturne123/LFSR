/*
	AUTHOR: PHAN HOAI HUONG NGUYEN (SYLVIA NGUYEN)
	DESCRIPTION: APPLICATION LOGIC MODULE OF THE AFU
	PURPOSE: Generate Random Integers using LFSR (Linear Feedback Shift Register) with modes:
		1. Ctrl = 00 -- Stop Mode (default at reset)
		2. Ctrl = 1X -- Continuous Mode (operation mode -- controlled by software writing to Ctrl register): LFSR generates a new random integer on every clock rising edge
		2. Ctrl = 01 -- Step Mode (operation mode -- controlled by software writing to Ctrl register): LFSR chooses a rising edge among all clock cycles and generates exactly one new pseudo-random integer on that edge
	IO:
		1. Clock: Active-high
		2. Reset: Active-high, Synchronous
		3. A: Address assigns the address to write input data to/load data from:
			- Polynomial register (POLY_REG: 0x0010)
			- LFSR register (LFSR_REG: 0x0012)
			- Control register (CTRL_REG: 0x0014)
		4. W: Write Input Enable Signal
		5. D: Input Data
	NOTES: Template obtained from Intel Computer Acceleration Lab Exercises
*/
module application #(parameter n = 8)(input logic reset, input logic clock,
							input logic W, input logic [15:0] A,
							input logic [n-1:0] D, output logic [n-1:0] Poly, output logic [n-1:0] Ctrl,
							output logic [n-1:0] Q); // A configurable LFSR.
/* IO */
reg [n-1:0] regPoly; // polynomial register
assign Poly = regPoly;
logic enable_Poly;
assign enable_Poly = (A == 16'h0012 && W) ? 1 : 0;

reg [n-1:0] Q_LFSR; // LFSR register
assign Q = Q_LFSR;
logic load_LFSR;
assign load_LFSR = (A == 16'h0014 && W) ? 1 : 0;
logic enable_LFSR;

reg [1:0] regCtrl; // control register
assign Ctrl = regCtrl;
logic enable_Ctrl;
assign enable_Ctrl = (A == 16'h0010 && W) ? 1 : 0;

/* STATE DEFINITION */
enum reg [1:0] {RESET, ENABLE, STALE} state; // FSM, state and next state
logic z; // FSM output
assign z = (state == ENABLE) ? 1 : 0;
assign enable_LFSR = z;

/* FINITE STATE MACHINE */
always_ff @(posedge clock) begin
	if (reset) state <= RESET;
	else case(state)
		RESET: if(~(regCtrl == 2'b00)) state <= ENABLE;
		ENABLE: if(regCtrl == 2'b00) state <= RESET;
						else if(regCtrl == 2'b01) state <= STALE;
		STALE: if(regCtrl[0] == 0) state <= RESET;
	endcase
end

/* POLYNOMIAL BLOCK */
always_ff @(posedge clock) begin
	if (reset) regPoly <= '0;
	else if (enable_Poly) regPoly <= D;
end

/* LFSR BLOCK */
always_ff @(posedge clock) begin
	if (reset) Q_LFSR <= '0;
	else if(load_LFSR) Q_LFSR <= D; // Load seeding value
	// E = 0 --> Q does not change
	else if(enable_LFSR) Q_LFSR <= (Q_LFSR >> 1) ^ (regPoly && Q_LFSR[0]); // Q behaves as a shift register
end

/* CTRL BLOCK */
always_ff @(posedge clock) begin
	if (reset) regCtrl <= 2'b00;
	else if(enable_Ctrl) regCtrl <= D[1:0];
end

endmodule: application

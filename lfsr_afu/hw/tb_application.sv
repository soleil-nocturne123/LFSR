/*
	AUTHOR: PHAN HOAI HUONG NGUYEN
	TESTBENCH TO VERIFY APPLICATION LOGIC UNIT
*/
`timescale 1ns / 1ps

module tb_application ( );
/* SETUP */
integer pass = 0;
integer fail = 0;
integer total = 0;
integer type_test = 0;
logic correct = 1;
assign err = ~correct;

/* DEFINE DUT */
parameter n = 8;
reg reset, clock, W;
reg [15:0] A;
reg [n-1:0] D;
wire [n-1:0] Q;
application #(.n(n)) DUT(.reset, .clock, .W, .A, .D, .Q);

/* CLOCK SIMULATION (100MHz) */
initial begin
	clock <= 1'b0;
	forever #5 begin clock <= ~clock;
	end
end

/* TESTING */
initial begin
/* INITIALIZATION */
// Initial
reset <= 1'b1; W <= 1'b0; #6
// Polynomial
reset <= 1'b0; A <= 16'h0010; D <= 221; W <= 1'b1; #10
// LFSR (Seed)
A <= 16'h0012; D <= 120; W <= 1'b1; #10
// CTRL set STOP mode
A <= 16'h0014; D[1:0] <= 2'b00; W <= 1'b1; #10
// End Initialization
W <= 1'b0;

/* RESULT DISPLAY */
$display("\n\n==== TEST SUMMARY ====");
$display("  TEST COUNT: %d", total);
$display("    - PASSED: %d", pass);
$display("    - FAILED: %d", fail);
$display("    - err = %d", err); 
$display("======================\n\n");
end
endmodule: tb_application

/*
	AUTHOR: PHAN HOAI HUONG NGUYEN
	DESCRIPTION: AFU WITH 32-BIT LINEAR FEEDBACK SHIFT REGISTER AS THE APPLICATION UNIT
			- The AFU has four registers at double-word (32-bit aligned) addresses 0 - 8 that
			are required by the CCI-P protocol (see specification for more information)
			as well as three registers that are part of the application logic for this AFU:
				+ Polynomial register: address 0x0010
				+ LFSR Data register:  address 0x0012
				+ Control register:    address 0x0014
	*** Software has to use byte-addresses to access these AFU registers, so in
	software code each of the above addresses would be shifted left two bit positions.
			- Operation of the LFSR:
				+ When Ctrl = 0b00 the LFSR is in stopped mode
				+ Setting Ctrl to 0b01 puts the LFSR into step mode
				+ Setting Ctrl to 0b10 (or 0b11) puts the LFSR into continuous mode
*/

`include "platform_if.vh"
`include "afu_json_info.vh"

module afu (input clock, input reset, input t_if_ccip_Rx rx, output t_if_ccip_Tx tx);

	 /* IO */
    parameter n = 32;
    logic [1:0] Ctrl; // control register
    logic [n-1:0] Q, Poly; // LFSR and polynomial register
    logic [15:0] A; // Address
    logic [n-1:0] D; // Data
    logic W; // Write signal

    // The c0 header is used for memory read responses.
    // The header must be interpreted as an MMIO response when
    // c0 mmmioRdValid or mmioWrValid is set.  In these cases the
    // c0 header is cast into a ReqMmioHdr.
    t_ccip_c0_ReqMmioHdr mmioHdr;
    assign mmioHdr = t_ccip_c0_ReqMmioHdr'(rx.c0.hdr);

    assign A = mmioHdr.address;     // rename address signal
    assign D = rx.c0.data;          // rename data signal
    assign W = rx.c0.mmioWrValid;   // rename write signal
	 
	 /* INSTANTIATE APPLICATION UNIT */
	 application #(.n)(.reset, .clock, .W, .A, .D, .Poly, .Ctrl, .Q);

    // The AFU must respond with its AFU ID in response to MMIO reads of
    // the CCI-P device feature header (DFH).  The AFU ID is a unique ID
    // for a given AFU.  Here we generated one with the "uuidgen"
    // program and stored it in the AFU's JSON file.  Compilation tools
    // automatically invoke the OPAE afu_json_mgr script to extract the 
    // UUID into afu_json_info.vh.
    logic [127:0] afu_id = `AFU_ACCEL_UUID;

    /* Response to memory-mapped IO reads */
	 // TX:
			// C0: MEMORY READ UPSTREAM REQUEST
			// C1: MEMORY WRITE UPSTREAM REQUEST
			// C2: DOWNSTREAM -- MMIO READ RESPONSE TO THE FIU
	 // RX:
			// C0: INTERLEAVES MEMORY RESPONSES, MIMO REQUESTS AND UMsgs
			// C1: RETURNS RESPONSES FOR AFU REQUESTS INITIATED ON TX C1
    always_ff @(posedge clock) begin
        if (reset) begin
            tx.c1.hdr <= '0;
            tx.c1.valid <= '0;
            tx.c0.hdr <= '0;
            tx.c0.valid <= '0;
            tx.c2.hdr <= '0;
            tx.c2.mmioRdValid <= '0;
        end
        else begin
            // Clear read response flag in case there was a response last cycle
            tx.c2.mmioRdValid <= 0;

            // Serve MMIO read requests
            if (rx.c0.mmioRdValid == 1'b1) begin
                // Copy TID, which the host needs to map the response to the request
                tx.c2.hdr.tid <= mmioHdr.tid;
                // Post response
                tx.c2.mmioRdValid <= 1;

                case (mmioHdr.address)
                    // Register 1: AFU header
                    16'h0000: tx.c2.data <= {
                        4'b0001, // Feature type = AFU
                        8'b0,    // reserved
                        4'b0,    // afu minor revision = 0
                        7'b0,    // reserved
                        1'b1,    // end of DFH list = 1
                        24'b0,   // next DFH offset = 0
                        4'b0,    // afu major revision = 0
                        12'b0    // feature ID = 0
                        };

                    // Register 2: AFU_ID_L
                    16'h0002: tx.c2.data <= afu_id[63:0];
						  
                    // Register 3: AFU_ID_H
                    16'h0004: tx.c2.data <= afu_id[127:64];
						  
                    // Register 4: DFH_RSVD0 and DFH_RSVD1
                    16'h0006: tx.c2.data <= 64'h0;
                    16'h0008: tx.c2.data <= 64'h0;

                    // 3 Application Logic Registers
                    16'h0010: tx.c2.data <= 64'(Poly);
                    16'h0012: tx.c2.data <= 64'(Q);
                    16'h0014: tx.c2.data <= 64'(Ctrl);

                    default:  tx.c2.data <= 64'h0;
                endcase
            end
        end
    end
endmodule: afu

//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Tzu-Yun Huang
//	 Editor		: Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : pseudo_DRAM.v
//   Module Name : pseudo_DRAM
//   Release version : v3.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_DRAM(
	clk, rst_n,
	AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
);

input clk, rst_n;
// write address channel
input [31:0] AW_ADDR;	//master
input AW_VALID;			//master
output reg AW_READY;	//slave
// write data channel
input W_VALID;			//master
input [63:0] W_DATA;	//master
output reg W_READY;		//slave
// write response channel
output reg B_VALID;		//slave
output reg [1:0] B_RESP;//slave
input B_READY;			//master
// read address channel
input [31:0] AR_ADDR;	//master
input AR_VALID;			//master
output reg AR_READY;	//slave
// read data channel
output reg [63:0] R_DATA;//slave
output reg R_VALID;		//slave
output reg [1:0] R_RESP;//slave
input R_READY;			//master

//================================================================
// parameters & integer
//================================================================

parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";

integer latency, i, t, latency1, latency2;
//================================================================
// wire & registers 
//================================================================
reg [63:0] DRAM[0:8191];
reg [63:0] w_data;
reg [31:0] ar_addr_r, aw_addr_r;
initial begin
	$readmemh(DRAM_p_r, DRAM);
	AW_READY ='d0;
	W_READY ='d0;
	B_VALID ='d0;
	B_RESP ='d0;
	AR_READY ='d0;
	R_DATA ='d0;
	R_VALID ='d0;
	R_RESP ='d0;
	latency = 0;
	latency1 = 0;
	latency2 = 0;
	w_data = 'd0;
	ar_addr_r = 'd0;
	aw_addr_r = 'd0;
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////



always @(posedge clk) begin
	latency = 0;
	latency1 = 0;
	if (AR_VALID === 0) begin
		check_ar_addr_rst_task;
	end
	if (AW_VALID === 0) begin
		check_aw_addr_rst_task;
	end
	if (W_VALID === 0) begin
		check_w_data_rst_task;
	end
	if (AW_VALID === 1) begin
		aw_addr_r = AW_ADDR;
		check_aw_addr_range_task;
		t = $urandom_range(1,49);
		for (i = 0; i < t; i = i + 1) begin
            check_aw_valid_aw_addr_stable_task;
            check_w_valid_task;
            @(posedge clk);
        end
		AW_READY = 'b1;
		check_w_valid_task;
		@(posedge clk)
		AW_READY = 'b0;
		W_READY = 'b1;
		
		while (W_VALID !== 1) begin
			check_w_valid_cycle_task;
            latency = latency + 1;
			@(posedge clk);
        end

		w_data = W_DATA;
		DRAM[aw_addr_r] = w_data;
		@(posedge clk);
		// if(W_VALID !== 1 || w_data !== W_DATA) begin
		// 	SPEC_DRAM_3_FAIL_task;
		// end
		W_READY = 'b0;
		B_VALID = 'b1;
		//DRAM[aw_addr_r] = w_data;
		// @(posedge clk);
		// W_READY = 'b0;
		// B_VALID = 'b1;
		while (B_READY !== 1) begin
            check_b_ready_cycle_task;
            latency1 = latency1 + 1;
			@(posedge clk);
        end

		@(posedge clk) begin
		B_VALID = 'b0;
		end
	end
	if (AR_VALID === 1) begin
		check_ar_addr_range_task;
		ar_addr_r = AR_ADDR;
		for (i = 0; i < t; i = i + 1) begin
            check_ar_valid_ar_addr_stable_task;
            check_r_ready_task;
            @(posedge clk);
        end
		// t = $urandom_range(1,50);
		// repeat(t) @(posedge clk);
		AR_READY = 'b1;
		check_r_ready_task;
		@(posedge clk)
		AR_READY = 'b0;
		
		R_VALID = 'b1;
		
		R_DATA = DRAM[ar_addr_r];

		while (R_READY !== 1) begin
			//check_r_ready_stable_task;
			check_r_ready_cycle_task;
			latency = latency + 1;
			@(posedge clk);
		end

		@(posedge clk) 
        R_VALID = 1'b0;
        R_DATA = 0;
	end
end


task check_ar_addr_rst_task; begin
	if(AR_ADDR !== 0)
		SPEC_DRAM_1_FAIL_task;
end endtask

task check_aw_addr_rst_task; begin
	if(AW_ADDR !== 0)
		SPEC_DRAM_1_FAIL_task;
end endtask

task check_w_data_rst_task; begin
	if(W_DATA !== 0)
		SPEC_DRAM_1_FAIL_task;
end endtask

task check_ar_addr_range_task;begin
	if(AR_ADDR > 'd8191)
		SPEC_DRAM_2_FAIL_task;
end endtask


task check_aw_addr_range_task;begin
	if(AW_ADDR > 'd8191)
		SPEC_DRAM_2_FAIL_task;
end endtask

task check_ar_valid_ar_addr_stable_task;begin
	if(AR_ADDR !== ar_addr_r || AR_VALID !== 1)
		SPEC_DRAM_3_FAIL_task;
end endtask

task check_aw_valid_aw_addr_stable_task;begin
	if(AW_ADDR !== aw_addr_r || AW_VALID !== 1)
		SPEC_DRAM_3_FAIL_task;
end endtask
			
task check_r_ready_stable_task;begin
	if(R_VALID !== 1)
		SPEC_DRAM_3_FAIL_task;
end endtask

task check_w_valid_w_data_stable_task;begin
	if(w_data !== W_DATA || W_VALID !==1)
		SPEC_DRAM_3_FAIL_task;
end endtask

task check_r_ready_cycle_task;begin
	if (latency > 100) SPEC_DRAM_4_FAIL_task;
end endtask

task check_w_valid_cycle_task;begin
	if (latency > 100) SPEC_DRAM_4_FAIL_task;
end endtask

task check_b_ready_cycle_task;begin
	if (latency1 > 100) SPEC_DRAM_4_FAIL_task;
end endtask


task check_r_ready_task;begin
	if(R_READY !== 0)
		SPEC_DRAM_5_FAIL_task;
end endtask

task check_w_valid_task;begin
	if(W_VALID !== 0)
		SPEC_DRAM_5_FAIL_task;
end endtask

	
task SPEC_DRAM_1_FAIL_task; begin
    $display();
    $display("*************************************************************************");
    $display("*                           SPEC DRAM-1 FAIL                              *");
    $display("*************************************************************************");
    $display();
    $finish;
end endtask

task SPEC_DRAM_2_FAIL_task; begin
    $display();
    $display("*************************************************************************");
    $display("*                           SPEC DRAM-2 FAIL                              *");
    $display("*************************************************************************");
    $display();
    $finish;
end endtask

task SPEC_DRAM_3_FAIL_task; begin
    $display();
    $display("*************************************************************************");
    $display("*                            SPEC DRAM-3 FAIL                             *");
    $display("*************************************************************************");
    $display();
	repeat(10) @(posedge clk);
    $finish;
end endtask

task SPEC_DRAM_4_FAIL_task; begin
    $display();
    $display("*************************************************************************");
    $display("*                            SPEC DRAM-4 FAIL                             *");
    $display("*************************************************************************");
    $display();
    $finish;
end endtask

task SPEC_DRAM_5_FAIL_task; begin
    $display();
    $display("*************************************************************************");
    $display("*                            SPEC DRAM-5 FAIL                             *");
    $display("*************************************************************************");
    $display();
    $finish;
end endtask



//////////////////////////////////////////////////////////////////////

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                 Error message from pseudo_DRAM.v                        *");
end endtask

endmodule

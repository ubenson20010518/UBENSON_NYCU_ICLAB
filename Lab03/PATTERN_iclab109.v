`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [13:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data; 

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;

real CYCLE = `CYCLE_TIME;
integer pat_read;
integer PAT_NUM;
integer total_latency, latency, out_cnt;
integer i_pat;
integer temp, i, t;

initial clk = 0;


reg one;
reg [12:0] two;
reg [15:0] three;
reg [63:0] golden_data;
always #(CYCLE/2.0) clk = ~clk;

initial begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r"); 
    reset_signal_task;

    i_pat = 0;
    total_latency = 0;
    temp = $fscanf(pat_read, "%d", PAT_NUM); 
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);

    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM); //Write down your DRAM Final State
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);		 //Write down your SD CARD Final State
    YOU_PASS_task;
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////

task reset_signal_task; begin
    rst_n     = 'b1;
    in_valid  = 'b0;
    direction = 'bx;
    addr_dram = 'bx;
    addr_sd   = 'bx;
    golden_data  = 'd0;
    total_latency = 0;

    force clk = 0;

    #CYCLE; rst_n = 0;
    #CYCLE; rst_n = 1;

    if (out_valid !== 'b0 || out_data  !== 'b0 || AW_ADDR   !== 'b0 || AW_VALID  !== 'b0 || W_VALID   !== 'b0 || W_DATA    !== 'b0 || B_READY   !== 'b0 || AR_ADDR   !== 'b0 || AR_VALID !== 'b0 || R_READY !== 'b0 || MOSI !== 'b1)
    begin
        $display("SPEC MAIN-1 FAIL");
        // repeat(2) #CYCLE;
        $finish;
    end
    #CYCLE; release clk;
end endtask

task input_task; begin
    temp = $fscanf(pat_read, "%d", one);
    temp = $fscanf(pat_read, "%d", two);
    temp = $fscanf(pat_read, "%d",three);
    t = $urandom_range(1, 4) ;
	repeat(t) @(negedge clk);

    in_valid  = 'b1;
    direction = one;
    addr_dram = two;
    addr_sd   = three;
    

    @(negedge clk);

    in_valid  = 'b0;
    direction = 'bx;
    addr_dram = 'bx;
    addr_sd   = 'bx;
end endtask


task wait_out_valid_task; begin
    latency = 0;
    while (out_valid !==1'b1) begin
        latency = latency + 1;
        if (latency == 10000) begin
            $display("SPEC MAIN-3 FAIL");
			repeat(2)@(negedge clk);
			$finish;
        end
        if (out_data !== 'd0) begin
            $display("SPEC MAIN-2 FAIL");
		    //repeat(9)@(negedge clk);
		    $finish;
        end
        if (!one && R_VALID) begin
            golden_data = u_DRAM.DRAM[two];
        end
        else if (one && W_VALID) begin
            golden_data = u_SD.SD[three];
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask
        
task check_ans_task; begin
    out_cnt = 0;
    if (golden_data !== u_DRAM.DRAM[two] || golden_data !== u_SD.SD[three]) begin
        $display ("SPEC MAIN-6 FAIL");
		// repeat(9) @(negedge clk);
		$finish;
    end
    for (i = 0; i < 8; i = i + 1) begin
        out_cnt = out_cnt +1;
        
        if (out_valid !== 'b1) begin
            $display ("SPEC MAIN-4 FAIL");
		    repeat(9) @(negedge clk);
		    $finish;	
        end
        if (out_valid === 'b1 && B_READY === 'b1) begin
            $display ("SPEC MAIN-6 FAIL");
		    repeat(9) @(negedge clk);
		    $finish;	
        end
        if (out_data !== golden_data[(63 - i*8) -: 8]) begin
            $display ("SPEC MAIN-5 FAIL");
			repeat(9) @(negedge clk);
			$finish;
        end
        
        @(negedge clk);
    end
    if (out_valid !== 'b0) begin
        $display ("SPEC MAIN-4 FAIL");
			repeat(9) @(negedge clk);
			$finish;
    end
    // out_valid turned 0, but out_data still have value
    else if (out_data !== 'd0) begin
        $display("SPEC MAIN-2 FAIL");
		//repeat(9)@(negedge clk);
		$finish;
    end

    total_latency = total_latency + latency;
end endtask


//////////////////////////////////////////////////////////////////////


task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    // write address channel
    .AW_ADDR(AW_ADDR),
    .AW_VALID(AW_VALID),
    .AW_READY(AW_READY),
    // write data channel
    .W_VALID(W_VALID),
    .W_DATA(W_DATA),
    .W_READY(W_READY),
    // write response channel
    .B_VALID(B_VALID),
    .B_RESP(B_RESP),
    .B_READY(B_READY),
    // read address channel
    .AR_ADDR(AR_ADDR),
    .AR_VALID(AR_VALID),
    .AR_READY(AR_READY),
    // read data channel
    .R_DATA(R_DATA),
    .R_VALID(R_VALID),
    .R_RESP(R_RESP),
    .R_READY(R_READY)
);

pseudo_SD u_SD (
    .clk(clk),
    .MOSI(MOSI),
    .MISO(MISO)
);

endmodule



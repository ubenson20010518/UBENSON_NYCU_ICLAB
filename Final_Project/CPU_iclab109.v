//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/


// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################


//==============================================//
//                  Parameter                   //
//==============================================//

parameter IDLE                		= 5'd0;
parameter INITIAL             		= 5'd1;
parameter WAIT_ARREADY_DATA_FIRST	= 5'd2;
parameter WAIT_ARREADY_INST_FIRST   = 5'd3;
parameter LOAD_INST_DATA            = 5'd4;
parameter WAIT_RLAST_INST           = 5'd5;
parameter WAIT_RLAST_DATA           = 5'd6;
parameter IF                  		= 5'd7;
parameter LOAD_INST           		= 5'd8;
parameter ID                  		= 5'd9;
parameter EXE                 		= 5'd10;
parameter MEM                 		= 5'd11;
parameter STORE_DATA          		= 5'd12;
parameter LOAD_DATA           		= 5'd13;
parameter DET                 		= 5'd14;
parameter CMP                 		= 5'd15;
parameter WB_CHECK            		= 5'd16;
parameter WAIT_ARREADY_INST   		= 5'd17;
parameter WAIT_AWREADY	      		= 5'd18;
parameter WAIT_BVALID	      		= 5'd19;
parameter WAIT_ARREADY_DATA   		= 5'd20;
parameter WAIT_AWREADY_SW     		= 5'd21;
parameter WAIT_WREADY_SW       		= 5'd22;
parameter WAIT_BVALID_SW      		= 5'd23;
parameter EXE2			      		= 5'd24;



// axi read
parameter ARID    	= 4'd0;    
parameter ARLEN   	= 7'd127;  
parameter ARSIZE  	= 3'b001;  
parameter ARBURST 	= 2'b01;    
// axi write	
parameter AWID    	= 4'd0;
parameter AWLEN   	= 7'd0;
parameter AWSIZE  	= 3'b001;
parameter AWBURST 	= 2'b01;

parameter WRITE 	= 1'b0;
parameter READ 		= 1'b1;

parameter signed OFFST = 16'h1000;





//####################################################
//               reg & wire
//####################################################

reg [4:0] next_state, current_state;
reg signed  [15:0] pc;
reg [3:0] previous_pc, previous_araddr_data;
reg signed [4:0] immediate;
reg signed [4:0] coeff_a;
reg signed [9:0] coeff_b;
reg func;
reg [2:0] opcode;
reg [3:0] rs, rt, rd;
reg [31:0] araddr_inst, araddr_data;

reg arready_inst_r, arready_data_r;

reg [15:0] DI_INST, DI_DATA;
reg WEB_INST, WEB_DATA;
reg [6:0] ADDR_INST, ADDR_DATA;
reg [6:0] addr_count_inst, addr_count_data;
reg [15:0] instruction_r, data_r;
reg signed [31:0] ALU_out;
reg [4:0] count_det;
reg signed [15:0] addr_DATA_MEM;


reg signed [15:0] rs_value, rt_value, rd_value;
reg signed [63:0] temp;
// reg signed [15:0] core_r0, core_r1, core_r2, core_r3;
// reg signed [15:0] core_r4, core_r5, core_r6, core_r7;
// reg signed [15:0] core_r8, core_r9, core_r10, core_r11;
// reg signed [15:0] core_r12, core_r13, core_r14, core_r15;
reg signed [31:0] result_16X16_a, result_16X16_b;
reg signed [63:0] result_32X32;
reg signed [66:0] sum;
reg after_first_inst_flag;


wire arvalid_inst, arvalid_data, rready_inst, rready_data;
wire load_complete_flag, load_inst_complete_flag, store_complete_flag, load_data_complete_flag;
wire out_of_bound_inst, out_of_bound_data;
wire [15:0] instruction;
wire [15:0] data;

wire [15:0] DI_INST_buffer0, DI_INST_buffer1, DI_INST_buffer2, DI_INST_buffer3, DI_INST_buffer4, DI_INST_buffer5;
wire WEB_INST_buffer0, WEB_INST_buffer1,WEB_INST_buffer2, WEB_INST_buffer3;


//==============================================//
//                     FSM                      //
//==============================================//

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		current_state <= IDLE;
	end
	else begin
		current_state <= next_state;
	end
end

always @(*) begin
  	case(current_state)
    	IDLE: next_state = INITIAL;
    	INITIAL: begin // maybe arready_m_inf[1] and arready_m_inf[0] high at a same time
      		if (arready_m_inf == 2'b11) begin
				next_state = LOAD_INST_DATA;
      		end
			else if (arready_m_inf[1]) begin
        		next_state = WAIT_ARREADY_DATA_FIRST;
      		end
			else if (arready_m_inf[0]) begin
				next_state = WAIT_ARREADY_INST_FIRST;
			end
			else begin
				next_state = INITIAL;
			end
		end
		WAIT_ARREADY_DATA_FIRST: begin
			if (arready_m_inf[0]) begin
				next_state = LOAD_INST_DATA;
			end
			else begin
				next_state = WAIT_ARREADY_DATA_FIRST;
			end
		end
		WAIT_ARREADY_INST_FIRST: begin
			if (arready_m_inf[1]) begin
				next_state = LOAD_INST_DATA;
			end
			else begin
				next_state = WAIT_ARREADY_INST_FIRST;
			end
		end
		LOAD_INST_DATA: begin
			if (rlast_m_inf == 2'b11) begin
				next_state = IF;
			end
			else if (rlast_m_inf[1]) begin
				next_state = WAIT_RLAST_DATA;
			end
			else if (rlast_m_inf[0]) begin
				next_state = WAIT_RLAST_INST;
			end
			else begin
				next_state = LOAD_INST_DATA;
			end
		end
		WAIT_RLAST_DATA: begin
			if (rlast_m_inf[0]) begin
				next_state = IF;
			end
			else begin
				next_state = WAIT_RLAST_DATA;
			end
		end
		WAIT_RLAST_INST: begin
			if (rlast_m_inf[1]) begin
				next_state = IF;
			end
			else begin
				next_state = WAIT_RLAST_INST;
			end
		end
		IF: begin
			if (out_of_bound_inst) begin
				next_state = WAIT_ARREADY_INST;
			end
			else begin
				next_state = ID;
			end
		end
		WAIT_ARREADY_INST: begin
			if (arready_m_inf[1]) begin
				next_state = LOAD_INST;
			end
			else begin
				next_state = WAIT_ARREADY_INST;
			end
		end
		LOAD_INST: begin
			if (rlast_m_inf[1]) begin
				next_state = IF;
			end
			else begin
				next_state = LOAD_INST;
			end
		end
		ID: next_state = EXE;
		DET: begin
			if (count_det == 25) begin
				next_state = CMP;
			end
			else begin
				next_state = DET;
			end
		end
		CMP: next_state = WB_CHECK;
		EXE: begin
			if (opcode == 3'b000 || opcode == 3'b001 || opcode == 3'b100) begin
				next_state = WB_CHECK;
			end
			else if (opcode == 3'b111) begin
				next_state = DET;
			end
			else begin
				next_state = MEM;
			end
		end
		// EXE2 : next_state = MEM;
		MEM: begin
			if (opcode == 3'b011) begin
				next_state = WAIT_AWREADY_SW;
			end
			else if (out_of_bound_data) begin
				next_state = WAIT_ARREADY_DATA;
			end
			else begin
				next_state = WB_CHECK;
			end
		end
		WAIT_ARREADY_DATA: begin
			if (arready_m_inf[0]) begin
				next_state = LOAD_DATA;
			end
			else begin
				next_state = WAIT_ARREADY_DATA;
			end
		end
		LOAD_DATA: begin
			if (rlast_m_inf[0]) begin
				next_state = MEM;
			end
			else begin
				next_state = LOAD_DATA;
			end
		end
		WAIT_AWREADY_SW: begin
			if (awready_m_inf) begin
				next_state = WAIT_WREADY_SW;
			end
			else begin
				next_state = WAIT_AWREADY_SW;
			end
		end
		WAIT_WREADY_SW: begin
			if (wready_m_inf) begin
				next_state = WAIT_BVALID_SW;
			end
			else begin
				next_state = WAIT_WREADY_SW;
			end
		end
		WAIT_BVALID_SW: begin
			if (bvalid_m_inf) begin
				next_state = WB_CHECK;
			end
			else begin
				next_state = WAIT_BVALID_SW;
			end
		end
		WB_CHECK: next_state = IF;
		default: next_state = IDLE;
	endcase
end




// pc counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		pc <= 0;
	end
	else if (current_state == WB_CHECK && opcode == 3'b100) begin
		pc <= (rs_value == rt_value)? pc + immediate + 1 : pc + 1;
	end
	else if (current_state == WB_CHECK) begin
		pc <= pc + 1;
	end
	else begin
		pc <= pc;
	end
end

// araddr instruction
always @(*) begin
	araddr_inst = {20'h00001, pc[10:7], 8'h00};
end

// araddr data
always @(*) begin
	araddr_data = {20'h00001, addr_DATA_MEM[11:8], 8'h00};
end

// store previous pc to check whether out of bound
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		previous_pc <= 0;
	end
	else if (current_state == WAIT_ARREADY_INST) begin
		previous_pc <= pc[10:7];
	end
	else begin
		previous_pc <= previous_pc;
	end
end

// store previous araddr_data to check whether out of bound
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		previous_araddr_data <= 0;
	end
	else if (current_state == WAIT_ARREADY_DATA) begin
		previous_araddr_data <= araddr_data[11:8];
	end
	else begin
		previous_araddr_data <= previous_araddr_data;
	end
end

assign out_of_bound_inst = (previous_pc != pc[10:7]);
assign out_of_bound_data = (previous_araddr_data != araddr_data[11:8]);
  

//==============================================//
//                  AXI SIGNAL                  //
//==============================================//


// axi read
assign arid_m_inf = {ARID, ARID};
assign araddr_m_inf = {araddr_inst, araddr_data};
assign arlen_m_inf = {ARLEN, ARLEN};
assign arsize_m_inf = {ARSIZE, ARSIZE};
assign arburst_m_inf = {ARBURST, ARBURST};
assign arvalid_m_inf = {arvalid_inst, arvalid_data};

assign rready_m_inf = {rready_inst, rready_data};


assign arvalid_inst = (current_state == WAIT_ARREADY_INST_FIRST || current_state == WAIT_ARREADY_INST || current_state == INITIAL);
assign arvalid_data = (current_state == WAIT_ARREADY_DATA_FIRST || current_state == WAIT_ARREADY_DATA || current_state == INITIAL);


assign rready_inst = (current_state == LOAD_INST_DATA || current_state == WAIT_RLAST_INST || current_state == LOAD_INST);
assign rready_data = (current_state == LOAD_INST_DATA || current_state == WAIT_RLAST_DATA || current_state == LOAD_DATA);


// axi write
assign awid_m_inf = AWID;
assign awaddr_m_inf = {16'b0, addr_DATA_MEM};
assign awsize_m_inf  = AWSIZE;
assign awburst_m_inf = AWBURST;
assign awlen_m_inf   = AWLEN;
assign awvalid_m_inf = (current_state == WAIT_AWREADY_SW);

assign wdata_m_inf = rt_value;
assign wlast_m_inf = (current_state == WAIT_WREADY_SW);
assign wvalid_m_inf = (current_state == WAIT_WREADY_SW);
assign bready_m_inf = (current_state == WAIT_BVALID_SW);


// choose DI_INST ADDR_INST WEB_INST
always @(*) begin
	if ((current_state == LOAD_INST_DATA || current_state == WAIT_RLAST_INST || current_state == LOAD_INST) && rvalid_m_inf[1]) begin
		DI_INST = rdata_m_inf[31:16];
		// WEB_INST = WRITE;
		ADDR_INST = addr_count_inst;
	end
	else if (current_state == IF || current_state == ID) begin
		DI_INST = 0;
		// WEB_INST = READ;
		ADDR_INST = pc[6:0];
	end
	else begin
		DI_INST = 0;
		// WEB_INST = READ;
		ADDR_INST = 0;
	end
end

// assign DI_INST_buffer0 = (rvalid_m_inf[1])? rdata_m_inf[31:16] : 0;
// assign DI_INST_buffer1 = (rvalid_m_inf[1])? DI_INST_buffer0 : 0;
// assign DI_INST_buffer2 = (rvalid_m_inf[1])? DI_INST_buffer1 : 0;
// assign DI_INST_buffer3 = (rvalid_m_inf[1])? DI_INST_buffer2 : 0;
// assign DI_INST_buffer4 = (rvalid_m_inf[1])? DI_INST_buffer3 : 0;
// assign DI_INST_buffer5 = (rvalid_m_inf[1])? DI_INST_buffer4 : 0;
// always @(*) begin
// 	DI_INST = (rvalid_m_inf[1])? rdata_m_inf[31:16] : 0;
// end

assign WEB_INST_buffer0 = (rvalid_m_inf[1])? WRITE: READ;
assign WEB_INST_buffer1 = (rvalid_m_inf[1])? WEB_INST_buffer0: READ;
assign WEB_INST_buffer2 = (rvalid_m_inf[1])? WEB_INST_buffer1: READ;
assign WEB_INST_buffer3 = (rvalid_m_inf[1])? WEB_INST_buffer2: READ;
always @(*) begin
	WEB_INST = (rvalid_m_inf[1])? WEB_INST_buffer3: READ;
end

SRAM_128X16 INSTRUCTION_MEM (
    .CK(clk),  .WEB(WEB_INST), .OE(1'b1),  .CS(1'b1),

    .A0(ADDR_INST[0]),  .A1(ADDR_INST[1]),  .A2(ADDR_INST[2]),  .A3(ADDR_INST[3]),  .A4(ADDR_INST[4]),  .A5(ADDR_INST[5]),  .A6(ADDR_INST[6]),

    .DI0(DI_INST[0]),   .DI1(DI_INST[1]),   .DI2(DI_INST[2]),   .DI3(DI_INST[3]),
    .DI4(DI_INST[4]),   .DI5(DI_INST[5]),   .DI6(DI_INST[6]),   .DI7(DI_INST[7]),
    .DI8(DI_INST[8]),   .DI9(DI_INST[9]),   .DI10(DI_INST[10]), .DI11(DI_INST[11]),
    .DI12(DI_INST[12]), .DI13(DI_INST[13]), .DI14(DI_INST[14]), .DI15(DI_INST[15]),

    .DO0(instruction[0]),   .DO1(instruction[1]),   .DO2(instruction[2]),   .DO3(instruction[3]),
    .DO4(instruction[4]),   .DO5(instruction[5]),   .DO6(instruction[6]),   .DO7(instruction[7]),
    .DO8(instruction[8]),   .DO9(instruction[9]),   .DO10(instruction[10]), .DO11(instruction[11]),
    .DO12(instruction[12]), .DO13(instruction[13]), .DO14(instruction[14]), .DO15(instruction[15])  
);


// store instruction
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		instruction_r <= 0;
	end
	else if (current_state == ID) begin
		instruction_r <= instruction;
	end
	else begin
		instruction_r <= instruction_r;
	end
end

// count SRAM address for instruction
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr_count_inst <= 0;
	end
	else if ((current_state == LOAD_INST_DATA || current_state == WAIT_RLAST_INST || current_state == LOAD_INST)) begin
		addr_count_inst <= (rvalid_m_inf[1] && rready_m_inf[1])? addr_count_inst + 1 : addr_count_inst;
	end
	else begin
		addr_count_inst <= 0;
	end
end

// choose DI_DATA ADDR_DATA WEB_DATA
always @(*) begin
	if ((current_state == LOAD_INST_DATA || current_state == WAIT_RLAST_DATA || current_state == LOAD_DATA) && rvalid_m_inf[0]) begin
		DI_DATA = rdata_m_inf[15:0];
		WEB_DATA = WRITE;
		ADDR_DATA = addr_count_data;
	end
	else if (current_state == WAIT_AWREADY_SW && !out_of_bound_data) begin // sw inst
		DI_DATA = rt_value;
		WEB_DATA = WRITE;
		ADDR_DATA = addr_DATA_MEM[7:1];
	end
	else if (current_state == MEM || current_state == WB_CHECK) begin // lw inst
		DI_DATA = 0;
		WEB_DATA = READ;
		ADDR_DATA = addr_DATA_MEM[7:1];
	end
	else begin
		DI_DATA = 0;
		WEB_DATA = READ;
		ADDR_DATA = 0;
	end
end


// addr_DATA_MEM
always @(*) begin
	addr_DATA_MEM = ((rs_value + immediate) <<< 1) + OFFST;
end

SRAM_128X16 DATA_MEM (
    .CK(clk),  .WEB(WEB_DATA), .OE(1'b1),  .CS(1'b1),

    .A0(ADDR_DATA[0]),  .A1(ADDR_DATA[1]),  .A2(ADDR_DATA[2]),  .A3(ADDR_DATA[3]),  .A4(ADDR_DATA[4]),  .A5(ADDR_DATA[5]),  .A6(ADDR_DATA[6]),

    .DI0(DI_DATA[0]),   .DI1(DI_DATA[1]),   .DI2(DI_DATA[2]),   .DI3(DI_DATA[3]),
    .DI4(DI_DATA[4]),   .DI5(DI_DATA[5]),   .DI6(DI_DATA[6]),   .DI7(DI_DATA[7]),
    .DI8(DI_DATA[8]),   .DI9(DI_DATA[9]),   .DI10(DI_DATA[10]), .DI11(DI_DATA[11]),
    .DI12(DI_DATA[12]), .DI13(DI_DATA[13]), .DI14(DI_DATA[14]), .DI15(DI_DATA[15]),

    .DO0(data[0]),   .DO1(data[1]),   .DO2(data[2]),   .DO3(data[3]),
    .DO4(data[4]),   .DO5(data[5]),   .DO6(data[6]),   .DO7(data[7]),
    .DO8(data[8]),   .DO9(data[9]),   .DO10(data[10]), .DO11(data[11]),
    .DO12(data[12]), .DO13(data[13]), .DO14(data[14]), .DO15(data[15])  
);

// store data
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_r <= 0;
	end
	else if (next_state == WB_CHECK) begin
		data_r <= data;
	end
	else begin
		data_r <= data_r;
	end
end

// count SRAM address for data
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr_count_data <= 0;
	end
	else if ((current_state == LOAD_INST_DATA || current_state == WAIT_RLAST_DATA || current_state == LOAD_DATA)) begin
		addr_count_data <= (rvalid_m_inf[0] && rready_m_inf[0])? addr_count_data + 1 : addr_count_data;
	end
	else begin
		addr_count_data <= 0;
	end
end

// choose rs rt rd func immediate coeff_a coeff_b
always @(*) begin
	opcode = instruction_r[15:13];
	rs = instruction_r[12:9];
	rt = instruction_r[8:5];
	rd = instruction_r[4:1];
	func = instruction_r[0];
	immediate = instruction_r[4:0];
	coeff_a = {1'b0, instruction_r[12:9]};
	coeff_b = {1'b0, instruction_r[8:0]};
end

// save rs_value
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rs_value <= 0;
	end
	else if (current_state == EXE) begin
		case(rs)
			0:  rs_value <= core_r0;
			1:  rs_value <= core_r1;
			2:  rs_value <= core_r2;
			3:  rs_value <= core_r3;
			4:  rs_value <= core_r4;
			5:  rs_value <= core_r5;
			6:  rs_value <= core_r6;
			7:  rs_value <= core_r7;
			8:  rs_value <= core_r8;
			9:  rs_value <= core_r9;
			10: rs_value <= core_r10;
			11: rs_value <= core_r11;
			12: rs_value <= core_r12;
			13: rs_value <= core_r13;
			14: rs_value <= core_r14;
			15: rs_value <= core_r15;
			default: rs_value <= rs_value;
		endcase
	end
	else begin
		rs_value <= rs_value;
	end
end

// save rt_value
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rt_value <= 0;
	end
	else if (current_state == EXE) begin
		case(rt)
			0:  rt_value <= core_r0;
			1:  rt_value <= core_r1;
			2:  rt_value <= core_r2;
			3:  rt_value <= core_r3;
			4:  rt_value <= core_r4;
			5:  rt_value <= core_r5;
			6:  rt_value <= core_r6;
			7:  rt_value <= core_r7;
			8:  rt_value <= core_r8;
			9:  rt_value <= core_r9;
			10: rt_value <= core_r10;
			11: rt_value <= core_r11;
			12: rt_value <= core_r12;
			13: rt_value <= core_r13;
			14: rt_value <= core_r14;
			15: rt_value <= core_r15;
			default: rt_value <= rt_value;
		endcase
	end
	else begin
		rt_value <= rt_value;
	end
end


// compute ALU_out
always @(*) begin
	if (current_state == WB_CHECK) begin
		case(opcode)
			3'b000: ALU_out = (func)? rs_value - rt_value : rs_value + rt_value;
			3'b001: ALU_out = (func)? rs_value * rt_value : (rs_value < rt_value);
			3'b111: ALU_out = (temp > 32767)? 32767 : (temp < -32768)? -32768 : temp;
			default: ALU_out = 0;
		endcase
	end
	// else if (current_state == WB_CHECK) begin
	// 	ALU_out = (temp > 32767)? 32767 : (temp < -32768)? -32768 : temp;
	// end
	else begin
		ALU_out = 0;
	end
end

//==============================================//
//                DETERMINANT                   //
//==============================================//

// count det
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_det <= 0;
	end
	else if (current_state == DET) begin
		count_det <= count_det + 1;
	end
	else begin
		count_det <= 0;
	end
end

// matrix
// always @(*) begin
// 	A11 = core_r0;	A12 = core_r1;	A13 = core_r2; 	A14 = core_r3;  
// 	A21 = core_r4;	A22 = core_r5;	A23 = core_r6;	A24 = core_r7; 
// 	A31 = core_r8;	A32 = core_r9;	A33 = core_r10;	A34 = core_r11;
// 	A41 = core_r12;	A42 = core_r13;	A43 = core_r14;	A44 = core_r15;
// end

// multiply 16bit X 16bit a	
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		result_16X16_a <= 0;
	end
	else if (current_state == DET) begin
		case(count_det)
			0: result_16X16_a <= core_r0 * core_r5;
			1: result_16X16_a <= core_r0 * core_r6;
			2: result_16X16_a <= core_r0 * core_r7;
			3: result_16X16_a <= core_r0 * core_r7;
			4: result_16X16_a <= core_r0 * core_r6;
			5: result_16X16_a <= core_r0 * core_r5;
			6: result_16X16_a <= core_r1 * core_r4;
			7: result_16X16_a <= core_r2 * core_r4;
			8: result_16X16_a <= core_r3 * core_r4;
			9: result_16X16_a <= core_r3 * core_r4;
			10:result_16X16_a <= core_r2 * core_r4;
			11:result_16X16_a <= core_r1 * core_r4;
			12:result_16X16_a <= core_r1 * core_r6;
			13:result_16X16_a <= core_r2 * core_r7;
			14:result_16X16_a <= core_r3 * core_r5;
			15:result_16X16_a <= core_r3 * core_r6;
			16:result_16X16_a <= core_r2 * core_r5;
			17:result_16X16_a <= core_r1 * core_r7;
			18:result_16X16_a <= core_r1 * core_r6;
			19:result_16X16_a <= core_r2 * core_r7;
			20:result_16X16_a <= core_r3 * core_r5;
			21:result_16X16_a <= core_r3 * core_r6;
			22:result_16X16_a <= core_r2 * core_r5;
			23:result_16X16_a <= core_r1 * core_r7;
			default: result_16X16_a <= result_16X16_a;
		endcase
	end
	else begin
		result_16X16_a <= 0;
	end
end

// multiply 16bit X 16bit b
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		result_16X16_b <= 0;
	end
	else if (current_state == DET) begin
		case(count_det)
			0: result_16X16_b <= core_r10 * core_r15;
			1: result_16X16_b <= core_r11 * core_r13;
			2: result_16X16_b <= core_r9 * core_r14;
			3: result_16X16_b <= core_r10 * core_r13;
			4: result_16X16_b <= core_r9 * core_r15;
			5: result_16X16_b <= core_r11 * core_r14;
			6: result_16X16_b <= core_r10 * core_r15;
			7: result_16X16_b <= core_r11 * core_r13;
			8: result_16X16_b <= core_r9 * core_r14;
			9: result_16X16_b <= core_r10 * core_r13;
			10:result_16X16_b <= core_r9 * core_r15;
			11:result_16X16_b <= core_r11 * core_r14;
			12:result_16X16_b <= core_r8 * core_r15;
			13:result_16X16_b <= core_r8 * core_r13;
			14:result_16X16_b <= core_r8 * core_r14;
			15:result_16X16_b <= core_r8 * core_r13;
			16:result_16X16_b <= core_r8 * core_r15;
			17:result_16X16_b <= core_r8 * core_r14;
			18:result_16X16_b <= core_r11 * core_r12;
			19:result_16X16_b <= core_r9 * core_r12;
			20:result_16X16_b <= core_r10 * core_r12;
			21:result_16X16_b <= core_r9 * core_r12;
			22:result_16X16_b <= core_r11 * core_r12;
			23:result_16X16_b <= core_r10 * core_r12;
			default: result_16X16_b <= result_16X16_b;
		endcase
	end
	else begin
		result_16X16_b <= 0;
	end
end

// multiply 32bit X 32bit
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		result_32X32 <= 0;
	end
	else if (current_state == DET) begin
		result_32X32 <= result_16X16_a * result_16X16_b;
	end
	else begin
		result_32X32 <= 0;
	end
end

// sum all
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sum <= 0;
	end
	else if (current_state == WB_CHECK) begin
		sum <= 0;
	end
	else if (current_state == DET) begin
		case(count_det)
			2, 3, 4, 11, 12, 13, 14, 15, 16, 23, 24, 25: sum <= sum + result_32X32;
			5, 6, 7, 8, 9, 10, 17, 18, 19, 20, 21, 22 :  sum <= sum - result_32X32;
			default: sum <= sum;
		endcase	
	end
	else begin
		sum <= sum;
	end
end

// shift operation
always @(*) begin
	if (current_state == WB_CHECK) begin
		temp = (sum >>> ({coeff_a[3:0], 1'b0})) + coeff_b;
	end
	else begin
		temp = 0;
	end
end


// write back reset to 10 for pattern
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r0  <= 0;
		core_r1  <= 0;
		core_r2  <= 0;
		core_r3  <= 0;
		core_r4  <= 0;
		core_r5  <= 0;
		core_r6  <= 0;
		core_r7  <= 0;
		core_r8  <= 0;
		core_r9  <= 0;
		core_r10 <= 0;
		core_r11 <= 0;
		core_r12 <= 0;
		core_r13 <= 0;
		core_r14 <= 0;
		core_r15 <= 0;
	end
	else if (current_state == WB_CHECK) begin
		if (opcode == 3'b000 || opcode == 3'b001) begin
			case(rd)
				0:  core_r0  <= ALU_out;
				1:  core_r1  <= ALU_out;
				2:  core_r2  <= ALU_out;
				3:  core_r3  <= ALU_out;
				4:  core_r4  <= ALU_out;
				5:  core_r5  <= ALU_out;
				6:  core_r6  <= ALU_out;
				7:  core_r7  <= ALU_out;
				8:  core_r8  <= ALU_out;
				9:  core_r9  <= ALU_out;
				10: core_r10 <= ALU_out;
				11: core_r11 <= ALU_out;
				12: core_r12 <= ALU_out;
				13: core_r13 <= ALU_out;
				14: core_r14 <= ALU_out;
				15: core_r15 <= ALU_out;
			endcase
		end
		else if (opcode == 3'b111) begin
			core_r0 <= ALU_out;
		end
		else if (opcode == 3'b010) begin
			case(rt)
				0:  core_r0  <= data;
				1:  core_r1  <= data;
				2:  core_r2  <= data;
				3:  core_r3  <= data;
				4:  core_r4  <= data;
				5:  core_r5  <= data;
				6:  core_r6  <= data;
				7:  core_r7  <= data;
				8:  core_r8  <= data;
				9:  core_r9  <= data;
				10: core_r10 <= data;
				11: core_r11 <= data;
				12: core_r12 <= data;
				13: core_r13 <= data;
				14: core_r14 <= data;
				15: core_r15 <= data;
			endcase
		end
	end
	else begin
		core_r0  <= core_r0 ;
		core_r1  <= core_r1 ;
		core_r2  <= core_r2 ;
		core_r3  <= core_r3 ;
		core_r4  <= core_r4 ;
		core_r5  <= core_r5 ;
		core_r6  <= core_r6 ;
		core_r7  <= core_r7 ;
		core_r8  <= core_r8 ;
		core_r9  <= core_r9 ;
		core_r10 <= core_r10;
		core_r11 <= core_r11;
		core_r12 <= core_r12;
		core_r13 <= core_r13;
		core_r14 <= core_r14;
		core_r15 <= core_r15;
	end
end
	

//==============================================//
//                    OUTPUT                    //
//==============================================//

// mark the first instruction flag
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		after_first_inst_flag <= 0;
	end
	else if (current_state == ID) begin
		after_first_inst_flag <= 1;
	end
	else begin
		after_first_inst_flag <= after_first_inst_flag;
	end
end



// output
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		IO_stall <= 1;
	end
	// else if (next_state == ID && instruction_r != 0) begin
	// else if (current_state == WB_CHECK) begin
	else if (next_state == ID && after_first_inst_flag) begin
		IO_stall <= 0;
	end
	else begin
		IO_stall <= 1;
	end
end

endmodule




















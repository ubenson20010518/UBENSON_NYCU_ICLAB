//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Midterm Proejct            : MRA  
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
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
	   rready_m_inf,
	
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
	   bready_m_inf 
);

// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// AXI CONSTANTS
// (1)	axi read channel
parameter ARID    = 4'd0;    // ID = 0
parameter ARLEN   = 8'd127;  // Burst Length
parameter ARSIZE  = 3'b100;  // 16 Bytes per Transfer
parameter ARBURST = 2'd1;    // INCR mode
// (2) 	axi write channel
parameter AWID    = 4'd0;
parameter AWLEN   = 8'd127;
parameter AWSIZE  = 3'b100;
parameter AWBURST = 2'd1;

parameter ID_WIDTH   = 4; 
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 128;
parameter READ  = 1'b1;
parameter WRITE = 1'b0;

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------





// FSM
`define STATE_BITS 4
parameter IDLE 					= `STATE_BITS'd0;
parameter INPUT_SAVE 			= `STATE_BITS'd1;
parameter WRITE_WEIGHT_SRAM 	= `STATE_BITS'd2;
parameter WAIT_ARREADY			= `STATE_BITS'd3;
parameter WRITE_LOCATION_SRAM 	= `STATE_BITS'd4;
parameter PROPAGATION 			= `STATE_BITS'd5;
parameter RETRACE 				= `STATE_BITS'd6;
parameter MAP_INITIAL			= `STATE_BITS'd7;
parameter CLEAN 				= `STATE_BITS'd8;
parameter WAIT_AWREADY 			= `STATE_BITS'd9;
parameter WRITE_RESULT_DRAM 	= `STATE_BITS'd10;
parameter WAIT_BVALID 			= `STATE_BITS'd11;

// path map state
parameter EMPTY = 0;
parameter BLOCKED = 1;
parameter TWO = 2;
parameter THREE = 3;



integer i, j;

// ===============================================================
//  					REG / WIRE
// ===============================================================


reg [`STATE_BITS-1:0] current_state, next_state;
reg [4:0] frame_id_r;
reg count_2;
reg [3:0] count_net_id;
reg [3:0] net_id_r [0:14];
reg [5:0] source_x_r [0:14], source_y_r [0:14], sink_x_r [0:14], sink_y_r [0:14];
reg [5:0] x_r, y_r;

reg WEB_LOC,  WEB_WEI;
reg [127:0] DI_LOC,   DI_WEI;
reg [6:0] ADDR_LOC, ADDR_WEI;
wire[127:0] DO_LOC,   DO_WEI;

reg [6:0] addr_count;
reg [1:0] count_4;
reg [1:0] pro_seq;
 
reg [1:0] path_map_r [0:63][0:63];
reg [127:0] net_id_data;
reg [3:0] retrace_cost;

wire [31:0] addr_location, addr_weight;
wire propagate_done_flag, retrace_done_flag;





// ===============================================================
//  					DESIGN
// ===============================================================


// FSM
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		current_state <= 0;
	end
	else begin
		current_state <= next_state;
	end
end

always @(*) begin
	case(current_state) 
		IDLE : 					next_state = (in_valid)? INPUT_SAVE : IDLE;
		INPUT_SAVE : 			next_state = (arready_m_inf)? WRITE_WEIGHT_SRAM : INPUT_SAVE;
		WRITE_WEIGHT_SRAM : 	next_state = (rlast_m_inf)? WAIT_ARREADY : WRITE_WEIGHT_SRAM;
		WAIT_ARREADY : 			next_state = (arready_m_inf)? WRITE_LOCATION_SRAM : WAIT_ARREADY;
		WRITE_LOCATION_SRAM : 	next_state = (rlast_m_inf)? MAP_INITIAL : WRITE_LOCATION_SRAM;
		MAP_INITIAL : 			next_state = PROPAGATION;
		PROPAGATION : 			next_state = (propagate_done_flag)? RETRACE : PROPAGATION;
		RETRACE : begin
								if (net_id_r[1] == 0 && retrace_done_flag == 1)begin
									next_state = WAIT_AWREADY;
								end
								else if (retrace_done_flag == 1) begin
									next_state = CLEAN;
								end
								else begin
									next_state = RETRACE;
								end
		end
		CLEAN : 				next_state = MAP_INITIAL;
		WAIT_AWREADY : 			next_state = (awready_m_inf)? WRITE_RESULT_DRAM : WAIT_AWREADY;
		WRITE_RESULT_DRAM :		next_state = (addr_count == 127)? WAIT_BVALID : WRITE_RESULT_DRAM;
		WAIT_BVALID : 			next_state = (bvalid_m_inf)? IDLE : WAIT_BVALID;
		default : 				next_state = IDLE;
	endcase
end

assign propagate_done_flag = (path_map_r[sink_y_r[0]][sink_x_r[0]][1]);
assign retrace_done_flag = (x_r == source_x_r[0] && y_r == source_y_r[0]) & (current_state == RETRACE && count_2);


// count_2
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_2 <= 0;
	end
	else if (in_valid) begin
		count_2 <= ~count_2;
	end
	// else if (current_state == WRITE_LOCATION_SRAM) begin
	// 	count_2 <= ~count_2;
	// end
	else if (current_state == RETRACE) begin
		count_2 <= ~count_2;
	end
	else begin
		count_2 <= 0;
	end
end

// count net id
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_net_id <= 0;
	end
	else if (in_valid && count_2) begin
		count_net_id <= count_net_id + 1;
	end
	else if (current_state == IDLE) begin
		count_net_id <= 0;
	end
	else begin
		count_net_id <= count_net_id;
	end
end

// store frame_id
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		frame_id_r <= 0;
	end
	else if (in_valid) begin
		frame_id_r <= frame_id;
	end
	else begin
		frame_id_r <= frame_id_r;
	end
end

// store net_id
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i = 0; i < 15; i = i + 1) begin
			net_id_r[i] <= 0;
		end
	end
	else if (in_valid) begin
		net_id_r[count_net_id] <= net_id;
	end
	else if (current_state == IDLE) begin
		for (i = 0; i < 15; i = i + 1) begin
			net_id_r[i] <= 0;
		end
	end
	else if (next_state == CLEAN) begin
		for (i = 0; i < 14; i = i + 1) begin
			net_id_r[i] <= net_id_r[i+1];
		end
		net_id_r[14] <= 0;
	end
	else begin
		for (i = 0; i < 15; i = i + 1) begin
			net_id_r[i] <= net_id_r[i];
		end
	end 
end

// store source
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i = 0; i < 15; i = i + 1) begin
			source_x_r[i] <= 0;
			source_y_r[i] <= 0;
		end
	end
	else if (in_valid && ~count_2) begin
		source_x_r[count_net_id] <= loc_x;
		source_y_r[count_net_id] <= loc_y;
	end
	else if (current_state == IDLE) begin
		for (i = 0; i < 15; i = i + 1) begin
			source_x_r[i] <= 0;
			source_y_r[i] <= 0;
		end
	end
	else if (next_state == CLEAN) begin
		for (i = 0; i < 14; i = i + 1) begin
			source_x_r[i] <= source_x_r[i+1];
			source_y_r[i] <= source_y_r[i+1];
		end
		source_x_r[14] <= 0;
		source_y_r[14] <= 0;
	end
	else begin
		for (i = 0; i < 15; i = i + 1) begin
			source_x_r[i] <= source_x_r[i];
			source_y_r[i] <= source_y_r[i];
		end
	end
end

// store sink
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i = 0; i < 15; i = i + 1) begin
			sink_x_r[i] <= 0;
			sink_y_r[i] <= 0;
		end
	end
	else if (in_valid && count_2) begin
		sink_x_r[count_net_id] <= loc_x;
		sink_y_r[count_net_id] <= loc_y;
	end
	else if (current_state == IDLE) begin
		for (i = 0; i < 15; i = i + 1) begin
			sink_x_r[i] <= 0;
			sink_y_r[i] <= 0;
		end
	end
	else if (next_state == CLEAN) begin
		for (i = 0; i < 14; i = i + 1) begin
			sink_x_r[i] <= sink_x_r[i+1];
			sink_y_r[i] <= sink_y_r[i+1];
		end
		sink_x_r[14] <= 0;
		sink_y_r[14] <= 0;
	end
	else begin
		for (i = 0; i < 15; i = i + 1) begin
			sink_x_r[i] <= sink_x_r[i];
			sink_y_r[i] <= sink_y_r[i];
		end
	end
end

// set address for reading DRAM location
assign addr_location = {16'h0001, frame_id_r, 11'd0};

// set address for reading DRAM weight

assign addr_weight = {16'h0002, frame_id_r, 11'd0};

// set DRAM read channel
assign arvalid_m_inf = (current_state == INPUT_SAVE || current_state == WAIT_ARREADY)? 1 : 0;
assign arid_m_inf = 0;
assign arburst_m_inf = 1;
assign arsize_m_inf = 4;
assign arlen_m_inf = 127;
assign rready_m_inf = (current_state == WRITE_WEIGHT_SRAM || current_state == WRITE_LOCATION_SRAM)? 1 : 0;
assign araddr_m_inf = (current_state == INPUT_SAVE || current_state == WRITE_WEIGHT_SRAM)? addr_weight : addr_location;


// set DRAM write channel
assign awvalid_m_inf = (current_state == WAIT_AWREADY)? 1 : 0;
assign awid_m_inf = 0;
assign awburst_m_inf = 1;
assign awsize_m_inf = 4;
assign awlen_m_inf = 127;
assign awaddr_m_inf = (current_state == WAIT_AWREADY || current_state == WRITE_RESULT_DRAM)?  addr_location : 0;

assign wdata_m_inf = (current_state == WRITE_RESULT_DRAM) ? DO_LOC : 0;
assign wvalid_m_inf = (current_state == WRITE_RESULT_DRAM);
assign wlast_m_inf = (addr_count == 127 && current_state == WRITE_RESULT_DRAM);
assign bready_m_inf = (current_state == WAIT_BVALID);


// count SRAM address for weight and location
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr_count <= 0;
	end
	else if (current_state == WRITE_WEIGHT_SRAM || current_state == WRITE_LOCATION_SRAM) begin
		addr_count <= (rvalid_m_inf && rready_m_inf)? addr_count + 1 : addr_count;
	end
	else if (current_state == WRITE_RESULT_DRAM) begin
		addr_count <= addr_count + wready_m_inf;
	end
	else begin
		addr_count <= 0;
	end
end




// choose DI_WEI ADDR_WEI WEB_WEI
always @(*) begin
	if (current_state == WRITE_WEIGHT_SRAM && rvalid_m_inf) begin
		DI_WEI = rdata_m_inf;
		WEB_WEI = WRITE;
		ADDR_WEI = addr_count;
	end
	else if (current_state == RETRACE) begin
		DI_WEI = 0;
		WEB_WEI = READ;
		ADDR_WEI = {y_r, x_r[5]};
	end
	else begin
		DI_WEI = 0;
		WEB_WEI = READ;
		ADDR_WEI = 0;
	end
end


// choose DI_LOC ADDR_LOC WEB_LOC
always @(*) begin
	if (current_state == WRITE_LOCATION_SRAM && rvalid_m_inf) begin
		DI_LOC = rdata_m_inf;
		WEB_LOC = WRITE;
		ADDR_LOC = addr_count;
	end
	else if (current_state == RETRACE) begin
		DI_LOC = net_id_data;
		WEB_LOC = ~count_2;
		ADDR_LOC = {y_r, x_r[5]};
	end 
	else if (current_state == WRITE_RESULT_DRAM) begin
		DI_LOC = 0;
		WEB_LOC = READ;
		ADDR_LOC = addr_count + wready_m_inf;
	end
	else begin
		DI_LOC = 0;
		WEB_LOC = READ;
		ADDR_LOC = 0;
	end
end


// sending net_id data in SRAM
always @(*) begin
    net_id_data = DO_LOC;
    case(x_r[4:0])
			0  : net_id_data[3:0]     = net_id_r[0];
			1  : net_id_data[7:4]     = net_id_r[0];
			2  : net_id_data[11:8]    = net_id_r[0];
			3  : net_id_data[15:12]   = net_id_r[0];
			4  : net_id_data[19:16]   = net_id_r[0];
			5  : net_id_data[23:20]   = net_id_r[0];
			6  : net_id_data[27:24]   = net_id_r[0];
			7  : net_id_data[31:28]   = net_id_r[0];
			8  : net_id_data[35:32]   = net_id_r[0];
			9  : net_id_data[39:36]   = net_id_r[0];
			10 : net_id_data[43:40]   = net_id_r[0];
			11 : net_id_data[47:44]   = net_id_r[0];
			12 : net_id_data[51:48]   = net_id_r[0];
			13 : net_id_data[55:52]   = net_id_r[0];
			14 : net_id_data[59:56]   = net_id_r[0];
			15 : net_id_data[63:60]   = net_id_r[0];
			16 : net_id_data[67:64]   = net_id_r[0];
			17 : net_id_data[71:68]   = net_id_r[0];
			18 : net_id_data[75:72]   = net_id_r[0];
			19 : net_id_data[79:76]   = net_id_r[0];
			20 : net_id_data[83:80]   = net_id_r[0];
			21 : net_id_data[87:84]   = net_id_r[0];
			22 : net_id_data[91:88]   = net_id_r[0];
			23 : net_id_data[95:92]   = net_id_r[0];
			24 : net_id_data[99:96]   = net_id_r[0];
			25 : net_id_data[103:100] = net_id_r[0];
			26 : net_id_data[107:104] = net_id_r[0];
			27 : net_id_data[111:108] = net_id_r[0];
			28 : net_id_data[115:112] = net_id_r[0];
			29 : net_id_data[119:116] = net_id_r[0];
			30 : net_id_data[123:120] = net_id_r[0];
			31 : net_id_data[127:124] = net_id_r[0];
			//default : 
		endcase
end




MAP_128X128 WEIGHT_MAP(
    .CK(clk), .WEB(WEB_WEI), .OE(1'b1), .CS(1'b1),

    .A0(ADDR_WEI[0]), .A1(ADDR_WEI[1]), .A2(ADDR_WEI[2]), .A3(ADDR_WEI[3]), .A4(ADDR_WEI[4]), .A5(ADDR_WEI[5]), .A6(ADDR_WEI[6]),

	.DO0  (DO_WEI[0]),   .DO1 (DO_WEI[1]),   .DO2 (DO_WEI[2]),   .DO3 (DO_WEI[3]),   .DO4 (DO_WEI[4]),   .DO5 (DO_WEI[5]),   .DO6 (DO_WEI[6]),   .DO7 (DO_WEI[7]),
    .DO8  (DO_WEI[8]),   .DO9 (DO_WEI[9]),   .DO10(DO_WEI[10]),  .DO11(DO_WEI[11]),  .DO12(DO_WEI[12]),  .DO13(DO_WEI[13]),  .DO14(DO_WEI[14]),  .DO15(DO_WEI[15]),
    .DO16 (DO_WEI[16]),  .DO17(DO_WEI[17]),  .DO18(DO_WEI[18]),  .DO19(DO_WEI[19]),  .DO20(DO_WEI[20]),  .DO21(DO_WEI[21]),  .DO22(DO_WEI[22]),  .DO23(DO_WEI[23]),
    .DO24 (DO_WEI[24]),  .DO25(DO_WEI[25]),  .DO26(DO_WEI[26]),  .DO27(DO_WEI[27]),  .DO28(DO_WEI[28]),  .DO29(DO_WEI[29]),  .DO30(DO_WEI[30]),  .DO31(DO_WEI[31]),
    .DO32 (DO_WEI[32]),  .DO33(DO_WEI[33]),  .DO34(DO_WEI[34]),  .DO35(DO_WEI[35]),  .DO36(DO_WEI[36]),  .DO37(DO_WEI[37]),  .DO38(DO_WEI[38]),  .DO39(DO_WEI[39]),
    .DO40 (DO_WEI[40]),  .DO41(DO_WEI[41]),  .DO42(DO_WEI[42]),  .DO43(DO_WEI[43]),  .DO44(DO_WEI[44]),  .DO45(DO_WEI[45]),  .DO46(DO_WEI[46]),  .DO47(DO_WEI[47]),
    .DO48 (DO_WEI[48]),  .DO49(DO_WEI[49]),  .DO50(DO_WEI[50]),  .DO51(DO_WEI[51]),  .DO52(DO_WEI[52]),  .DO53(DO_WEI[53]),  .DO54(DO_WEI[54]),  .DO55(DO_WEI[55]),
    .DO56 (DO_WEI[56]),  .DO57(DO_WEI[57]),  .DO58(DO_WEI[58]),  .DO59(DO_WEI[59]),  .DO60(DO_WEI[60]),  .DO61(DO_WEI[61]),  .DO62(DO_WEI[62]),  .DO63(DO_WEI[63]),
    .DO64 (DO_WEI[64]),  .DO65(DO_WEI[65]),  .DO66(DO_WEI[66]),  .DO67(DO_WEI[67]),  .DO68(DO_WEI[68]),  .DO69(DO_WEI[69]),  .DO70(DO_WEI[70]),  .DO71(DO_WEI[71]),
    .DO72 (DO_WEI[72]),  .DO73(DO_WEI[73]),  .DO74(DO_WEI[74]),  .DO75(DO_WEI[75]),  .DO76(DO_WEI[76]),  .DO77(DO_WEI[77]),  .DO78(DO_WEI[78]),  .DO79(DO_WEI[79]),
    .DO80 (DO_WEI[80]),  .DO81(DO_WEI[81]),  .DO82(DO_WEI[82]),  .DO83(DO_WEI[83]),  .DO84(DO_WEI[84]),  .DO85(DO_WEI[85]),  .DO86(DO_WEI[86]),  .DO87(DO_WEI[87]),
    .DO88 (DO_WEI[88]),  .DO89(DO_WEI[89]),  .DO90(DO_WEI[90]),  .DO91(DO_WEI[91]),  .DO92(DO_WEI[92]),  .DO93(DO_WEI[93]),  .DO94(DO_WEI[94]),  .DO95(DO_WEI[95]),
    .DO96 (DO_WEI[96]),  .DO97(DO_WEI[97]),  .DO98(DO_WEI[98]),  .DO99(DO_WEI[99]), .DO100(DO_WEI[100]),.DO101(DO_WEI[101]),.DO102(DO_WEI[102]),.DO103(DO_WEI[103]),
    .DO104(DO_WEI[104]),.DO105(DO_WEI[105]),.DO106(DO_WEI[106]),.DO107(DO_WEI[107]),.DO108(DO_WEI[108]),.DO109(DO_WEI[109]),.DO110(DO_WEI[110]),.DO111(DO_WEI[111]),
    .DO112(DO_WEI[112]),.DO113(DO_WEI[113]),.DO114(DO_WEI[114]),.DO115(DO_WEI[115]),.DO116(DO_WEI[116]),.DO117(DO_WEI[117]),.DO118(DO_WEI[118]),.DO119(DO_WEI[119]),
    .DO120(DO_WEI[120]),.DO121(DO_WEI[121]),.DO122(DO_WEI[122]),.DO123(DO_WEI[123]),.DO124(DO_WEI[124]),.DO125(DO_WEI[125]),.DO126(DO_WEI[126]),.DO127(DO_WEI[127]),

    .DI0  (DI_WEI[0]),   .DI1  (DI_WEI[1]),   .DI2 (DI_WEI[2]),   .DI3 (DI_WEI[3]),   .DI4 (DI_WEI[4]),   .DI5 (DI_WEI[5]),   .DI6 (DI_WEI[6]),   .DI7 (DI_WEI[7]),
    .DI8  (DI_WEI[8]),   .DI9  (DI_WEI[9]),   .DI10(DI_WEI[10]),  .DI11(DI_WEI[11]),  .DI12(DI_WEI[12]),  .DI13(DI_WEI[13]),  .DI14(DI_WEI[14]),  .DI15(DI_WEI[15]),
    .DI16 (DI_WEI[16]),  .DI17 (DI_WEI[17]),  .DI18(DI_WEI[18]),  .DI19(DI_WEI[19]),  .DI20(DI_WEI[20]),  .DI21(DI_WEI[21]),  .DI22(DI_WEI[22]),  .DI23(DI_WEI[23]),
    .DI24 (DI_WEI[24]),  .DI25 (DI_WEI[25]),  .DI26(DI_WEI[26]),  .DI27(DI_WEI[27]),  .DI28(DI_WEI[28]),  .DI29(DI_WEI[29]),  .DI30(DI_WEI[30]),  .DI31(DI_WEI[31]),
    .DI32 (DI_WEI[32]),  .DI33 (DI_WEI[33]),  .DI34(DI_WEI[34]),  .DI35(DI_WEI[35]),  .DI36(DI_WEI[36]),  .DI37(DI_WEI[37]),  .DI38(DI_WEI[38]),  .DI39(DI_WEI[39]),
    .DI40 (DI_WEI[40]),  .DI41 (DI_WEI[41]),  .DI42(DI_WEI[42]),  .DI43(DI_WEI[43]),  .DI44(DI_WEI[44]),  .DI45(DI_WEI[45]),  .DI46(DI_WEI[46]),  .DI47(DI_WEI[47]),
    .DI48 (DI_WEI[48]),  .DI49 (DI_WEI[49]),  .DI50(DI_WEI[50]),  .DI51(DI_WEI[51]),  .DI52(DI_WEI[52]),  .DI53(DI_WEI[53]),  .DI54(DI_WEI[54]),  .DI55(DI_WEI[55]),
    .DI56 (DI_WEI[56]),  .DI57 (DI_WEI[57]),  .DI58(DI_WEI[58]),  .DI59(DI_WEI[59]),  .DI60(DI_WEI[60]),  .DI61(DI_WEI[61]),  .DI62(DI_WEI[62]),  .DI63(DI_WEI[63]),
    .DI64 (DI_WEI[64]),  .DI65 (DI_WEI[65]),  .DI66(DI_WEI[66]),  .DI67(DI_WEI[67]),  .DI68(DI_WEI[68]),  .DI69(DI_WEI[69]),  .DI70(DI_WEI[70]),  .DI71(DI_WEI[71]),
    .DI72 (DI_WEI[72]),  .DI73 (DI_WEI[73]),  .DI74(DI_WEI[74]),  .DI75(DI_WEI[75]),  .DI76(DI_WEI[76]),  .DI77(DI_WEI[77]),  .DI78(DI_WEI[78]),  .DI79(DI_WEI[79]),
    .DI80 (DI_WEI[80]),  .DI81 (DI_WEI[81]),  .DI82(DI_WEI[82]),  .DI83(DI_WEI[83]),  .DI84(DI_WEI[84]),  .DI85(DI_WEI[85]),  .DI86(DI_WEI[86]),  .DI87(DI_WEI[87]),
    .DI88 (DI_WEI[88]),  .DI89 (DI_WEI[89]),  .DI90(DI_WEI[90]),  .DI91(DI_WEI[91]),  .DI92(DI_WEI[92]),  .DI93(DI_WEI[93]),  .DI94(DI_WEI[94]),  .DI95(DI_WEI[95]),
    .DI96 (DI_WEI[96]),  .DI97 (DI_WEI[97]),  .DI98(DI_WEI[98]),  .DI99(DI_WEI[99]), .DI100(DI_WEI[100]),.DI101(DI_WEI[101]),.DI102(DI_WEI[102]),.DI103(DI_WEI[103]),
    .DI104(DI_WEI[104]), .DI105(DI_WEI[105]),.DI106(DI_WEI[106]),.DI107(DI_WEI[107]),.DI108(DI_WEI[108]),.DI109(DI_WEI[109]),.DI110(DI_WEI[110]),.DI111(DI_WEI[111]),
    .DI112(DI_WEI[112]), .DI113(DI_WEI[113]),.DI114(DI_WEI[114]),.DI115(DI_WEI[115]),.DI116(DI_WEI[116]),.DI117(DI_WEI[117]),.DI118(DI_WEI[118]),.DI119(DI_WEI[119]),
    .DI120(DI_WEI[120]), .DI121(DI_WEI[121]),.DI122(DI_WEI[122]),.DI123(DI_WEI[123]),.DI124(DI_WEI[124]),.DI125(DI_WEI[125]),.DI126(DI_WEI[126]),.DI127(DI_WEI[127]));

MAP_128X128 LOCATION_MAP(
    .CK(clk), .WEB(WEB_LOC), .OE(1'b1), .CS(1'b1),

    .A0(ADDR_LOC[0]), .A1(ADDR_LOC[1]), .A2(ADDR_LOC[2]), .A3(ADDR_LOC[3]), .A4(ADDR_LOC[4]), .A5(ADDR_LOC[5]), .A6(ADDR_LOC[6]),

	.DO0  (DO_LOC[0]),   .DO1 (DO_LOC[1]),   .DO2 (DO_LOC[2]),   .DO3 (DO_LOC[3]),   .DO4 (DO_LOC[4]),   .DO5 (DO_LOC[5]),   .DO6 (DO_LOC[6]),   .DO7 (DO_LOC[7]),
    .DO8  (DO_LOC[8]),   .DO9 (DO_LOC[9]),   .DO10(DO_LOC[10]),  .DO11(DO_LOC[11]),  .DO12(DO_LOC[12]),  .DO13(DO_LOC[13]),  .DO14(DO_LOC[14]),  .DO15(DO_LOC[15]),
    .DO16 (DO_LOC[16]),  .DO17(DO_LOC[17]),  .DO18(DO_LOC[18]),  .DO19(DO_LOC[19]),  .DO20(DO_LOC[20]),  .DO21(DO_LOC[21]),  .DO22(DO_LOC[22]),  .DO23(DO_LOC[23]),
    .DO24 (DO_LOC[24]),  .DO25(DO_LOC[25]),  .DO26(DO_LOC[26]),  .DO27(DO_LOC[27]),  .DO28(DO_LOC[28]),  .DO29(DO_LOC[29]),  .DO30(DO_LOC[30]),  .DO31(DO_LOC[31]),
    .DO32 (DO_LOC[32]),  .DO33(DO_LOC[33]),  .DO34(DO_LOC[34]),  .DO35(DO_LOC[35]),  .DO36(DO_LOC[36]),  .DO37(DO_LOC[37]),  .DO38(DO_LOC[38]),  .DO39(DO_LOC[39]),
    .DO40 (DO_LOC[40]),  .DO41(DO_LOC[41]),  .DO42(DO_LOC[42]),  .DO43(DO_LOC[43]),  .DO44(DO_LOC[44]),  .DO45(DO_LOC[45]),  .DO46(DO_LOC[46]),  .DO47(DO_LOC[47]),
    .DO48 (DO_LOC[48]),  .DO49(DO_LOC[49]),  .DO50(DO_LOC[50]),  .DO51(DO_LOC[51]),  .DO52(DO_LOC[52]),  .DO53(DO_LOC[53]),  .DO54(DO_LOC[54]),  .DO55(DO_LOC[55]),
    .DO56 (DO_LOC[56]),  .DO57(DO_LOC[57]),  .DO58(DO_LOC[58]),  .DO59(DO_LOC[59]),  .DO60(DO_LOC[60]),  .DO61(DO_LOC[61]),  .DO62(DO_LOC[62]),  .DO63(DO_LOC[63]),
    .DO64 (DO_LOC[64]),  .DO65(DO_LOC[65]),  .DO66(DO_LOC[66]),  .DO67(DO_LOC[67]),  .DO68(DO_LOC[68]),  .DO69(DO_LOC[69]),  .DO70(DO_LOC[70]),  .DO71(DO_LOC[71]),
    .DO72 (DO_LOC[72]),  .DO73(DO_LOC[73]),  .DO74(DO_LOC[74]),  .DO75(DO_LOC[75]),  .DO76(DO_LOC[76]),  .DO77(DO_LOC[77]),  .DO78(DO_LOC[78]),  .DO79(DO_LOC[79]),
    .DO80 (DO_LOC[80]),  .DO81(DO_LOC[81]),  .DO82(DO_LOC[82]),  .DO83(DO_LOC[83]),  .DO84(DO_LOC[84]),  .DO85(DO_LOC[85]),  .DO86(DO_LOC[86]),  .DO87(DO_LOC[87]),
    .DO88 (DO_LOC[88]),  .DO89(DO_LOC[89]),  .DO90(DO_LOC[90]),  .DO91(DO_LOC[91]),  .DO92(DO_LOC[92]),  .DO93(DO_LOC[93]),  .DO94(DO_LOC[94]),  .DO95(DO_LOC[95]),
    .DO96 (DO_LOC[96]),  .DO97(DO_LOC[97]),  .DO98(DO_LOC[98]),  .DO99(DO_LOC[99]), .DO100(DO_LOC[100]),.DO101(DO_LOC[101]),.DO102(DO_LOC[102]),.DO103(DO_LOC[103]),
    .DO104(DO_LOC[104]),.DO105(DO_LOC[105]),.DO106(DO_LOC[106]),.DO107(DO_LOC[107]),.DO108(DO_LOC[108]),.DO109(DO_LOC[109]),.DO110(DO_LOC[110]),.DO111(DO_LOC[111]),
    .DO112(DO_LOC[112]),.DO113(DO_LOC[113]),.DO114(DO_LOC[114]),.DO115(DO_LOC[115]),.DO116(DO_LOC[116]),.DO117(DO_LOC[117]),.DO118(DO_LOC[118]),.DO119(DO_LOC[119]),
    .DO120(DO_LOC[120]),.DO121(DO_LOC[121]),.DO122(DO_LOC[122]),.DO123(DO_LOC[123]),.DO124(DO_LOC[124]),.DO125(DO_LOC[125]),.DO126(DO_LOC[126]),.DO127(DO_LOC[127]),

    .DI0  (DI_LOC[0]),   .DI1  (DI_LOC[1]),   .DI2 (DI_LOC[2]),   .DI3 (DI_LOC[3]),   .DI4 (DI_LOC[4]),   .DI5 (DI_LOC[5]),   .DI6 (DI_LOC[6]),   .DI7 (DI_LOC[7]),
    .DI8  (DI_LOC[8]),   .DI9  (DI_LOC[9]),   .DI10(DI_LOC[10]),  .DI11(DI_LOC[11]),  .DI12(DI_LOC[12]),  .DI13(DI_LOC[13]),  .DI14(DI_LOC[14]),  .DI15(DI_LOC[15]),
    .DI16 (DI_LOC[16]),  .DI17 (DI_LOC[17]),  .DI18(DI_LOC[18]),  .DI19(DI_LOC[19]),  .DI20(DI_LOC[20]),  .DI21(DI_LOC[21]),  .DI22(DI_LOC[22]),  .DI23(DI_LOC[23]),
    .DI24 (DI_LOC[24]),  .DI25 (DI_LOC[25]),  .DI26(DI_LOC[26]),  .DI27(DI_LOC[27]),  .DI28(DI_LOC[28]),  .DI29(DI_LOC[29]),  .DI30(DI_LOC[30]),  .DI31(DI_LOC[31]),
    .DI32 (DI_LOC[32]),  .DI33 (DI_LOC[33]),  .DI34(DI_LOC[34]),  .DI35(DI_LOC[35]),  .DI36(DI_LOC[36]),  .DI37(DI_LOC[37]),  .DI38(DI_LOC[38]),  .DI39(DI_LOC[39]),
    .DI40 (DI_LOC[40]),  .DI41 (DI_LOC[41]),  .DI42(DI_LOC[42]),  .DI43(DI_LOC[43]),  .DI44(DI_LOC[44]),  .DI45(DI_LOC[45]),  .DI46(DI_LOC[46]),  .DI47(DI_LOC[47]),
    .DI48 (DI_LOC[48]),  .DI49 (DI_LOC[49]),  .DI50(DI_LOC[50]),  .DI51(DI_LOC[51]),  .DI52(DI_LOC[52]),  .DI53(DI_LOC[53]),  .DI54(DI_LOC[54]),  .DI55(DI_LOC[55]),
    .DI56 (DI_LOC[56]),  .DI57 (DI_LOC[57]),  .DI58(DI_LOC[58]),  .DI59(DI_LOC[59]),  .DI60(DI_LOC[60]),  .DI61(DI_LOC[61]),  .DI62(DI_LOC[62]),  .DI63(DI_LOC[63]),
    .DI64 (DI_LOC[64]),  .DI65 (DI_LOC[65]),  .DI66(DI_LOC[66]),  .DI67(DI_LOC[67]),  .DI68(DI_LOC[68]),  .DI69(DI_LOC[69]),  .DI70(DI_LOC[70]),  .DI71(DI_LOC[71]),
    .DI72 (DI_LOC[72]),  .DI73 (DI_LOC[73]),  .DI74(DI_LOC[74]),  .DI75(DI_LOC[75]),  .DI76(DI_LOC[76]),  .DI77(DI_LOC[77]),  .DI78(DI_LOC[78]),  .DI79(DI_LOC[79]),
    .DI80 (DI_LOC[80]),  .DI81 (DI_LOC[81]),  .DI82(DI_LOC[82]),  .DI83(DI_LOC[83]),  .DI84(DI_LOC[84]),  .DI85(DI_LOC[85]),  .DI86(DI_LOC[86]),  .DI87(DI_LOC[87]),
    .DI88 (DI_LOC[88]),  .DI89 (DI_LOC[89]),  .DI90(DI_LOC[90]),  .DI91(DI_LOC[91]),  .DI92(DI_LOC[92]),  .DI93(DI_LOC[93]),  .DI94(DI_LOC[94]),  .DI95(DI_LOC[95]),
    .DI96 (DI_LOC[96]),  .DI97 (DI_LOC[97]),  .DI98(DI_LOC[98]),  .DI99(DI_LOC[99]), .DI100(DI_LOC[100]),.DI101(DI_LOC[101]),.DI102(DI_LOC[102]),.DI103(DI_LOC[103]),
    .DI104(DI_LOC[104]), .DI105(DI_LOC[105]),.DI106(DI_LOC[106]),.DI107(DI_LOC[107]),.DI108(DI_LOC[108]),.DI109(DI_LOC[109]),.DI110(DI_LOC[110]),.DI111(DI_LOC[111]),
    .DI112(DI_LOC[112]), .DI113(DI_LOC[113]),.DI114(DI_LOC[114]),.DI115(DI_LOC[115]),.DI116(DI_LOC[116]),.DI117(DI_LOC[117]),.DI118(DI_LOC[118]),.DI119(DI_LOC[119]),
    .DI120(DI_LOC[120]), .DI121(DI_LOC[121]),.DI122(DI_LOC[122]),.DI123(DI_LOC[123]),.DI124(DI_LOC[124]),.DI125(DI_LOC[125]),.DI126(DI_LOC[126]),.DI127(DI_LOC[127]));



// ===============================================================
//  					PATH MAP
// ===============================================================

// count_4
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		count_4 <= 0;
	end
	else if (current_state == PROPAGATION || current_state == MAP_INITIAL) begin 
		count_4 <= (propagate_done_flag)? count_4 - 2'd2 : count_4 + 1'd1;
	end
	else if (current_state == RETRACE) begin
		count_4 <= (count_2)? count_4 - 1'd1 : count_4;
	end
	else begin
		count_4 <= 0;
	end
end

// propagate sequence 2233
always @(*) begin
	case(count_4)
		0: pro_seq = TWO;
		1: pro_seq = TWO;
		2: pro_seq = THREE;
		3: pro_seq = THREE;
		default: pro_seq = BLOCKED;
	endcase
end


// store path map
always @(posedge clk) begin
//always @(posedge clk or negedge rst_n) begin
    // if (!rst_n) begin
	// 	for(i = 0; i < 64; i = i + 1) begin
    //         for(j = 0; j < 64; j = j + 1) begin
    //             path_map_r[i][j] <= 0;
	// 		end
	// 	end
	// end
	// LHS
	 if (current_state == WRITE_LOCATION_SRAM && rvalid_m_inf && ~addr_count[0]) begin
		for (i = 0; i < 32; i = i + 1) begin
			path_map_r[addr_count[6:1]][i] <= (rdata_m_inf[4*i+3 -: 4] != 0)? BLOCKED : EMPTY;
		end
	end
	// RHS
	else if (current_state == WRITE_LOCATION_SRAM && rvalid_m_inf && addr_count[0]) begin
		for (i = 0; i < 32; i = i + 1) begin
			path_map_r[addr_count[6:1]][i+32] <= (rdata_m_inf[4*i+3 -: 4] != 0)? BLOCKED : EMPTY;
		end
	end
	else if (current_state == MAP_INITIAL) begin
		path_map_r[source_y_r[0]][source_x_r[0]] <= pro_seq; //set source 2
		path_map_r[sink_y_r[0]][sink_x_r[0]] <= EMPTY;   //set sink 0
	end
	else if (current_state == PROPAGATION) begin
		//62X62
		for (i = 1; i < 63; i = i + 1) begin
			for (j = 1; j < 63; j = j + 1) begin
				if (path_map_r[i][j] == EMPTY && (path_map_r[i-1][j][1] | path_map_r[i+1][j][1] | path_map_r[i][j-1][1] | path_map_r[i][j+1][1])) begin
					path_map_r[i][j] <= pro_seq;
                end
				else begin
					path_map_r[i][j] <= path_map_r[i][j];
				end
            end
		end
		// Upper boundry 1X62
		for (i = 1; i < 63; i = i + 1) begin
			if (path_map_r[0][i] == EMPTY && (path_map_r[0][i+1][1] | path_map_r[1][i][1] | path_map_r[0][i-1][1])) begin
				path_map_r[0][i] <= pro_seq;
			end
			else begin
				path_map_r[0][i] <= path_map_r[0][i];
			end
		end
		// Lower boundry 1X62
		for (i = 1; i < 63; i = i + 1) begin
			if (path_map_r[63][i] == EMPTY && (path_map_r[63][i+1][1] | path_map_r[62][i][1] | path_map_r[63][i-1][1])) begin
				path_map_r[63][i] <= pro_seq;
			end
			else begin
				path_map_r[63][i] <= path_map_r[63][i];
			end
		end
		// Left boundry 62X1
		for (i = 1; i < 63; i = i + 1) begin
			if (path_map_r[i][0] == EMPTY && (path_map_r[i+1][0][1] | path_map_r[i][1][1] | path_map_r[i-1][0][1])) begin
				path_map_r[i][0] <= pro_seq;
			end
			else begin
				path_map_r[i][0] <= path_map_r[i][0];
			end
		end
		// Right boundry 62X1
		for (i = 1; i < 63; i = i + 1) begin
			if (path_map_r[i][63] == EMPTY && (path_map_r[i+1][63][1] | path_map_r[i][62][1] | path_map_r[i-1][63][1])) begin
				path_map_r[i][63] <= pro_seq;
			end
			else begin
				path_map_r[i][63] <= path_map_r[i][63];
			end
		end

		// Corner [0][0]
		path_map_r[0][0] <= (path_map_r[0][0] == EMPTY && (path_map_r[1][0][1] | path_map_r[0][1][1]))? pro_seq : path_map_r[0][0];

		// Corner [0][63]
		path_map_r[0][63] <= (path_map_r[0][63] == EMPTY && (path_map_r[1][63][1] | path_map_r[0][62][1]))? pro_seq : path_map_r[0][63];

		// Corner [63][0]
		path_map_r[63][0] <= (path_map_r[63][0] == EMPTY && (path_map_r[63][1][1] | path_map_r[62][0][1]))? pro_seq : path_map_r[63][0];

		// Corner [63][63]
		path_map_r[63][63] <= (path_map_r[63][63] == EMPTY && (path_map_r[63][62][1] | path_map_r[62][63][1]))? pro_seq : path_map_r[63][63];

	end
	else if (current_state == RETRACE && count_2) begin
		path_map_r[y_r][x_r] <= BLOCKED;
	end
	else if (current_state == CLEAN) begin
		for (i = 0; i < 64; i = i + 1) begin
			for (j = 0; j < 64; j = j + 1) begin
				if (path_map_r[i][j] != BLOCKED) begin
					path_map_r[i][j] <= EMPTY;
				end
			end
        end
    end
end





// retrace coordinate for x and y
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_r <= 0;
        y_r <= 0;
    end
	else if (current_state == PROPAGATION && propagate_done_flag) begin
		x_r <= sink_x_r[0];
		y_r <= sink_y_r[0];
	end
	else if (current_state == RETRACE && count_2) begin
		if (path_map_r[y_r+1][x_r] == pro_seq && y_r != 63) begin // down
			x_r <= x_r;
			y_r <= y_r + 1;
		end
		else if (path_map_r[y_r-1][x_r] == pro_seq && y_r != 0) begin // up
			x_r <= x_r;
			y_r <= y_r - 1;
		end
		else if (path_map_r[y_r][x_r+1] == pro_seq && x_r != 63) begin // right
			x_r <= x_r + 1;
			y_r <= y_r;
		end
		else if (path_map_r[y_r][x_r-1] == pro_seq && x_r !=0) begin // left
			x_r <= x_r - 1;
			y_r <= y_r;
		end
		else begin
			x_r <= x_r;
			y_r <= y_r;
		end
	end
	else begin
		x_r <= x_r;
		y_r <= y_r;
	end
end


// ===============================================================
//  					COST
// ===============================================================

always @(*) begin
	case(x_r[4:0])
		0  : retrace_cost = DO_WEI[3:0];
		1  : retrace_cost = DO_WEI[7:4];
		2  : retrace_cost = DO_WEI[11:8];
		3  : retrace_cost = DO_WEI[15:12];
		4  : retrace_cost = DO_WEI[19:16];
		5  : retrace_cost = DO_WEI[23:20];
		6  : retrace_cost = DO_WEI[27:24];
		7  : retrace_cost = DO_WEI[31:28];
		8  : retrace_cost = DO_WEI[35:32];
		9  : retrace_cost = DO_WEI[39:36];
		10 : retrace_cost = DO_WEI[43:40];
		11 : retrace_cost = DO_WEI[47:44];
		12 : retrace_cost = DO_WEI[51:48];
		13 : retrace_cost = DO_WEI[55:52];
		14 : retrace_cost = DO_WEI[59:56];
		15 : retrace_cost = DO_WEI[63:60];
		16 : retrace_cost = DO_WEI[67:64];
		17 : retrace_cost = DO_WEI[71:68];
		18 : retrace_cost = DO_WEI[75:72];
		19 : retrace_cost = DO_WEI[79:76];
		20 : retrace_cost = DO_WEI[83:80];
		21 : retrace_cost = DO_WEI[87:84];
		22 : retrace_cost = DO_WEI[91:88];
		23 : retrace_cost = DO_WEI[95:92];
		24 : retrace_cost = DO_WEI[99:96];
		25 : retrace_cost = DO_WEI[103:100];
		26 : retrace_cost = DO_WEI[107:104];
		27 : retrace_cost = DO_WEI[111:108];
		28 : retrace_cost = DO_WEI[115:112];
		29 : retrace_cost = DO_WEI[119:116];
		30 : retrace_cost = DO_WEI[123:120];
		31 : retrace_cost = DO_WEI[127:124];
		default : retrace_cost = 0;
	endcase
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		busy <= 0;
	end
    else begin
        busy <= ~(next_state == IDLE || next_state == INPUT_SAVE || in_valid);
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cost <= 0;
    end
    else begin
        if (current_state == IDLE) begin
            cost <= 0;
		end
        else if (current_state == RETRACE && count_2) begin
            if ((x_r == source_x_r[0] && y_r == source_y_r[0]) || (x_r == sink_x_r[0] && y_r == sink_y_r[0])) begin
                cost <= cost;
			end
            else begin
				cost <= cost + retrace_cost;
            end
        end
		else begin
			cost <= cost;
		end
    end
end

endmodule

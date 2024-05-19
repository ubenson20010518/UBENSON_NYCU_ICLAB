// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input cg_en;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
integer i, j;
parameter Q_SCALE1 = 2295;
parameter Q_SCALE2 = 510;

parameter IDLE = 4'd0;
parameter CONV = 4'd1;
parameter QUANT1 = 4'd2;
parameter MAX_POOL = 4'd3;
parameter FULLY_CONNECT = 4'd4;
parameter QUANT2 = 4'd5;
parameter OUT = 4'd6;


//==============================================//
//           reg & wire declaration             //
//==============================================//

reg [9:0] count_r;
// reg [7:0] img1_r[0:35], img2_r[0:35];
// reg [7:0] img1 [0:5][0:5], img2[0:5][0:5];
reg [7:0] img_r [0:5][0:5];
reg [7:0] kernel_r [0:2][0:2];
reg [7:0] weight_r [0:1][0:1];
// reg [15:0] feature_map1_r [0:3][0:3];
// reg [15:0] feature_map2_r [0:3][0:3];
reg [19:0] feature_map_r [0:3][0:3];
// reg [7:0] quant1_1_r [0:3][0:3];
// reg [7:0] quant2_1_r [0:3][0:3];
reg [7:0] quant1_r [0:3][0:3];
// reg [7:0] max_pool1_r [0:1][0:1];
// reg [7:0] max_pool2_r [0:1][0:1];
reg [7:0] max_pool_r [0:1][0:1];
// reg [15:0] flatten1_r [0:3];
// reg [15:0] flatten2_r [0:3];
reg [16:0] flatten_r [0:3];
// reg [7:0] quant1_2_r [0:3];
// reg [7:0] quant2_2_r [0:3];
reg [7:0] quant_final1_r [0:3], quant_final2_r [0:3];
reg [3:0] current_state, next_state;

reg [7:0] a_mul_in0, a_mul_in1, a_mul_in2, a_mul_in3, a_mul_in4, a_mul_in5, a_mul_in6, a_mul_in7, a_mul_in8;
reg [7:0] b_mul_in0, b_mul_in1, b_mul_in2, b_mul_in3, b_mul_in4, b_mul_in5, b_mul_in6, b_mul_in7, b_mul_in8;
reg [19:0] dp0, dp1, dp2, dp3, dp4, dp5, dp6, dp7, dp8;
reg [19:0] dp_sum;
reg [19:0] fc_sum0, fc_sum1, fc_sum2, fc_sum3;
reg [19:0] a_div_in0, a_div_in1, a_div_in2, a_div_in3, b_div_in0, b_div_in1, b_div_in2, b_div_in3;
reg [7:0] quant_out0, quant_out1, quant_out2, quant_out3;
reg [7:0] cmp_in_0_0, cmp_in_0_1, cmp_in_0_2, cmp_in_0_3, cmp_in_0_4, cmp_in_0_5, big_0_0, big_0_1, max_pool_0;
reg [7:0] cmp_in_1_0, cmp_in_1_1, cmp_in_1_2, cmp_in_1_3, cmp_in_1_4, cmp_in_1_5, big_1_0, big_1_1, max_pool_1;
reg [7:0] cmp_in_2_0, cmp_in_2_1, cmp_in_2_2, cmp_in_2_3, cmp_in_2_4, cmp_in_2_5, big_2_0, big_2_1, max_pool_2;
reg [7:0] cmp_in_3_0, cmp_in_3_1, cmp_in_3_2, cmp_in_3_3, cmp_in_3_4, cmp_in_3_5, big_3_0, big_3_1, max_pool_3;

reg [9:0] d0, d1, d2, d3;
reg [9:0] pos_d0, pos_d1, pos_d2, pos_d3;
reg [9:0] L1_distance;
reg [9:0] similarity_score;

// buffer
reg [19:0] buf_dp_sum1, buf_dp_sum2, buf_dp_sum3, buf_dp_sum4;
reg buf_img_clk1, buf_img_clk2;

wire DONE;
wire conv_clk, quant1_clk, quant2_1_clk, quant2_2_clk, max_pool_clk, fc_clk;
wire conv_sleep, quant1_sleep, quant2_1_sleep, quant2_2_sleep, max_pool_sleep, fc_sleep; 
wire img_clk, kernel_clk, weight_clk;
wire img_sleep, kernel_sleep, weight_sleep;

assign img_sleep = ~(count_r >= 0 && count_r <= 71);
assign kernel_sleep = ~(count_r >= 0 && count_r <= 8);
assign weight_sleep = ~(count_r >= 0 && count_r <= 3);


// assign conv_sleep = ~(current_state == CONV);
// assign quant1_sleep = ~(current_state == QUANT1);
// assign max_pool_sleep = ~(current_state == MAX_POOL);
// assign fc_sleep = ~(current_state == FULLY_CONNECT);
// assign quant2_1_sleep = ~(current_state == QUANT2);
// assign quant2_2_sleep = ~(current_state == QUANT2);
assign quant2_1_sleep = ~((count_r == 0) || (count_r == 43));
assign quant2_2_sleep = ~((count_r == 0) || (count_r == 79));

assign conv_sleep = ~((count_r == 0) || (count_r >= 21 && count_r <= 36) || (count_r >= 57 && count_r <= 72));
assign quant1_sleep = ~((count_r == 0) || (count_r >= 37 && count_r <= 40) || (count_r >= 73 && count_r <= 76));
assign max_pool_sleep = ~((count_r == 0) || (count_r == 41) || (count_r == 77));
assign fc_sleep = ~((count_r == 0) || (count_r == 42) || (count_r == 78));
// assign quant2_1_sleep = ~((count_r == 0) || (count_r == 43));
// assign quant2_2_sleep = ~((count_r == 0) || (count_r == 79));

// assign conv_sleep = ~((count_r == 0) || (count_r >= 20 && count_r <= 37) || (count_r >= 56 && count_r <= 73));
// assign quant1_sleep = ~((count_r == 0) || (count_r >= 36 && count_r <= 41) || (count_r >= 72 && count_r <= 77));
// assign max_pool_sleep = ~((count_r == 0) || (count_r >= 40 && count_r <= 42) || (count_r >= 76 && count_r <= 78));
// assign fc_sleep = ~((count_r == 0) || (count_r >= 41 && count_r <= 43) || (count_r >= 77 && count_r <= 79));
// assign quant2_1_sleep = ~((count_r == 0) || (count_r >= 42 && count_r <= 44));
// assign quant2_2_sleep = ~((count_r == 0) || (count_r >= 78 && count_r <= 80));

//==============================================//
//                     FSM                      //
//==============================================//
always @ (posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		current_state <= IDLE;
	end
	else begin
		current_state <= next_state;
	end
end

always @ (*) begin 
	case (current_state)
		IDLE : begin
			if (count_r == 20 || count_r == 56) next_state = CONV;
			else next_state = IDLE;
		end
		CONV : begin
			if (count_r == 36 || count_r == 72) next_state = QUANT1;
			else next_state = CONV;
		end
		QUANT1 : begin
			if (count_r == 40 || count_r == 76) next_state = MAX_POOL;
			else next_state = QUANT1;
		end
		MAX_POOL : begin
			next_state = FULLY_CONNECT;
		end
		FULLY_CONNECT : begin
			next_state = QUANT2;
		end
		QUANT2 : begin
			if (count_r == 43) next_state = IDLE;
			else if (count_r == 79) next_state = OUT;
			else next_state = QUANT2;
		end 
		OUT : next_state = IDLE;
		default : next_state = IDLE;
	endcase
end


//==============================================//
//                  design                      //
//==============================================//

assign DONE = (count_r == 81)? 1'b1 : 1'b0;

// counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		count_r <= 0;
	end
	else if(DONE) begin
        count_r <= 0;
    end
	else if (in_valid || count_r != 0) begin
		count_r <= count_r + 1;
	end
	else begin
		count_r <= 0;
	end
end

//GATED_OR GATED_IMG ( .CLOCK(clk), .SLEEP_CTRL(cg_en && img_sleep), .RST_N(rst_n), .CLOCK_GATED(img_clk) );

// store img1 and img2
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0; i < 6; i = i + 1) begin
            for(j = 0; j < 6; j = j + 1) begin
				img_r[i][j] <= 0;
			end
		end
	end
	else if (in_valid) begin
		case (count_r)
			0,	36 : img_r[0][0] <= img; 
			1,	37 : img_r[0][1] <= img;
			2,	38 : img_r[0][2] <= img; 
			3,	39 : img_r[0][3] <= img; 
			4,	40 : img_r[0][4] <= img; 
			5,	41 : img_r[0][5] <= img; 
			6,	42 : img_r[1][0] <= img; 
			7,	43 : img_r[1][1] <= img; 
			8,	44 : img_r[1][2] <= img; 
			9,	45 : img_r[1][3] <= img; 
			10,	46 : img_r[1][4] <= img; 
			11,	47 : img_r[1][5] <= img; 
			12,	48 : img_r[2][0] <= img; 
			13,	49 : img_r[2][1] <= img; 
			14,	50 : img_r[2][2] <= img; 
			15,	51 : img_r[2][3] <= img; 
			16,	52 : img_r[2][4] <= img; 
			17,	53 : img_r[2][5] <= img; 
			18,	54 : img_r[3][0] <= img; 
			19,	55 : img_r[3][1] <= img; 
			20,	56 : img_r[3][2] <= img; 
			21,	57 : img_r[3][3] <= img; 
			22,	58 : img_r[3][4] <= img; 
			23,	59 : img_r[3][5] <= img; 
			24,	60 : img_r[4][0] <= img; 
			25,	61 : img_r[4][1] <= img; 
			26,	62 : img_r[4][2] <= img; 
			27,	63 : img_r[4][3] <= img; 
			28,	64 : img_r[4][4] <= img; 
			29,	65 : img_r[4][5] <= img; 
			30,	66 : img_r[5][0] <= img; 
			31,	67 : img_r[5][1] <= img;
			32,	68 : img_r[5][2] <= img; 
			33,	69 : img_r[5][3] <= img; 
			34,	70 : img_r[5][4] <= img; 
			35,	71 : img_r[5][5] <= img;
			default : begin
				for(i = 0; i < 6; i = i + 1) begin
					for(j = 0; j < 6; j = j + 1) begin
						img_r[i][j] <= img_r[i][j];
					end
				end
			end
		endcase
	end
	else begin
		for(i = 0; i < 6; i = i + 1) begin
			for(j = 0; j < 6; j = j + 1) begin
				img_r[i][j] <= img_r[i][j];
			end
		end
	end
end

//GATED_OR GATED_KERNEL ( .CLOCK(clk), .SLEEP_CTRL(cg_en && kernel_sleep), .RST_N(rst_n), .CLOCK_GATED(kernel_clk) );

// store kernel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0; i < 3; i = i + 1) begin
            for(j = 0; j < 3; j = j + 1) begin
				kernel_r[i][j] <= 0;
			end
		end
	end
	else if (in_valid) begin
		case (count_r) 
			0 : kernel_r[0][0] <= ker; 1 : kernel_r[0][1] <= ker; 2 : kernel_r[0][2] <= ker;
			3 : kernel_r[1][0] <= ker; 4 : kernel_r[1][1] <= ker; 5 : kernel_r[1][2] <= ker;
			6 : kernel_r[2][0] <= ker; 7 : kernel_r[2][1] <= ker; 8 : kernel_r[2][2] <= ker;
			default : begin
				for(i = 0; i < 3; i = i + 1) begin
            		for(j = 0; j < 3; j = j + 1) begin
						kernel_r[i][j] <= kernel_r[i][j];
					end
				end
			end
		endcase
	end
	else begin
		for(i = 0; i < 3; i = i + 1) begin
			for(j = 0; j < 3; j = j + 1) begin
				kernel_r[i][j] <= kernel_r[i][j];
			end
		end
	end
end

//GATED_OR GATED_WEIGHT ( .CLOCK(clk), .SLEEP_CTRL(cg_en && weight_sleep), .RST_N(rst_n), .CLOCK_GATED(weight_clk) );

// store weight
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) begin
				weight_r[i][j] <= 0;
			end
		end
	end
	else if (in_valid) begin
		case(count_r)
			0: weight_r[0][0] <= weight;
            1: weight_r[0][1] <= weight;
            2: weight_r[1][0] <= weight;
            3: weight_r[1][1] <= weight;
			default : begin
				for(i = 0; i < 2; i = i + 1) begin
					for(j = 0; j < 2; j = j + 1) begin
						weight_r[i][j] <= weight_r[i][j];
					end
				end
			end
		endcase
	end
	else begin
		for(i = 0; i < 2; i = i + 1) begin
			for(j = 0; j < 2; j = j + 1) begin
				weight_r[i][j] <= weight_r[i][j];
			end
		end
	end
end


//==============================================//
//                  convolution                 //
//==============================================//

// choose multiply input
always @(*) begin
    case(count_r)
		21, 57 : begin
			a_mul_in0 = img_r [0][0]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [0][1]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [0][2]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [1][0]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [1][1]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [1][2]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [2][0]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [2][1]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [2][2]; b_mul_in8 = kernel_r[2][2];
		end
		22, 58 : begin 
            a_mul_in0 = img_r [0][1]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [0][2]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [0][3]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [1][1]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [1][2]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [1][3]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [2][1]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [2][2]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [2][3]; b_mul_in8 = kernel_r[2][2];
        end
        23, 59 : begin 
            a_mul_in0 = img_r [0][2]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [0][3]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [0][4]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [1][2]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [1][3]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [1][4]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [2][2]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [2][3]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [2][4]; b_mul_in8 = kernel_r[2][2];
        end
        24, 60 : begin 
            a_mul_in0 = img_r [0][3]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [0][4]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [0][5]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [1][3]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [1][4]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [1][5]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [2][3]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [2][4]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [2][5]; b_mul_in8 = kernel_r[2][2];
        end
        25, 61 : begin 
            a_mul_in0 = img_r [1][0]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [1][1]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [1][2]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [2][0]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [2][1]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [2][2]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [3][0]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [3][1]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [3][2]; b_mul_in8 = kernel_r[2][2];
        end
        26, 62 : begin 
            a_mul_in0 = img_r [1][1]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [1][2]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [1][3]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [2][1]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [2][2]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [2][3]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [3][1]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [3][2]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [3][3]; b_mul_in8 = kernel_r[2][2];
        end
        27, 63 : begin 
            a_mul_in0 = img_r [1][2]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [1][3]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [1][4]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [2][2]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [2][3]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [2][4]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [3][2]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [3][3]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [3][4]; b_mul_in8 = kernel_r[2][2];
        end
        28, 64 : begin 
            a_mul_in0 = img_r [1][3]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [1][4]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [1][5]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [2][3]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [2][4]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [2][5]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [3][3]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [3][4]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [3][5]; b_mul_in8 = kernel_r[2][2];
        end
        29, 65 : begin 
            a_mul_in0 = img_r [2][0]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [2][1]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [2][2]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [3][0]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [3][1]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [3][2]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [4][0]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [4][1]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [4][2]; b_mul_in8 = kernel_r[2][2];
        end
        30, 66 : begin 
            a_mul_in0 = img_r [2][1]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [2][2]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [2][3]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [3][1]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [3][2]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [3][3]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [4][1]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [4][2]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [4][3]; b_mul_in8 = kernel_r[2][2];
        end
        31, 67 : begin 
            a_mul_in0 = img_r [2][2]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [2][3]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [2][4]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [3][2]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [3][3]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [3][4]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [4][2]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [4][3]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [4][4]; b_mul_in8 = kernel_r[2][2];
        end
        32, 68 : begin 
            a_mul_in0 = img_r [2][3]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [2][4]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [2][5]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [3][3]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [3][4]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [3][5]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [4][3]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [4][4]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [4][5]; b_mul_in8 = kernel_r[2][2];
        end
        33, 69 : begin 
            a_mul_in0 = img_r [3][0]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [3][1]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [3][2]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [4][0]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [4][1]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [4][2]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [5][0]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [5][1]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [5][2]; b_mul_in8 = kernel_r[2][2];
        end
        34, 70 : begin 
            a_mul_in0 = img_r [3][1]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [3][2]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [3][3]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [4][1]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [4][2]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [4][3]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [5][1]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [5][2]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [5][3]; b_mul_in8 = kernel_r[2][2];
        end
        35, 71 : begin 
            a_mul_in0 = img_r [3][2]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [3][3]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [3][4]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [4][2]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [4][3]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [4][4]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [5][2]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [5][3]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [5][4]; b_mul_in8 = kernel_r[2][2];
        end
        36, 72 : begin 
            a_mul_in0 = img_r [3][3]; b_mul_in0 = kernel_r[0][0];    
            a_mul_in1 = img_r [3][4]; b_mul_in1 = kernel_r[0][1];
            a_mul_in2 = img_r [3][5]; b_mul_in2 = kernel_r[0][2];
            a_mul_in3 = img_r [4][3]; b_mul_in3 = kernel_r[1][0];
            a_mul_in4 = img_r [4][4]; b_mul_in4 = kernel_r[1][1];
            a_mul_in5 = img_r [4][5]; b_mul_in5 = kernel_r[1][2];    
            a_mul_in6 = img_r [5][3]; b_mul_in6 = kernel_r[2][0];
            a_mul_in7 = img_r [5][4]; b_mul_in7 = kernel_r[2][1];
            a_mul_in8 = img_r [5][5]; b_mul_in8 = kernel_r[2][2];
        end
		42, 78 : begin
			a_mul_in0 = max_pool_r[0][0]; b_mul_in0 = weight_r[0][0];    
            a_mul_in1 = max_pool_r[0][1]; b_mul_in1 = weight_r[1][0];
            a_mul_in2 = max_pool_r[0][0]; b_mul_in2 = weight_r[0][1];
            a_mul_in3 = max_pool_r[0][1]; b_mul_in3 = weight_r[1][1];
            a_mul_in4 = max_pool_r[1][0]; b_mul_in4 = weight_r[0][0];
            a_mul_in5 = max_pool_r[1][1]; b_mul_in5 = weight_r[1][0];    
            a_mul_in6 = max_pool_r[1][0]; b_mul_in6 = weight_r[0][1];
            a_mul_in7 = max_pool_r[1][1]; b_mul_in7 = weight_r[1][1];
            a_mul_in8 = 0; b_mul_in8 = 0;
        end
		default : begin
            a_mul_in0 = 0; b_mul_in0 = 0;    
            a_mul_in1 = 0; b_mul_in1 = 0;
            a_mul_in2 = 0; b_mul_in2 = 0;
            a_mul_in3 = 0; b_mul_in3 = 0;
            a_mul_in4 = 0; b_mul_in4 = 0;
            a_mul_in5 = 0; b_mul_in5 = 0;    
            a_mul_in6 = 0; b_mul_in6 = 0;
            a_mul_in7 = 0; b_mul_in7 = 0;
            a_mul_in8 = 0; b_mul_in8 = 0;
        end
	endcase
end

// dot product
always @(*) begin
	dp0 = a_mul_in0 * b_mul_in0;
	dp1 = a_mul_in1 * b_mul_in1;
	dp2 = a_mul_in2 * b_mul_in2;
	dp3 = a_mul_in3 * b_mul_in3;
	dp4 = a_mul_in4 * b_mul_in4;
	dp5 = a_mul_in5 * b_mul_in5;
	dp6 = a_mul_in6 * b_mul_in6;
	dp7 = a_mul_in7 * b_mul_in7;
	dp8 = a_mul_in8 * b_mul_in8;
end

// fully connected sum
always @(*) begin
	fc_sum0 = dp0 + dp1;
	fc_sum1 = dp2 + dp3;
	fc_sum2 = dp4 + dp5;
	fc_sum3 = dp6 + dp7;
end

// conv sum 
always @(*) begin
	dp_sum = (fc_sum0 + fc_sum1) + (fc_sum2 + fc_sum3 + dp8);
end


GATED_OR GATED_CONV ( .CLOCK(clk), .SLEEP_CTRL(cg_en && conv_sleep), .RST_N(rst_n), .CLOCK_GATED(conv_clk) );
// feature map 4X4
always @(posedge conv_clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
				feature_map_r[i][j] <= 0;
			end
		end
	end
	else begin
		case(count_r)
			21, 57 : feature_map_r[0][0] <= dp_sum;
			22, 58 : feature_map_r[0][1] <= dp_sum;
			23, 59 : feature_map_r[0][2] <= dp_sum;
			24, 60 : feature_map_r[0][3] <= dp_sum;
			25, 61 : feature_map_r[1][0] <= dp_sum;
			26, 62 : feature_map_r[1][1] <= dp_sum;
			27, 63 : feature_map_r[1][2] <= dp_sum;
			28, 64 : feature_map_r[1][3] <= dp_sum;
			29, 65 : feature_map_r[2][0] <= dp_sum;
			30, 66 : feature_map_r[2][1] <= dp_sum;
			31, 67 : feature_map_r[2][2] <= dp_sum;
			32, 68 : feature_map_r[2][3] <= dp_sum;
			33, 69 : feature_map_r[3][0] <= dp_sum;
			34, 70 : feature_map_r[3][1] <= dp_sum;
			35, 71 : feature_map_r[3][2] <= dp_sum;
			36, 72 : feature_map_r[3][3] <= dp_sum;
			default : begin
				for(i = 0; i < 4; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        feature_map_r[i][j] <= feature_map_r[i][j];
                    end
                end
			end
		endcase
	end
end

GATED_OR GATED_FC ( .CLOCK(clk), .SLEEP_CTRL(cg_en && fc_sleep), .RST_N(rst_n), .CLOCK_GATED(fc_clk) );

// fully connected store flatten
always @(posedge fc_clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0; i < 4; i = i + 1) begin
			flatten_r[i] <= 0;
		end
	end
	else begin
		case(count_r)
			42, 78 : begin
				flatten_r[0] <= fc_sum0;
				flatten_r[1] <= fc_sum1;
				flatten_r[2] <= fc_sum2;
				flatten_r[3] <= fc_sum3;
			end
			default : begin
				for(i = 0; i < 4; i = i + 1) begin
					flatten_r[i] <= ~flatten_r[i];
				end
			end
		endcase
	end
end

//==============================================//
//                  quantization                //
//==============================================//

// choose divide input
always @(*) begin
	case (count_r)
		//25, 61 : begin
		37, 73 : begin	
			a_div_in0 = feature_map_r[0][0];
			a_div_in1 = feature_map_r[0][1];
			a_div_in2 = feature_map_r[0][2];
			a_div_in3 = feature_map_r[0][3];
			b_div_in0 = Q_SCALE1;
			b_div_in1 = Q_SCALE1;
			b_div_in2 = Q_SCALE1;
			b_div_in3 = Q_SCALE1;
		end
		//29, 65 : begin
		38, 74 : begin
			a_div_in0 = feature_map_r[1][0];
			a_div_in1 = feature_map_r[1][1];
			a_div_in2 = feature_map_r[1][2];
			a_div_in3 = feature_map_r[1][3];
			b_div_in0 = Q_SCALE1;
			b_div_in1 = Q_SCALE1;
			b_div_in2 = Q_SCALE1;
			b_div_in3 = Q_SCALE1;
		end
		//33, 69 : begin
		39, 75 : begin
			a_div_in0 = feature_map_r[2][0];
			a_div_in1 = feature_map_r[2][1];
			a_div_in2 = feature_map_r[2][2];
			a_div_in3 = feature_map_r[2][3];
			b_div_in0 = Q_SCALE1;
			b_div_in1 = Q_SCALE1;
			b_div_in2 = Q_SCALE1;
			b_div_in3 = Q_SCALE1;
		end
		// 37, 73 : begin
		40, 76 : begin
			a_div_in0 = feature_map_r[3][0];
			a_div_in1 = feature_map_r[3][1];
			a_div_in2 = feature_map_r[3][2];
			a_div_in3 = feature_map_r[3][3];
			b_div_in0 = Q_SCALE1;
			b_div_in1 = Q_SCALE1;
			b_div_in2 = Q_SCALE1;
			b_div_in3 = Q_SCALE1;
		end
		43, 79 : begin
			a_div_in0 = flatten_r[0];
			a_div_in1 = flatten_r[1];
			a_div_in2 = flatten_r[2];
			a_div_in3 = flatten_r[3];
			b_div_in0 = Q_SCALE2;
			b_div_in1 = Q_SCALE2;
			b_div_in2 = Q_SCALE2;
			b_div_in3 = Q_SCALE2;
		end
		default : begin
			a_div_in0 = 0;
			a_div_in1 = 0;
			a_div_in2 = 0;
			a_div_in3 = 0;
			b_div_in0 = 0;
			b_div_in1 = 0;
			b_div_in2 = 0;
			b_div_in3 = 0;
		end
	endcase
end

// divide
always @(*) begin
	quant_out0 = a_div_in0 / b_div_in0;
	quant_out1 = a_div_in1 / b_div_in1;
	quant_out2 = a_div_in2 / b_div_in2;
	quant_out3 = a_div_in3 / b_div_in3;
end


GATED_OR GATED_QUANT1 ( .CLOCK(clk), .SLEEP_CTRL(cg_en && quant1_sleep), .RST_N(rst_n), .CLOCK_GATED(quant1_clk) );

// quantiztion 4X4
always @(posedge quant1_clk or negedge rst_n) begin
    if (!rst_n) begin
		for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
				quant1_r[i][j] <= 0;
			end
		end
	end
	else begin
		if (count_r == 37 || count_r == 73) begin
			quant1_r[0][0] <= quant_out0;
			quant1_r[0][1] <= quant_out1;
			quant1_r[0][2] <= quant_out2;
			quant1_r[0][3] <= quant_out3;
		end
		else if (count_r == 38 || count_r == 74) begin
			quant1_r[1][0] <= quant_out0;
			quant1_r[1][1] <= quant_out1;
			quant1_r[1][2] <= quant_out2;
			quant1_r[1][3] <= quant_out3;
		end
		else if (count_r == 39 || count_r == 75) begin
			quant1_r[2][0] <= quant_out0;
			quant1_r[2][1] <= quant_out1;
			quant1_r[2][2] <= quant_out2;
			quant1_r[2][3] <= quant_out3;
		end
		else if (count_r == 40 || count_r == 76) begin
			quant1_r[3][0] <= quant_out0;
			quant1_r[3][1] <= quant_out1;
			quant1_r[3][2] <= quant_out2;
			quant1_r[3][3] <= quant_out3;
		end
		else begin
			for(i = 0; i < 4; i = i + 1) begin
				for(j = 0; j < 4; j = j + 1) begin
					quant1_r[i][j] <= quant1_r[i][j];
				end
			end
		end
	end
end

GATED_OR GATED_QUANT2_1 ( .CLOCK(clk), .SLEEP_CTRL(cg_en && quant2_1_sleep), .RST_N(rst_n), .CLOCK_GATED(quant2_1_clk) );

// final quantiztion img1 4X1
always @(posedge quant2_1_clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0; i < 4; i = i + 1) begin
			quant_final1_r[i] <= 0;
		end
	end
	else begin
		if (count_r == 43) begin
			quant_final1_r[0] <= quant_out0;
			quant_final1_r[1] <= quant_out1;
			quant_final1_r[2] <= quant_out2;
			quant_final1_r[3] <= quant_out3;
		end
		else  begin
			for(i = 0; i < 4; i = i + 1) begin
				quant_final1_r[i] <= ~quant_final1_r[i];
			end
		end
	end
end

GATED_OR GATED_QUANT2_2 ( .CLOCK(clk), .SLEEP_CTRL(cg_en && quant2_2_sleep), .RST_N(rst_n), .CLOCK_GATED(quant2_2_clk) );

// final quantiztion img2 4X1
always @(posedge quant2_2_clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0; i < 4; i = i + 1) begin
			quant_final2_r[i] <= 0;
		end
	end
	else begin
		case (count_r)
			79 : begin
				quant_final2_r[0] <= quant_out0;
				quant_final2_r[1] <= quant_out1;
				quant_final2_r[2] <= quant_out2;
				quant_final2_r[3] <= quant_out3;
			end
			default : begin
				for(i = 0; i < 4; i = i + 1) begin
					quant_final2_r[i] <= ~quant_final2_r[i];
				end
			end
		endcase
	end
end



//==============================================//
//                  max pooling                 //
//==============================================//

// select cmp input
always @(*) begin
	case(count_r) 
		41, 77 : begin
			cmp_in_0_0 = quant1_r[0][0];
			cmp_in_0_1 = quant1_r[0][1];
			cmp_in_0_2 = quant1_r[1][0];
			cmp_in_0_3 = big_0_0;
			cmp_in_0_4 = quant1_r[1][1];
			cmp_in_0_5 = big_0_1;
			
			cmp_in_1_0 = quant1_r[0][2];
			cmp_in_1_1 = quant1_r[0][3];
			cmp_in_1_2 = quant1_r[1][2];
			cmp_in_1_3 = big_1_0;
			cmp_in_1_4 = quant1_r[1][3];
			cmp_in_1_5 = big_1_1;
		
			cmp_in_2_0 = quant1_r[2][0];
			cmp_in_2_1 = quant1_r[2][1];
			cmp_in_2_2 = quant1_r[3][0];
			cmp_in_2_3 = big_2_0;
			cmp_in_2_4 = quant1_r[3][1];
			cmp_in_2_5 = big_2_1;
		
			cmp_in_3_0 = quant1_r[2][2];
			cmp_in_3_1 = quant1_r[2][3];
			cmp_in_3_2 = quant1_r[3][2];
			cmp_in_3_3 = big_3_0;
			cmp_in_3_4 = quant1_r[3][3];
			cmp_in_3_5 = big_3_1;
		end
		default : begin
			cmp_in_0_0 = 0;
			cmp_in_0_1 = 0;
			cmp_in_0_2 = 0;
			cmp_in_0_3 = 0;
			cmp_in_0_4 = 0;
			cmp_in_0_5 = 0;
			
			cmp_in_1_0 = 0;
			cmp_in_1_1 = 0;
			cmp_in_1_2 = 0;
			cmp_in_1_3 = 0;
			cmp_in_1_4 = 0;
			cmp_in_1_5 = 0;
		
			cmp_in_2_0 = 0;
			cmp_in_2_1 = 0;
			cmp_in_2_2 = 0;
			cmp_in_2_3 = 0;
			cmp_in_2_4 = 0;
			cmp_in_2_5 = 0;
		
			cmp_in_3_0 = 0;
			cmp_in_3_1 = 0;
			cmp_in_3_2 = 0;
			cmp_in_3_3 = 0;
			cmp_in_3_4 = 0;
			cmp_in_3_5 = 0;
		end
	endcase
end

// compare
always @(*) begin
	big_0_0 = (cmp_in_0_0 > cmp_in_0_1)? cmp_in_0_0 : cmp_in_0_1;
	big_0_1 = (cmp_in_0_2 > cmp_in_0_3)? cmp_in_0_2 : cmp_in_0_3;
	max_pool_0 = (cmp_in_0_4 > cmp_in_0_5)? cmp_in_0_4 : cmp_in_0_5;

	big_1_0 = (cmp_in_1_0 > cmp_in_1_1)? cmp_in_1_0 : cmp_in_1_1;
	big_1_1 = (cmp_in_1_2 > cmp_in_1_3)? cmp_in_1_2 : cmp_in_1_3;
	max_pool_1 = (cmp_in_1_4 > cmp_in_1_5)? cmp_in_1_4 : cmp_in_1_5;

	big_2_0 = (cmp_in_2_0 > cmp_in_2_1)? cmp_in_2_0 : cmp_in_2_1;
	big_2_1 = (cmp_in_2_2 > cmp_in_2_3)? cmp_in_2_2 : cmp_in_2_3;
	max_pool_2 = (cmp_in_2_4 > cmp_in_2_5)? cmp_in_2_4 : cmp_in_2_5;

	big_3_0 = (cmp_in_3_0 > cmp_in_3_1)? cmp_in_3_0 : cmp_in_3_1;
	big_3_1 = (cmp_in_3_2 > cmp_in_3_3)? cmp_in_3_2 : cmp_in_3_3;
	max_pool_3 = (cmp_in_3_4 > cmp_in_3_5)? cmp_in_3_4 : cmp_in_3_5;
end

GATED_OR GATED_MAX_POOL ( .CLOCK(clk), .SLEEP_CTRL(cg_en && max_pool_sleep), .RST_N(rst_n), .CLOCK_GATED(max_pool_clk) );

// store max pool
always @(posedge max_pool_clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) begin	
				max_pool_r[i][j] <= 0;	
			end
		end
	end
	else begin
		if (count_r == 41 || count_r == 77) begin
			max_pool_r[0][0] <= max_pool_0;
			max_pool_r[0][1] <= max_pool_1;
			max_pool_r[1][0] <= max_pool_2;
			max_pool_r[1][1] <= max_pool_3;
		end
		else  begin
			for(i = 0; i < 2; i = i + 1) begin
				for(j = 0; j < 2; j = j + 1) begin	
					max_pool_r[i][j] <= ~max_pool_r[i][j];	
				end
			end
		end
	end
end
		
//==============================================//
//          L1 distance  Activate               //
//==============================================//

// distance
always @(*) begin
	d0 = quant_final1_r[0] - quant_final2_r[0];
	d1 = quant_final1_r[1] - quant_final2_r[1];
	d2 = quant_final1_r[2] - quant_final2_r[2];
	d3 = quant_final1_r[3] - quant_final2_r[3];
end

// absolute
always @(*) begin
	pos_d0 = (d0[9])? (~d0) + 10'd1 : d0;
	pos_d1 = (d1[9])? (~d1) + 10'd1 : d1;
	pos_d2 = (d2[9])? (~d2) + 10'd1 : d2;
	pos_d3 = (d3[9])? (~d3) + 10'd1 : d3;
end

// L1 distance
always @(*) begin
	L1_distance = pos_d0 + pos_d1 + pos_d2 + pos_d3;
end

// activation
always @(*) begin
	similarity_score = (L1_distance < 16)? 0 : L1_distance;
end

//==============================================//
//                   OUTPUT                     //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		out_valid <= 0;
		out_data <= 0;
	end
	else if (count_r == 80) begin
		out_valid <= 1;
		out_data <= similarity_score;
	end
	else begin
		out_valid <= 0;
		out_data <= 0;
	end
end


endmodule
//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

//================================================================
// PARAMETER
//================================================================
parameter A = 4'd14;
parameter B = 4'd13;
parameter C = 4'd12;
parameter E = 4'd11;
parameter I = 4'd10;
parameter L = 4'd9;
parameter O = 4'd8;
parameter V = 4'd7;

parameter SUBTREE0 = 4'd6;
parameter SUBTREE1 = 4'd5;
parameter SUBTREE2 = 4'd4;
parameter SUBTREE3 = 4'd3;
parameter SUBTREE4 = 4'd2;
parameter SUBTREE5 = 4'd1;
parameter SUBTREE6 = 4'd0;


//FSM
`define STATE_BITS 4
parameter IDLE =        `STATE_BITS'd0;
parameter DATA_IN =     `STATE_BITS'd1;
parameter COMBINE_0 =   `STATE_BITS'd2;
parameter COMBINE_1 =   `STATE_BITS'd3;
parameter COMBINE_2 =   `STATE_BITS'd4;
parameter COMBINE_3 =   `STATE_BITS'd5;
parameter COMBINE_4 =   `STATE_BITS'd6;
parameter COMBINE_5 =   `STATE_BITS'd7;
parameter COMBINE_6 =   `STATE_BITS'd8;
parameter ILOVE =       `STATE_BITS'd9;
parameter ICLAB =       `STATE_BITS'd10;

integer i;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================



reg [3:0] current_state, next_state;
reg out_mode_r;
reg [5:0] weight [0:15];
reg [3:0] IN_character_r [0:7];
reg [4:0] IN_weight_r [0:7];
wire [31:0] OUT_character;

reg [7:0] huff_contain[14:0];
reg [7:0] encode [7:0];
reg [2:0] count_bit [7:0];
reg [19:0] code_r;

reg [2:0]  count_char, count_lenght;
reg [2:0]  bit_length;
reg [7:0] select_code;


// ===============================================================
// Design
// ===============================================================

//FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case (current_state)
        IDLE : next_state = (in_valid)? DATA_IN : IDLE;
        DATA_IN : next_state = (!in_valid)? COMBINE_0 : DATA_IN;
        COMBINE_0 : next_state = COMBINE_1;
        COMBINE_1 : next_state = COMBINE_2;
        COMBINE_2 : next_state = COMBINE_3;
        COMBINE_3 : next_state = COMBINE_4;
        COMBINE_4 : next_state = COMBINE_5;
        COMBINE_5 : next_state = COMBINE_6;
        COMBINE_6 : next_state = (out_mode_r)? ICLAB : ILOVE;
        ICLAB : next_state = (count_char == 4 && count_lenght == bit_length - 1)? IDLE : ICLAB;
        ILOVE : next_state = (count_char == 4 && count_lenght == bit_length - 1)? IDLE : ILOVE;
        default : next_state = IDLE;
    endcase
end

// store mode
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_mode_r <= 0;
    end
    else if (current_state == IDLE && in_valid) begin
        out_mode_r <= out_mode;
    end
    else begin
        out_mode_r <= out_mode_r;
    end
end

// store weight
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 15; i = i + 1) begin
            weight[i] <= 0;
        end
        weight[15] <= 5'd31;
    end
    else if (in_valid) begin
        for (i = 0; i < 7; i = i + 1) begin
            weight[i] <= 0;
        end
        weight[V] <= in_weight;
        weight[O] <= weight[V];
        weight[L] <= weight[O];
        weight[I] <= weight[L];
        weight[E] <= weight[I];
        weight[C] <= weight[E];
        weight[B] <= weight[C];
        weight[A] <= weight[B];
    end
    else if (current_state == COMBINE_0) begin
        weight[SUBTREE0] <= weight[OUT_character[7:4]] + weight[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_1) begin
        weight[SUBTREE1] <= weight[OUT_character[7:4]] + weight[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_2) begin
        weight[SUBTREE2] <= weight[OUT_character[7:4]] + weight[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_3) begin
        weight[SUBTREE3] <= weight[OUT_character[7:4]] + weight[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_4) begin
        weight[SUBTREE4] <= weight[OUT_character[7:4]] + weight[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_5) begin
        weight[SUBTREE5] <= weight[OUT_character[7:4]] + weight[OUT_character[3:0]];
    end
    else begin
        for (i = 0; i < 16; i = i + 1) begin
            weight[i] <= weight[i];
        end
    end
end

// choose IN_character_r
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 8; i = i + 1) begin
            IN_character_r[i] <= 0;
        end
    end
    else if (in_valid) begin
        IN_character_r[0] <= A; 
        IN_character_r[1] <= B;
        IN_character_r[2] <= C;
        IN_character_r[3] <= E;
        IN_character_r[4] <= I;
        IN_character_r[5] <= L;
        IN_character_r[6] <= O;
        IN_character_r[7] <= V;
    end
    else if (current_state == COMBINE_0) begin
        IN_character_r[0] <= 4'd15; 
        IN_character_r[1] <= OUT_character[31:28];
        IN_character_r[2] <= OUT_character[27:24];
        IN_character_r[3] <= OUT_character[23:20];
        IN_character_r[4] <= OUT_character[19:16];
        IN_character_r[5] <= OUT_character[15:12];
        IN_character_r[6] <= OUT_character[11:8];
        IN_character_r[7] <= SUBTREE0;
    end
    else if (current_state == COMBINE_1) begin
        IN_character_r[0] <= 4'd15; 
        IN_character_r[1] <= 4'd15;
        IN_character_r[2] <= OUT_character[27:24];
        IN_character_r[3] <= OUT_character[23:20];
        IN_character_r[4] <= OUT_character[19:16];
        IN_character_r[5] <= OUT_character[15:12];
        IN_character_r[6] <= OUT_character[11:8];
        IN_character_r[7] <= SUBTREE1;
    end
    else if (current_state == COMBINE_2) begin
        IN_character_r[0] <= 4'd15; 
        IN_character_r[1] <= 4'd15;
        IN_character_r[2] <= 4'd15;
        IN_character_r[3] <= OUT_character[23:20];
        IN_character_r[4] <= OUT_character[19:16];
        IN_character_r[5] <= OUT_character[15:12];
        IN_character_r[6] <= OUT_character[11:8];
        IN_character_r[7] <= SUBTREE2;
    end
    else if (current_state == COMBINE_3) begin
        IN_character_r[0] <= 4'd15; 
        IN_character_r[1] <= 4'd15;
        IN_character_r[2] <= 4'd15;
        IN_character_r[3] <= 4'd15;
        IN_character_r[4] <= OUT_character[19:16];
        IN_character_r[5] <= OUT_character[15:12];
        IN_character_r[6] <= OUT_character[11:8];
        IN_character_r[7] <= SUBTREE3;
    end
    else if (current_state == COMBINE_4) begin
        IN_character_r[0] <= 4'd15; 
        IN_character_r[1] <= 4'd15;
        IN_character_r[2] <= 4'd15;
        IN_character_r[3] <= 4'd15;
        IN_character_r[4] <= 4'd15;
        IN_character_r[5] <= OUT_character[15:12];
        IN_character_r[6] <= OUT_character[11:8];
        IN_character_r[7] <= SUBTREE4;
    end
    else if (current_state == COMBINE_5) begin
        IN_character_r[0] <= 4'd15; 
        IN_character_r[1] <= 4'd15;
        IN_character_r[2] <= 4'd15;
        IN_character_r[3] <= 4'd15;
        IN_character_r[4] <= 4'd15;
        IN_character_r[5] <= 4'd15;
        IN_character_r[6] <= OUT_character[11:8];
        IN_character_r[7] <= SUBTREE5;
    end
    else if (current_state == IDLE) begin
        for (i = 0; i < 8; i = i + 1) begin
            IN_character_r[i] <= 0;
        end
    end
    else begin
        for (i = 0; i < 8; i = i + 1) begin
            IN_character_r[i] <= IN_character_r[i];
        end
    end
end

// choose IN_weight_r
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 8; i = i + 1) begin
            IN_weight_r[i] <= 0;
        end
    end
    else if (in_valid) begin
        IN_weight_r[7] <= in_weight;
        IN_weight_r[6] <= IN_weight_r[7];
        IN_weight_r[5] <= IN_weight_r[6];
        IN_weight_r[4] <= IN_weight_r[5];
        IN_weight_r[3] <= IN_weight_r[4];
        IN_weight_r[2] <= IN_weight_r[3];
        IN_weight_r[1] <= IN_weight_r[2];
        IN_weight_r[0] <= IN_weight_r[1];
    end
    else if (current_state == COMBINE_0 || current_state == COMBINE_1 || current_state == COMBINE_2 || current_state == COMBINE_3 || current_state == COMBINE_4 || current_state == COMBINE_5) begin
        IN_weight_r[0] <= 5'd31;
        IN_weight_r[1] <= weight[OUT_character[31:28]];
        IN_weight_r[2] <= weight[OUT_character[27:24]];
        IN_weight_r[3] <= weight[OUT_character[23:20]];
        IN_weight_r[4] <= weight[OUT_character[19:16]];
        IN_weight_r[5] <= weight[OUT_character[15:12]];
        IN_weight_r[6] <= weight[OUT_character[11: 8]];
        IN_weight_r[7] <= weight[OUT_character[7:4]] + weight[OUT_character[3:0]];
    end
    else if (current_state == IDLE) begin
        for (i = 0; i < 8; i = i + 1) begin
            IN_weight_r[i] <= 0;
        end
    end
    else begin
        for (i = 0; i < 8; i = i + 1) begin
            IN_weight_r[i] <= IN_weight_r[i];
        end
    end   
end

// sort IP
SORT_IP #(.IP_WIDTH(8)) 
SORT_U0(.IN_character({IN_character_r[0], IN_character_r[1], IN_character_r[2], IN_character_r[3], IN_character_r[4], IN_character_r[5], IN_character_r[6], IN_character_r[7]}), 
        .IN_weight({IN_weight_r[0], IN_weight_r[1], IN_weight_r[2], IN_weight_r[3], IN_weight_r[4], IN_weight_r[5], IN_weight_r[6], IN_weight_r[7]}), 
        .OUT_character(OUT_character));

// to mark the character in substree
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        huff_contain[A] <= 8'b10000000;
        huff_contain[B] <= 8'b01000000;
        huff_contain[C] <= 8'b00100000;
        huff_contain[E] <= 8'b00010000;
        huff_contain[I] <= 8'b00001000;
        huff_contain[L] <= 8'b00000100;
        huff_contain[O] <= 8'b00000010;
        huff_contain[V] <= 8'b00000001;
        
        huff_contain[SUBTREE0] <= 8'd0;
        huff_contain[SUBTREE1] <= 8'd0;
        huff_contain[SUBTREE2] <= 8'd0;
        huff_contain[SUBTREE3] <= 8'd0;
        huff_contain[SUBTREE4] <= 8'd0;
        huff_contain[SUBTREE5] <= 8'd0;
        huff_contain[SUBTREE6] <= 8'd0;
    end
    else if (current_state == COMBINE_0) begin
        huff_contain[SUBTREE0] <= huff_contain[OUT_character[7:4]] | huff_contain[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_1) begin
        huff_contain[SUBTREE1] <= huff_contain[OUT_character[7:4]] | huff_contain[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_2) begin
        huff_contain[SUBTREE2] <= huff_contain[OUT_character[7:4]] | huff_contain[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_3) begin
        huff_contain[SUBTREE3] <= huff_contain[OUT_character[7:4]] | huff_contain[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_4) begin
        huff_contain[SUBTREE4] <= huff_contain[OUT_character[7:4]] | huff_contain[OUT_character[3:0]];
    end
    else if (current_state == COMBINE_5) begin
        huff_contain[SUBTREE5] <= huff_contain[OUT_character[7:4]] | huff_contain[OUT_character[3:0]];
    end
    // else if (current_state == COMBINE_6) begin
    //     huff_contain[SUBTREE6] <= huff_contain[OUT_character[7:4]] | huff_contain[OUT_character[3:0]];
    // end
    else if (current_state == IDLE) begin
        huff_contain[A] <= 8'b10000000;
        huff_contain[B] <= 8'b01000000;
        huff_contain[C] <= 8'b00100000;
        huff_contain[E] <= 8'b00010000;
        huff_contain[I] <= 8'b00001000;
        huff_contain[L] <= 8'b00000100;
        huff_contain[O] <= 8'b00000010;
        huff_contain[V] <= 8'b00000001;
        
        huff_contain[SUBTREE0] <= 8'd0;
        huff_contain[SUBTREE1] <= 8'd0;
        huff_contain[SUBTREE2] <= 8'd0;
        huff_contain[SUBTREE3] <= 8'd0;
        huff_contain[SUBTREE4] <= 8'd0;
        huff_contain[SUBTREE5] <= 8'd0;
        huff_contain[SUBTREE6] <= 8'd0;
    end
    else begin
        huff_contain[A] <= huff_contain[A];
        huff_contain[B] <= huff_contain[B];
        huff_contain[C] <= huff_contain[C];
        huff_contain[E] <= huff_contain[E];
        huff_contain[I] <= huff_contain[I];
        huff_contain[L] <= huff_contain[L];
        huff_contain[O] <= huff_contain[O];
        huff_contain[V] <= huff_contain[V];
        
        huff_contain[SUBTREE0] <= huff_contain[SUBTREE0];
        huff_contain[SUBTREE1] <= huff_contain[SUBTREE1];
        huff_contain[SUBTREE2] <= huff_contain[SUBTREE2];
        huff_contain[SUBTREE3] <= huff_contain[SUBTREE3];
        huff_contain[SUBTREE4] <= huff_contain[SUBTREE4];
        huff_contain[SUBTREE5] <= huff_contain[SUBTREE5];
        huff_contain[SUBTREE6] <= huff_contain[SUBTREE6];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 8; i = i + 1) begin
            encode[i] <= 0;
        end
    end
    else if (current_state == COMBINE_0 || current_state == COMBINE_1 || current_state == COMBINE_2 || current_state == COMBINE_3 || current_state == COMBINE_4 || current_state == COMBINE_5 || current_state == COMBINE_6) begin
        encode[7] <= (huff_contain[OUT_character[7:4]][7])? ({encode[7][6:0], 1'b0}) : (huff_contain[OUT_character[3:0]][7])? ({encode[7][6:0], 1'b1}) : encode[7]; // A
        encode[6] <= (huff_contain[OUT_character[7:4]][6])? ({encode[6][6:0], 1'b0}) : (huff_contain[OUT_character[3:0]][6])? ({encode[6][6:0], 1'b1}) : encode[6]; // B
        encode[5] <= (huff_contain[OUT_character[7:4]][5])? ({encode[5][6:0], 1'b0}) : (huff_contain[OUT_character[3:0]][5])? ({encode[5][6:0], 1'b1}) : encode[5]; // C
        encode[4] <= (huff_contain[OUT_character[7:4]][4])? ({encode[4][6:0], 1'b0}) : (huff_contain[OUT_character[3:0]][4])? ({encode[4][6:0], 1'b1}) : encode[4]; // E
        encode[3] <= (huff_contain[OUT_character[7:4]][3])? ({encode[3][6:0], 1'b0}) : (huff_contain[OUT_character[3:0]][3])? ({encode[3][6:0], 1'b1}) : encode[3]; // I
        encode[2] <= (huff_contain[OUT_character[7:4]][2])? ({encode[2][6:0], 1'b0}) : (huff_contain[OUT_character[3:0]][2])? ({encode[2][6:0], 1'b1}) : encode[2]; // L
        encode[1] <= (huff_contain[OUT_character[7:4]][1])? ({encode[1][6:0], 1'b0}) : (huff_contain[OUT_character[3:0]][1])? ({encode[1][6:0], 1'b1}) : encode[1]; // O
        encode[0] <= (huff_contain[OUT_character[7:4]][0])? ({encode[0][6:0], 1'b0}) : (huff_contain[OUT_character[3:0]][0])? ({encode[0][6:0], 1'b1}) : encode[0]; // V
    end
    else if (current_state == IDLE) begin
        for (i = 0; i < 8; i = i + 1) begin
            encode[i] <= 0;
        end
    end
    else begin
        for (i = 0; i < 8; i = i + 1) begin
            encode[i] <= encode[i];
        end
    end
end

// count each character bit
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 8; i = i + 1) begin
            count_bit[i] <= 0;
        end
    end
    else if (current_state == COMBINE_0 || current_state == COMBINE_1 || current_state == COMBINE_2 || current_state == COMBINE_3 || current_state == COMBINE_4 || current_state == COMBINE_5 || current_state == COMBINE_6) begin
        for (i = 0; i < 8; i = i + 1) begin
            count_bit[i] <= count_bit[i] + huff_contain[OUT_character[7:4]][i] + huff_contain[OUT_character[3:0]][i];
        end
    end
    else if (current_state == IDLE) begin
        for (i = 0; i < 8; i = i + 1) begin
            count_bit[i] <= 0;
        end
    end
    else begin
        for (i = 0; i < 8; i = i + 1) begin
            count_bit[i] <= count_bit[i];
        end
    end
end

// move to next character
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_char <= 0;
    end
    else if (current_state == ILOVE || current_state == ICLAB) begin
        count_char <= (count_lenght == bit_length - 1)? count_char + 1 : count_char;
    end
    else begin
        count_char <= 0;
    end
end

// count each character number
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_lenght <= 0;
    end
    else if (current_state == ILOVE || current_state == ICLAB) begin
        count_lenght <= (count_lenght == bit_length - 1)? 0 : count_lenght + 1;
    end
    else begin
        count_lenght <= 0;
    end
end

// select bit lenght and select code
always @(*) begin
    if (current_state == ILOVE) begin
        case(count_char)
            0: begin bit_length = count_bit[3];    select_code = encode[3]; end // I
            1: begin bit_length = count_bit[2];    select_code = encode[2]; end // L
            2: begin bit_length = count_bit[1];    select_code = encode[1]; end // O
            3: begin bit_length = count_bit[0];    select_code = encode[0]; end // V
            4: begin bit_length = count_bit[4];    select_code = encode[4]; end // E
            default: begin bit_length = 0; select_code = 0; end
        endcase
    end
    else if (current_state == ICLAB) begin
        case(count_char)
            0: begin bit_length = count_bit[3];    select_code = encode[3]; end // I
            1: begin bit_length = count_bit[5];    select_code = encode[5]; end // C
            2: begin bit_length = count_bit[2];    select_code = encode[2]; end // L
            3: begin bit_length = count_bit[7];    select_code = encode[7]; end // A
            4: begin bit_length = count_bit[6];    select_code = encode[6]; end // B
            default: begin bit_length = 0; select_code = 0; end
        endcase
    end
    else begin
        bit_length = 0;
        select_code  = 0;
    end
end


// output
always @(*) begin
    if (!rst_n) begin
        out_valid = 0;
        out_code  = 0;
    end
    else if (current_state == ICLAB || current_state == ILOVE) begin
        out_valid = 1;
        out_code  = select_code[count_lenght];
    end
    else begin
        out_valid = 0;
        out_code  = 0;
    end
end





endmodule
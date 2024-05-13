//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Cheng-Te Chang (chengdez.ee12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
parameter inst_extra_prec = 0;
parameter ONE = {1'b0, 8'd127, 23'd0};
integer i, j, k;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

reg [6:0] count_r;
reg [31:0] img_r[0:3][0:3];
reg [31:0] kernel_r[0:2][0:2][0:2];
reg [31:0] weight_r[0:1][0:1];
reg [31:0] img_padding[0:5][0:5];
reg [1:0] opt_r;
reg [31:0] kernel_temp[0:2][0:2];
reg [31:0] a_mul_in0, a_mul_in1, a_mul_in2, a_mul_in3, a_mul_in4, a_mul_in5, a_mul_in6, a_mul_in7, a_mul_in8;
reg [31:0] b_mul_in0, b_mul_in1, b_mul_in2, b_mul_in3, b_mul_in4, b_mul_in5, b_mul_in6, b_mul_in7, b_mul_in8;
reg [31:0] mul_out0_r, mul_out1_r, mul_out2_r, mul_out3_r, mul_out4_r, mul_out5_r, mul_out6_r, mul_out7_r, mul_out8_r;
reg [31:0] feature_map_r[0:3][0:3];
reg [31:0] feature_map_temp;
reg [31:0] max_pooling_r[0:1][0:1];
reg [31:0] sum_in_0, sum_in_1, sum_in_2, sum_in_3, sum_in_4, sum_in_5, sum_in_6, sum_in_7, sum_in_8, sum_in_9, sum_in_10, sum_in_11;
reg [31:0] flatten_r[0:3];
reg [31:0] cmp_in_0, cmp_in_1, cmp_in_2, cmp_in_3, cmp_in_4, cmp_in_5, cmp_in_6, cmp_in_7, cmp_in_8, cmp_in_9;
reg [31:0] x_max_r, x_min_r;
reg [31:0] numerator_r, denominator_r, norm_r;
reg [31:0] exp_pos_out_r, exp_neg_out_r;
reg [31:0] sigmoid_den_r, tanh_den_r, soft_plus_r, ln_out_r, tanh_num_r;
reg [31:0] sub_in_0, sub_in_1;
reg [31:0] relu_0_r, relu_1_r, relu_2_r, relu_3_r;

wire [31:0] mul_out0, mul_out1, mul_out2, mul_out3, mul_out4, mul_out5, mul_out6, mul_out7, mul_out8;
wire [31:0] sum3_out0, sum3_out1, sum3_out2, sum3_out_final; 
wire [31:0] feature_map_sum2_out;
wire [31:0] big_0, big_1, big_2, big_3, big_4, big_5, big_6, big_7, small_0, small_1, small_2, small_3, small_4, small_5, small_6, small_7, small_8, small_9, small_10, small_11;
wire [31:0] max_0, max_1, max_2, max_3;
wire [31:0] sub_out_0, sub_out_1, div_out, sub_out_2;
wire [31:0] exp_pos_out, exp_neg_out;
wire [31:0] ln_out;





assign DONE = (count_r == 72)? 1'b1 : 1'b0;
assign out_valid = (count_r >= 69 && count_r <= 72)? 1'b1 : 1'b0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_r <= 0;
    end
    else if(DONE) begin
        count_r <= 0;
    end
    else if (in_valid == 1'b1 || count_r != 0) begin
        count_r <= count_r + 1;
    end
    else begin
        count_r <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                img_r[i][j] <= 32'b0;
            end
        end
    end
    else if (in_valid) begin
        case(count_r)
            0,  16, 32 : img_r[0][0] <= Img;
            1,  17, 33 : img_r[0][1] <= Img;
            2,  18, 34 : img_r[0][2] <= Img;
            3,  19, 35 : img_r[0][3] <= Img;
            4,  20, 36 : img_r[1][0] <= Img;
            5,  21, 37 : img_r[1][1] <= Img;
            6,  22, 38 : img_r[1][2] <= Img;
            7,  23, 39 : img_r[1][3] <= Img;
            8,  24, 40 : img_r[2][0] <= Img;
            9,  25, 41 : img_r[2][1] <= Img;
            10, 26, 42 : img_r[2][2] <= Img;
            11, 27, 43 : img_r[2][3] <= Img;
            12, 28, 44 : img_r[3][0] <= Img;
            13, 29, 45 : img_r[3][1] <= Img;
            14, 30, 46 : img_r[3][2] <= Img;
            15, 31, 47 : img_r[3][3] <= Img;
            default : begin
                for(i = 0; i < 4; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        img_r[i][j] <= img_r[i][j];
                    end
                end
            end
        endcase
    end
    else begin
        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                img_r[i][j] <= img_r[i][j];
            end
        end
    end    
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 3; i = i + 1) begin
            for(j = 0; j < 3; j = j + 1) begin
                for(k = 0; k < 3; k = k + 1)begin
                    kernel_r[i][j][k] <= 32'b0;
                end
            end
        end
    end
    else if (count_r < 27) begin
        case(count_r)
            0 : kernel_r[0][0][0] <= Kernel;  9 : kernel_r[1][0][0] <= Kernel; 18 : kernel_r[2][0][0] <= Kernel;
            1 : kernel_r[0][0][1] <= Kernel; 10 : kernel_r[1][0][1] <= Kernel; 19 : kernel_r[2][0][1] <= Kernel;
            2 : kernel_r[0][0][2] <= Kernel; 11 : kernel_r[1][0][2] <= Kernel; 20 : kernel_r[2][0][2] <= Kernel;
            3 : kernel_r[0][1][0] <= Kernel; 12 : kernel_r[1][1][0] <= Kernel; 21 : kernel_r[2][1][0] <= Kernel;
            4 : kernel_r[0][1][1] <= Kernel; 13 : kernel_r[1][1][1] <= Kernel; 22 : kernel_r[2][1][1] <= Kernel;
            5 : kernel_r[0][1][2] <= Kernel; 14 : kernel_r[1][1][2] <= Kernel; 23 : kernel_r[2][1][2] <= Kernel;
            6 : kernel_r[0][2][0] <= Kernel; 15 : kernel_r[1][2][0] <= Kernel; 24 : kernel_r[2][2][0] <= Kernel;
            7 : kernel_r[0][2][1] <= Kernel; 16 : kernel_r[1][2][1] <= Kernel; 25 : kernel_r[2][2][1] <= Kernel;
            8 : kernel_r[0][2][2] <= Kernel; 17 : kernel_r[1][2][2] <= Kernel; 26 : kernel_r[2][2][2] <= Kernel;
            
            default : begin
                for(i = 0; i < 3; i = i + 1) begin
                    for(j = 0; j < 3; j = j + 1) begin
                        for(k = 0; k < 3; k = k + 1)begin
                            kernel_r[i][j][k] <= kernel_r[i][j][k];
                        end
                    end
                end
            end
        endcase
    end
    else begin
        for(i = 0; i < 3; i = i + 1) begin
            for(j = 0; j < 3; j = j + 1) begin
                for(k = 0; k < 3; k = k + 1)begin
                    kernel_r[i][j][k] <= kernel_r[i][j][k];
                end
            end
        end
    end
end

always @(*) begin
    if(opt_r[1]) begin
        img_padding [0][0] = img_r[0][0];   img_padding [0][1] = img_r[0][0];   img_padding [0][2] = img_r[0][1];   img_padding [0][3] = img_r[0][2];   img_padding [0][4] = img_r[0][3];   img_padding [0][5] = img_r[0][3];
        img_padding [1][0] = img_r[0][0];   img_padding [1][1] = img_r[0][0];   img_padding [1][2] = img_r[0][1];   img_padding [1][3] = img_r[0][2];   img_padding [1][4] = img_r[0][3];   img_padding [1][5] = img_r[0][3];
        img_padding [2][0] = img_r[1][0];   img_padding [2][1] = img_r[1][0];   img_padding [2][2] = img_r[1][1];   img_padding [2][3] = img_r[1][2];   img_padding [2][4] = img_r[1][3];   img_padding [2][5] = img_r[1][3];
        img_padding [3][0] = img_r[2][0];   img_padding [3][1] = img_r[2][0];   img_padding [3][2] = img_r[2][1];   img_padding [3][3] = img_r[2][2];   img_padding [3][4] = img_r[2][3];   img_padding [3][5] = img_r[2][3];
        img_padding [4][0] = img_r[3][0];   img_padding [4][1] = img_r[3][0];   img_padding [4][2] = img_r[3][1];   img_padding [4][3] = img_r[3][2];   img_padding [4][4] = img_r[3][3];   img_padding [4][5] = img_r[3][3];
        img_padding [5][0] = img_r[3][0];   img_padding [5][1] = img_r[3][0];   img_padding [5][2] = img_r[3][1];   img_padding [5][3] = img_r[3][2];   img_padding [5][4] = img_r[3][3];   img_padding [5][5] = img_r[3][3];
    end
    else begin
        img_padding [0][0] = 32'b0;         img_padding [0][1] = 32'b0;         img_padding [0][2] = 32'b0;         img_padding [0][3] = 32'b0;         img_padding [0][4] = 32'b0;         img_padding [0][5] = 32'b0;
        img_padding [1][0] = 32'b0;         img_padding [1][1] = img_r[0][0];   img_padding [1][2] = img_r[0][1];   img_padding [1][3] = img_r[0][2];   img_padding [1][4] = img_r[0][3];   img_padding [1][5] = 32'b0;
        img_padding [2][0] = 32'b0;         img_padding [2][1] = img_r[1][0];   img_padding [2][2] = img_r[1][1];   img_padding [2][3] = img_r[1][2];   img_padding [2][4] = img_r[1][3];   img_padding [2][5] = 32'b0;
        img_padding [3][0] = 32'b0;         img_padding [3][1] = img_r[2][0];   img_padding [3][2] = img_r[2][1];   img_padding [3][3] = img_r[2][2];   img_padding [3][4] = img_r[2][3];   img_padding [3][5] = 32'b0;
        img_padding [4][0] = 32'b0;         img_padding [4][1] = img_r[3][0];   img_padding [4][2] = img_r[3][1];   img_padding [4][3] = img_r[3][2];   img_padding [4][4] = img_r[3][3];   img_padding [4][5] = 32'b0;
        img_padding [5][0] = 32'b0;         img_padding [5][1] = 32'b0;         img_padding [5][2] = 32'b0;         img_padding [5][3] = 32'b0;         img_padding [5][4] = 32'b0;         img_padding [5][5] = 32'b0;
    end
end
            
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        weight_r[0][0] <= 0;    weight_r[0][1] <= 0;
        weight_r[1][0] <= 0;    weight_r[1][1] <= 0;
    end
    else if (DONE) begin
        weight_r[0][0] <= 0;    weight_r[0][1] <= 0;
        weight_r[1][0] <= 0;    weight_r[1][1] <= 0;
    end
    else if (in_valid) begin
        case(count_r)
            0: weight_r[0][0] <= Weight;
            1: weight_r[0][1] <= Weight;
            2: weight_r[1][0] <= Weight;
            3: weight_r[1][1] <= Weight;
            default: begin
                weight_r[0][0] <= weight_r[0][0];    weight_r[0][1] <= weight_r[0][1];
                weight_r[1][0] <= weight_r[1][0];    weight_r[1][1] <= weight_r[1][1];
            end
        endcase
    end
    else begin
        weight_r[0][0] <= weight_r[0][0];    weight_r[0][1] <= weight_r[0][1];
        weight_r[1][0] <= weight_r[1][0];    weight_r[1][1] <= weight_r[1][1];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        opt_r <= 2'd0;
    end
    else if (DONE) begin
        opt_r <= 2'd0;
    end
    else if (in_valid && count_r == 0) begin
        opt_r <= Opt;
    end
    else begin
        opt_r <= opt_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 3; i = i + 1) begin
            for(j = 0; j < 3; j = j + 1) begin
                kernel_temp[i][j] <= 0;
            end
        end
    end
    else if (count_r >= 9 && count_r <= 24) begin
        for(i = 0; i < 3; i = i + 1) begin
            for(j = 0; j < 3; j = j + 1) begin
                kernel_temp[i][j] <= kernel_r[0][i][j];
            end
        end 
    end
    else if (count_r >= 25 && count_r <= 40) begin
        for(i = 0; i < 3; i = i + 1) begin
            for(j = 0; j < 3; j = j + 1) begin
                kernel_temp[i][j] <= kernel_r[1][i][j];
            end
        end 
    end
    else if (count_r >= 41 && count_r <= 56) begin
        for(i = 0; i < 3; i = i + 1) begin
            for(j = 0; j < 3; j = j + 1) begin
                kernel_temp[i][j] <= kernel_r[2][i][j];
            end
        end 
    end
end
    

//conv
always @(*) begin
    case(count_r)
        10, 26, 42 : begin 
            a_mul_in0 = img_padding [0][0]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [0][1]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [0][2]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [1][0]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [1][1]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [1][2]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [2][0]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [2][1]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [2][2]; b_mul_in8 = kernel_temp[2][2];
        end
        11, 27, 43 : begin 
            a_mul_in0 = img_padding [0][1]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [0][2]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [0][3]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [1][1]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [1][2]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [1][3]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [2][1]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [2][2]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [2][3]; b_mul_in8 = kernel_temp[2][2];
        end
        12, 28, 44 : begin 
            a_mul_in0 = img_padding [0][2]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [0][3]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [0][4]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [1][2]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [1][3]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [1][4]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [2][2]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [2][3]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [2][4]; b_mul_in8 = kernel_temp[2][2];
        end
        13, 29, 45 : begin 
            a_mul_in0 = img_padding [0][3]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [0][4]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [0][5]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [1][3]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [1][4]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [1][5]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [2][3]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [2][4]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [2][5]; b_mul_in8 = kernel_temp[2][2];
        end
        14, 30, 46 : begin 
            a_mul_in0 = img_padding [1][0]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [1][1]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [1][2]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [2][0]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [2][1]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [2][2]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [3][0]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [3][1]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [3][2]; b_mul_in8 = kernel_temp[2][2];
        end
        15, 31, 47 : begin 
            a_mul_in0 = img_padding [1][1]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [1][2]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [1][3]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [2][1]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [2][2]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [2][3]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [3][1]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [3][2]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [3][3]; b_mul_in8 = kernel_temp[2][2];
        end
        16, 32, 48 : begin 
            a_mul_in0 = img_padding [1][2]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [1][3]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [1][4]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [2][2]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [2][3]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [2][4]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [3][2]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [3][3]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [3][4]; b_mul_in8 = kernel_temp[2][2];
        end
        17, 33, 49 : begin 
            a_mul_in0 = img_padding [1][3]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [1][4]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [1][5]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [2][3]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [2][4]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [2][5]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [3][3]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [3][4]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [3][5]; b_mul_in8 = kernel_temp[2][2];
        end
        18, 34, 50 : begin 
            a_mul_in0 = img_padding [2][0]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [2][1]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [2][2]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [3][0]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [3][1]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [3][2]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [4][0]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [4][1]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [4][2]; b_mul_in8 = kernel_temp[2][2];
        end
        19, 35, 51 : begin 
            a_mul_in0 = img_padding [2][1]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [2][2]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [2][3]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [3][1]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [3][2]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [3][3]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [4][1]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [4][2]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [4][3]; b_mul_in8 = kernel_temp[2][2];
        end
        20, 36, 52 : begin 
            a_mul_in0 = img_padding [2][2]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [2][3]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [2][4]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [3][2]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [3][3]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [3][4]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [4][2]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [4][3]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [4][4]; b_mul_in8 = kernel_temp[2][2];
        end
        21, 37, 53 : begin 
            a_mul_in0 = img_padding [2][3]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [2][4]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [2][5]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [3][3]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [3][4]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [3][5]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [4][3]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [4][4]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [4][5]; b_mul_in8 = kernel_temp[2][2];
        end
        22, 38, 54 : begin 
            a_mul_in0 = img_padding [3][0]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [3][1]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [3][2]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [4][0]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [4][1]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [4][2]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [5][0]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [5][1]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [5][2]; b_mul_in8 = kernel_temp[2][2];
        end
        23, 39, 55 : begin 
            a_mul_in0 = img_padding [3][1]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [3][2]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [3][3]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [4][1]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [4][2]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [4][3]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [5][1]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [5][2]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [5][3]; b_mul_in8 = kernel_temp[2][2];
        end
        24, 40, 56 : begin 
            a_mul_in0 = img_padding [3][2]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [3][3]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [3][4]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [4][2]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [4][3]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [4][4]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [5][2]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [5][3]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [5][4]; b_mul_in8 = kernel_temp[2][2];
        end
        25, 41, 57 : begin 
            a_mul_in0 = img_padding [3][3]; b_mul_in0 = kernel_temp[0][0];    
            a_mul_in1 = img_padding [3][4]; b_mul_in1 = kernel_temp[0][1];
            a_mul_in2 = img_padding [3][5]; b_mul_in2 = kernel_temp[0][2];
            a_mul_in3 = img_padding [4][3]; b_mul_in3 = kernel_temp[1][0];
            a_mul_in4 = img_padding [4][4]; b_mul_in4 = kernel_temp[1][1];
            a_mul_in5 = img_padding [4][5]; b_mul_in5 = kernel_temp[1][2];    
            a_mul_in6 = img_padding [5][3]; b_mul_in6 = kernel_temp[2][0];
            a_mul_in7 = img_padding [5][4]; b_mul_in7 = kernel_temp[2][1];
            a_mul_in8 = img_padding [5][5]; b_mul_in8 = kernel_temp[2][2];
        end
        60 : begin 
            a_mul_in0 = max_0; b_mul_in0 = weight_r[0][0];    
            a_mul_in1 = max_1; b_mul_in1 = weight_r[1][0];
            a_mul_in2 = max_0; b_mul_in2 = weight_r[0][1];
            a_mul_in3 = max_1; b_mul_in3 = weight_r[1][1];
            a_mul_in4 = max_2; b_mul_in4 = weight_r[0][0];
            a_mul_in5 = max_3; b_mul_in5 = weight_r[1][0];    
            a_mul_in6 = max_2; b_mul_in6 = weight_r[0][1];
            a_mul_in7 = max_3; b_mul_in7 = weight_r[1][1];
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


//multiply
// Instance of DW_fp_mult
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 ( .a(a_mul_in0), .b(b_mul_in0), .rnd(3'b000), .z(mul_out0), .status() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U2 ( .a(a_mul_in1), .b(b_mul_in1), .rnd(3'b000), .z(mul_out1), .status() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U3 ( .a(a_mul_in2), .b(b_mul_in2), .rnd(3'b000), .z(mul_out2), .status() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U4 ( .a(a_mul_in3), .b(b_mul_in3), .rnd(3'b000), .z(mul_out3), .status() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U5 ( .a(a_mul_in4), .b(b_mul_in4), .rnd(3'b000), .z(mul_out4), .status() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U6 ( .a(a_mul_in5), .b(b_mul_in5), .rnd(3'b000), .z(mul_out5), .status() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U7 ( .a(a_mul_in6), .b(b_mul_in6), .rnd(3'b000), .z(mul_out6), .status() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U8 ( .a(a_mul_in7), .b(b_mul_in7), .rnd(3'b000), .z(mul_out7), .status() );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U9 ( .a(a_mul_in8), .b(b_mul_in8), .rnd(3'b000), .z(mul_out8), .status() );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mul_out0_r <= 32'b0;
        mul_out1_r <= 32'b0;
        mul_out2_r <= 32'b0;
        mul_out3_r <= 32'b0;
        mul_out4_r <= 32'b0;
        mul_out5_r <= 32'b0;
        mul_out6_r <= 32'b0;
        mul_out7_r <= 32'b0;
        mul_out8_r <= 32'b0;
    end
    else if (count_r >= 10 && count_r <= 57) begin
        mul_out0_r <= mul_out0;
        mul_out1_r <= mul_out1;
        mul_out2_r <= mul_out2;
        mul_out3_r <= mul_out3;
        mul_out4_r <= mul_out4;
        mul_out5_r <= mul_out5;
        mul_out6_r <= mul_out6;
        mul_out7_r <= mul_out7;
        mul_out8_r <= mul_out8;
    end
    else if (count_r == 60) begin
        mul_out0_r <= mul_out0;
        mul_out1_r <= mul_out1;
        mul_out2_r <= mul_out2;
        mul_out3_r <= mul_out3;
        mul_out4_r <= mul_out4;
        mul_out5_r <= mul_out5;
        mul_out6_r <= mul_out6;
        mul_out7_r <= mul_out7;
        mul_out8_r <= mul_out8;
    end
    else begin
        mul_out0_r <= mul_out0_r;
        mul_out1_r <= mul_out1_r;
        mul_out2_r <= mul_out2_r;
        mul_out3_r <= mul_out3_r;
        mul_out4_r <= mul_out4_r;
        mul_out5_r <= mul_out5_r;
        mul_out6_r <= mul_out6_r;
        mul_out7_r <= mul_out7_r;
        mul_out8_r <= mul_out8_r;
    end
end

//conv or matrix mul or exp
always @(*) begin
    if (count_r == 61) begin
        sum_in_0 = mul_out0_r;
        sum_in_1 = mul_out1_r;
        sum_in_2 = 0;
        sum_in_3 = mul_out2_r;
        sum_in_4 = mul_out3_r;
        sum_in_5 = 0;
        sum_in_6 = mul_out4_r;
        sum_in_7 = mul_out5_r;
        sum_in_8 = 0;
        sum_in_9 = mul_out6_r;
        sum_in_10 = mul_out7_r;
        sum_in_11 = 0;
    end
    else if(count_r >= 66 && count_r <= 69)begin
        sum_in_0 = ONE;
        sum_in_1 = exp_neg_out_r;
        sum_in_2 = 0;
        sum_in_3 = exp_pos_out_r;
        sum_in_4 = exp_neg_out_r;
        sum_in_5 = 0;
        sum_in_6 = ONE;
        sum_in_7 = exp_pos_out_r;
        sum_in_8 = 0;
        sum_in_9 = sum3_out0;
        sum_in_10 = sum3_out1;
        sum_in_11 = sum3_out2;
    end
    else begin
        sum_in_0 = mul_out0_r;
        sum_in_1 = mul_out1_r;
        sum_in_2 = mul_out2_r;
        sum_in_3 = mul_out3_r;
        sum_in_4 = mul_out4_r;
        sum_in_5 = mul_out5_r;
        sum_in_6 = mul_out6_r;
        sum_in_7 = mul_out7_r;
        sum_in_8 = mul_out8_r;
        sum_in_9 = sum3_out0;
        sum_in_10 = sum3_out1;
        sum_in_11 = sum3_out2;
    end
end







//add3
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U10 (.a(sum_in_0), .b(sum_in_1), .c(sum_in_2), .rnd(3'b000), .z(sum3_out0), .status() );
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U11 (.a(sum_in_3), .b(sum_in_4), .c(sum_in_5), .rnd(3'b000), .z(sum3_out1), .status() );
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U12 (.a(sum_in_6), .b(sum_in_7), .c(sum_in_8), .rnd(3'b000), .z(sum3_out2), .status() );
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) U13 (.a(sum_in_9), .b(sum_in_10), .c(sum_in_11), .rnd(3'b000), .z(sum3_out_final), .status() );
//add2
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U14 ( .a(feature_map_temp), .b(sum3_out_final), .rnd(3'b000), .z(feature_map_sum2_out), .status() );


//feature_map
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                feature_map_r[i][j] <= 32'b0;
            end
        end
    end
    else begin
        case(count_r)
            11 : feature_map_r[0][0] <= sum3_out_final;
            12 : feature_map_r[0][1] <= sum3_out_final;
            13 : feature_map_r[0][2] <= sum3_out_final;
            14 : feature_map_r[0][3] <= sum3_out_final;
            15 : feature_map_r[1][0] <= sum3_out_final;
            16 : feature_map_r[1][1] <= sum3_out_final;
            17 : feature_map_r[1][2] <= sum3_out_final;
            18 : feature_map_r[1][3] <= sum3_out_final;
            19 : feature_map_r[2][0] <= sum3_out_final;
            20 : feature_map_r[2][1] <= sum3_out_final;
            21 : feature_map_r[2][2] <= sum3_out_final;
            22 : feature_map_r[2][3] <= sum3_out_final;
            23 : feature_map_r[3][0] <= sum3_out_final;
            24 : feature_map_r[3][1] <= sum3_out_final;
            25 : feature_map_r[3][2] <= sum3_out_final;
            26 : feature_map_r[3][3] <= sum3_out_final;

            27 : feature_map_r[0][0] <= feature_map_sum2_out;
            28 : feature_map_r[0][1] <= feature_map_sum2_out;
            29 : feature_map_r[0][2] <= feature_map_sum2_out;
            30 : feature_map_r[0][3] <= feature_map_sum2_out;
            31 : feature_map_r[1][0] <= feature_map_sum2_out;
            32 : feature_map_r[1][1] <= feature_map_sum2_out;
            33 : feature_map_r[1][2] <= feature_map_sum2_out;
            34 : feature_map_r[1][3] <= feature_map_sum2_out;
            35 : feature_map_r[2][0] <= feature_map_sum2_out;
            36 : feature_map_r[2][1] <= feature_map_sum2_out;
            37 : feature_map_r[2][2] <= feature_map_sum2_out;
            38 : feature_map_r[2][3] <= feature_map_sum2_out;
            39 : feature_map_r[3][0] <= feature_map_sum2_out;
            40 : feature_map_r[3][1] <= feature_map_sum2_out;
            41 : feature_map_r[3][2] <= feature_map_sum2_out;
            42 : feature_map_r[3][3] <= feature_map_sum2_out;

            43 : feature_map_r[0][0] <= feature_map_sum2_out;
            44 : feature_map_r[0][1] <= feature_map_sum2_out;
            45 : feature_map_r[0][2] <= feature_map_sum2_out;
            46 : feature_map_r[0][3] <= feature_map_sum2_out;
            47 : feature_map_r[1][0] <= feature_map_sum2_out;
            48 : feature_map_r[1][1] <= feature_map_sum2_out;
            49 : feature_map_r[1][2] <= feature_map_sum2_out;
            50 : feature_map_r[1][3] <= feature_map_sum2_out;
            51 : feature_map_r[2][0] <= feature_map_sum2_out;
            52 : feature_map_r[2][1] <= feature_map_sum2_out;
            53 : feature_map_r[2][2] <= feature_map_sum2_out;
            54 : feature_map_r[2][3] <= feature_map_sum2_out;
            55 : feature_map_r[3][0] <= feature_map_sum2_out;
            56 : feature_map_r[3][1] <= feature_map_sum2_out;
            57 : feature_map_r[3][2] <= feature_map_sum2_out;
            58 : feature_map_r[3][3] <= feature_map_sum2_out;

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
        


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        feature_map_temp <= 32'b0;
    end
    else begin
        case(count_r)
            26 : feature_map_temp <= feature_map_r[0][0];
            27 : feature_map_temp <= feature_map_r[0][1];
            28 : feature_map_temp <= feature_map_r[0][2];
            29 : feature_map_temp <= feature_map_r[0][3];
            30 : feature_map_temp <= feature_map_r[1][0];
            31 : feature_map_temp <= feature_map_r[1][1];
            32 : feature_map_temp <= feature_map_r[1][2];
            33 : feature_map_temp <= feature_map_r[1][3];
            34 : feature_map_temp <= feature_map_r[2][0];
            35 : feature_map_temp <= feature_map_r[2][1];
            36 : feature_map_temp <= feature_map_r[2][2];
            37 : feature_map_temp <= feature_map_r[2][3];
            38 : feature_map_temp <= feature_map_r[3][0];
            39 : feature_map_temp <= feature_map_r[3][1];
            40 : feature_map_temp <= feature_map_r[3][2];
            41 : feature_map_temp <= feature_map_r[3][3];

            42 : feature_map_temp <= feature_map_r[0][0];
            43 : feature_map_temp <= feature_map_r[0][1];
            44 : feature_map_temp <= feature_map_r[0][2];
            45 : feature_map_temp <= feature_map_r[0][3];
            46 : feature_map_temp <= feature_map_r[1][0];
            47 : feature_map_temp <= feature_map_r[1][1];
            48 : feature_map_temp <= feature_map_r[1][2];
            49 : feature_map_temp <= feature_map_r[1][3];
            50 : feature_map_temp <= feature_map_r[2][0];
            51 : feature_map_temp <= feature_map_r[2][1];
            52 : feature_map_temp <= feature_map_r[2][2];
            53 : feature_map_temp <= feature_map_r[2][3];
            54 : feature_map_temp <= feature_map_r[3][0];
            55 : feature_map_temp <= feature_map_r[3][1];
            56 : feature_map_temp <= feature_map_r[3][2];
            57 : feature_map_temp <= feature_map_r[3][3];

            default : feature_map_temp <= 32'b0;
        endcase
    end
end

//Max_pooling
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U15 ( .a(cmp_in_0), .b(cmp_in_1), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_0), .z1(big_0), .status0(),  .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U16 ( .a(cmp_in_2), .b(cmp_in_3), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_1), .z1(big_1), .status0(),  .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U17 ( .a(cmp_in_4), .b(cmp_in_5), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_2), .z1(max_0), .status0(),  .status1() );

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U18 ( .a(cmp_in_6), .b(cmp_in_7), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_3), .z1(big_2), .status0(),  .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U19 ( .a(cmp_in_8), .b(cmp_in_9), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_4), .z1(big_3), .status0(),  .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U20 ( .a(feature_map_r[1][3]), .b(big_3), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_5), .z1(max_1), .status0(),  .status1() );

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U21 ( .a(feature_map_r[2][0]), .b(feature_map_r[2][1]), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_6), .z1(big_4), .status0(),  .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U22 ( .a(feature_map_r[3][0]), .b(big_4), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_7), .z1(big_5), .status0(),  .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U23 ( .a(feature_map_r[3][1]), .b(big_5), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_8), .z1(max_2), .status0(),  .status1() );

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U24 ( .a(feature_map_r[2][2]), .b(feature_map_r[2][3]), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_9), .z1(big_6), .status0(),  .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U25 ( .a(feature_map_r[3][2]), .b(big_6), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_10), .z1(big_7), .status0(),  .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U26 ( .a(feature_map_r[3][3]), .b(big_7), .zctr(1'b0), .aeqb(),  .altb(), .agtb(), .unordered(),  .z0(small_11), .z1(max_3), .status0(),  .status1() );




always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) begin
                max_pooling_r[i][j] <= 32'b0;
            end
        end
    end
    else if(count_r == 59) begin
        max_pooling_r[0][0] <= max_0;
        max_pooling_r[0][1] <= max_1;
        max_pooling_r[1][0] <= max_2;
        max_pooling_r[1][1] <= max_3;
    end
    else begin
        for(i = 0; i < 2; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) begin
                max_pooling_r[i][j] <= max_pooling_r[i][j];
            end
        end
    end
end

//flatten
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flatten_r[0] <= 32'b0;
        flatten_r[1] <= 32'b0;
        flatten_r[2] <= 32'b0;
        flatten_r[3] <= 32'b0;
    end
    else if (count_r == 61) begin
        flatten_r[0] <= sum3_out0;
        flatten_r[1] <= sum3_out1;
        flatten_r[2] <= sum3_out2;
        flatten_r[3] <= sum3_out_final;
    end
    else begin
        flatten_r[0] <= flatten_r[0];
        flatten_r[1] <= flatten_r[1];
        flatten_r[2] <= flatten_r[2];
        flatten_r[3] <= flatten_r[3];
    end
end


//select comp input
always @(*) begin
    if(count_r == 62) begin
        cmp_in_0 = flatten_r[0];
        cmp_in_1 = flatten_r[1];
        cmp_in_2 = flatten_r[2];
        cmp_in_3 = big_0;
        cmp_in_4 = flatten_r[3];
        cmp_in_5 = big_1;
        cmp_in_6 = flatten_r[2];
        cmp_in_7 = small_0;
        cmp_in_8 = flatten_r[3];
        cmp_in_9 = small_3;
    end
    else begin
        cmp_in_0 = feature_map_r[0][0];
        cmp_in_1 = feature_map_r[0][1];
        cmp_in_2 = feature_map_r[1][0];
        cmp_in_3 = big_0;
        cmp_in_4 = feature_map_r[1][1];
        cmp_in_5 = big_1;
        cmp_in_6 = feature_map_r[0][2];
        cmp_in_7 = feature_map_r[0][3];
        cmp_in_8 = feature_map_r[1][2];
        cmp_in_9 = big_2;
    end   
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_max_r <= 32'b0;
        x_min_r <= 32'b0;
    end
    else if (count_r == 62) begin
        x_max_r <= max_0;
        x_min_r <= small_4;
    end
    else begin
        x_max_r <= x_max_r;
        x_min_r <= x_min_r;
    end
end

always @(*) begin
    if(count_r == 63) begin
        sub_in_0 = flatten_r[0];
        sub_in_1 = x_min_r;
    end
    else if (count_r == 64) begin
        sub_in_0 = flatten_r[1];
        sub_in_1 = x_min_r;
    end
    else if (count_r == 65) begin
        sub_in_0 = flatten_r[2];
        sub_in_1 = x_min_r;
    end
    else if (count_r == 66) begin
        sub_in_0 = flatten_r[3];
        sub_in_1 = x_min_r;
    end
    
    else begin
        sub_in_0 = 0;
        sub_in_1 = 0;
    end
end

//sub _numerator _denominator

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U27 ( .a(sub_in_0), .b(sub_in_1), .rnd(3'b000), .z(sub_out_0), .status() );
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U28 ( .a(x_max_r), .b(x_min_r), .rnd(3'b000), .z(sub_out_1), .status() );
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U33 ( .a(exp_pos_out_r), .b(exp_neg_out_r), .rnd(3'b000), .z(sub_out_2), .status() );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        numerator_r <= 32'b0;
        denominator_r <= 32'b0;
    end
    else if (count_r >= 63 && count_r <= 66)begin
        numerator_r <= sub_out_0;
        denominator_r <= sub_out_1;
    end
    else if (count_r >= 67 && count_r <= 70)begin
        case(opt_r)  
            1 : begin //tanh
                numerator_r <= tanh_num_r;
                denominator_r <= tanh_den_r;
            end
            2 : begin //sigmoid
                numerator_r <= ONE;
                denominator_r <= sigmoid_den_r;
            end
            default : begin
                numerator_r <= numerator_r;
                denominator_r <= denominator_r;
            end
        endcase
    end
    else begin
        numerator_r <= numerator_r;
        denominator_r <= denominator_r;
    end
end

//norm
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) U29 ( .a(numerator_r), .b(denominator_r), .rnd(3'b000), .z(div_out), .status());


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        norm_r <= 32'b0;
    end
    else if (count_r >= 64 && count_r <= 67)begin
        norm_r <= div_out;
    end
    else begin
        norm_r <= norm_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        relu_0_r <= 32'b0;
        relu_1_r <= 32'b0;
        relu_2_r <= 32'b0;
        relu_3_r <= 32'b0;
    end
    else if (count_r >= 65 && count_r <= 71)begin
        relu_0_r <= norm_r;
        relu_1_r <= relu_0_r;
        relu_2_r <= relu_1_r;
        relu_3_r <= relu_2_r;
    end
    else begin
        relu_0_r <= relu_0_r;
        relu_1_r <= relu_1_r;
        relu_2_r <= relu_2_r;
        relu_3_r <= relu_3_r;
    end
end
//exp_pos
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U30 (.a(norm_r), .z(exp_pos_out), .status() );
//exp_neg
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U31 (.a({~norm_r[31], norm_r[30:0]}), .z(exp_neg_out), .status() );
//ln
DW_fp_ln #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_extra_prec,inst_arch) U32 (.a(soft_plus_r), .z(ln_out), .status() );


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        exp_pos_out_r <= 32'b0;
        exp_neg_out_r <= 32'b0;
    end
    else if (count_r >= 65 && count_r <= 68) begin
        exp_pos_out_r <= exp_pos_out;
        exp_neg_out_r <= exp_neg_out;
    end
    else begin
        exp_pos_out_r <= exp_pos_out_r;
        exp_neg_out_r <= exp_neg_out_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sigmoid_den_r <= 32'b0;
        tanh_den_r <= 32'b0;
        soft_plus_r <= 32'b0;
    end
    else if (count_r >= 66 && count_r <= 69) begin
        sigmoid_den_r <= sum3_out0; //sigmoid
        tanh_den_r <= sum3_out1; //tanh
        soft_plus_r <= sum3_out2; //soft plus
    end
    else begin
        sigmoid_den_r <= sigmoid_den_r;
        tanh_den_r <= tanh_den_r;
        soft_plus_r <= soft_plus_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ln_out_r <= 32'b0;
    end
    else if (count_r >= 67 && count_r <= 70) begin
        ln_out_r <= ln_out;
    end
    else begin
        ln_out_r <= ln_out_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tanh_num_r <= 32'b0;
    end
    else if (count_r >= 66 && count_r <= 69) begin
        tanh_num_r <= sub_out_2;
    end
    else begin
        tanh_num_r <= tanh_num_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out <= 32'b0;
    end
    else if (count_r >= 68 && count_r <= 71) begin
        case(opt_r)
            0 : out <= (norm_r[31])? 32'b0 : relu_2_r;
            1 : out <= div_out;
            2 : out <= div_out;
            3 : out <= ln_out_r;
            default : out <= 32'b0;
        endcase
    end
    else begin
        out <= 32'b0;
    end
end



endmodule

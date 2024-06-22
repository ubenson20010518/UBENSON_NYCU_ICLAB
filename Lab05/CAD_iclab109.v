module CAD(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    mode,
    matrix_size,
    matrix,
    matrix_idx,
    // output signals
    out_valid,
    out_value
    );

input [1:0] matrix_size;
input clk;
input [7:0] matrix;
input rst_n;
input [3:0] matrix_idx;
input in_valid2;

input mode;
input in_valid;
output reg out_valid;
output reg out_value;

`define STATE_BITS 6
parameter IDLE                 = `STATE_BITS'd0;
parameter IMG_IN_8_8           = `STATE_BITS'd1;
parameter IMG_IN_16_16         = `STATE_BITS'd2;
parameter IMG_IN_32_32         = `STATE_BITS'd3;
parameter KER_IN               = `STATE_BITS'd4;
parameter WAIT_IN_VALID2       = `STATE_BITS'd5;
parameter IN_VALID2            = `STATE_BITS'd6;
parameter LOAD_SRAM_DATA_8_8   = `STATE_BITS'd7;
parameter LOAD_SRAM_DATA_16_16 = `STATE_BITS'd8;
parameter LOAD_SRAM_DATA_32_32 = `STATE_BITS'd9;
parameter CONV_8_8             = `STATE_BITS'd10;
parameter CONV_16_16           = `STATE_BITS'd11;
parameter CONV_32_32           = `STATE_BITS'd12;
parameter DECONV_8_8           = `STATE_BITS'd13;
parameter DECONV_16_16         = `STATE_BITS'd14;
parameter DECONV_32_32         = `STATE_BITS'd15;
parameter WAIT0                = `STATE_BITS'd16;
parameter WAIT1                = `STATE_BITS'd17;
parameter WAIT2                = `STATE_BITS'd18;
parameter WRITE = 0;
parameter READ = 1;

integer i, j;



//=======================================================
//                   Reg/Wire
//=======================================================
reg [`STATE_BITS-1:0] next_state, current_state;

reg [13:0] count_img_in;
reg [8:0] count_ker_in;
reg [7:0] count_load_data;
reg [14:0] count_conv;
reg [14:0] count_deconv;
reg [4:0] count_16_set;
reg [2:0] count_7;
reg [10:0] count_img_addr;
reg [6:0] count_ker_addr;
reg in_valid2_delay;
reg WEB_IMG, WEB_KER;
reg signed [7:0] img_32X32 [0:31][0:31];
reg signed [7:0] ker_5X5 [0:4][0:4];
reg [5:0] count_col, count_row, conv_row;
reg [6:0] count_deconv_col, count_deconv_row;
reg [4:0]  count_19;
reg signed [20:0] max_pooling_r;
reg signed [20:0] deconv_r;
reg signed [7:0] img_5X40_pad[0:4][0:39];
reg signed [7:0] img_5X32_r [0:4][0:31];



reg mode_r;
reg [3:0] matrix_img_idx_r;
reg [3:0] matrix_ker_idx_r;
reg [1:0] matrix_size_r;
reg [3:0] ker_idx_r, img_idx_r;
reg [7:0] matrix_r [0:7];
reg [6:0] ADDR_KER, load_ker_addr;
reg [10:0] ADDR_IMG, load_img_addr;

reg signed [7:0]  in_0, in_1, in_2, in_3, in_4,
            in_5, in_6, in_7, in_8, in_9,
            in_10, in_11, in_12, in_13, in_14,
            in_15, in_16, in_17, in_18, in_19,
            in_20, in_21, in_22, in_23, in_24,
            in_25, in_26, in_27, in_28, in_29,
            in_30, in_31, in_32, in_33, in_34,
            in_35, in_36, in_37, in_38, in_39,
            in_40, in_41, in_42, in_43, in_44,
            in_45, in_46, in_47, in_48, in_49;
reg signed [20:0] dp_out_r;
reg signed [20:0] feat_2X2[0:1][0:1];
reg signed [20:0] feature_map_r[0:1][0:1];


wire signed [63:0] DI_IMG, DI_KER, DO_IMG, DO_KER;
// wire [10:0] ADDR_IMG;
wire signed [20:0] dp25_out;
wire signed [20:0] candidate0, candidate1, max_pooling;



//=======================================================
//                     FSM
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case(current_state)
        IDLE : begin
            if (in_valid) begin
                case(matrix_size)
                    0 : next_state = IMG_IN_8_8;
                    1 : next_state = IMG_IN_16_16;
                    2 : next_state = IMG_IN_32_32;
                    default : next_state = IDLE;
                endcase
            end
            else begin
                next_state = IDLE;
            end
        end
        IMG_IN_8_8 : begin
            if (count_img_in == 1023) begin //count_img_addr == 128
                next_state = KER_IN;
            end
            else begin
                next_state = IMG_IN_8_8;
            end
        end
        IMG_IN_16_16 : begin
            if (count_img_in == 4095) begin //count_img_addr == 512
                next_state = KER_IN;
            end
            else begin
                next_state = IMG_IN_16_16;
            end
        end
        IMG_IN_32_32 : begin
            if (count_img_in == 16383) begin //count_img_addr == 2048
                next_state = KER_IN;
            end
            else begin
                next_state = IMG_IN_32_32;
            end
        end
        KER_IN : begin
            if (count_ker_in == 399) begin
                next_state = WAIT_IN_VALID2;
            end
            else begin
                next_state = KER_IN;
            end
        end
        WAIT_IN_VALID2 : begin
            if (in_valid2) begin
                next_state = IN_VALID2;
            end
            else begin
                next_state = WAIT_IN_VALID2;
            end
        end
        IN_VALID2 : begin
            if (!in_valid2) begin
                case(matrix_size_r)
                    0 : next_state = LOAD_SRAM_DATA_8_8;
                    1 : next_state = LOAD_SRAM_DATA_16_16;
                    2 : next_state = LOAD_SRAM_DATA_32_32;
                    default : next_state = IN_VALID2;
                endcase
            end
            else begin
                next_state = IN_VALID2;
            end
        end
        LOAD_SRAM_DATA_8_8 : begin
            if (count_load_data == 7+1) begin
                next_state = (mode_r)?WAIT0 : CONV_8_8;
            end
            else begin
                next_state = LOAD_SRAM_DATA_8_8;
            end
        end
        LOAD_SRAM_DATA_16_16 : begin
            if (count_load_data == 31+1) begin
                next_state = (mode_r)?WAIT1 : CONV_16_16;
            end
            else begin
                next_state = LOAD_SRAM_DATA_16_16;
            end
        end
        LOAD_SRAM_DATA_32_32 : begin
            if (count_load_data == 127+1) begin
                next_state = (mode_r)?WAIT2 : CONV_32_32;
            end
            else begin
                next_state = LOAD_SRAM_DATA_32_32;
            end
        end
        WAIT0 : next_state = DECONV_8_8;
        WAIT1 : next_state = DECONV_16_16;
        WAIT2 : next_state = DECONV_32_32;
            

        CONV_8_8 : begin
            if (count_conv == 84) begin
                if (count_16_set == 16)
                    next_state = IDLE;
                else begin
                    next_state = WAIT_IN_VALID2;
                end
            end
            else begin
                next_state = CONV_8_8;
            end
        end
        CONV_16_16 : begin
            if (count_conv == 724) begin
                if (count_16_set == 16)
                    next_state = IDLE;
                else begin
                    next_state = WAIT_IN_VALID2;
                end
            end
            else begin
                next_state = CONV_16_16;
            end
        end
        CONV_32_32 : begin
            if (count_conv == 3924) begin
                if (count_16_set == 16)
                    next_state = IDLE;
                else begin
                    next_state = WAIT_IN_VALID2;
                end
            end
            else begin
                next_state = CONV_32_32;
            end
        end
        DECONV_8_8 : begin
            if (count_deconv == 2879+1) begin
                if (count_16_set == 16)
                    next_state = IDLE;
                else begin
                    next_state = WAIT_IN_VALID2;
                end
            end
            else begin
                next_state = DECONV_8_8;
            end
        end
        DECONV_16_16 : begin
            if (count_deconv == 7999+1) begin
                if (count_16_set == 16)
                    next_state = IDLE;
                else begin
                    next_state = WAIT_IN_VALID2;
                end
            end
            else begin
                next_state = DECONV_16_16;
            end
        end
        DECONV_32_32 : begin
            if (count_deconv == 25919+1) begin
                if (count_16_set == 16)
                    next_state = IDLE;
                else begin
                    next_state = WAIT_IN_VALID2;
                end
            end
            else begin
                next_state = DECONV_32_32;
            end
        end
        
        default : begin
            next_state = IDLE;
        end
    endcase

end

//=======================================================
//                    Design
//=======================================================           

// count img input
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_img_in <= 0;
    end
    else if (current_state == IMG_IN_8_8 || current_state == IMG_IN_16_16 || current_state == IMG_IN_32_32) begin
        count_img_in <= count_img_in + 1;
    end
    else begin
        count_img_in <= 0;
    end
end

// count kernel input
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_ker_in <= 0;
    end
    else if (current_state == KER_IN) begin
        count_ker_in <= count_ker_in + 1;
    end
    else begin
        count_ker_in <= 0;
    end
end

// count load data
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_load_data <= 0;
    end
    else if (current_state == LOAD_SRAM_DATA_8_8 || current_state == LOAD_SRAM_DATA_16_16 || current_state == LOAD_SRAM_DATA_32_32) begin
        count_load_data <= count_load_data + 1;
    end
    else begin
        count_load_data <= 0;
    end
end

// count convolution
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_conv <= 0;
    end
    else if (current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) begin
        count_conv <= count_conv + 1;
    end
    else begin
        count_conv <= 0;
    end
end


//count deconvolution
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_deconv <= 0;
    end
    else if (current_state == DECONV_8_8 || current_state == DECONV_16_16 || current_state == DECONV_32_32) begin
        count_deconv <= count_deconv + 1;
    end
    else begin
        count_deconv <= 0;
    end
end

//count whether finish 16 sets
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_16_set <= 0;
    end
    else if (in_valid2 && in_valid2_delay) begin
        count_16_set <= count_16_set + 1;
    end
    else begin
        count_16_set <= (in_valid)? 0 : count_16_set;
    end
end

//delay in_valid2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_valid2_delay <= 0;
    end
    else begin
        in_valid2_delay <= in_valid2;
    end
end

//count 7 clk for one element
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_7 <= 0;
    end
    else if (current_state == IMG_IN_8_8 || current_state == IMG_IN_16_16 || current_state == IMG_IN_32_32 || current_state == LOAD_SRAM_DATA_8_8 || current_state == LOAD_SRAM_DATA_16_16 || current_state == LOAD_SRAM_DATA_32_32) begin
        count_7 <= (&count_7)?0 : count_7 + 1;
    end
    else if (current_state == KER_IN) begin
        count_7 <= (count_7 == 4)?0 : count_7 + 1;
    end
    else begin
        count_7 <= 0;
    end
end

// store matrix_idx
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        matrix_img_idx_r <= 0;
        matrix_ker_idx_r <= 0;
    end
    else if (in_valid2 && in_valid2_delay == 0) begin
        matrix_img_idx_r <= matrix_idx;
        matrix_ker_idx_r <= matrix_ker_idx_r;
    end
    else if (in_valid2 && in_valid2_delay == 1) begin
        matrix_img_idx_r <= matrix_img_idx_r;
        matrix_ker_idx_r <= matrix_idx;
    end
    else begin
        matrix_img_idx_r <= matrix_img_idx_r;
        matrix_ker_idx_r <= matrix_ker_idx_r;
    end
end

// store mode
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode_r <= 0;
    end
    else if (in_valid2 && current_state == WAIT_IN_VALID2) begin
        mode_r <= mode;
    end
    else begin
        mode_r <= mode_r;
    end
end

//store matrix size
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        matrix_size_r <= 2'd0;
    else if (in_valid && current_state == IDLE)
        matrix_size_r <= matrix_size;
    else
        matrix_size_r <= matrix_size_r;
end

//store matrix index
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        img_idx_r <= 0;    
        ker_idx_r <= 0;
    end
    else if (in_valid2) begin
        img_idx_r <= ker_idx_r;    
        ker_idx_r <= matrix_idx;
    end
    else begin
        img_idx_r <= img_idx_r;    
        ker_idx_r <= ker_idx_r;
    end
end

//store matrix
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 8; i = i + 1) begin
            matrix_r[i] <= 0;
        end
    end
    else if (in_valid) begin
        matrix_r[0] <= matrix_r[1];
        matrix_r[1] <= matrix_r[2];
        matrix_r[2] <= matrix_r[3];
        matrix_r[3] <= matrix_r[4];
        matrix_r[4] <= matrix_r[5];
        matrix_r[5] <= matrix_r[6];
        matrix_r[6] <= matrix_r[7];
        matrix_r[7] <= matrix;
    end
    else begin
        matrix_r[0] <= 0;
        matrix_r[1] <= 0;
        matrix_r[2] <= 0;
        matrix_r[3] <= 0;
        matrix_r[4] <= 0;
        matrix_r[5] <= 0;
        matrix_r[6] <= 0;
        matrix_r[7] <= 0;
    end
end

assign DI_IMG = {matrix_r[0], matrix_r[1], matrix_r[2], matrix_r[3], matrix_r[4],matrix_r[5], matrix_r[6], matrix_r[7]};
assign DI_KER = {matrix_r[3], matrix_r[4],matrix_r[5], matrix_r[6], matrix_r[7]};

// set WEB
always @(*) begin
    if((current_state == IMG_IN_8_8 || current_state == IMG_IN_16_16 || current_state == IMG_IN_32_32) && (&count_7)) begin
        WEB_IMG = WRITE;
        WEB_KER = READ;
    end
    else if (current_state == KER_IN && count_7 == 4) begin
        WEB_IMG = READ;
        WEB_KER = WRITE;
    end
    else begin
        WEB_IMG = READ;
        WEB_KER = READ;
    end
end

// set img ADDR
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_img_addr <= 0;
    end
    else if (in_valid2 || current_state == IDLE) begin
        count_img_addr <= 0;
    end
    else if ((current_state == IMG_IN_8_8 || current_state == IMG_IN_16_16 || current_state == IMG_IN_32_32) && (&count_7)) begin
        count_img_addr <= count_img_addr + 1;
    end
     else if ((current_state == LOAD_SRAM_DATA_8_8 || current_state == LOAD_SRAM_DATA_16_16 || current_state == LOAD_SRAM_DATA_32_32)) begin
        count_img_addr <= count_img_addr + 1;
    end
    else begin
        count_img_addr <= count_img_addr;
    end
end

// set kernel ADDR
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_ker_addr <= 0;
    end
     else if (in_valid2 || current_state == IDLE) begin
        count_ker_addr <= 0;
    end
    else if ((current_state == KER_IN) && (count_7 == 4)) begin
        count_ker_addr <= (count_ker_addr>79)? 0: count_ker_addr + 1;
    end
    else if ((current_state == LOAD_SRAM_DATA_8_8 || current_state == LOAD_SRAM_DATA_16_16 || current_state == LOAD_SRAM_DATA_32_32) && count_load_data <5) begin
        count_ker_addr <= (count_ker_addr>79)? 0: count_ker_addr + 1;
    end
    else begin
        count_ker_addr <= (count_ker_addr>79)? 0: count_ker_addr;
    end
end

// load img address
always @(*) begin
    if (current_state == LOAD_SRAM_DATA_8_8) begin
        load_img_addr = count_img_addr + matrix_img_idx_r*8;
    end
    else if (current_state == LOAD_SRAM_DATA_16_16) begin
        load_img_addr = count_img_addr + matrix_img_idx_r*32;
    end
    else if (current_state == LOAD_SRAM_DATA_32_32) begin
        load_img_addr = count_img_addr + matrix_img_idx_r*128;
    end
    else begin
        load_img_addr = 0;
    end
end

// load kernel address
always @(*) begin
    if ((current_state == LOAD_SRAM_DATA_8_8 || current_state == LOAD_SRAM_DATA_16_16 || current_state == LOAD_SRAM_DATA_32_32) && count_load_data <5) begin
        load_ker_addr = count_ker_addr + matrix_ker_idx_r*5;
    end
    else begin
        load_ker_addr = 0;
    end
end


always @(*) begin
    if (current_state == IMG_IN_8_8 || current_state == IMG_IN_16_16 || current_state == IMG_IN_32_32) begin
        ADDR_IMG = count_img_addr;
        ADDR_KER = 0;
    end
    else if (current_state == KER_IN) begin
        ADDR_IMG = 0;
        ADDR_KER = count_ker_addr;
    end
    else if (current_state == LOAD_SRAM_DATA_8_8 || current_state == LOAD_SRAM_DATA_16_16 || current_state == LOAD_SRAM_DATA_32_32) begin
        ADDR_IMG = load_img_addr;
        ADDR_KER = load_ker_addr;
    end
    else begin
        ADDR_IMG = 0;
        ADDR_KER = 0;
    end
end

// load img
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_32X32[i][j] <= 0;
            end
        end
    end
    else if (current_state == LOAD_SRAM_DATA_8_8 && count_load_data > 0) begin
        {img_32X32[7][0], img_32X32[7][1], img_32X32[7][2], img_32X32[7][3], img_32X32[7][4], img_32X32[7][5], img_32X32[7][6], img_32X32[7][7]} <= DO_IMG;
        for (i = 6; i > -1; i = i - 1) begin
            {img_32X32[i][0], img_32X32[i][1], img_32X32[i][2], img_32X32[i][3], img_32X32[i][4], img_32X32[i][5], img_32X32[i][6], img_32X32[i][7]} <= {img_32X32[i+1][0], img_32X32[i+1][1], img_32X32[i+1][2], img_32X32[i+1][3], img_32X32[i+1][4], img_32X32[i+1][5], img_32X32[i+1][6], img_32X32[i+1][7]};
        end
    end
    else if (current_state == LOAD_SRAM_DATA_16_16 && count_load_data > 0) begin
        {img_32X32[15][8], img_32X32[15][9], img_32X32[15][10], img_32X32[15][11], img_32X32[15][12], img_32X32[15][13], img_32X32[15][14], img_32X32[15][15]} <= DO_IMG;
        {img_32X32[15][0], img_32X32[15][1], img_32X32[15][2], img_32X32[15][3], img_32X32[15][4], img_32X32[15][5], img_32X32[15][6], img_32X32[15][7]} <= {img_32X32[15][8], img_32X32[15][9], img_32X32[15][10], img_32X32[15][11], img_32X32[15][12], img_32X32[15][13], img_32X32[15][14], img_32X32[15][15]};
        for (i = 14; i > -1; i = i - 1) begin
            {img_32X32[i][8], img_32X32[i][9], img_32X32[i][10], img_32X32[i][11], img_32X32[i][12], img_32X32[i][13], img_32X32[i][14], img_32X32[i][15]} <= {img_32X32[i+1][0], img_32X32[i+1][1], img_32X32[i+1][2], img_32X32[i+1][3], img_32X32[i+1][4], img_32X32[i+1][5], img_32X32[i+1][6], img_32X32[i+1][7]};
            {img_32X32[i][0], img_32X32[i][1], img_32X32[i][2], img_32X32[i][3], img_32X32[i][4], img_32X32[i][5], img_32X32[i][6], img_32X32[i][7]} <= {img_32X32[i][8], img_32X32[i][9], img_32X32[i][10], img_32X32[i][11], img_32X32[i][12], img_32X32[i][13], img_32X32[i][14], img_32X32[i][15]};
        end
    end

    else if (current_state == LOAD_SRAM_DATA_32_32 && count_load_data > 0) begin
            {img_32X32[31][24], img_32X32[31][25], img_32X32[31][26], img_32X32[31][27], img_32X32[31][28], img_32X32[31][29], img_32X32[31][30], img_32X32[31][31]} <= DO_IMG;
            {img_32X32[31][16], img_32X32[31][17], img_32X32[31][18], img_32X32[31][19], img_32X32[31][20], img_32X32[31][21], img_32X32[31][22], img_32X32[31][23]} <= {img_32X32[31][24], img_32X32[31][25], img_32X32[31][26], img_32X32[31][27], img_32X32[31][28], img_32X32[31][29], img_32X32[31][30], img_32X32[31][31]};
            {img_32X32[31][8], img_32X32[31][9], img_32X32[31][10], img_32X32[31][11], img_32X32[31][12], img_32X32[31][13], img_32X32[31][14], img_32X32[31][15]} <= {img_32X32[31][16], img_32X32[31][17], img_32X32[31][18], img_32X32[31][19], img_32X32[31][20], img_32X32[31][21], img_32X32[31][22], img_32X32[31][23]};
            {img_32X32[31][0], img_32X32[31][1], img_32X32[31][2], img_32X32[31][3], img_32X32[31][4], img_32X32[31][5], img_32X32[31][6], img_32X32[31][7]} <= {img_32X32[31][8], img_32X32[31][9], img_32X32[31][10], img_32X32[31][11], img_32X32[31][12], img_32X32[31][13], img_32X32[31][14], img_32X32[31][15]};

        for (i = 30; i > -1; i = i - 1) begin
            {img_32X32[i][24], img_32X32[i][25], img_32X32[i][26], img_32X32[i][27], img_32X32[i][28], img_32X32[i][29], img_32X32[i][30], img_32X32[i][31]} <= {img_32X32[i+1][0], img_32X32[i+1][1], img_32X32[i+1][2], img_32X32[i+1][3], img_32X32[i+1][4], img_32X32[i+1][5], img_32X32[i+1][6], img_32X32[i+1][7]};    
            {img_32X32[i][16], img_32X32[i][17], img_32X32[i][18], img_32X32[i][19], img_32X32[i][20], img_32X32[i][21], img_32X32[i][22], img_32X32[i][23]} <= {img_32X32[i][24], img_32X32[i][25], img_32X32[i][26], img_32X32[i][27], img_32X32[i][28], img_32X32[i][29], img_32X32[i][30], img_32X32[i][31]};
            {img_32X32[i][8], img_32X32[i][9], img_32X32[i][10], img_32X32[i][11], img_32X32[i][12], img_32X32[i][13], img_32X32[i][14], img_32X32[i][15]} <= {img_32X32[i][16], img_32X32[i][17], img_32X32[i][18], img_32X32[i][19], img_32X32[i][20], img_32X32[i][21], img_32X32[i][22], img_32X32[i][23]};
            {img_32X32[i][0], img_32X32[i][1], img_32X32[i][2], img_32X32[i][3], img_32X32[i][4], img_32X32[i][5], img_32X32[i][6], img_32X32[i][7]} <= {img_32X32[i][8], img_32X32[i][9], img_32X32[i][10], img_32X32[i][11], img_32X32[i][12], img_32X32[i][13], img_32X32[i][14], img_32X32[i][15]};
        end
    end
    else if((current_state == DECONV_8_8) && count_deconv_col == 11 && count_19 == 18) begin
        for (i = 0; i < 31; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_32X32[i][j] <= img_32X32[i+1][j];
            end
        end
        for (i = 0; i < 32; i = i + 1) begin
            img_32X32[31][i] <= 0;
        end
    end
    else if((current_state == DECONV_16_16) && count_deconv_col == 19 && count_19 == 18) begin
        for (i = 0; i < 31; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_32X32[i][j] <= img_32X32[i+1][j];
            end
        end
        for (i = 0; i < 32; i = i + 1) begin
            img_32X32[31][i] <= 0;
        end
    end
    else if((current_state == DECONV_32_32) && count_deconv_col == 35 && count_19 == 18) begin
        for (i = 0; i < 31; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_32X32[i][j] <= img_32X32[i+1][j];
            end
        end
        for (i = 0; i < 32; i = i + 1) begin
            img_32X32[31][i] <= 0;
        end
    end
    else if (in_valid2) begin
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_32X32[i][j] <= 0;
            end
        end
    end
    else begin
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_32X32[i][j] <= img_32X32[i][j];
            end
        end
    end
end

// load kernel
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 5; i = i + 1) begin
            for (j = 0; j < 5; j = j + 1) begin
                ker_5X5[i][j] <= 0;
            end
        end
    end
    else if ((current_state == LOAD_SRAM_DATA_8_8 || current_state == LOAD_SRAM_DATA_16_16 || current_state == LOAD_SRAM_DATA_32_32) && count_load_data > 0 && count_load_data < 6) begin
        {ker_5X5[4][0], ker_5X5[4][1], ker_5X5[4][2], ker_5X5[4][3], ker_5X5[4][4]} <= DO_KER;
        {ker_5X5[3][0], ker_5X5[3][1], ker_5X5[3][2], ker_5X5[3][3], ker_5X5[3][4]} <= {ker_5X5[4][0], ker_5X5[4][1], ker_5X5[4][2], ker_5X5[4][3], ker_5X5[4][4]};
        {ker_5X5[2][0], ker_5X5[2][1], ker_5X5[2][2], ker_5X5[2][3], ker_5X5[2][4]} <= {ker_5X5[3][0], ker_5X5[3][1], ker_5X5[3][2], ker_5X5[3][3], ker_5X5[3][4]};
        {ker_5X5[1][0], ker_5X5[1][1], ker_5X5[1][2], ker_5X5[1][3], ker_5X5[1][4]} <= {ker_5X5[2][0], ker_5X5[2][1], ker_5X5[2][2], ker_5X5[2][3], ker_5X5[2][4]};
        {ker_5X5[0][0], ker_5X5[0][1], ker_5X5[0][2], ker_5X5[0][3], ker_5X5[0][4]} <= {ker_5X5[1][0], ker_5X5[1][1], ker_5X5[1][2], ker_5X5[1][3], ker_5X5[1][4]};
    end
    else begin
        for (i = 0; i < 5; i = i + 1) begin
            for (j = 0; j < 5; j = j + 1) begin
                ker_5X5[i][j] <= ker_5X5[i][j];
            end
        end
    end
end



//=======================================================
//                  CONVOLUTION
//=======================================================

// count column 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_col <= 0;
    end
    else if (current_state == CONV_8_8) begin
        case (count_19)
            1: count_col <= count_col + 1;
            19:count_col <= (count_col == 3)? 0 : count_col+1;
            default : count_col <= count_col;
        endcase

    end
    else if (current_state == CONV_16_16) begin
        case (count_19)
            1: count_col <= count_col + 1;
            19:count_col <= (count_col == 11)? 0 : count_col+1;
            default : count_col <= count_col;
        endcase
    end
    else if (current_state == CONV_32_32) begin
        case (count_19)
            1: count_col <= count_col + 1;
            19:count_col <= (count_col == 27)? 0 : count_col+1;
            default : count_col <= count_col;
        endcase
    end
    else begin
        count_col <= 0;
    end
end


// count row

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_row <= 0;
    end
    else if (current_state == CONV_8_8) begin 
        case (count_19)
            19:count_row <= (count_col == 3)? count_row + 2 : count_row;
            default : count_row <= count_row;
        endcase
    end
    else if (current_state == CONV_16_16) begin
        case (count_19)
            19:count_row <= (count_col == 11)? count_row + 2 : count_row;
            default : count_row <= count_row;
        endcase
    end
    else if (current_state == CONV_32_32) begin
        case (count_19)
            19:count_row <= (count_col == 27)? count_row + 2 : count_row;
            default : count_row <= count_row;
        endcase
    end
    else begin
        count_row <= 0;
    end
end

always @(*) begin
        conv_row = (!count_19[0])? count_row : count_row + 1;
    end



// count deconvolution column
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_deconv_col <= 0;
    end
    else if (current_state == DECONV_8_8 && count_19 == 19) begin
        count_deconv_col <= (count_deconv_col == 11)? 0 : count_deconv_col + 1;
    end
    else if (current_state == DECONV_16_16 && count_19 == 19) begin
        count_deconv_col <= (count_deconv_col == 19)? 0 : count_deconv_col + 1;
    end
    else if (current_state == DECONV_32_32 && count_19 == 19) begin
        count_deconv_col <= (count_deconv_col == 35)? 0 : count_deconv_col + 1;
    end
    else if (in_valid2) begin
        count_deconv_col <= 0;
    end
    else begin
        count_deconv_col <= count_deconv_col;
    end
end

// count deconvolution row
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
       count_deconv_row <= 0;
    end
    else if (current_state == DECONV_8_8 && count_19 == 19) begin 
        count_deconv_row <= (count_deconv_col == 11)? count_deconv_row + 1 : count_deconv_row;
    end
    else if (current_state == DECONV_16_16 && count_19 == 19) begin 
        count_deconv_row <= (count_deconv_col == 19)? count_deconv_row + 1 : count_deconv_row;
    end
    else if (current_state == DECONV_32_32 && count_19 == 19) begin 
        count_deconv_row <= (count_deconv_col == 35)? count_deconv_row + 1 : count_deconv_row;
    end
    else if (in_valid2) begin
        count_deconv_row <= 0;
    end
    else begin
        count_deconv_row <= count_deconv_row;
    end
end

// 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 5; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_5X32_r[i][j] <= 0;
            end
        end
    end
    
    else if (current_state == DECONV_8_8 && count_deconv_col == 11 && count_19 == 19) begin
        for(i = 0; i < 32; i = i + 1) begin
            img_5X32_r[4][i] <= img_32X32[0][i];
        end
        for (i = 3; i > -1; i = i - 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_5X32_r[i][j] <= img_5X32_r[i+1][j];
            end
        end
    end
    else if (current_state == DECONV_16_16 && count_deconv_col == 19 && count_19 == 19) begin
        for(i = 0; i < 32; i = i + 1) begin
            img_5X32_r[4][i] <= img_32X32[0][i];
        end
        for (i = 3; i > -1; i = i - 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_5X32_r[i][j] <= img_5X32_r[i+1][j];
            end
        end
    end
    else if (current_state == DECONV_32_32 && count_deconv_col == 35 && count_19 == 19) begin
        for(i = 0; i < 32; i = i + 1) begin
            img_5X32_r[4][i] <= img_32X32[0][i];
        end
        for (i = 3; i > -1; i = i - 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_5X32_r[i][j] <= img_5X32_r[i+1][j];
            end
        end
    end
    else if (count_deconv == 0) begin
        for(i = 0; i < 32; i = i + 1) begin
            img_5X32_r[4][i] <= img_32X32[0][i];
        end
        for (i = 3; i > -1; i = i - 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_5X32_r[i][j] <= 0;
            end
        end
    end
    else begin
        for (i = 0; i < 5; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                img_5X32_r[i][j] <= img_5X32_r[i][j];
            end
        end
    end
end


always @(*) begin
    for (i = 0; i < 5; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            img_5X40_pad[i][j] = 0;
            img_5X40_pad[i][j+36] = 0;
        end
    end
    for (i = 0; i < 5; i = i + 1) begin
        for (j = 4; j < 36; j = j + 1) begin
            img_5X40_pad[i][j] = img_5X32_r[i][j-4];
        end
    end
end



always @(*) begin
    if (current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) begin
        in_0 = img_32X32[0+conv_row][0+count_col]; in_25 = ker_5X5[0][0];
        in_1 = img_32X32[0+conv_row][1+count_col]; in_26 = ker_5X5[0][1];
        in_2 = img_32X32[0+conv_row][2+count_col]; in_27 = ker_5X5[0][2];
        in_3 = img_32X32[0+conv_row][3+count_col]; in_28 = ker_5X5[0][3];
        in_4 = img_32X32[0+conv_row][4+count_col]; in_29 = ker_5X5[0][4];
        
    end
    
    else if (current_state == DECONV_8_8 || current_state == DECONV_16_16 || current_state == DECONV_32_32) begin
        in_0 = img_5X40_pad[0][0+count_deconv_col]; in_25 = ker_5X5[4][4];
        in_1 = img_5X40_pad[0][1+count_deconv_col]; in_26 = ker_5X5[4][3];
        in_2 = img_5X40_pad[0][2+count_deconv_col]; in_27 = ker_5X5[4][2];
        in_3 = img_5X40_pad[0][3+count_deconv_col]; in_28 = ker_5X5[4][1];
        in_4 = img_5X40_pad[0][4+count_deconv_col]; in_29 = ker_5X5[4][0];
        
    end

    else begin
        in_0 = 0; in_25 = 0;
        in_1 = 0; in_26 = 0;
        in_2 = 0; in_27 = 0;
        in_3 = 0; in_28 = 0;
        in_4 = 0; in_29 = 0;
        
    end
end





always @(*) begin
    if (current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) begin
        
        in_5 = img_32X32[1+conv_row][0+count_col]; in_30 = ker_5X5[1][0];
        in_6 = img_32X32[1+conv_row][1+count_col]; in_31 = ker_5X5[1][1];
        in_7 = img_32X32[1+conv_row][2+count_col]; in_32 = ker_5X5[1][2];
        in_8 = img_32X32[1+conv_row][3+count_col]; in_33 = ker_5X5[1][3];
        in_9 = img_32X32[1+conv_row][4+count_col]; in_34 = ker_5X5[1][4];
        
    end
    
    else if (current_state == DECONV_8_8 || current_state == DECONV_16_16 || current_state == DECONV_32_32) begin
        
        in_5 = img_5X40_pad[1][0+count_deconv_col]; in_30 = ker_5X5[3][4];
        in_6 = img_5X40_pad[1][1+count_deconv_col]; in_31 = ker_5X5[3][3];
        in_7 = img_5X40_pad[1][2+count_deconv_col]; in_32 = ker_5X5[3][2];
        in_8 = img_5X40_pad[1][3+count_deconv_col]; in_33 = ker_5X5[3][1];
        in_9 = img_5X40_pad[1][4+count_deconv_col]; in_34 = ker_5X5[3][0];
        
    end

    else begin
        
        in_5 = 0; in_30 = 0;
        in_6 = 0; in_31 = 0;
        in_7 = 0; in_32 = 0;
        in_8 = 0; in_33 = 0;
        in_9 = 0; in_34 = 0;
        
    end
end





always @(*) begin
    if (current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) begin
        
        in_10 = img_32X32[2+conv_row][0+count_col]; in_35 = ker_5X5[2][0];
        in_11 = img_32X32[2+conv_row][1+count_col]; in_36 = ker_5X5[2][1];
        in_12 = img_32X32[2+conv_row][2+count_col]; in_37 = ker_5X5[2][2];
        in_13 = img_32X32[2+conv_row][3+count_col]; in_38 = ker_5X5[2][3];
        in_14 = img_32X32[2+conv_row][4+count_col]; in_39 = ker_5X5[2][4];
        
    end
    
    else if (current_state == DECONV_8_8 || current_state == DECONV_16_16 || current_state == DECONV_32_32) begin
        
        in_10 = img_5X40_pad[2][0+count_deconv_col]; in_35 = ker_5X5[2][4];
        in_11 = img_5X40_pad[2][1+count_deconv_col]; in_36 = ker_5X5[2][3];
        in_12 = img_5X40_pad[2][2+count_deconv_col]; in_37 = ker_5X5[2][2];
        in_13 = img_5X40_pad[2][3+count_deconv_col]; in_38 = ker_5X5[2][1];
        in_14 = img_5X40_pad[2][4+count_deconv_col]; in_39 = ker_5X5[2][0];
        
    end

    else begin
        
        in_10 = 0; in_35 = 0;
        in_11 = 0; in_36 = 0;
        in_12 = 0; in_37 = 0;
        in_13 = 0; in_38 = 0;
        in_14 = 0; in_39 = 0;
        
    end
end




always @(*) begin
    if (current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) begin
        
        in_15 = img_32X32[3+conv_row][0+count_col]; in_40 = ker_5X5[3][0];
        in_16 = img_32X32[3+conv_row][1+count_col]; in_41 = ker_5X5[3][1];
        in_17 = img_32X32[3+conv_row][2+count_col]; in_42 = ker_5X5[3][2];
        in_18 = img_32X32[3+conv_row][3+count_col]; in_43 = ker_5X5[3][3];
        in_19 = img_32X32[3+conv_row][4+count_col]; in_44 = ker_5X5[3][4];
        
    end
    
    else if (current_state == DECONV_8_8 || current_state == DECONV_16_16 || current_state == DECONV_32_32) begin
        
        in_15 = img_5X40_pad[3][0+count_deconv_col]; in_40 = ker_5X5[1][4];
        in_16 = img_5X40_pad[3][1+count_deconv_col]; in_41 = ker_5X5[1][3];
        in_17 = img_5X40_pad[3][2+count_deconv_col]; in_42 = ker_5X5[1][2];
        in_18 = img_5X40_pad[3][3+count_deconv_col]; in_43 = ker_5X5[1][1];
        in_19 = img_5X40_pad[3][4+count_deconv_col]; in_44 = ker_5X5[1][0];
        
    end

    else begin
        
        in_15 = 0; in_40 = 0;
        in_16 = 0; in_41 = 0;
        in_17 = 0; in_42 = 0;
        in_18 = 0; in_43 = 0;
        in_19 = 0; in_44 = 0;
        
    end
end




always @(*) begin
    if (current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) begin
        
        in_20 = img_32X32[4+conv_row][0+count_col]; in_45 = ker_5X5[4][0];
        in_21 = img_32X32[4+conv_row][1+count_col]; in_46 = ker_5X5[4][1];
        in_22 = img_32X32[4+conv_row][2+count_col]; in_47 = ker_5X5[4][2];
        in_23 = img_32X32[4+conv_row][3+count_col]; in_48 = ker_5X5[4][3];
        in_24 = img_32X32[4+conv_row][4+count_col]; in_49 = ker_5X5[4][4];
    end
    
    else if (current_state == DECONV_8_8 || current_state == DECONV_16_16 || current_state == DECONV_32_32) begin
        
        in_20 = img_5X40_pad[4][0+count_deconv_col]; in_45 = ker_5X5[0][4];
        in_21 = img_5X40_pad[4][1+count_deconv_col]; in_46 = ker_5X5[0][3];
        in_22 = img_5X40_pad[4][2+count_deconv_col]; in_47 = ker_5X5[0][2];
        in_23 = img_5X40_pad[4][3+count_deconv_col]; in_48 = ker_5X5[0][1];
        in_24 = img_5X40_pad[4][4+count_deconv_col]; in_49 = ker_5X5[0][0];
    end

    else begin
        
        in_20 = 0; in_45 = 0;
        in_21 = 0; in_46 = 0;
        in_22 = 0; in_47 = 0;
        in_23 = 0; in_48 = 0;
        in_24 = 0; in_49 = 0;
    end
end

dp25 U0(
    .in_0(in_0), .in_1(in_1), .in_2(in_2), .in_3(in_3), .in_4(in_4),
    .in_5(in_5), .in_6(in_6), .in_7(in_7), .in_8(in_8), .in_9(in_9),
    .in_10(in_10), .in_11(in_11), .in_12(in_12), .in_13(in_13), .in_14(in_14),
    .in_15(in_15), .in_16(in_16), .in_17(in_17), .in_18(in_18), .in_19(in_19),
    .in_20(in_20), .in_21(in_21), .in_22(in_22), .in_23(in_23), .in_24(in_24),
    .in_25(in_25), .in_26(in_26), .in_27(in_27), .in_28(in_28), .in_29(in_29),
    .in_30(in_30), .in_31(in_31), .in_32(in_32), .in_33(in_33), .in_34(in_34),
    .in_35(in_35), .in_36(in_36), .in_37(in_37), .in_38(in_38), .in_39(in_39),
    .in_40(in_40), .in_41(in_41), .in_42(in_42), .in_43(in_43), .in_44(in_44),
    .in_45(in_45), .in_46(in_46), .in_47(in_47), .in_48(in_48), .in_49(in_49),
    .dp25_out(dp25_out)
);


// store dp output in feature map
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (i = 0; i < 2; i = i + 1) begin
            for (j = 0; j < 2; j = j + 1) begin
                feature_map_r[i][j] <= 0;
            end
        end
    end
    else if((current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) && count_19 < 4) begin
        feature_map_r[1][1] <= dp25_out;
        feature_map_r[0][1] <= feature_map_r[1][1];
        feature_map_r[1][0] <= feature_map_r[0][1];
        feature_map_r[0][0] <= feature_map_r[1][0];
    end

    
    else begin
        for (i = 0; i < 2; i = i + 1) begin
            for (j = 0; j < 2; j = j + 1) begin
                feature_map_r[i][j] <= feature_map_r[i][j];
            end
        end
    end
end



//=======================================================
//                   MAX POOLING
//=======================================================


// count 20 clk for output 20 bit
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_19 <= 0;
    end
    else if (current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) begin
        count_19 <= (count_19 == 19)? 0 : count_19 + 1;
        
        
    end
    else if (current_state == DECONV_8_8 || current_state == DECONV_16_16 || current_state == DECONV_32_32) begin
        count_19 <= (count_19 == 19)? 0 : count_19 + 1;
        
    end   
    else begin
        count_19 <= 0;
    end
end




// Maxpooling feature 2X2
assign candidate0 = (feature_map_r[0][0] > feature_map_r[0][1]) ? feature_map_r[0][0] : feature_map_r[0][1];
assign candidate1 = (feature_map_r[1][0] > feature_map_r[1][1]) ? feature_map_r[1][0] : feature_map_r[1][1];
assign max_pooling    = (candidate0 > candidate1) ? candidate0 : candidate1;


//store maxpooling
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        max_pooling_r <= 0;
    end
    else if ((current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) && count_19 == 4) begin
        max_pooling_r <= max_pooling;
    end
    else begin
        max_pooling_r <= max_pooling_r;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        deconv_r <= 0;
    end
    else if (current_state == DECONV_8_8 || current_state == DECONV_16_16 || current_state == DECONV_32_32) begin
        deconv_r <= dp25_out;
    end
    else begin
        deconv_r <= 0;
    end
end



//=======================================================
//                  OUTPUT
//=======================================================

always @(*) begin
    if (!rst_n) begin
        out_valid = 0;
        out_value = 0;
    end
    else if ((current_state == CONV_8_8 || current_state == CONV_16_16 || current_state == CONV_32_32) && count_conv >4) begin
        out_valid = 1;
        case(count_19)
            4+1: out_value = max_pooling_r[0];
            5+1: out_value = max_pooling_r[1];
            6+1: out_value = max_pooling_r[2];
            7+1: out_value = max_pooling_r[3];
            8+1: out_value = max_pooling_r[4];
            9+1: out_value = max_pooling_r[5];
            10+1: out_value = max_pooling_r[6];
            11+1: out_value = max_pooling_r[7];
            12+1: out_value = max_pooling_r[8];
            13+1: out_value = max_pooling_r[9];
            14+1: out_value = max_pooling_r[10];
            15+1: out_value = max_pooling_r[11];
            16+1: out_value = max_pooling_r[12];
            17+1: out_value = max_pooling_r[13];
            18+1: out_value = max_pooling_r[14];
            0: out_value = max_pooling_r[15];
            0+1: out_value = max_pooling_r[16];
            1+1: out_value = max_pooling_r[17];
            2+1: out_value = max_pooling_r[18];
            3+1: out_value = max_pooling_r[19];
            default: out_value = 0;
        endcase
    end
    else if ((current_state == DECONV_8_8 || current_state == DECONV_16_16 || current_state == DECONV_32_32)&&count_deconv>0) begin
        out_valid = 1;
        case(count_19)
            0+1: out_value = deconv_r[0];
            1+1: out_value = deconv_r[1];
            2+1: out_value = deconv_r[2];
            3+1: out_value = deconv_r[3];
            4+1: out_value = deconv_r[4];
            5+1: out_value = deconv_r[5];
            6+1: out_value = deconv_r[6];
            7+1: out_value = deconv_r[7];
            8+1: out_value = deconv_r[8];
            9+1: out_value = deconv_r[9];
            10+1: out_value = deconv_r[10];
            11+1: out_value = deconv_r[11];
            12+1: out_value = deconv_r[12];
            13+1: out_value = deconv_r[13];
            14+1: out_value = deconv_r[14];
            15+1: out_value = deconv_r[15];
            16+1: out_value = deconv_r[16];
            17+1: out_value = deconv_r[17];
            18+1: out_value = deconv_r[18];
            0: out_value = deconv_r[19];
            default: out_value = 0;
        endcase
    end
    else begin
        out_valid = 0;
        out_value = 0;
    end
end
    

//=======================================================
//                    SRAM
//=======================================================

SRAM_2048X64 SRAM_IMG(
    .CK(clk), .WEB(WEB_IMG), .OE(1'b1), .CS(1'b1),

    .A0(ADDR_IMG[0]), .A1(ADDR_IMG[1]), .A2(ADDR_IMG[2]), .A3(ADDR_IMG[3]), .A4(ADDR_IMG[4]), .A5(ADDR_IMG[5]), .A6(ADDR_IMG[6]), .A7(ADDR_IMG[7]), .A8(ADDR_IMG[8]), .A9(ADDR_IMG[9]), .A10(ADDR_IMG[10]),

    .DI0(DI_IMG[0]),  .DI1(DI_IMG[1]),  .DI2(DI_IMG[2]),  .DI3(DI_IMG[3]),  .DI4(DI_IMG[4]),  .DI5(DI_IMG[5]),  .DI6(DI_IMG[6]),  .DI7(DI_IMG[7]),  .DI8(DI_IMG[8]),  .DI9(DI_IMG[9]),
    .DI10(DI_IMG[10]),.DI11(DI_IMG[11]),.DI12(DI_IMG[12]),.DI13(DI_IMG[13]),.DI14(DI_IMG[14]),.DI15(DI_IMG[15]),.DI16(DI_IMG[16]),.DI17(DI_IMG[17]),.DI18(DI_IMG[18]),.DI19(DI_IMG[19]),
    .DI20(DI_IMG[20]),.DI21(DI_IMG[21]),.DI22(DI_IMG[22]),.DI23(DI_IMG[23]),.DI24(DI_IMG[24]),.DI25(DI_IMG[25]),.DI26(DI_IMG[26]),.DI27(DI_IMG[27]),.DI28(DI_IMG[28]),.DI29(DI_IMG[29]),
    .DI30(DI_IMG[30]),.DI31(DI_IMG[31]),.DI32(DI_IMG[32]),.DI33(DI_IMG[33]),.DI34(DI_IMG[34]),.DI35(DI_IMG[35]),.DI36(DI_IMG[36]),.DI37(DI_IMG[37]),.DI38(DI_IMG[38]),.DI39(DI_IMG[39]),
    .DI40(DI_IMG[40]),.DI41(DI_IMG[41]),.DI42(DI_IMG[42]),.DI43(DI_IMG[43]),.DI44(DI_IMG[44]),.DI45(DI_IMG[45]),.DI46(DI_IMG[46]),.DI47(DI_IMG[47]),.DI48(DI_IMG[48]),.DI49(DI_IMG[49]),
    .DI50(DI_IMG[50]),.DI51(DI_IMG[51]),.DI52(DI_IMG[52]),.DI53(DI_IMG[53]),.DI54(DI_IMG[54]),.DI55(DI_IMG[55]),.DI56(DI_IMG[56]),.DI57(DI_IMG[57]),.DI58(DI_IMG[58]),.DI59(DI_IMG[59]),
    .DI60(DI_IMG[60]),.DI61(DI_IMG[61]),.DI62(DI_IMG[62]),.DI63(DI_IMG[63]),

    .DO0(DO_IMG[0]),  .DO1(DO_IMG[1]),  .DO2(DO_IMG[2]),  .DO3(DO_IMG[3]),  .DO4(DO_IMG[4]),  .DO5(DO_IMG[5]),  .DO6(DO_IMG[6]),  .DO7(DO_IMG[7]),  .DO8(DO_IMG[8]),  .DO9(DO_IMG[9]),
    .DO10(DO_IMG[10]),.DO11(DO_IMG[11]),.DO12(DO_IMG[12]),.DO13(DO_IMG[13]),.DO14(DO_IMG[14]),.DO15(DO_IMG[15]),.DO16(DO_IMG[16]),.DO17(DO_IMG[17]),.DO18(DO_IMG[18]),.DO19(DO_IMG[19]),
    .DO20(DO_IMG[20]),.DO21(DO_IMG[21]),.DO22(DO_IMG[22]),.DO23(DO_IMG[23]),.DO24(DO_IMG[24]),.DO25(DO_IMG[25]),.DO26(DO_IMG[26]),.DO27(DO_IMG[27]),.DO28(DO_IMG[28]),.DO29(DO_IMG[29]),
    .DO30(DO_IMG[30]),.DO31(DO_IMG[31]),.DO32(DO_IMG[32]),.DO33(DO_IMG[33]),.DO34(DO_IMG[34]),.DO35(DO_IMG[35]),.DO36(DO_IMG[36]),.DO37(DO_IMG[37]),.DO38(DO_IMG[38]),.DO39(DO_IMG[39]),
    .DO40(DO_IMG[40]),.DO41(DO_IMG[41]),.DO42(DO_IMG[42]),.DO43(DO_IMG[43]),.DO44(DO_IMG[44]),.DO45(DO_IMG[45]),.DO46(DO_IMG[46]),.DO47(DO_IMG[47]),.DO48(DO_IMG[48]),.DO49(DO_IMG[49]),
    .DO50(DO_IMG[50]),.DO51(DO_IMG[51]),.DO52(DO_IMG[52]),.DO53(DO_IMG[53]),.DO54(DO_IMG[54]),.DO55(DO_IMG[55]),.DO56(DO_IMG[56]),.DO57(DO_IMG[57]),.DO58(DO_IMG[58]),.DO59(DO_IMG[59]),
    .DO60(DO_IMG[60]),.DO61(DO_IMG[61]),.DO62(DO_IMG[62]),.DO63(DO_IMG[63]) );

SRAM_80X40 KERNEL_SRAM (
    .CK(clk), .WEB(WEB_KER), .OE(1'b1), .CS(1'b1),

    .A0(ADDR_KER[0]), .A1(ADDR_KER[1]), .A2(ADDR_KER[2]), .A3(ADDR_KER[3]), .A4(ADDR_KER[4]), .A5(ADDR_KER[5]), .A6(ADDR_KER[6]),

    .DI0(DI_KER[0]),  .DI1(DI_KER[1]),  .DI2(DI_KER[2]),  .DI3(DI_KER[3]),  .DI4(DI_KER[4]),  .DI5(DI_KER[5]),  .DI6(DI_KER[6]),  .DI7(DI_KER[7]),  .DI8(DI_KER[8]),  .DI9(DI_KER[9]),
    .DI10(DI_KER[10]),.DI11(DI_KER[11]),.DI12(DI_KER[12]),.DI13(DI_KER[13]),.DI14(DI_KER[14]),.DI15(DI_KER[15]),.DI16(DI_KER[16]),.DI17(DI_KER[17]),.DI18(DI_KER[18]),.DI19(DI_KER[19]),
    .DI20(DI_KER[20]),.DI21(DI_KER[21]),.DI22(DI_KER[22]),.DI23(DI_KER[23]),.DI24(DI_KER[24]),.DI25(DI_KER[25]),.DI26(DI_KER[26]),.DI27(DI_KER[27]),.DI28(DI_KER[28]),.DI29(DI_KER[29]),
    .DI30(DI_KER[30]),.DI31(DI_KER[31]),.DI32(DI_KER[32]),.DI33(DI_KER[33]),.DI34(DI_KER[34]),.DI35(DI_KER[35]),.DI36(DI_KER[36]),.DI37(DI_KER[37]),.DI38(DI_KER[38]),.DI39(DI_KER[39]),

    .DO0(DO_KER[0]),  .DO1(DO_KER[1]),  .DO2(DO_KER[2]),  .DO3(DO_KER[3]),  .DO4(DO_KER[4]),  .DO5(DO_KER[5]),  .DO6(DO_KER[6]),  .DO7(DO_KER[7]),  .DO8(DO_KER[8]),  .DO9(DO_KER[9]),
    .DO10(DO_KER[10]),.DO11(DO_KER[11]),.DO12(DO_KER[12]),.DO13(DO_KER[13]),.DO14(DO_KER[14]),.DO15(DO_KER[15]),.DO16(DO_KER[16]),.DO17(DO_KER[17]),.DO18(DO_KER[18]),.DO19(DO_KER[19]),
    .DO20(DO_KER[20]),.DO21(DO_KER[21]),.DO22(DO_KER[22]),.DO23(DO_KER[23]),.DO24(DO_KER[24]),.DO25(DO_KER[25]),.DO26(DO_KER[26]),.DO27(DO_KER[27]),.DO28(DO_KER[28]),.DO29(DO_KER[29]),
    .DO30(DO_KER[30]),.DO31(DO_KER[31]),.DO32(DO_KER[32]),.DO33(DO_KER[33]),.DO34(DO_KER[34]),.DO35(DO_KER[35]),.DO36(DO_KER[36]),.DO37(DO_KER[37]),.DO38(DO_KER[38]),.DO39(DO_KER[39])  );

endmodule

module dp25 (
    in_0, in_1, in_2, in_3, in_4,
    in_5, in_6, in_7, in_8, in_9,
    in_10, in_11, in_12, in_13, in_14,
    in_15, in_16, in_17, in_18, in_19,
    in_20, in_21, in_22, in_23, in_24,
    in_25, in_26, in_27, in_28, in_29,
    in_30, in_31, in_32, in_33, in_34,
    in_35, in_36, in_37, in_38, in_39,
    in_40, in_41, in_42, in_43, in_44,
    in_45, in_46, in_47, in_48, in_49,
    dp25_out
);
input  signed   [7:0]   in_0, in_1, in_2, in_3, in_4,
                        in_5, in_6, in_7, in_8, in_9,
                        in_10, in_11, in_12, in_13, in_14,
                        in_15, in_16, in_17, in_18, in_19,
                        in_20, in_21, in_22, in_23, in_24,
                        in_25, in_26, in_27, in_28, in_29,
                        in_30, in_31, in_32, in_33, in_34,
                        in_35, in_36, in_37, in_38, in_39,
                        in_40, in_41, in_42, in_43, in_44,
                        in_45, in_46, in_47, in_48, in_49;
output signed  [20:0] dp25_out;
wire   signed  [20:0] MUL0, MUL1, MUL2, MUL3, MUL4, MUL5, MUL6, MUL7, MUL8, MUL9, MUL10, MUL11, MUL12, MUL13, MUL14, MUL15, MUL16, MUL17, MUL18, MUL19, MUL20, MUL21, MUL22, MUL23, MUL24;

assign MUL0 = in_0 * in_25;
assign MUL1 = in_1 * in_26;
assign MUL2 = in_2 * in_27;
assign MUL3 = in_3 * in_28;
assign MUL4 = in_4 * in_29;
assign MUL5 = in_5 * in_30;
assign MUL6 = in_6 * in_31;
assign MUL7 = in_7 * in_32;
assign MUL8 = in_8 * in_33;
assign MUL9 = in_9 * in_34;
assign MUL10 = in_10 * in_35;
assign MUL11 = in_11 * in_36;
assign MUL12 = in_12 * in_37;
assign MUL13 = in_13 * in_38;
assign MUL14 = in_14 * in_39;
assign MUL15 = in_15 * in_40;
assign MUL16 = in_16 * in_41;
assign MUL17 = in_17 * in_42;
assign MUL18 = in_18 * in_43;
assign MUL19 = in_19 * in_44;
assign MUL20 = in_20 * in_45;
assign MUL21 = in_21 * in_46;
assign MUL22 = in_22 * in_47;
assign MUL23 = in_23 * in_48;
assign MUL24 = in_24 * in_49;
assign dp25_out = MUL0 + MUL1 + MUL2 + MUL3 + MUL4 + MUL5 + MUL6 + MUL7 + MUL8 + MUL9 + MUL10 + MUL11 + MUL12 + MUL13 + MUL14 + MUL15 + MUL16 + MUL17 + MUL18 + MUL19 + MUL20 + MUL21 + MUL22 + MUL23 + MUL24;
endmodule
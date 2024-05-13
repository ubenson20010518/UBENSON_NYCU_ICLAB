//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`define S_BIT 6

module BRIDGE(
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

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//



parameter START_TX = 2'b01;
parameter START_TOKEN = 8'hFE;
parameter COMMAND_R_SD = 6'd17;
parameter COMMAND_W_SD = 6'd24;
parameter RESPONSE = 8'b0;
parameter ENDBIT = 1'b1;

parameter IDLE                      = `S_BIT'd0;
parameter ADDR_IN                   = `S_BIT'd1;
parameter D_SENDING_ARADDR          = `S_BIT'd2;
parameter D_RECIEVING_RDATA           = `S_BIT'd3;
parameter SD_SENDING_COMMAND       	= `S_BIT'd4;
parameter SD_WAITING_MISO_RESPONSE  	= `S_BIT'd5;
parameter SPI_DATA_DELAY  	= `S_BIT'd6;
parameter SD_SENDING_DATA          	= `S_BIT'd7;
parameter SD_WAITING_EIGHT_CYCLE 	= `S_BIT'd8;
parameter SD_WAITTING_BUSY          = `S_BIT'd9;
parameter SD_WAITING_MISO_DATA          	= `S_BIT'd10;
parameter SD_COMBINING_DATA        	= `S_BIT'd11;
parameter D_SENDING_AWADDR      	= `S_BIT'd12;
parameter D_WRITING_WDATA      	    = `S_BIT'd13;
parameter D_WAITING_B_VALID     	= `S_BIT'd14;
parameter D_DELAY_ONE_CYCLE              	    = `S_BIT'd15;
parameter OUTPUT               = `S_BIT'd16;
parameter DELAY                       = `S_BIT'd17;


//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [`S_BIT-1: 0] next_state, current_state;
reg [5:0] SPI_DATA_to_D_cnt_r;
reg direction_r;
reg [47:0] command_info_r;



reg [2:0] out_data_cnt_r;
reg [87:0] data_info_r;
reg [12:0] addr_dram_r;
reg [15:0] addr_sd_r;
reg [6:0] data_cnt_r;
reg [5:0] command_cnt_r;



//==============================================//
//                  design                      //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*) begin
	case(current_state)
		IDLE : next_state <= ADDR_IN;
		
		ADDR_IN : next_state <= (in_valid)? (direction)? SD_SENDING_COMMAND : D_SENDING_ARADDR : ADDR_IN;

        D_SENDING_ARADDR : begin
            if (AR_READY) begin
                next_state <= D_RECIEVING_RDATA;
            end 
            else begin
                next_state <= D_SENDING_ARADDR;
            end
        end
        D_RECIEVING_RDATA : begin
            if (R_VALID) begin
                next_state <= SD_SENDING_COMMAND;
            end 
            else begin
                next_state <= D_RECIEVING_RDATA;
            end
        end
        SD_SENDING_COMMAND : begin
            if (command_cnt_r == 6'd47) begin
                next_state <= SD_WAITING_MISO_RESPONSE;
            end 
            else begin
                next_state <= SD_SENDING_COMMAND;
            end
        end
        SD_WAITING_MISO_RESPONSE : begin
            if (!MISO) begin
                next_state <= SPI_DATA_DELAY;
            end 
            else begin
                next_state <= SD_WAITING_MISO_RESPONSE;
            end
        end
        SPI_DATA_DELAY : begin
            if (SPI_DATA_to_D_cnt_r == 6'd14) begin
                if (direction_r)
                next_state <= SD_WAITING_MISO_DATA;
                else
                next_state <= SD_SENDING_DATA;
            end 
            else begin
                next_state <= SPI_DATA_DELAY;
            end
        end
        SD_WAITING_MISO_DATA : begin
            if (!MISO) begin
                next_state <= SD_COMBINING_DATA ;
            end 
            else begin
                next_state <= SD_WAITING_MISO_DATA;
            end
        end
        SD_COMBINING_DATA : begin
            if (data_cnt_r == 7'd79) begin
                next_state <= D_SENDING_AWADDR ;
            end 
            else begin
                next_state <= SD_COMBINING_DATA;
            end
        end
        //DELAY : next_state <= SD_SENDING_DATA;
        SD_SENDING_DATA : begin
            if (data_cnt_r == 7'd87) begin
                next_state <= SD_WAITING_EIGHT_CYCLE ;
            end 
            else begin
                next_state <= SD_SENDING_DATA;
            end
        end
        SD_WAITING_EIGHT_CYCLE : begin
            if (data_cnt_r == 7'd95) begin
                next_state <= SD_WAITTING_BUSY ;
            end 
            else begin
                next_state <= SD_WAITING_EIGHT_CYCLE;
            end
        end
        SD_WAITTING_BUSY : begin
            if (MISO) begin
                next_state <= OUTPUT ;
            end 
            else begin
                next_state <= SD_WAITTING_BUSY;
            end
        end
        D_SENDING_AWADDR : begin
            if (AW_READY) begin
                next_state <= D_WRITING_WDATA ;
            end 
            else begin
                next_state <= D_SENDING_AWADDR;
            end
        end
        D_WRITING_WDATA : begin
            if (W_READY) begin
                next_state <= D_WAITING_B_VALID ;
            end 
            else begin
                next_state <= D_WRITING_WDATA;
            end
        end
        D_WAITING_B_VALID : begin
            if (B_VALID) begin
                next_state <= D_DELAY_ONE_CYCLE ;
            end 
            else begin
                next_state <= D_WAITING_B_VALID;
            end
        end
        D_DELAY_ONE_CYCLE : next_state <= OUTPUT;
        OUTPUT : begin
            if (out_data_cnt_r == 4'd7) begin
                next_state <= IDLE;
            end 
            else begin
                next_state <= OUTPUT;
            end
        end
        default : next_state <= IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_dram_r <= 13'd0;
        addr_sd_r   <= 16'd0;
        direction_r <= 1'b0;
    end
    else if (in_valid) begin
        addr_dram_r <= addr_dram;
        addr_sd_r   <= addr_sd;
        direction_r <= direction;
    end
    else begin
        addr_dram_r <= addr_dram_r;
        addr_sd_r   <= addr_sd_r;
        direction_r <= direction_r;
    end
end    

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        command_info_r <= 48'd0;
    end 
    else if (direction && in_valid) begin
        command_info_r[47:46] <= START_TX;
        command_info_r[45:40] <= COMMAND_R_SD;
        command_info_r[39:8]  <= {16'b0, addr_sd};
        command_info_r[7:0]   <= {CRC7({START_TX, COMMAND_R_SD, {16'b0, addr_sd}}), 1'b1};
    end
    else if (R_VALID) begin
        command_info_r[47:46] <= START_TX;
        command_info_r[45:40] <= COMMAND_W_SD;
        command_info_r[39:8]  <= {16'b0, addr_sd_r};
        command_info_r[7:0]   <= {CRC7({START_TX, COMMAND_W_SD, {16'b0, addr_sd_r}}), 1'b1};
    end
    else if(current_state == SD_SENDING_COMMAND && R_VALID == 0) begin
        command_info_r <= {command_info_r[46:0], command_info_r[47]};
    end
    else if (current_state) begin
        command_info_r <= 48'b0;
    end
    else begin
        command_info_r <= command_info_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_info_r <= 88'd0;
    end
    else if (R_VALID) begin
        data_info_r[87:80] <= START_TOKEN;
        data_info_r[79:16] <= R_DATA;
        data_info_r[15:0] <= CRC16_CCITT(R_DATA);
    end
    else if (current_state == SD_COMBINING_DATA) begin
        data_info_r <= {data_info_r[86:0], MISO};
    end
    else if (current_state == SD_SENDING_DATA) begin
        data_info_r <= {data_info_r[86:0], data_info_r[87]};
    end
    else if (current_state == IDLE) begin
        data_info_r <= 88'b0;
    end
    else begin
        data_info_r <= data_info_r;
    end
end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         data_cnt_r <= 7'd0;
//     else if (current_state == SD_SENDING_DATA || current_state == SD_WAITTING_DATA_RESPONSE || c_state == SD_GATHER_DATA)
//         data_cnt_r <= data_cnt_r + 1'd1;
//     else
//         data_cnt_r <= 7'd0;
// end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_cnt_r <= 7'd0;
    end
    else begin
        data_cnt_r <= (current_state == SD_SENDING_DATA || current_state == SD_WAITING_EIGHT_CYCLE || current_state == SD_COMBINING_DATA)? data_cnt_r + 1'd1 : 7'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        command_cnt_r <= 6'd0;
    end
    else begin
        command_cnt_r <= (current_state == SD_SENDING_COMMAND)? command_cnt_r + 1'd1 : 6'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        SPI_DATA_to_D_cnt_r <= 6'd0;
    end
    else begin
        SPI_DATA_to_D_cnt_r <= (current_state == SPI_DATA_DELAY)? SPI_DATA_to_D_cnt_r + 1'd1 : 6'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data_cnt_r <= 3'd0;
    end
    else begin
        out_data_cnt_r <= (current_state == OUTPUT)? out_data_cnt_r + 1'd1 : 3'd0;
    end
end

assign out_valid = (current_state == OUTPUT);

always @(*) begin
    if (current_state == OUTPUT) begin
        case(out_data_cnt_r) 
            3'd0: out_data <= data_info_r[79:72];
            3'd1: out_data <= data_info_r[71:64];
            3'd2: out_data <= data_info_r[63:56];
            3'd3: out_data <= data_info_r[55:48];
            3'd4: out_data <= data_info_r[47:40];
            3'd5: out_data <= data_info_r[39:32];
            3'd6: out_data <= data_info_r[31:24];
            3'd7: out_data <= data_info_r[23:16];
            default: out_data <= 8'd0;
        endcase
    end
    else begin
        out_data <= 8'd0;
    end
end

assign AR_ADDR = (current_state == D_SENDING_ARADDR)? {19'd0, addr_dram_r} : 32'd0;
assign AR_VALID = (current_state == D_SENDING_ARADDR);
assign R_READY = (current_state == D_RECIEVING_RDATA);
assign AW_ADDR = (current_state == D_SENDING_AWADDR)? {19'd0, addr_dram_r} : 32'd0;
assign AW_VALID = (current_state == D_SENDING_AWADDR);
assign W_DATA = (current_state == D_WRITING_WDATA)? data_info_r[79:16] : 64'd0;
assign W_VALID = (current_state == D_WRITING_WDATA);
assign B_READY = (current_state == D_WRITING_WDATA || current_state == D_WAITING_B_VALID);

assign MOSI = (current_state == SD_SENDING_COMMAND && R_VALID == 0)? command_info_r[47] : (current_state == SD_SENDING_DATA) ? data_info_r[87] : 1'b1;




//==============================================//
//             Example for function             //
//==============================================//

function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT;
    // Try to implement CRC-16-CCITT function by yourself.
    input [63:0] data;
    reg [15:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'b0001_0000_0010_0001; // x^16 + x^12 + x^5 + 1

    begin
        crc = 16'd0;
        for (i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1;
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end
endfunction

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




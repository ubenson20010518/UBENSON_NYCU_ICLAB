module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

reg [1:0] next_state, current_state;
reg [7:0] data;

parameter IDLE =            2'd0;
parameter DIN_TO_DATA =     2'd1;
parameter DATA_TO_DOUT =    2'd2;
parameter WAIT_SACK_LOW =   2'd3;

// FSM
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case(current_state) 
        IDLE: begin
            if (sready) begin
                next_state = DIN_TO_DATA;
            end
            else begin
                next_state = IDLE;
            end
        end
        DIN_TO_DATA: begin
            if (sreq) begin
                next_state = DATA_TO_DOUT;
            end
            else begin
                next_state = DIN_TO_DATA;
            end
        end
        DATA_TO_DOUT: begin
            if (sack) begin
                next_state = WAIT_SACK_LOW;
            end
            else begin
                next_state = DATA_TO_DOUT;
            end
        end
        WAIT_SACK_LOW: begin
            if (!sack) begin
                next_state = IDLE;
            end
            else begin
                next_state = WAIT_SACK_LOW;
            end
        end
        default: next_state = IDLE;
    endcase
end

// sreq
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        sreq <= 0;
    end
    else if (((sready == 1 && current_state == IDLE) || current_state == DIN_TO_DATA || current_state == DATA_TO_DOUT) && sack == 0) begin
        sreq <= 1;
    end
    else begin
        sreq <= 0;
    end
end

// data
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        data <= 0;
    end
    else if (sready == 1 && current_state == IDLE) begin
        data <= din;
    end
    else begin
        data <= data;
    end
end


NDFF_syn NDFF_syn1 (.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));

// dack
always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dack <= 0;
    end
    else if (dreq) begin
        dack <= 1;
    end
    else begin
        dack <= 0;
    end
end


always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 0;
    end
    else if (dack == 1 && dbusy == 0) begin
        dout <= data;
    end
    else begin
        dout <= 0;
    end
end

always @(*) begin
    dvalid = (dack & !dbusy);
end

NDFF_syn NDFF_syn2 (.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));

assign sidle = (current_state == IDLE);




endmodule
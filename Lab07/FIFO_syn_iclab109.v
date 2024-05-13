module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output  flag_fifo_to_clk2;
input flag_clk2_to_fifo;

output flag_fifo_to_clk1;
input flag_clk1_to_fifo;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

// rdata
//  Add one more register stage to rdata
// always @(posedge rclk, negedge rst_n) begin
//     if (!rst_n) begin
//         rdata <= 0;
//     end
//     else begin
// 		if (rinc & !rempty) begin
// 			rdata <= rdata_q;
// 		end
//     end
// end


reg rinc_r;

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rinc_r <= 0;
    end
    else begin
        rinc_r <= rinc;
    end
end

always @(posedge rclk, negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end
    else begin
		if (rinc_r) begin
			rdata <= rdata_q;
		end
    end
end


reg [$clog2(WORDS):0] waddr_r;
reg [$clog2(WORDS):0] raddr_r;

reg [$clog2(WORDS):0] rq2_wptr;
reg [$clog2(WORDS):0] wq2_rptr;


wire WEAN;
wire [6:0] g_to_b_r;

assign WEAN = (winc)? (wfull)? 1 : 0 : 1;

// 4bit
always @(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
        waddr_r <= 0;
    end
    else if (!wfull && winc) begin
        waddr_r <= waddr_r + 1;
    end
    else begin
        waddr_r <= waddr_r;
    end
end

// 4bit
always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        raddr_r <= 0;
    end
    else if (rinc && !rempty) begin
        raddr_r <= raddr_r + 1;
    end
    else begin
        raddr_r <= raddr_r;
    end
end

always @(*) begin
    wptr = (waddr_r >> 1) ^ waddr_r;
end

always @(*) begin
    rptr = (raddr_r >> 1) ^ raddr_r;
end


NDFF_BUS_syn #(7) sync_w2r (.D(wptr), .Q(rq2_wptr), .clk(rclk), .rst_n(rst_n));
NDFF_BUS_syn #(7) sync_r2w (.D(rptr), .Q(wq2_rptr), .clk(wclk), .rst_n(rst_n));

// gray to binary

assign g_to_b_r[0] = wq2_rptr[6]^wq2_rptr[5]^wq2_rptr[4]^wq2_rptr[3]^wq2_rptr[2]^wq2_rptr[1]^wq2_rptr[0];
assign g_to_b_r[1] = wq2_rptr[6]^wq2_rptr[5]^wq2_rptr[4]^wq2_rptr[3]^wq2_rptr[2]^wq2_rptr[1];
assign g_to_b_r[2] = wq2_rptr[6]^wq2_rptr[5]^wq2_rptr[4]^wq2_rptr[3]^wq2_rptr[2];
assign g_to_b_r[3] = wq2_rptr[6]^wq2_rptr[5]^wq2_rptr[4]^wq2_rptr[3];
assign g_to_b_r[4] = wq2_rptr[6]^wq2_rptr[5]^wq2_rptr[4];
assign g_to_b_r[5] = wq2_rptr[6]^wq2_rptr[5];
assign g_to_b_r[6] = wq2_rptr[6];



always @(*) begin
    wfull = ({~waddr_r[6], waddr_r[5:0]} == g_to_b_r);
end

always @(*) begin
    rempty = (rptr == rq2_wptr);
end

DUAL_64X8X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(WEAN),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(waddr_r[0]),
    .A1(waddr_r[1]),
    .A2(waddr_r[2]),
    .A3(waddr_r[3]),
    .A4(waddr_r[4]),
    .A5(waddr_r[5]),
    .B0(raddr_r[0]),
    .B1(raddr_r[1]),
    .B2(raddr_r[2]),
    .B3(raddr_r[3]),
    .B4(raddr_r[4]),
    .B5(raddr_r[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7])
);


endmodule

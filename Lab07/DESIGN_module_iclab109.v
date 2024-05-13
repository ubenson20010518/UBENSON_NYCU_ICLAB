module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_matrix_A,
    in_matrix_B,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_matrix,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [3:0] in_matrix_A;
input [3:0] in_matrix_B;
input out_idle;
output reg handshake_sready;
output reg [7:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [7:0] out_matrix;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;


parameter IDLE                  = 3'd0;
parameter WAIT_HANDSHACK_DONE   = 3'd1;
parameter WAIT_FIFO_NOT_EMPTY   = 3'd2;
parameter OUT                   = 3'd3;
parameter WAIT                  = 3'd4;


integer i;

reg [3:0] in_matrix_A_r[0:15];
reg [3:0] in_matrix_B_r[0:15];
reg [4:0] count_in_1, count_handshack;
reg [8:0] count_out_1;
reg in_valid_r;
reg [2:0] current_state_1, next_state_1;
reg out_valid_r, out_valid_rr;


assign flag_clk1_to_fifo = in_valid;

// FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state_1 <= IDLE;
    end
    else begin
        current_state_1 <= next_state_1;
    end
end

always @(*) begin
    case(current_state_1)
        IDLE: begin
            if (in_valid) begin
                next_state_1 = WAIT_HANDSHACK_DONE;
            end
            else begin
                next_state_1 = IDLE;
            end
        end
        WAIT_HANDSHACK_DONE: begin
            if (count_handshack == 16) begin
                next_state_1 = WAIT_FIFO_NOT_EMPTY;
            end
            else begin
                next_state_1 = WAIT;
            end
        end
        WAIT: begin
            if (count_handshack == 16) begin
                next_state_1 = WAIT_FIFO_NOT_EMPTY;
            end
            else begin
                next_state_1 = WAIT_HANDSHACK_DONE;
            end
        end
        WAIT_FIFO_NOT_EMPTY: begin
            if (!fifo_empty) begin
                next_state_1 = OUT;
            end
            else begin
                next_state_1 = WAIT_FIFO_NOT_EMPTY;
            end
        end
        OUT: begin
            if (count_out_1 == 255) begin
                next_state_1 = IDLE;
            end
            else begin
                next_state_1 = OUT;
            end
        end
        default: next_state_1 = IDLE;
    endcase
end
            

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_valid_r <= 0;
    end
    else begin
        in_valid_r <= in_valid;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_in_1 <= 0;
    end
    else if (in_valid) begin
        count_in_1 <= count_in_1 + 1;
    end
    else begin
        count_in_1 <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_handshack <= 0;
    end
    else if (in_valid && !in_valid_r) begin
        count_handshack <= 0;
    end
    else begin
        count_handshack <= (out_idle && handshake_sready)? count_handshack + 1 : count_handshack;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_out_1 <= 0;
    end
    else if (current_state_1 == IDLE) begin
        count_out_1 <= 0;
    end
    else if (current_state_1 == OUT && !fifo_empty) begin
        count_out_1 <= count_out_1 + 1;
    end
    else begin
        count_out_1 <= count_out_1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        handshake_sready <= 0;
    end
    else if (current_state_1 == WAIT_HANDSHACK_DONE && out_idle) begin
        handshake_sready <= 1;
    end
    else begin
        handshake_sready <= 0;
    end
end

assign fifo_rinc = ~fifo_empty;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 16; i = i + 1) begin
            in_matrix_A_r[i] <= 0;
        end
    end
    else if (in_valid) begin
        in_matrix_A_r[count_in_1] <= in_matrix_A;
    end
    else begin
        for (i = 0; i < 16; i = i + 1) begin
            in_matrix_A_r[i] <= in_matrix_A_r[i];
        end
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 16; i = i + 1) begin
            in_matrix_B_r[i] <= 0;
        end
    end
    else if (in_valid) begin
        in_matrix_B_r[count_in_1] <= in_matrix_B;
    end
    else begin
        for (i = 0; i < 16; i = i + 1) begin
            in_matrix_B_r[i] <= in_matrix_B_r[i];
        end
    end
end

always @(*) begin
    if (handshake_sready) begin
        handshake_din = {in_matrix_A_r[count_handshack], in_matrix_B_r[count_handshack]};
    end
    else begin
        handshake_din = 0;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid_r <= 0;
        out_valid_rr <= 0;
    end
    else if (!fifo_empty && next_state_1 == OUT) begin
        out_valid_r <= 1;
        out_valid_rr <= out_valid_r;
    end
    else begin
        out_valid_r <= 0;
        out_valid_rr <= out_valid_r;
    end
end


always @(*) begin
    out_valid = out_valid_rr;
end

always @(*) begin
    if (!rst_n) begin
        out_matrix = 0;
    end
    else if (out_valid) begin
        out_matrix = fifo_rdata;
    end
    else begin
        out_matrix = 0;
    end
end


endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_matrix,
    out_valid,
    out_matrix,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [7:0] in_matrix;
output reg out_valid;
output reg [7:0] out_matrix;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;


parameter IDLE = 3'd0;
parameter IN = 3'd1;
parameter WAIT_INVALID_LOW = 3'd2;
parameter WAIT_INVALID_HIGH = 3'd3;
parameter CALCULATE = 3'd4;

integer i;

reg [4:0] count_in_2;
reg [8:0] count_out_2;
reg [2:0] next_state_2, current_state_2;
reg [3:0] matrix_A [0:15], matrix_B [0:15];
reg [3:0] count_col, count_row;
wire [7:0] result;


// FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state_2 <= IDLE;
    end
    else begin
        current_state_2 <= next_state_2;
    end
end

always @(*) begin
    case(current_state_2)
        IDLE: begin
            if (in_valid) begin
                next_state_2 = IN;
            end
            else begin
                next_state_2 = IDLE;
            end
        end
        IN: begin
            next_state_2 = WAIT_INVALID_LOW;
        end
        WAIT_INVALID_LOW: begin
            if (!in_valid) begin
                next_state_2 = WAIT_INVALID_HIGH;
            end
            else begin
                next_state_2 = WAIT_INVALID_LOW;
            end
        end
        WAIT_INVALID_HIGH: begin
            if (count_in_2 == 16) begin
                next_state_2 = CALCULATE;
            end
            else if (in_valid) begin
                next_state_2 = IN;
            end
            else begin
                next_state_2 = WAIT_INVALID_HIGH;
            end
        end
        CALCULATE: begin
            if (count_out_2 == 257) begin
                next_state_2 = IDLE;
            end
            else begin
                next_state_2 = CALCULATE;
            end
        end
        default: next_state_2 = IDLE;
    endcase
end




always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_in_2 <= 0;
    end
    else if (current_state_2 == IDLE) begin
        count_in_2 <= 0;
    end
    else if (current_state_2 == IN) begin
        count_in_2 <= count_in_2 + 1;
    end
    else begin
        count_in_2 <= count_in_2;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 16; i = i + 1) begin
            matrix_A[i] <= 0;
        end
    end
    else if (in_valid) begin
        matrix_A[count_in_2] <= in_matrix[7:4];
    end
    else begin
        for (i = 0; i < 16; i = i + 1) begin
            matrix_A[i] <= matrix_A[i];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 16; i = i + 1) begin
            matrix_B[i] <= 0;
        end
    end
    else if (in_valid) begin
        matrix_B[count_in_2] <= in_matrix[3:0];
    end
    else begin
        for (i = 0; i < 16; i = i + 1) begin
            matrix_B[i] <= matrix_B[i];
        end
    end
end

always @(*) begin
    busy = (current_state_2 == CALCULATE);
end



// column 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_col <= 0;
    end
    else if (current_state_2 == IDLE) begin
        count_col <= 0;
    end
    else if (current_state_2 == CALCULATE && !fifo_full) begin
        count_col <= count_col + 1;
    end
    else begin
        count_col <= count_col;
    end
end



// row
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_row<= 0;
    end
    else if (current_state_2 == IDLE) begin
        count_row <= 0;
    end
    else if (current_state_2 == CALCULATE && !fifo_full) begin
        count_row <= (count_col == 15)? count_row + 1 : count_row;
    end
    else begin
        count_row <= count_row;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_out_2 <= 0;
    end
    else if (current_state_2 == IDLE) begin
        count_out_2 <= 0;
    end
    else if (current_state_2 == CALCULATE && !fifo_full) begin
        count_out_2 <= count_out_2 + 1;
    end
    else begin
        count_out_2 <= count_out_2;
    end
end


always @(*) out_matrix = matrix_A[count_row] * matrix_B[count_col];

always @(*) begin
    if((current_state_2 == CALCULATE) && !fifo_full) begin
        out_valid = (in_valid) ? 0 : 1;
    end 
    else begin
        out_valid = 0;
    end

end
    



endmodule
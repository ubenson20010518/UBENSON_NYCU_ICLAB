module bridge(input clk, INF.bridge_inf inf);


typedef enum logic [2:0] {
    IDLE,
    WAIT_AR_READY,
    WAIT_R_VALID,
    OUT_READ_DATA,
    WAIT_AW_READY,
    WAIT_W_READY,
    WAIT_B_VALID,
    DONE
} state_t;

state_t current_state, next_state;

logic [63:0] data_r;






//================================================================
// state 
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

always_comb begin
    case (current_state)
        IDLE: begin
            if (inf.C_in_valid) begin
                next_state = (inf.C_r_wb)? WAIT_AR_READY : WAIT_AW_READY;
            end
            else begin
                next_state = IDLE;
            end
        end
        WAIT_AR_READY: begin
            if (inf.AR_READY) begin
                next_state = WAIT_R_VALID;
            end
            else begin
                next_state = WAIT_AR_READY;
            end
        end
        WAIT_R_VALID: begin
            if (inf.R_VALID) begin
                next_state = OUT_READ_DATA;
            end
            else begin
                next_state = WAIT_R_VALID;
            end
        end
        OUT_READ_DATA: begin
            next_state = IDLE;
        end
        WAIT_AW_READY: begin
            if (inf.AW_READY) begin
                next_state = WAIT_W_READY;
            end
            else begin
                next_state = WAIT_AW_READY;
            end
        end
        WAIT_W_READY: begin
            if (inf.W_READY) begin
                next_state = WAIT_B_VALID;
            end
            else begin
                next_state = WAIT_W_READY;
            end
        end
        WAIT_B_VALID: begin
            if (inf.B_VALID) begin
                next_state = DONE;
            end
            else begin
                next_state = WAIT_B_VALID;
            end
        end
        DONE: begin
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end



//================================================================
// logic 
//================================================================

assign inf.AR_VALID = (current_state == WAIT_AR_READY);
assign inf.R_READY = (current_state == WAIT_R_VALID);
assign inf.AW_VALID = (current_state == WAIT_AW_READY);
assign inf.W_VALID = (current_state == WAIT_W_READY);
assign inf.B_READY = (current_state == WAIT_W_READY || current_state == WAIT_B_VALID);

// read
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AR_ADDR <= 17'd0;
    end
    else if (inf.C_in_valid) begin
        inf.AR_ADDR <= {5'b10000, {1'b0, inf.C_addr, 3'b000}};
    end
    else begin
        inf.AR_ADDR <= inf.AR_ADDR;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        data_r <= 0;
    end
    else if (inf.R_VALID && inf.R_READY) begin
        data_r <= inf.R_DATA;
    end
    else begin
        data_r <= data_r;
    end
end

// write
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AW_ADDR <= 17'd0;
    end
    else if (inf.C_in_valid) begin
        inf.AW_ADDR <= {5'b10000, {1'b0, inf.C_addr, 3'b000}};;
    end
    else begin
        inf.AW_ADDR <= inf.AW_ADDR;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.W_DATA <= 64'd0;
    end
    else if (inf.C_in_valid) begin
        inf.W_DATA <= inf.C_data_w;
    end
    else begin
        inf.W_DATA <= inf.W_DATA;
    end
end



// output
assign inf.C_out_valid = (current_state == OUT_READ_DATA || current_state == DONE);

always_comb begin
    inf.C_data_r = (current_state == OUT_READ_DATA)? data_r : 64'd0;
end







endmodule
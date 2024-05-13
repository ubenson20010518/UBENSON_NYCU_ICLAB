module PREFIX (
    // input port
    clk,
    rst_n,
    in_valid,
    opt,
    in_data,
    // output port
    out_valid,
    out
);

input clk;
input rst_n;
input in_valid;
input opt;
input [4:0] in_data;
output reg out_valid;
output reg signed [94:0] out;


integer i;

parameter IDLE = 4'd0;
parameter INPUT_SAVE = 4'd1;
parameter SHIFT_19 = 4'd2;
parameter SHIFT_OP = 4'd3;
parameter OUT = 4'd4;



reg signed [40:0] in_data_r [0:18];
reg [4:0] count_op;
reg signed [40:0] result;
reg [4:0] flag;
reg [4:0] in_temp_r [0:18];
reg [4:0] flag_r;
reg signed [40:0] in_0, in_1;
reg [3:0] mode;
reg opt_r;
reg in_valid_delay;
reg [4:0] RPE_r[0:18];
reg [4:0] operator_stack_r[0:8];

reg [3:0] next_state, current_state;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= 0;
    end
    else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case (current_state)
        IDLE: next_state = (in_valid)? INPUT_SAVE : IDLE;
        INPUT_SAVE: next_state = (!in_valid)? (opt_r)? SHIFT_19 : IDLE : INPUT_SAVE;
        SHIFT_19: next_state = (count_op == 18)? SHIFT_OP : SHIFT_19;
        SHIFT_OP: next_state = (operator_stack_r[8] == 0)? OUT : SHIFT_OP;
        OUT: next_state = IDLE;
        default : next_state = IDLE;
    endcase
end




always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_op <= 0;
    end
    else if (!in_valid && !opt_r) begin
        count_op <= (count_op == 10)? 0 : count_op + 1;
    end
    else if (current_state == SHIFT_19 && (!in_temp_r[count_op][1] && operator_stack_r[8][1]) && (in_temp_r[count_op][4]) ) begin
        count_op <= count_op ;
    end
    else if (current_state == SHIFT_19) begin
        count_op <= count_op + 1;
    end
    else begin
        count_op <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_valid_delay <= 0;
    end
    else if (in_valid) begin
        in_valid_delay <= in_valid;
    end
    else begin
        in_valid_delay <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        opt_r <= 0;
    end
    else if (in_valid && !in_valid_delay) begin
        opt_r <= opt;
    end
    else begin
        opt_r <= opt_r;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 19; i = i + 1) begin
            in_temp_r[i] <= 0;
        end
    end
    else if (in_valid) begin
        in_temp_r[0] <= in_data;
        for (i = 0; i < 18; i = i + 1) begin
            in_temp_r[i+1] <= in_temp_r[i];
        end
    end
    else begin
        for (i = 0; i < 19; i = i + 1) begin
            in_temp_r[i] <= in_temp_r[i];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 19; i = i + 1) begin
            in_data_r[i] <= 0;
            
        end
        flag_r <= 0;
    end
    else if (in_valid) begin
        in_data_r[0] <= in_data;
        for (i = 0; i < 18; i = i + 1) begin
            in_data_r[i+1] <= in_data_r[i];
        end
        flag_r <= 0;
    end
    //     in_data_r[18] <= in_data;
    //     for (i = 17; i > -1; i = i - 1) begin
    //         in_data_r[i] <= in_data_r[i+1];
    //     end
    // end
    else if (count_op != 0 && !opt_r) begin
        in_data_r[flag] <= result;
        flag_r <= flag;
        case(flag)
            2: begin
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            3: begin
                in_data_r[2] <= in_data_r[0];
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            4: begin
                in_data_r[3] <= in_data_r[1];
                in_data_r[2] <= in_data_r[0];
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            5: begin
                in_data_r[4] <= in_data_r[2];
                in_data_r[3] <= in_data_r[1];
                in_data_r[2] <= in_data_r[0];
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            6: begin
                for (i = 2; i < 6; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            7: begin
                for (i = 2; i < 7; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            8: begin
                for (i = 2; i < 8; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            9: begin
                for (i = 2; i < 9; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            10: begin
                for (i = 2; i < 10; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            11: begin
                for (i = 2; i < 11; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            12: begin
                for (i = 2; i < 12; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            13: begin
                for (i = 2; i < 13; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            14: begin
                for (i = 2; i < 14; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            15: begin
                for (i = 2; i < 15; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            16: begin
                for (i = 2; i < 16; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            17: begin
                for (i = 2; i < 17; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
            18: begin
                for (i = 2; i < 18; i = i + 1) begin
                    in_data_r[i] <= in_data_r[i-2];
                end
                in_data_r[1] <= 0;
                in_data_r[0] <= 0;
            end
        endcase
    end
        
    else begin
        for (i = 0; i < 19; i = i + 1) begin
            in_data_r[i] <= in_data_r[i];
        end
        flag_r <= 0;
    end
end

always @(*) begin
    if(in_data_r[2][4] && in_temp_r[2][4] && flag_r < 2) begin
        flag=2;
        in_0 = in_data_r[0];
        in_1 = in_data_r[1];
        mode = in_data_r[2][3:0];
    end
    else if (in_data_r[3][4] && in_temp_r[3][4] && flag_r < 3) begin
        flag=3;
        in_0 = in_data_r[1];
        in_1 = in_data_r[2];
        mode = in_data_r[3][3:0];
    end
    else if (in_data_r[4][4] && in_temp_r[4][4] && flag_r < 4) begin
        flag=4;
        in_0 = in_data_r[2];
        in_1 = in_data_r[3];
        mode = in_data_r[4][3:0];
    end
    else if (in_data_r[5][4] && in_temp_r[5][4] && flag_r < 5) begin
        flag=5;
        in_0 = in_data_r[3];
        in_1 = in_data_r[4];
        mode = in_data_r[5][3:0];
    end
    else if (in_data_r[6][4] && in_temp_r[6][4] && flag_r < 6) begin
        flag=6;
        in_0 = in_data_r[4];
        in_1 = in_data_r[5];
        mode = in_data_r[6][3:0];
    end
    else if (in_data_r[7][4] && in_temp_r[7][4] && flag_r < 7) begin
        flag=7;
        in_0 = in_data_r[5];
        in_1 = in_data_r[6];
        mode = in_data_r[7][3:0];
    end
    else if (in_data_r[8][4] && in_temp_r[8][4] && flag_r < 8) begin
        flag=8;
        in_0 = in_data_r[6];
        in_1 = in_data_r[7];
        mode = in_data_r[8][3:0];
    end
    else if (in_data_r[9][4] && in_temp_r[9][4] && flag_r < 9) begin
        flag=9;
        in_0 = in_data_r[7];
        in_1 = in_data_r[8];
        mode = in_data_r[9][3:0];
    end
    else if (in_data_r[10][4] && in_temp_r[10][4] && flag_r < 10) begin
        flag=10;
        in_0 = in_data_r[8];
        in_1 = in_data_r[9];
        mode = in_data_r[10][3:0];
    end
    else if (in_data_r[11][4] && in_temp_r[11][4] && flag_r < 11) begin
        flag=11;
        in_0 = in_data_r[9];
        in_1 = in_data_r[10];
        mode = in_data_r[11][3:0];
    end
    else if (in_data_r[12][4] && in_temp_r[12][4] && flag_r < 12) begin
        flag=12;
        in_0 = in_data_r[10];
        in_1 = in_data_r[11];
        mode = in_data_r[12][3:0];
    end
    else if (in_data_r[13][4] && in_temp_r[13][4] && flag_r < 13) begin
        flag=13;
        in_0 = in_data_r[11];
        in_1 = in_data_r[12];
        mode = in_data_r[13][3:0];
    end
    else if (in_data_r[14][4] && in_temp_r[14][4] && flag_r < 14) begin
        flag=14;
        in_0 = in_data_r[12];
        in_1 = in_data_r[13];
        mode = in_data_r[14][3:0];
    end
    else if (in_data_r[15][4] && in_temp_r[15][4] && flag_r < 15) begin
        flag=15;
        in_0 = in_data_r[13];
        in_1 = in_data_r[14];
        mode = in_data_r[15][3:0];
    end
    else if (in_data_r[16][4] && in_temp_r[16][4] && flag_r < 16) begin
        flag=16;
        in_0 = in_data_r[14];
        in_1 = in_data_r[15];
        mode = in_data_r[16][3:0];
    end
    else if (in_data_r[17][4] && in_temp_r[17][4] && flag_r < 17) begin
        flag=17;
        in_0 = in_data_r[15];
        in_1 = in_data_r[16];
        mode = in_data_r[17][3:0];
    end
    else if (in_data_r[18][4] && in_temp_r[18][4] && flag_r < 18) begin
        flag=18;
        in_0 = in_data_r[16];
        in_1 = in_data_r[17];
        mode = in_data_r[18][3:0];
    end
    else begin
        flag = 0;
        in_0 = 0;
        in_1 = 0;
        mode = 0;
    end       
end



always @(*) begin
    case(mode) 
        4'b0000: result = in_1+in_0;
        4'b0001: result = in_1-in_0;
        4'b0010: result = in_1*in_0;
        4'b0011: result = in_1/in_0;
        default: result = 0;
    endcase
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
        for (i = 0; i < 19; i = i + 1) begin
            RPE_r[i] <= 0;
        end
        for (i = 0; i < 9; i = i + 1) begin
            operator_stack_r[i] <= 0;
        end
        
    end
    else if (current_state == SHIFT_19) begin
        if (!in_temp_r[count_op][4]) begin //in_temp_r is operand
            RPE_r[18] <= in_temp_r[count_op];
            for (i = 17; i > -1; i = i - 1) begin
                RPE_r[i] <= RPE_r[i+1];
            end
        end
        else if (in_temp_r[count_op][4]) begin // in_temp_r is operator
            // stack is empty or current operator is larger the top of stack
            if (operator_stack_r[8] == 0) begin
                operator_stack_r[8] <= in_temp_r[count_op];
                for (i = 7; i > -1; i = i - 1) begin
                    operator_stack_r[i] <= operator_stack_r[i+1];
                end
            end
            //current operator is smaller the top of stack
            else if ((!in_temp_r[count_op][1] && operator_stack_r[8][1])) begin
                operator_stack_r[0] <= 0;
                for (i = 0; i < 8; i = i + 1) begin
                    operator_stack_r[i+1] <= operator_stack_r[i];
                end
                RPE_r[18] <= operator_stack_r[8];
                for (i = 17; i > -1; i = i - 1) begin
                    RPE_r[i] <= RPE_r[i+1];
                end
            end
            else begin
                operator_stack_r[8] <= in_temp_r[count_op];
                for (i = 7; i > -1; i = i - 1) begin
                    operator_stack_r[i] <= operator_stack_r[i+1];
                end
            end
        end
    end
    else if (current_state == SHIFT_OP) begin
        operator_stack_r[0] <= 0;
        for (i = 0; i < 8; i = i + 1) begin
            operator_stack_r[i+1] <= operator_stack_r[i];
        end
        RPE_r[18] <= operator_stack_r[8];
        for (i = 17; i > -1; i = i - 1) begin
            RPE_r[i] <= RPE_r[i+1];
        end
    end
end






always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
        out <= 0;
        out_valid <= 0;
    end
    else if (!opt_r && count_op == 10) begin
        out <= in_data_r[18];
        out_valid <= 1;
    end
    else if (next_state == OUT) begin
        out <= {RPE_r[0], RPE_r[1], RPE_r[2], RPE_r[3], RPE_r[4], RPE_r[5], RPE_r[6], RPE_r[7], RPE_r[8], RPE_r[9], RPE_r[10], RPE_r[11], RPE_r[12], RPE_r[13], RPE_r[14], RPE_r[15], RPE_r[16], RPE_r[17], RPE_r[18]};
        out_valid <= 1;
    end
    else begin
        out <= 0;
        out_valid <= 0;
    end
end


endmodule
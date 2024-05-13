module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated types.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system
//
// Each enumerated type defines a set of named states that the corresponding process can be in.
typedef enum logic [1:0]{
    IDLE,
    MAKE_DRINK,
    SUPPLY,
    CHECK_DATE
} state_t;

typedef enum logic [3:0]{
    IDLE_M,
    WAIT_TYPE_VALID_M,
    WAIT_SIZE_VALID_M,
    WAIT_DATE_VALID_M,
    WAIT_BOX_NO_VALID_M,
    SET_R_VALID_M,
    WAIT_R_DONE_M,
    CHECK_EXP_M,
    CHECK_ING_M,
    SET_W_VALID_M,
    WAIT_W_DONE_M,
    COMPLETE_M
} state_m;

typedef enum logic [3:0]{
    IDLE_S,
    WAIT_DATE_VALID_S,
    WAIT_BOX_NO_VALID_S,
    WAIT_BT_VALID_S,
    WAIT_GT_VALID_S,
    WAIT_MILK_VALID_S,
    WAIT_PJ_VALID_S,
    SET_R_VALID_S,
    WAIT_R_DONE_S,
    CHECK_OVERFLOW_S,
    SET_W_VALID_S,
    WAIT_W_DONE_S,
    COMPLETE_S
} state_s;

typedef enum logic [3:0]{
    IDLE_C,
    WAIT_DATE_VALID_C,
    WAIT_BOX_NO_VALID_C,
    SET_R_VALID_C,
    WAIT_R_DONE_C,
    CHECK_EXP_C,
    COMPLETE_C
} state_c;


// REGISTERS
state_t state, nstate;
state_m make_state, make_nstate;
state_s supply_state, supply_nstate;
state_c check_state, check_nstate;


Bev_Type type_r;
Bev_Size size_r;
Month month_r, final_month;
Day day_r, final_day;
Barrel_No box_no_r;
Bev_Bal final_bal;

Error_Msg err_r;


Bev_Bal bev_contain;

ING black_tea_r, green_tea_r, milk_r, pineapple_juice_r;

logic expired_flag, no_ing_or_overflow_flag;
logic [12:0] final_black_tea, final_green_tea, final_milk, final_pineapple_juice;
logic [11:0] black_tea_consume, green_tea_consume, milk_consume, pineapple_juice_consume;
logic [11:0] black_tea_ratio, green_tea_ratio, milk_ratio, pineapple_juice_ratio;
logic delay_size_valid;

// STATE MACHINE
always_ff @( posedge clk or negedge inf.rst_n) begin : TOP_FSM_SEQ
    if (!inf.rst_n) state <= IDLE;
    else state <= nstate;
end

always_comb begin : TOP_FSM_COMB
    case(state)
        IDLE: begin
            if (inf.sel_action_valid)
            begin
                case(inf.D.d_act[0])
                    Make_drink: nstate = MAKE_DRINK;
                    Supply: nstate = SUPPLY;
                    Check_Valid_Date: nstate = CHECK_DATE;
                    default: nstate = IDLE;
                endcase
            end
            else
            begin
                nstate = IDLE;
            end
        end
        MAKE_DRINK  : nstate = (inf.out_valid)? IDLE : MAKE_DRINK;
        SUPPLY      : nstate = (inf.out_valid)? IDLE : SUPPLY;
        CHECK_DATE  : nstate = (inf.out_valid)? IDLE : CHECK_DATE;
        default: nstate = IDLE;
    endcase
end


// MAKE DRINK FSM
always_ff @( posedge clk or negedge inf.rst_n) begin : MAKE_DRINK_FSM_SEQ
    if (!inf.rst_n) make_state <= IDLE_M;
    else make_state <= make_nstate;
end

always_comb begin : MAKE_DRINK_FSM_COMB
    case(make_state)
        IDLE_M: begin
            if (inf.sel_action_valid) begin
                make_nstate = (inf.D.d_act[0] == Make_drink)? WAIT_TYPE_VALID_M : IDLE_M;
            end
            else begin
                make_nstate = IDLE_M;
            end
        end
        WAIT_TYPE_VALID_M: begin
            if (inf.type_valid) begin
                make_nstate = WAIT_SIZE_VALID_M;
            end
            else begin
                make_nstate = WAIT_TYPE_VALID_M;
            end
        end
        WAIT_SIZE_VALID_M: begin
            if (inf.size_valid) begin
                make_nstate = WAIT_DATE_VALID_M;
            end
            else begin
                make_nstate = WAIT_SIZE_VALID_M;
            end
        end
        WAIT_DATE_VALID_M: begin
            if (inf.date_valid) begin
                make_nstate = WAIT_BOX_NO_VALID_M;
            end
            else begin
                make_nstate = WAIT_DATE_VALID_M;
            end
        end
        WAIT_BOX_NO_VALID_M: begin
           if (inf.box_no_valid) begin
                make_nstate = SET_R_VALID_M;
            end
            else begin
                make_nstate = WAIT_BOX_NO_VALID_M;
            end
        end 
        SET_R_VALID_M: begin
            make_nstate = WAIT_R_DONE_M;
        end
        WAIT_R_DONE_M: begin
            if (inf.C_out_valid) begin
                make_nstate = CHECK_EXP_M;
            end
            else begin
                make_nstate = WAIT_R_DONE_M;
            end
        end
        CHECK_EXP_M: begin
            if (expired_flag) begin
                make_nstate = COMPLETE_M;
            end
            else begin
                make_nstate = CHECK_ING_M;
            end
        end
        CHECK_ING_M: begin
            if (no_ing_or_overflow_flag) begin
                make_nstate = COMPLETE_M;
            end
            else begin
                make_nstate = SET_W_VALID_M;
            end
        end
        SET_W_VALID_M: begin
            make_nstate = WAIT_W_DONE_M;
        end
        WAIT_W_DONE_M: begin
             if (inf.C_out_valid) begin
                make_nstate = COMPLETE_M;
            end
            else begin
                make_nstate = WAIT_W_DONE_M;
            end
        end
        COMPLETE_M: begin
            make_nstate = IDLE_M;
        end
        default: begin
            make_nstate = IDLE_M;
        end
    endcase
end

// SUPPLY FSM
always_ff @( posedge clk or negedge inf.rst_n) begin : SUPPLY_FSM_SEQ
    if (!inf.rst_n) supply_state <= IDLE_S;
    else supply_state <= supply_nstate;
end

always_comb begin : SUPPLY_FSM_COMB
    case(supply_state)
        IDLE_S: begin
            if (inf.sel_action_valid) begin
                supply_nstate = (inf.D.d_act[0] == Supply)? WAIT_DATE_VALID_S : IDLE_S;
            end
            else begin
                supply_nstate = IDLE_S;
            end
        end
        WAIT_DATE_VALID_S: begin
            if (inf.date_valid) begin
                supply_nstate = WAIT_BOX_NO_VALID_S;
            end
            else begin
                supply_nstate = WAIT_DATE_VALID_S;
            end
        end
        WAIT_BOX_NO_VALID_S: begin
           if (inf.box_no_valid) begin
                supply_nstate = WAIT_BT_VALID_S;
            end
            else begin
                supply_nstate = WAIT_BOX_NO_VALID_S;
            end
        end
        WAIT_BT_VALID_S: begin
           if (inf.box_sup_valid) begin
                supply_nstate = WAIT_GT_VALID_S;
            end
            else begin
                supply_nstate = WAIT_BT_VALID_S;
            end
        end
        WAIT_GT_VALID_S: begin
           if (inf.box_sup_valid) begin
                supply_nstate = WAIT_MILK_VALID_S;
            end
            else begin
                supply_nstate = WAIT_GT_VALID_S;
            end
        end
        WAIT_MILK_VALID_S: begin
           if (inf.box_sup_valid) begin
                supply_nstate = WAIT_PJ_VALID_S;
            end
            else begin
                supply_nstate = WAIT_MILK_VALID_S;
            end
        end
        WAIT_PJ_VALID_S: begin
           if (inf.box_sup_valid) begin
                supply_nstate = SET_R_VALID_S;
            end
            else begin
                supply_nstate = WAIT_PJ_VALID_S;
            end
        end
        SET_R_VALID_S: begin
            supply_nstate = WAIT_R_DONE_S;
        end
        WAIT_R_DONE_S: begin
            if (inf.C_out_valid) begin
                supply_nstate = CHECK_OVERFLOW_S;
            end
            else begin
                supply_nstate = WAIT_R_DONE_S;
            end
        end
        CHECK_OVERFLOW_S: begin
            supply_nstate = SET_W_VALID_S;
        end
        
        SET_W_VALID_S: begin
            supply_nstate = WAIT_W_DONE_S;
        end
        WAIT_W_DONE_S: begin
             if (inf.C_out_valid) begin
                supply_nstate = COMPLETE_S;
            end
            else begin
                supply_nstate = WAIT_W_DONE_S;
            end
        end
        COMPLETE_S: begin
            supply_nstate = IDLE_S;
        end
        default: begin
            supply_nstate = IDLE_S;
        end
    endcase
end

// SUPPLY FSM
always_ff @( posedge clk or negedge inf.rst_n) begin : CHECK_VALID_DATE_FSM_SEQ
    if (!inf.rst_n) check_state <= IDLE_C;
    else check_state <= check_nstate;
end

always_comb begin : CHECK_VALID_DATE_FSM_COMB
    case(check_state)
        IDLE_C: begin
            if (inf.sel_action_valid) begin
                check_nstate = (inf.D.d_act[0] == Check_Valid_Date)? WAIT_DATE_VALID_C : IDLE_C;
            end
            else begin
                check_nstate = IDLE_C;
            end
        end
         WAIT_DATE_VALID_C: begin
            if (inf.date_valid) begin
                check_nstate = WAIT_BOX_NO_VALID_C;
            end
            else begin
                check_nstate = WAIT_DATE_VALID_C;
            end
        end
        WAIT_BOX_NO_VALID_C: begin
           if (inf.box_no_valid) begin
                check_nstate = SET_R_VALID_C;
            end
            else begin
                check_nstate = WAIT_BOX_NO_VALID_C;
            end
        end
        SET_R_VALID_C: begin
            check_nstate = WAIT_R_DONE_C;
        end
        WAIT_R_DONE_C: begin
            if (inf.C_out_valid) begin
                check_nstate = CHECK_EXP_C;
            end
            else begin
                check_nstate = WAIT_R_DONE_C;
            end
        end
        CHECK_EXP_C: begin
            check_nstate = COMPLETE_C;
        end
        COMPLETE_C: begin
            check_nstate = IDLE_C;
        end
        default: begin
            check_nstate = IDLE_C;
        end
    endcase 
end

// store input information
always_ff @( posedge clk or negedge inf.rst_n) begin : SAVE_TYPE
    if (!inf.rst_n) begin
        type_r <= Black_Tea;
    end
    else if (inf.type_valid) begin
        type_r <= inf.D.d_type[0];
    end
    else begin
        type_r <= type_r;
    end
end

// delay size valid
always_ff @( posedge clk or negedge inf.rst_n) begin : DELAY_SIZE_VALID
    if (!inf.rst_n) begin
        delay_size_valid <= 0;
    end
    else if (inf.size_valid) begin
        delay_size_valid <= 1;
    end
    else begin
        delay_size_valid <= 0;
    end
end


always_ff @( posedge clk or negedge inf.rst_n) begin : SAVE_SIZE
    if (!inf.rst_n) begin
        size_r <= L;
    end
    else if (state == IDLE) begin
        size_r <= L;
    end
    else if (inf.size_valid) begin
        size_r <= inf.D.d_size[0];
    end
    else begin
        size_r <= size_r;
    end
end

always_ff @( posedge clk or negedge inf.rst_n) begin : SAVE_MONTH_DAY
    if (!inf.rst_n) begin
        month_r <= 0;
        day_r <= 0;
    end
    else if (state == IDLE) begin
        month_r <= 0;
        day_r <= 0;
    end
    else if (inf.date_valid) begin
        month_r <= inf.D.d_date[0].M;
        day_r <= inf.D.d_date[0].D;
    end
    else begin
        month_r <= month_r;
        day_r <= day_r;
    end 
end

always_ff @( posedge clk or negedge inf.rst_n) begin : SAVE_BOX_NO
    if (!inf.rst_n) begin
        box_no_r <= 0;
    end
    else if (state == IDLE) begin
        box_no_r <= 0;
    end
    else if (inf.box_no_valid) begin
        box_no_r <= inf.D.d_box_no[0];
    end
    else begin
        box_no_r <= box_no_r;
    end
end

always_ff @( posedge clk or negedge inf.rst_n) begin : SAVE_ING
    if (!inf.rst_n) begin
        black_tea_r <= 0;
        green_tea_r <= 0;
        milk_r <= 0;
        pineapple_juice_r <= 0;
    end
    else if (state == IDLE) begin
        black_tea_r <= 0;
        green_tea_r <= 0;
        milk_r <= 0;
        pineapple_juice_r <= 0;
    end
    else if (inf.box_sup_valid) begin
        case(supply_state)
            WAIT_BT_VALID_S: black_tea_r <= inf.D.d_ing[0];
            WAIT_GT_VALID_S: green_tea_r <= inf.D.d_ing[0];
            WAIT_MILK_VALID_S: milk_r <= inf.D.d_ing[0];
            WAIT_PJ_VALID_S: pineapple_juice_r <= inf.D.d_ing[0];
        endcase
    end
    else begin
        black_tea_r <= black_tea_r;
        green_tea_r <= green_tea_r;
        milk_r <= milk_r;
        pineapple_juice_r <= pineapple_juice_r;
    end
end

always_ff @( posedge clk or negedge inf.rst_n) begin : SAVE_BEV_CONTAIN
    if (!inf.rst_n) begin
        bev_contain.black_tea <= 0;
        bev_contain.green_tea <= 0;
        bev_contain.milk <= 0;
        bev_contain.pineapple_juice <= 0;
        bev_contain.M <= 1;
        bev_contain.D <= 1;
    end
    else if (state == IDLE) begin
        bev_contain.black_tea <= 0;
        bev_contain.green_tea <= 0;
        bev_contain.milk <= 0;
        bev_contain.pineapple_juice <= 0;
        bev_contain.M <= 1;
        bev_contain.D <= 1;
    end
    else if (inf.C_out_valid) begin
        bev_contain.black_tea <= inf.C_data_r[63:52];
        bev_contain.green_tea <= inf.C_data_r[51:40];
        bev_contain.milk <= inf.C_data_r[31:20];
        bev_contain.pineapple_juice <= inf.C_data_r[19:8];
        bev_contain.M <= inf.C_data_r[35:32];
        bev_contain.D <= inf.C_data_r[4:0];
    end
    else begin
        bev_contain.black_tea <= bev_contain.black_tea;
        bev_contain.green_tea <= bev_contain.green_tea;
        bev_contain.milk <= bev_contain.milk;
        bev_contain.pineapple_juice <= bev_contain.pineapple_juice;
        bev_contain.M <= bev_contain.M;
        bev_contain.D <= bev_contain.D;
    end
end

always_comb begin : CHECK_EXPIRED
    if ((month_r > bev_contain.M) || (month_r == bev_contain.M && day_r > bev_contain.D)) begin
        expired_flag = 1;
    end
    else begin
        expired_flag = 0;
    end
end

always_comb begin : COMPUTE_FINAL_ING
    if (state == MAKE_DRINK) begin
        final_black_tea = bev_contain.black_tea - black_tea_consume;
        final_green_tea = bev_contain.green_tea - green_tea_consume;
        final_milk = bev_contain.milk - milk_consume;
        final_pineapple_juice = bev_contain.pineapple_juice - pineapple_juice_consume;
    end
    else if (state == SUPPLY) begin
        final_black_tea = bev_contain.black_tea + black_tea_r;
        final_green_tea = bev_contain.green_tea + green_tea_r;
        final_milk = bev_contain.milk + milk_r;
        final_pineapple_juice = bev_contain.pineapple_juice + pineapple_juice_r;
    end
    else begin
        final_black_tea = 0;
        final_green_tea = 0;
        final_milk = 0;
        final_pineapple_juice = 0;
    end
end



always_comb begin : SET_FINAL_DATE
    final_month =  bev_contain.M;
    final_day = bev_contain.D;
end

always_comb begin : CHECK_SUFFICIENT_ING_OR_OVERFLOW
    if (final_black_tea[12] || final_green_tea[12] || final_milk[12] || final_pineapple_juice[12]) begin
        no_ing_or_overflow_flag = 1;
    end
    else begin
        no_ing_or_overflow_flag = 0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        black_tea_ratio <= 0;
    end
    else if (state == IDLE) begin
        black_tea_consume <= 0;
    end
    else if (delay_size_valid) begin
        case (size_r)
            L: begin
                if(type_r == Black_Tea)     black_tea_consume <= 960;
                else if(type_r == Milk_Tea) black_tea_consume <= 720;
                else if(type_r == Extra_Milk_Tea || type_r == Super_Pineapple_Tea || type_r == Super_Pineapple_Milk_Tea) black_tea_consume <= 480;  
            end
            M: begin
                if(type_r == Black_Tea)     black_tea_consume <= 720;
                else if(type_r == Milk_Tea) black_tea_consume <= 540;
                else if(type_r == Extra_Milk_Tea || type_r == Super_Pineapple_Tea || type_r == Super_Pineapple_Milk_Tea) black_tea_consume <= 360;  
            end
            S: begin
                if(type_r == Black_Tea)     black_tea_consume <= 480;
                else if(type_r == Milk_Tea) black_tea_consume <= 360;
                else if(type_r == Extra_Milk_Tea || type_r == Super_Pineapple_Tea || type_r == Super_Pineapple_Milk_Tea) black_tea_consume <= 240;  
            end
            default: begin end
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        green_tea_consume <= 0;
    end
    else if (state == IDLE) begin
        green_tea_consume <= 0;
    end
    else if (delay_size_valid) begin
        case (size_r)
            L: begin
                if(type_r == Green_Tea)     green_tea_consume <= 960;
                else if(type_r == Green_Milk_Tea) green_tea_consume <= 480;
                end
            M: begin
                if(type_r == Green_Tea)     green_tea_consume <= 720;
                else if(type_r == Green_Milk_Tea) green_tea_consume <= 360;
                end
            S: begin
                if(type_r == Green_Tea)     green_tea_consume <= 480;
                else if(type_r == Green_Milk_Tea) green_tea_consume <= 240;
                end
            default: begin end
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        milk_consume <= 0;
    end
    else if (state == IDLE) begin
        milk_consume <= 0;
    end
    else if (delay_size_valid) begin
        case (size_r)
            L: begin
                if(type_r == Milk_Tea || type_r == Super_Pineapple_Milk_Tea) milk_consume <= 240;
                else if(type_r == Extra_Milk_Tea || type_r == Green_Milk_Tea) milk_consume <= 480;
                end
            M: begin
                if(type_r == Milk_Tea || type_r == Super_Pineapple_Milk_Tea)     milk_consume <= 180;
                else if(type_r == Extra_Milk_Tea || type_r == Green_Milk_Tea) milk_consume <= 360;
                end
            S: begin
                if(type_r == Milk_Tea || type_r == Super_Pineapple_Milk_Tea)     milk_consume <= 120;
                else if(type_r == Extra_Milk_Tea || type_r == Green_Milk_Tea) milk_consume <= 240;
                end
            default: begin end
        endcase
    end
end


always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        pineapple_juice_consume <= 0;
    end
    else if (state == IDLE) begin
        pineapple_juice_consume <= 0;
    end
    else if (delay_size_valid) begin
        case (size_r)
            L: begin
                if(type_r == Pineapple_Juice)     pineapple_juice_consume <= 960;
                else if(type_r == Super_Pineapple_Tea) pineapple_juice_consume <= 480;
                else if(type_r == Super_Pineapple_Milk_Tea) pineapple_juice_consume <= 240;
                end
            M: begin
                if(type_r == Pineapple_Juice)     pineapple_juice_consume <= 720;
                else if(type_r == Super_Pineapple_Tea) pineapple_juice_consume <= 360;
                else if(type_r == Super_Pineapple_Milk_Tea) pineapple_juice_consume <= 180;
                end
            S: begin
                if(type_r == Pineapple_Juice)     pineapple_juice_consume <= 480;
                else if(type_r == Super_Pineapple_Tea) pineapple_juice_consume <= 240;
                else if(type_r == Super_Pineapple_Milk_Tea) pineapple_juice_consume <= 120;
                end
            default: begin end
        endcase
    end
end


// correct the ingredient
always_ff @(posedge clk or negedge inf.rst_n) begin 
    if(!inf.rst_n) begin
        final_bal <= 0;
    end
    else begin
        case(state)
            MAKE_DRINK: begin
                final_bal.black_tea <= final_black_tea[11:0];
                final_bal.green_tea <= final_green_tea[11:0];
                final_bal.milk <= final_milk[11:0];
                final_bal.pineapple_juice <= final_pineapple_juice[11:0];
                final_bal.M <= bev_contain.M;
                final_bal.D <= bev_contain.D;
            end
            SUPPLY: begin
                final_bal.black_tea <= (final_black_tea[12])? 4095 : final_black_tea[11:0];
                final_bal.green_tea <= (final_green_tea[12])? 4095 : final_green_tea[11:0];
                final_bal.milk <= (final_milk[12])? 4095 : final_milk[11:0];
                final_bal.pineapple_juice <= (final_pineapple_juice[12])? 4095 : final_pineapple_juice[11:0];
                final_bal.M <= month_r;
                final_bal.D <= day_r;
            end
            default: begin
                final_bal.black_tea <= final_bal.black_tea;
                final_bal.green_tea <= final_bal.green_tea;
                final_bal.milk <= final_bal.milk;
                final_bal.pineapple_juice <= final_bal.pineapple_juice;
                final_bal.M <= final_bal.M;
                final_bal.D <= final_bal.D;
            end
        endcase
    end
end

// to bridge signal
always_comb begin
    if (make_state == SET_R_VALID_M || supply_state == SET_R_VALID_S || check_state == SET_R_VALID_C) begin
        inf.C_addr = box_no_r;
        inf.C_r_wb = 1;
        inf.C_in_valid = 1;
        inf.C_data_w = 0;
    end
    else if (make_state == SET_W_VALID_M || supply_state == SET_W_VALID_S) begin
        inf.C_addr = box_no_r;
        inf.C_r_wb = 0;
        inf.C_in_valid = 1;
        inf.C_data_w = {final_bal.black_tea, final_bal.green_tea, {4'd0, final_bal.M}, final_bal.milk, final_bal.pineapple_juice, {3'd0, final_bal.D}};
    end
    else begin
        inf.C_addr = 0;
        inf.C_r_wb = 0;
        inf.C_in_valid = 0;
        inf.C_data_w = 0;
    end
end

// store error
always_ff @( posedge clk or negedge inf.rst_n) begin : STORE_ERROR
    if (!inf.rst_n) begin
        err_r <= No_Err;
    end
    else if (state == IDLE) begin
        err_r <= No_Err;
    end
    else if (make_state == CHECK_EXP_M || check_state == CHECK_EXP_C) begin
        err_r <= (expired_flag)? No_Exp : No_Err;
    end
    else if (make_state == CHECK_ING_M) begin
        err_r <= (no_ing_or_overflow_flag)? No_Ing : No_Err;
    end
    else if (supply_state == CHECK_OVERFLOW_S) begin
        err_r <= (no_ing_or_overflow_flag)? Ing_OF : No_Err;
    end
    else begin
        err_r <= err_r;
    end
end

// output
always_comb begin : OUTPUT
    if (make_state == COMPLETE_M || supply_state == COMPLETE_S || check_state == COMPLETE_C) begin
        inf.out_valid = 1'b1;
        inf.err_msg   = err_r;
        inf.complete  = (err_r == No_Err);
    end
    else begin
        inf.out_valid = 1'b0;
        inf.err_msg   = No_Err;
        inf.complete  = 1'b0;
    end
end





endmodule

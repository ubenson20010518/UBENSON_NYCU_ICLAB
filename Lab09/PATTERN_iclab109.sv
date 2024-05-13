/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter addr_offset = 65536;

//================================================================
// wire & registers 
//================================================================
integer patcount, lat, total_lat, a;
integer PATNUM = 4000;
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box

Error_Msg golden_err;
logic     golden_complete;
Action action_id;
logic [8:0] box_no;

Bev_Bal bev_contain;
ING black_tea_ratio, green_tea_ratio, milk_ratio, pineapple_juice_ratio, black_tea_consume, green_tea_consume, milk_consume, pineapple_juice_consume;
ING final_black_tea, final_green_tea, final_milk, final_pineapple_juice;
//================================================================
// class random
//================================================================
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Make_drink, Supply, Check_Valid_Date};
    }
endclass

class random_type;
    randc Bev_Type bev_type;
    constraint range{
        bev_type inside{
            Black_Tea      	         ,
            Milk_Tea	             ,
            Extra_Milk_Tea           ,
            Green_Tea 	             ,
            Green_Milk_Tea           ,
            Pineapple_Juice          ,
            Super_Pineapple_Tea      ,
            Super_Pineapple_Milk_Tea
        };
    }
endclass

class random_size;
    randc Bev_Size bev_size;
    constraint range{
        bev_size inside{
            L, M, S
        };
    }
endclass

class random_date;
    randc Date date;
    constraint month_range{
        date.M inside{[1:12]};
    }
    constraint day_range{
        if (date.M == 1 || date.M == 3 || date.M == 5 || date.M == 7 || date.M == 8 || date.M == 10 || date.M == 12)
            date.D inside{[1:31]};
        if (date.M == 4 || date.M == 6 || date.M == 9 || date.M == 11 )
            date.D inside{[1:30]};
        if (date.M == 2)
            date.D inside{[1:28]};
    }
endclass

class random_box_no;
    randc logic [7:0] box_no;
    constraint range{
        box_no inside{[0:255]};
    }
endclass

class random_ing;
    randc ING black_tea;
    randc ING green_tea;
    randc ING milk;
    randc ING pineapple_juice;
    constraint range{
        black_tea inside{[0:4095]};
        green_tea inside{[0:4095]};
        milk inside{[0:4095]};
        pineapple_juice inside{[0:4095]};
    }    
endclass







//================================================================
// initial
//================================================================

random_act rand_act = new();
random_box_no rand_box_no = new();
random_date rand_date = new();
random_size rand_size = new();
random_type rand_type = new();
random_ing rand_ing = new();


initial $readmemh(DRAM_p_r, golden_DRAM); 
initial begin
    reset_signal_task;
    lat = 0;
    total_lat = 0;

    for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
        input_task;
        compute_golden_ans_task;
        wait_out_valid_task;
        check_ans_task;
    end
    YOU_PASS_TASK;
end


task reset_signal_task; begin
    inf.rst_n            = 'b1;
    inf.sel_action_valid = 'b0;
    inf.type_valid       = 'b0;
    inf.size_valid       = 'b0;
    inf.date_valid       = 'b0;
    inf.box_no_valid     = 'b0;
    inf.box_sup_valid    = 'b0;
    inf.D                = 'bx;

    force clk = 0;

    #10; inf.rst_n = 'b0;
    #50; inf.rst_n = 'b1;
    release clk;

    if(inf.out_valid !== 1'b0 || inf.complete !== 1'b0 || inf.err_msg !== 2'b00) begin
        $display("************************************************************");
        $display("*  Output signal should be 0 after initial RESET           *");
        $display("************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    repeat(2) @(negedge clk);


end endtask

task input_task; begin


    a = rand_act.randomize();
    a = rand_box_no.randomize();
    a = rand_date.randomize();
    a = rand_size.randomize();
    a = rand_type.randomize();
    a = rand_ing.randomize();

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.sel_action_valid = 'b1;
    if (patcount < 2350)
        inf.D.d_act[0] = Make_drink;
    else if (patcount < 2760 && patcount >= 2350)
        inf.D.d_act[0] = (patcount % 2 == 0)? Supply : Make_drink;
    else if (patcount < 3170 && patcount >= 2760)
        inf.D.d_act[0] = (patcount % 2 == 0)? Check_Valid_Date : Make_drink;
    else if (patcount < 3380 && patcount >= 3170)
        inf.D.d_act[0] = Supply;
    else if (patcount < 3790 && patcount >= 3380)
        inf.D.d_act[0] = (patcount % 2 == 0)? Supply : Check_Valid_Date;
    else if (patcount < 4000 && patcount >= 3790) 
        inf.D.d_act[0] = Check_Valid_Date;
    else 
        inf.D.d_act[0] = rand_act.act_id;
    //inf.D.d_act[0] = (patcount < 30)? Make_drink : (patcount < 230)? Supply : rand_act.act_id;
    action_id = inf.D.d_act[0];
    @(negedge clk);
    inf.sel_action_valid = 'b0;
    inf.D.d_act = 'bx;

    case(action_id)
        Make_drink: begin
            make_drink_task;
        end
        Supply: begin
            supply_task;
        end
        Check_Valid_Date: begin
            check_valid_date_task;
        end
    endcase
end endtask








task make_drink_task; begin
    repeat($urandom_range(0,3)) @(negedge clk);
    inf.type_valid = 'b1;
    inf.D.d_type[0] = rand_type.bev_type;
    @(negedge clk);
    inf.type_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.size_valid = 'b1;
    inf.D.d_size[0] = rand_size.bev_size;
    @(negedge clk);
    inf.size_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.date_valid = 'b1;
    inf.D.d_date[0] = rand_date.date;
    @(negedge clk);
    inf.date_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.box_no_valid = 'b1;
    inf.D.d_box_no[0] = (patcount < 20)? 0 : rand_box_no.box_no;
    box_no = inf.D.d_box_no[0];
    @(negedge clk);
    inf.box_no_valid = 'b0;
    inf.D = 'bx;
end endtask

task supply_task; begin
    repeat($urandom_range(0,3)) @(negedge clk);
    inf.date_valid = 'b1;
    inf.D.d_date[0] = rand_date.date;
    @(negedge clk);
    inf.date_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.box_no_valid = 'b1;
    inf.D.d_box_no[0] = rand_box_no.box_no;
    box_no = inf.D.d_box_no[0];
    @(negedge clk);
    inf.box_no_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.box_sup_valid = 'b1;
    inf.D.d_ing[0] = rand_ing.black_tea;
    @(negedge clk);
    inf.box_sup_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.box_sup_valid = 'b1;
    inf.D.d_ing[0] = rand_ing.green_tea;
    @(negedge clk);
    inf.box_sup_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.box_sup_valid = 'b1;
    inf.D.d_ing[0] = rand_ing.milk;
    @(negedge clk);
    inf.box_sup_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.box_sup_valid = 'b1;
    inf.D.d_ing[0] = rand_ing.pineapple_juice;
    @(negedge clk);
    inf.box_sup_valid = 'b0;
    inf.D = 'bx;
end endtask

task check_valid_date_task; begin
    repeat($urandom_range(0,3)) @(negedge clk);
    inf.date_valid = 'b1;
    inf.D.d_date[0] = rand_date.date;
    @(negedge clk);
    inf.date_valid = 'b0;
    inf.D = 'bx;

    repeat($urandom_range(0,3)) @(negedge clk);
    inf.box_no_valid = 'b1;
    inf.D.d_box_no[0] = rand_box_no.box_no;
    box_no = inf.D.d_box_no[0];
    @(negedge clk);
    inf.box_no_valid = 'b0;
    inf.D = 'bx;
end endtask




task compute_golden_ans_task; begin
    bev_contain.black_tea[3:0]          = golden_DRAM[addr_offset + box_no*8 + 6][7:4];
    bev_contain.black_tea[11:4]         = golden_DRAM[addr_offset + box_no*8 + 7];
    bev_contain.green_tea[7:0]          = golden_DRAM[addr_offset + box_no*8 + 5];
    bev_contain.green_tea[11:8]         = golden_DRAM[addr_offset + box_no*8 + 6][3:0];
    bev_contain.milk[3:0]               = golden_DRAM[addr_offset + box_no*8 + 2][7:4];
    bev_contain.milk[11:4]              = golden_DRAM[addr_offset + box_no*8 + 3];
    bev_contain.pineapple_juice[7:0]    = golden_DRAM[addr_offset + box_no*8 + 1];
    bev_contain.pineapple_juice[11:8]   = golden_DRAM[addr_offset + box_no*8 + 2][3:0];
    bev_contain.M                       = golden_DRAM[addr_offset + box_no*8 + 4];
    bev_contain.D                       = golden_DRAM[addr_offset + box_no*8];

    case(action_id)
        Make_drink: begin
            if (rand_type.bev_type == Black_Tea) begin
                black_tea_ratio = 240;
                green_tea_ratio = 0;
                milk_ratio = 0;
                pineapple_juice_ratio = 0;
            end
            if (rand_type.bev_type == Milk_Tea) begin
                black_tea_ratio = 180;
                green_tea_ratio = 0;
                milk_ratio = 60;
                pineapple_juice_ratio = 0;
            end
            if (rand_type.bev_type == Extra_Milk_Tea) begin
                black_tea_ratio = 120;
                green_tea_ratio = 0;
                milk_ratio = 120;
                pineapple_juice_ratio = 0;
            end
            if (rand_type.bev_type == Green_Tea) begin
                black_tea_ratio = 0;
                green_tea_ratio = 240;
                milk_ratio = 0;
                pineapple_juice_ratio = 0;
            end
            if (rand_type.bev_type == Green_Milk_Tea) begin
                black_tea_ratio = 0;
                green_tea_ratio = 120;
                milk_ratio = 120;
                pineapple_juice_ratio = 0;
            end
            if (rand_type.bev_type == Pineapple_Juice) begin
                black_tea_ratio = 0;
                green_tea_ratio = 0;
                milk_ratio = 0;
                pineapple_juice_ratio = 240;
            end
            if (rand_type.bev_type == Super_Pineapple_Tea) begin
                black_tea_ratio = 120;
                green_tea_ratio = 0;
                milk_ratio = 0;
                pineapple_juice_ratio = 120;
            end
            if (rand_type.bev_type == Super_Pineapple_Milk_Tea) begin
                black_tea_ratio = 120;
                green_tea_ratio = 0;
                milk_ratio = 60;
                pineapple_juice_ratio = 60;
            end

            if (rand_size.bev_size == L) begin
                black_tea_consume = black_tea_ratio*4;
                green_tea_consume = green_tea_ratio*4;
                milk_consume = milk_ratio*4;
                pineapple_juice_consume = pineapple_juice_ratio*4;
            end
            if (rand_size.bev_size == M) begin
                black_tea_consume = black_tea_ratio*2 + black_tea_ratio;
                green_tea_consume = green_tea_ratio*2 + green_tea_ratio;
                milk_consume = milk_ratio*2 + milk_ratio;
                pineapple_juice_consume = pineapple_juice_ratio*2 + pineapple_juice_ratio;
            end
            if (rand_size.bev_size == S) begin
                black_tea_consume = black_tea_ratio*2;
                green_tea_consume = green_tea_ratio*2;
                milk_consume = milk_ratio*2;
                pineapple_juice_consume = pineapple_juice_ratio*2;
            end

            if (rand_date.date.M > bev_contain.M  || (rand_date.date.M == bev_contain.M && rand_date.date.D > bev_contain.D)) begin
                golden_err = No_Exp;
                golden_complete = 0;
            end
            else if (black_tea_consume > bev_contain.black_tea || green_tea_consume > bev_contain.green_tea || milk_consume > bev_contain.milk || pineapple_juice_consume > bev_contain.pineapple_juice) begin
                golden_err = No_Ing;
                golden_complete = 0;
            end
            else begin
                golden_err = No_Err;
                golden_complete = 1;
                final_black_tea = bev_contain.black_tea - black_tea_consume;
                final_green_tea = bev_contain.green_tea - green_tea_consume;
                final_milk = bev_contain.milk - milk_consume;
                final_pineapple_juice = bev_contain.pineapple_juice - pineapple_juice_consume;

                golden_DRAM[addr_offset + box_no*8 + 6][7:4] = final_black_tea[3:0];
                golden_DRAM[addr_offset + box_no*8 + 7] = final_black_tea[11:4];
                golden_DRAM[addr_offset + box_no*8 + 5] = final_green_tea[7:0];
                golden_DRAM[addr_offset + box_no*8 + 6][3:0] = final_green_tea[11:8];
                golden_DRAM[addr_offset + box_no*8 + 2][7:4] = final_milk[3:0];
                golden_DRAM[addr_offset + box_no*8 + 3] = final_milk[11:4];
                golden_DRAM[addr_offset + box_no*8 + 1] = final_pineapple_juice[7:0];
                golden_DRAM[addr_offset + box_no*8 + 2][3:0] = final_pineapple_juice[11:8];
            end
        end
        Supply: begin
            golden_err = No_Err;
            golden_complete = 1;
            if (bev_contain.black_tea > 4095 - rand_ing.black_tea) begin
                golden_err = Ing_OF;
                golden_complete = 0;
                final_black_tea = 4095;
            end
            else begin
                final_black_tea = bev_contain.black_tea + rand_ing.black_tea;
            end
            if (bev_contain.green_tea > 4095 - rand_ing.green_tea) begin
                golden_err = Ing_OF;
                golden_complete = 0;
                final_green_tea = 4095;
            end
            else begin
                final_green_tea = bev_contain.green_tea + rand_ing.green_tea;
            end
            if (bev_contain.milk > 4095 - rand_ing.milk) begin
                golden_err = Ing_OF;
                golden_complete = 0;
                final_milk = 4095;
            end
            else begin
                final_milk = bev_contain.milk + rand_ing.milk;
            end
            if (bev_contain.pineapple_juice > 4095 - rand_ing.pineapple_juice) begin
                golden_err = Ing_OF;
                golden_complete = 0;
                final_pineapple_juice = 4095;
            end
            else begin
                final_pineapple_juice = bev_contain.pineapple_juice + rand_ing.pineapple_juice;
            end
            golden_DRAM[addr_offset + box_no*8 + 6][7:4] = final_black_tea[3:0];
            golden_DRAM[addr_offset + box_no*8 + 7] = final_black_tea[11:4];
            golden_DRAM[addr_offset + box_no*8 + 5] = final_green_tea[7:0];
            golden_DRAM[addr_offset + box_no*8 + 6][3:0] = final_green_tea[11:8];
            golden_DRAM[addr_offset + box_no*8 + 2][7:4] = final_milk[3:0];
            golden_DRAM[addr_offset + box_no*8 + 3] = final_milk[11:4];
            golden_DRAM[addr_offset + box_no*8 + 1] = final_pineapple_juice[7:0];
            golden_DRAM[addr_offset + box_no*8 + 2][3:0] = final_pineapple_juice[11:8];
            golden_DRAM[addr_offset + box_no*8 + 4] = rand_date.date.M;
            golden_DRAM[addr_offset + box_no*8] = rand_date.date.D;
        end
        Check_Valid_Date: begin
            if ((bev_contain.M < rand_date.date.M) || (bev_contain.M == rand_date.date.M && bev_contain.D < rand_date.date.D)) begin
                golden_err = No_Exp;
                golden_complete = 0;
            end
            else begin
                golden_err = No_Err;
                golden_complete = 1;
            end
        end
    endcase
end endtask

task wait_out_valid_task; begin
    lat = 0;
    while (inf.out_valid !== 'b1) begin
        lat = lat + 1;
        if (lat > 1000) begin
            $display(" Execution latency exceed 1000 cycles. ");
            $finish;
        end
        @(negedge clk);
    end
    total_lat = total_lat + lat;
end endtask

task check_ans_task; begin
    while(inf.out_valid === 1'b1) begin
        if (inf.err_msg !== golden_err || inf.complete !== golden_complete) begin
            $display("                              Wrong Answer                               ");
            repeat(2) @(negedge clk);
            $finish;
        end
        else if(inf.complete === 1'b1 && inf.err_msg != 2'b00) begin
            $display("              Complete should be 1 when there's no error                 ");
            $finish;
        end
        else if(inf.complete === 1'b0 && inf.err_msg == 2'b00) begin
            $display("              Complete should be 1 when there's no error                 ");
            $finish;
        end
        else begin
            $display("\033[0;32m PASS PATTERN NO.%4d \033[0m", patcount);
            @(negedge clk);
        end
    end
end endtask

task YOU_PASS_TASK; begin
    $display ("----------------------------------------------------------------------------------------------------------------------");
    $display ("                                                  Congratulations                                                                        ");
    $display ("                                           You have passed all patterns!                                                                 ");
    $display ("----------------------------------------------------------------------------------------------------------------------");
    repeat(2)@(negedge clk);
    $finish;
end endtask



endprogram

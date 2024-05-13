/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab09: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

/*
    Coverage Part
*/


class BEV;
    Bev_Type bev_type;
    Bev_Size bev_size;
endclass

BEV bev_info = new();
Error_Msg err_msg;
Action act;
ING ing;


always_ff @(posedge clk) begin
    if (inf.type_valid) begin
        bev_info.bev_type = inf.D.d_type[0];
    end
end

always_ff @(posedge clk) begin
    if (inf.size_valid) begin
        bev_info.bev_size = inf.D.d_size[0];
    end
end

always_ff @(posedge clk) begin
    if (inf.out_valid) begin
        err_msg = inf.err_msg;
    end
end

always_ff @(posedge clk) begin
    if (inf.sel_action_valid) begin
        act = inf.D.d_act[0];
    end
end

always_ff @(posedge clk) begin
    if (inf.box_sup_valid) begin
        ing = inf.D.d_ing[0];
    end
end

/*
1. Each case of Beverage_Type should be select at least 100 times.
*/


covergroup Spec1 @(posedge clk iff(inf.type_valid));
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint bev_info.bev_type{
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup


/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/
covergroup Spec2 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint bev_info.bev_size{
        bins b_bev_size [] = {[L:S]};
    }
endgroup
/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/
covergroup Spec3 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;
    option.at_least = 100;
    coverpoint bev_info.bev_type;
    coverpoint bev_info.bev_size;
    cross bev_info.bev_type, bev_info.bev_size;
endgroup
/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/
covergroup Spec4 @(posedge clk iff(inf.out_valid === 1));
    option.per_instance = 1;
    option.at_least = 20;
    berr:coverpoint err_msg{
        bins b_err_msg [] = {[No_Err:Ing_OF]};
    }
endgroup
/*
5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/
covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;
    option.at_least = 200;
    bact:coverpoint act{
        bins b_act [] = ([Make_drink:Check_Valid_Date] => [Make_drink:Check_Valid_Date]);
    }
endgroup
/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/
covergroup Spec6 @(posedge clk iff(inf.box_sup_valid));
    option.per_instance = 1;
    option.at_least = 1;
    bing: coverpoint ing {
        option.auto_bin_max = 32;
    }
endgroup
/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/
// Spec1_2_3 cov_inst_1_2_3 = new();
Spec1 conv_spec1 = new();
Spec2 conv_spec2 = new();
Spec3 conv_spec3 = new();
Spec4 conv_spec4 = new();
Spec5 conv_spec5 = new();
Spec6 conv_spec6 = new();
/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/


Action action_r;
logic [2:0] valid_signal_sum;
logic [2:0] counter_ing;
logic start_op;

always_ff @(posedge clk) begin
    if (inf.sel_action_valid)
        action_r <= inf.D.d_act[0];
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        counter_ing <= 0;
    end
    else if (inf.out_valid) begin
        counter_ing <= 0;
    end
    else if (inf.box_sup_valid) begin
        counter_ing <= counter_ing + 1;
    end
    else begin
        counter_ing <= counter_ing;
    end
end


always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) start_op <= 0 ;
	else begin 
		case (action_r)
			Make_drink : begin 
				if (inf.box_no_valid) start_op <= 1 ;
				else start_op <= 0 ;
			end
			Supply : begin 
				if (counter_ing == 4) start_op <= 1 ;
				else start_op <= 0 ;
			end
			Check_Valid_Date : begin 
				if (inf.box_no_valid) start_op <= 1 ;
				else start_op <= 0 ;
			end
		endcase
	end
end

/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/
always @(negedge inf.rst_n) begin
    #(0.5);
    assertion_01 : assert (
        (inf.out_valid === 'b0 && 
         inf.err_msg === 'b0 && 
         inf.complete === 'b0 &&
         inf.C_addr === 'b0 && 
         inf.C_data_w === 'b0 && 
         inf.C_in_valid === 'b0 && 
         inf.C_r_wb === 'b0 &&
         inf.C_out_valid === 'b0 && 
         inf.C_data_r === 'b0 &&
         inf.AR_VALID === 'b0 && 
         inf.AR_ADDR === 'b0 && 
         inf.R_READY === 'b0 &&
         inf.AW_VALID === 'b0 && 
         inf.AW_ADDR === 'b0 && 
         inf.W_VALID === 'b0 && 
         inf.W_DATA === 'b0 && 
         inf.B_READY === 'b0)
    )
    else begin
        $fatal(0, "Assertion 1 is violated");
    end
end

/*
    2.	Latency should be less than 1000 cycles for each operation.
*/
assertion_02 : assert property(@(posedge clk) (start_op === 1) |-> (##[1:1000] inf.out_valid))
else begin
    $fatal(0, "Assertion 2 is violated");
end
/*
    3. If out_valid does not pull up, complete should be 0.
*/
// assertion_03 : assert property(@(posedge inf.complete) (inf.err_msg == No_Err))
// else begin
//     $fatal(0, "Assertion 3 is violated");
// end
assertion_03 : assert property(@(negedge clk) (inf.out_valid === 'b1 && inf.complete === 'b1) |-> (inf.err_msg === No_Err))
else begin
    $fatal(0, "Assertion 3 is violated");
end
/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall.
*/



assertion_04_1_make_drink : assert property(@(posedge clk) (inf.sel_action_valid === 1 && inf.D.d_act[0] === Make_drink) |-> ##[1:4] inf.type_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end

assertion_04_2_make_drink : assert property(@(posedge clk) (inf.type_valid === 1 && action_r === Make_drink) |-> ##[1:4] inf.size_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end

assertion_04_3_make_drink : assert property(@(posedge clk) (inf.size_valid === 1 && action_r === Make_drink) |-> ##[1:4] inf.date_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end

assertion_04_4_make_drink : assert property(@(posedge clk) (inf.date_valid === 1 && action_r === Make_drink) |-> ##[1:4] inf.box_no_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end


assertion_04_1_supply : assert property(@(posedge clk) (inf.sel_action_valid === 1 && inf.D.d_act[0] === Supply) |-> ##[1:4] inf.date_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end

assertion_04_2_supply : assert property(@(posedge clk) (inf.date_valid === 1 && action_r === Supply) |-> ##[1:4] inf.box_no_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end

assertion_04_3_supply : assert property(@(posedge clk) (inf.box_no_valid === 1 && action_r === Supply) |-> ##[1:4] inf.box_sup_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end

assertion_04_4_supply : assert property(@(posedge clk) (inf.box_sup_valid === 1 && action_r === Supply && counter_ing == 1) |-> ##[1:4] inf.box_sup_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end

assertion_04_5_supply : assert property(@(posedge clk) (inf.box_sup_valid === 1 && action_r === Supply && counter_ing == 2) |-> ##[1:4] inf.box_sup_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end

// assertion_04_6_supply : assert property(@(posedge clk) (inf.box_sup_valid === 1 && action_r === Supply && counter_ing == 3) |-> ##[1:4] inf.box_sup_valid)
// else begin
//     $fatal(0, "Assertion 4 is violated");
// end

assertion_04_1_check_valid_date : assert property(@(posedge clk) (inf.sel_action_valid === 1 && inf.D.d_act[0] === Check_Valid_Date) |-> ##[1:4] inf.date_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end

assertion_04_2_check_valid_date : assert property(@(posedge clk) (inf.date_valid === 1 && action_r === Check_Valid_Date) |-> ##[1:4] inf.box_no_valid)
else begin
    $fatal(0, "Assertion 4 is violated");
end


/*
    5. All input valid signals won't overlap with each other. 
*/
always_comb begin
    valid_signal_sum = inf.sel_action_valid + inf.type_valid + inf.size_valid + inf.date_valid + inf.box_no_valid + inf.box_sup_valid;
end

assertion_05 : assert property(@(posedge clk) (valid_signal_sum <= 1))
else begin
    $fatal(0, "Assertion 5 is violated");
end

/*
    6. Out_valid can only be high for exactly one cycle.
*/
assertion_06 : assert property(@(negedge clk) (inf.out_valid === 1) |-> ##1 (inf.out_valid === 0))
else begin
    $fatal(0, "Assertion 6 is violated");
end
/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/
assertion_07 : assert property (@(negedge clk) (inf.out_valid === 1) |-> ##[2:5] (inf.sel_action_valid === 1))
else begin
    $fatal(0, "Assertion 7 is violated");
end
/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/

always @(posedge inf.date_valid) begin
    assertion_08_1: assert (inf.D.d_date[0][4:0] !== 5'd0) 
    else begin
        $fatal(0, "Assertion 8 is violated");
    end
end
always @(posedge inf.date_valid) begin
    assertion_08_2 : assert (
                            inf.D.d_date[0][8:5] === 4'd1  && inf.D.d_date[0][4:0] <= 5'd31 ||
                            inf.D.d_date[0][8:5] === 4'd2  && inf.D.d_date[0][4:0] <= 5'd28 ||
                            inf.D.d_date[0][8:5] === 4'd3  && inf.D.d_date[0][4:0] <= 5'd31 ||
                            inf.D.d_date[0][8:5] === 4'd4  && inf.D.d_date[0][4:0] <= 5'd30 ||
                            inf.D.d_date[0][8:5] === 4'd5  && inf.D.d_date[0][4:0] <= 5'd31 ||
                            inf.D.d_date[0][8:5] === 4'd6  && inf.D.d_date[0][4:0] <= 5'd30 ||
                            inf.D.d_date[0][8:5] === 4'd7  && inf.D.d_date[0][4:0] <= 5'd31 ||
                            inf.D.d_date[0][8:5] === 4'd8  && inf.D.d_date[0][4:0] <= 5'd31 ||
                            inf.D.d_date[0][8:5] === 4'd9  && inf.D.d_date[0][4:0] <= 5'd30 ||
                            inf.D.d_date[0][8:5] === 4'd10 && inf.D.d_date[0][4:0] <= 5'd31 ||
                            inf.D.d_date[0][8:5] === 4'd11 && inf.D.d_date[0][4:0] <= 5'd30 ||
                            inf.D.d_date[0][8:5] === 4'd12 && inf.D.d_date[0][4:0] <= 5'd31)
    else begin
        $fatal(0, "Assertion 8 is violated");
    end
end
/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/

assertion_09_1 : assert property (@(negedge clk) (inf.C_in_valid === 1) |-> ##1 (inf.C_in_valid === 0))
else begin
    $fatal(0, "Assertion 9 is violated");
end


assertion_09_2 : assert property (@(negedge inf.C_out_valid) (inf.C_in_valid === 1) |-> (inf.C_in_valid === 1))
else begin
    $fatal(0, "Assertion 9 is violated");
end

endmodule

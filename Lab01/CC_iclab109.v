//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab01 Exercise		: Code Calculator
//   Author     		  : Jhan-Yi LIAO
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CC.v
//   Module Name : CC
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module CC(
  // Input signals
    opt,
    in_n0, in_n1, in_n2, in_n3, in_n4,  
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [3:0] in_n0, in_n1, in_n2, in_n3, in_n4;
input [2:0] opt;
wire [3:0] sorted_n0, sorted_n1, sorted_n2, sorted_n3, sorted_n4;
wire [3:0] a0, a1, a2, a3, a4, normalize_num;
wire [4:0] normalize_sum;
wire signed [4:0] avg;
wire signed [10:0] b0, b1, b2, b3, b4;
wire [9:0] eq0;
wire signed[9:0] eq1;
wire [9:0]_eq1;
output  [9:0] out_n;         					

//Sort U0(in_n0, in_n1, in_n2, in_n3, in_n4, sorted_n0, sorted_n1, sorted_n2, sorted_n3, sorted_n4);


wire [3:0] a[3:0], b[3:0], c[3:0], d[3:0], e[1:0];

assign a[0] = (in_n0 > in_n3)?in_n3 : in_n0; //0
assign a[1] = (in_n0 > in_n3)?in_n0 : in_n3; //3
assign a[2] = (in_n1 > in_n4)?in_n4 : in_n1; //1
assign a[3] = (in_n1 > in_n4)?in_n1 : in_n4; //4

assign b[0] = (a[0] > in_n2)?in_n2 : a[0]; //0
assign b[1] = (a[0] > in_n2)?a[0] : in_n2; //2
assign b[2] = (a[2] > a[1])?a[1] : a[2]; //1
assign b[3] = (a[2] > a[1])?a[2] : a[1]; //3

assign c[0] = (b[0] > b[2])?b[2] : b[0]; //0
assign c[1] = (b[0] > b[2])?b[0] : b[2]; //1
assign c[2] = (b[1] > a[3])?a[3] : b[1]; //2
assign c[3] = (b[1] > a[3])?b[1] : a[3]; //4

assign d[0] = (c[1] > c[2])?c[2] : c[1]; //1
assign d[1] = (c[1] > c[2])?c[1] : c[2]; //2
assign d[2] = (b[3] > c[3])?c[3] : b[3]; //3
assign d[3] = (b[3] > c[3])?b[3] : c[3]; //4

assign e[0] = (d[1] > d[2])?d[2] : d[1]; //2
assign e[1] = (d[1] > d[2])?d[1] : d[2]; //3

assign sorted_n0 = c[0];
assign sorted_n1 = d[0];
assign sorted_n2 = e[0];
assign sorted_n3 = e[1];
assign sorted_n4 = d[3];



assign a0 = (opt[1])?sorted_n4 : sorted_n0;
assign a1 = (opt[1])?sorted_n3 : sorted_n1;
assign a2 = sorted_n2;
assign a3 = (opt[1])?sorted_n1 : sorted_n3;
assign a4 = (opt[1])?sorted_n0 : sorted_n4;

assign normalize_sum = a0+a4;
assign normalize_num = normalize_sum[4:1];

assign b0 = (opt[0])?a0-normalize_num : a0;
assign b1 = (opt[0])?a1-normalize_num : a1;
assign b2 = (opt[0])?a2-normalize_num : a2;
assign b3 = (opt[0])?a3-normalize_num : a3;
assign b4 = (opt[0])?a4-normalize_num : a4;

assign avg = ((b0 + b1 + b2) + (b3 + b4))/5; 
assign eq1 = b3 * 3 - b0 * b4;
assign eq0 = (b0 + (b1 * b2 + avg * b3))/3;
//assign _eq1 = (eq1[9])?((~eq1)+10'b1) : eq1;
assign _eq1 = (eq1<0)?(-eq1) : eq1;
assign out_n = (opt[2])?_eq1 : eq0;
//assign out_n = (opt[2])?(eq1[9])?((~eq1)+10'b1) : eq1 : eq0;

endmodule


/* module Sort(
    in_n0, in_n1, in_n2, in_n3, in_n4,
	sorted_n0, sorted_n1, sorted_n2, sorted_n3, sorted_n4
);

input [3:0]in_n0, in_n1, in_n2, in_n3, in_n4;
output [3:0]sorted_n0, sorted_n1, sorted_n2, sorted_n3, sorted_n4;

wire [3:0] a[3:0], b[3:0], c[3:0], d[3:0], e[1:0];

assign a[0] = (in_n0 > in_n3)?in_n3 : in_n0; //0
assign a[1] = (in_n0 > in_n3)?in_n0 : in_n3; //3
assign a[2] = (in_n1 > in_n4)?in_n4 : in_n1; //1
assign a[3] = (in_n1 > in_n4)?in_n1 : in_n4; //4

assign b[0] = (a[0] > in_n2)?in_n2 : a[0]; //0
assign b[1] = (a[0] > in_n2)?a[0] : in_n2; //2
assign b[2] = (a[2] > a[1])?a[1] : a[2]; //1
assign b[3] = (a[2] > a[1])?a[2] : a[1]; //3

assign c[0] = (b[0] > b[2])?b[2] : b[0]; //0
assign c[1] = (b[0] > b[2])?b[0] : b[2]; //1
assign c[2] = (b[1] > a[3])?a[3] : b[1]; //2
assign c[3] = (b[1] > a[3])?b[1] : a[3]; //4

assign d[0] = (c[1] > c[2])?c[2] : c[1]; //1
assign d[1] = (c[1] > c[2])?c[1] : c[2]; //2
assign d[2] = (b[3] > c[3])?c[3] : b[3]; //3
assign d[3] = (b[3] > c[3])?b[3] : c[3]; //4

assign e[0] = (d[1] > d[2])?d[2] : d[1]; //2
assign e[1] = (d[1] > d[2])?d[1] : d[2]; //3

assign sorted_n0 = c[0];
assign sorted_n1 = d[0];
assign sorted_n2 = e[0];
assign sorted_n3 = e[1];
assign sorted_n4 = d[3];

endmodule */


 /* module BubbleSort(
    in_n0, in_n1, in_n2, in_n3, in_n4,
	sorted_n0, sorted_n1, sorted_n2, sorted_n3, sorted_n4
);

input [3:0]in_n0, in_n1, in_n2, in_n3, in_n4;
output [3:0]sorted_n0, sorted_n1, sorted_n2, sorted_n3, sorted_n4;

wire [3:0]a[7:0], b[5:0], c[3:0], d[1:0];

assign a[0] = (in_n0 > in_n1)?in_n1 : in_n0; //0
assign a[1] = (in_n0 > in_n1)?in_n0 : in_n1; //1
assign a[2] = (a[0] > in_n2)?in_n2 : a[0]; //0
assign a[3] = (a[0] > in_n2)?a[0] : in_n2; //2
assign a[4] = (a[2] > in_n3)?in_n3 : a[2]; //0
assign a[5] = (a[2] > in_n3)?a[2] : in_n3; //3
assign a[6] = (a[4] > in_n4)?in_n4 : a[4]; //0
assign a[7] = (a[4] > in_n4)?a[4] : in_n4; //4
assign sorted_n0 = a[6];

assign b[0] = (a[1] > a[3])?a[3] : a[1]; //1
assign b[1] = (a[1] > a[3])?a[1] : a[3]; //2
assign b[2] = (b[0] > a[5])?a[5] : b[0]; //1
assign b[3] = (b[0] > a[5])?b[0] : a[5]; //3
assign b[4] = (b[2] > a[7])?a[7] : b[2]; //1
assign b[5] = (b[2] > a[7])?b[2] : a[7]; //4
assign sorted_n1 = b[4];

assign c[0] = (b[1] > b[3])?b[3] : b[1]; //2
assign c[1] = (b[1] > b[3])?b[1] : b[3]; //3
assign c[2] = (c[0] > b[5])?b[5] : c[0]; //2
assign c[3] = (c[0] > b[5])?c[0] : b[5]; //4
assign sorted_n2 = c[2];

assign d[0] = (c[1] > c[3])?c[3] : c[1]; //3
assign d[1] = (c[1] > c[3])?c[1] : c[3]; //4
assign sorted_n3 = d[0];
assign sorted_n4 = d[1];

endmodule  */

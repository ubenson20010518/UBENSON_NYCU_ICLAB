//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output [IP_WIDTH*4-1:0] OUT_character;

// ===============================================================
// Design
// ===============================================================


reg [3:0] character [0:7];
reg [4:0] weight [0:7];
reg [8:0] wei_char [0:7];
reg [8:0] cmp [0:5][0:7];


integer i;

always @(*) begin
    for (i = 0; i < 8; i = i + 1) begin
        character[i] = 0;
        weight[i] = 0;
    end
    for (i = 0; i < IP_WIDTH; i = i + 1) begin
        character[i] = IN_character[i*4 + 3 -: 4];
        weight[i] = IN_weight[i*5 + 4 -: 5];
    end
end


always @(*) begin
    for (i = 0; i < 8; i = i + 1) begin
        wei_char[i] = {weight[i], character[i]};
    end
end

always @(*) begin
    {cmp[0][0], cmp[0][2]} = (wei_char[0][8:4] > wei_char[2][8:4] || (wei_char[0][8:4] == wei_char[2][8:4] && wei_char[0][3:0] > wei_char[2][3:0])) ? {wei_char[0], wei_char[2]} : {wei_char[2], wei_char[0]};
    {cmp[0][1], cmp[0][3]} = (wei_char[1][8:4] > wei_char[3][8:4] || (wei_char[1][8:4] == wei_char[3][8:4] && wei_char[1][3:0] > wei_char[3][3:0])) ? {wei_char[1], wei_char[3]} : {wei_char[3], wei_char[1]};
    {cmp[0][4], cmp[0][6]} = (wei_char[4][8:4] > wei_char[6][8:4] || (wei_char[4][8:4] == wei_char[6][8:4] && wei_char[4][3:0] > wei_char[6][3:0])) ? {wei_char[4], wei_char[6]} : {wei_char[6], wei_char[4]};
    {cmp[0][5], cmp[0][7]} = (wei_char[5][8:4] > wei_char[7][8:4] || (wei_char[5][8:4] == wei_char[7][8:4] && wei_char[5][3:0] > wei_char[7][3:0])) ? {wei_char[5], wei_char[7]} : {wei_char[7], wei_char[5]};

    {cmp[1][0], cmp[1][4]} = (cmp[0][0][8:4] > cmp[0][4][8:4] || (cmp[0][0][8:4] == cmp[0][4][8:4] && cmp[0][0][3:0] > cmp[0][4][3:0])) ? {cmp[0][0], cmp[0][4]} : {cmp[0][4], cmp[0][0]};
    {cmp[1][1], cmp[1][5]} = (cmp[0][1][8:4] > cmp[0][5][8:4] || (cmp[0][1][8:4] == cmp[0][5][8:4] && cmp[0][1][3:0] > cmp[0][5][3:0])) ? {cmp[0][1], cmp[0][5]} : {cmp[0][5], cmp[0][1]};
    {cmp[1][2], cmp[1][6]} = (cmp[0][2][8:4] > cmp[0][6][8:4] || (cmp[0][2][8:4] == cmp[0][6][8:4] && cmp[0][2][3:0] > cmp[0][6][3:0])) ? {cmp[0][2], cmp[0][6]} : {cmp[0][6], cmp[0][2]};
    {cmp[1][3], cmp[1][7]} = (cmp[0][3][8:4] > cmp[0][7][8:4] || (cmp[0][3][8:4] == cmp[0][7][8:4] && cmp[0][3][3:0] > cmp[0][7][3:0])) ? {cmp[0][3], cmp[0][7]} : {cmp[0][7], cmp[0][3]};

    {cmp[2][0], cmp[2][1]} = (cmp[1][0][8:4] > cmp[1][1][8:4] || (cmp[1][0][8:4] == cmp[1][1][8:4] && cmp[1][0][3:0] > cmp[1][1][3:0])) ? {cmp[1][0], cmp[1][1]} : {cmp[1][1], cmp[1][0]};
    {cmp[2][2], cmp[2][3]} = (cmp[1][2][8:4] > cmp[1][3][8:4] || (cmp[1][2][8:4] == cmp[1][3][8:4] && cmp[1][2][3:0] > cmp[1][3][3:0])) ? {cmp[1][2], cmp[1][3]} : {cmp[1][3], cmp[1][2]};
    {cmp[2][4], cmp[2][5]} = (cmp[1][4][8:4] > cmp[1][5][8:4] || (cmp[1][4][8:4] == cmp[1][5][8:4] && cmp[1][4][3:0] > cmp[1][5][3:0])) ? {cmp[1][4], cmp[1][5]} : {cmp[1][5], cmp[1][4]};
    {cmp[2][6], cmp[2][7]} = (cmp[1][6][8:4] > cmp[1][7][8:4] || (cmp[1][6][8:4] == cmp[1][7][8:4] && cmp[1][6][3:0] > cmp[1][7][3:0])) ? {cmp[1][6], cmp[1][7]} : {cmp[1][7], cmp[1][6]};

    {cmp[3][2], cmp[3][4]} = (cmp[2][2][8:4] > cmp[2][4][8:4] || (cmp[2][2][8:4] == cmp[2][4][8:4] && cmp[2][2][3:0] > cmp[2][4][3:0])) ? {cmp[2][2], cmp[2][4]} : {cmp[2][4], cmp[2][2]};
    {cmp[3][3], cmp[3][5]} = (cmp[2][3][8:4] > cmp[2][5][8:4] || (cmp[2][3][8:4] == cmp[2][5][8:4] && cmp[2][3][3:0] > cmp[2][5][3:0])) ? {cmp[2][3], cmp[2][5]} : {cmp[2][5], cmp[2][3]};
    {cmp[3][0], cmp[3][1]} = {cmp[2][0], cmp[2][1]};
    {cmp[3][6], cmp[3][7]} = {cmp[2][6], cmp[2][7]};

    {cmp[4][1], cmp[4][4]} = (cmp[3][1][8:4] > cmp[3][4][8:4] || (cmp[3][1][8:4] == cmp[3][4][8:4] && cmp[3][1][3:0] > cmp[3][4][3:0])) ? {cmp[3][1], cmp[3][4]} : {cmp[3][4], cmp[3][1]};
    {cmp[4][3], cmp[4][6]} = (cmp[3][3][8:4] > cmp[3][6][8:4] || (cmp[3][3][8:4] == cmp[3][6][8:4] && cmp[3][3][3:0] > cmp[3][6][3:0])) ? {cmp[3][3], cmp[3][6]} : {cmp[3][6], cmp[3][3]};
    {cmp[4][0], cmp[4][2]} = {cmp[3][0], cmp[3][2]};
    {cmp[4][5], cmp[4][7]} = {cmp[3][5], cmp[3][7]};

    {cmp[5][1], cmp[5][2]} = (cmp[4][1][8:4] > cmp[4][2][8:4] || (cmp[4][1][8:4] == cmp[4][2][8:4] && cmp[4][1][3:0] > cmp[4][2][3:0])) ? {cmp[4][1], cmp[4][2]} : {cmp[4][2], cmp[4][1]};
    {cmp[5][3], cmp[5][4]} = (cmp[4][3][8:4] > cmp[4][4][8:4] || (cmp[4][3][8:4] == cmp[4][4][8:4] && cmp[4][3][3:0] > cmp[4][4][3:0])) ? {cmp[4][3], cmp[4][4]} : {cmp[4][4], cmp[4][3]};
    {cmp[5][5], cmp[5][6]} = (cmp[4][5][8:4] > cmp[4][6][8:4] || (cmp[4][5][8:4] == cmp[4][6][8:4] && cmp[4][5][3:0] > cmp[4][6][3:0])) ? {cmp[4][5], cmp[4][6]} : {cmp[4][6], cmp[4][5]};
    {cmp[5][0], cmp[5][7]} = {cmp[4][0], cmp[4][7]};
end



genvar idx;
generate
    for (idx = 0; idx < IP_WIDTH; idx = idx + 1) begin: loop
        assign OUT_character[(4*idx)+3 -: 4] = cmp[5][IP_WIDTH - idx - 1][3:0];
    end
endgenerate

endmodule
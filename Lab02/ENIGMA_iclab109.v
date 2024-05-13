//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab02 Exercise		: Enigma
//   Author     		: Yi-Xuan, Ran
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ENIGMA.v
//   Module Name : ENIGMA
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
 
module ENIGMA(
	// Input Ports
	clk, 
	rst_n, 
	in_valid, 
	in_valid_2, 
	crypt_mode, 
	code_in, 

	// Output Ports
	out_code, 
	out_valid
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk;              // clock input
input rst_n;            // asynchronous reset (active low)
input in_valid;         // code_in valid signal for rotor (level sensitive). 0/1: inactive/active
input in_valid_2;       // code_in valid signal for code  (level sensitive). 0/1: inactive/active
input crypt_mode;       // 0: encrypt; 1:decrypt; only valid for 1 cycle when in_valid is active

input [6-1:0] code_in;	// When in_valid   is active, then code_in is input of rotors. 
						// When in_valid_2 is active, then code_in is input of code words.
							
output reg out_valid;       	// 0: out_code is not valid; 1: out_code is valid
output reg [6-1:0] out_code;	// encrypted/decrypted code word


parameter Idle		=2'b00;	//0
parameter Encryption=2'b10;	//2
parameter Decryption=2'b11;	//3

reg [5:0] rotor_A[63:0],rotor_B[63:0];
reg [5:0] next_rotor_A[63:0],next_rotor_B[63:0];
//reg [5:0] rotor_AB[127:0];
//reg [5:0] next_rotor_AB[127:0];
reg [5:0] rotor_A_out, rotor_B_out, inv_rotor_A_out, inv_rotor_B_out, reflector_out;
reg [1:0] next_state, current_state;
//reg [7:0] count_in, count_out;
reg _crypt_mode, store_in_valid_2, pre_in_valid;
reg [7:0] counter;
//reg [5:0] _rotor_A_out, _rotor_B_out, _reflector_out, _inv_rotor_B_out;
reg [5:0] _code_in;
wire [1:0] rotor_A_change;
wire [2:0] rotor_B_change;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		current_state <= Idle;
	else
		current_state <= next_state;
end

//store crypt_mode
// always @(posedge clk or negedge rst_n) begin
	// if(!rst_n)
		// _crypt_mode <= 1'b0;
	// else if (crypt_mode == 1'b1)
		// _crypt_mode <= 1'b1;
	// else if (crypt_mode == 1'b0)
		// _crypt_mode <= 1'b0;
	// else
		// _crypt_mode <= _crypt_mode;
// end

always @(posedge clk) begin
	pre_in_valid <= in_valid;
end

always @(posedge clk)begin
	_crypt_mode <= (!pre_in_valid & in_valid)? crypt_mode : _crypt_mode;
end

//state
always @(*) begin
	if(!rst_n)
		next_state <= Idle;
	else begin
		case(current_state)
			Idle: begin
				next_state <= (in_valid)? Idle : (in_valid_2)? (_crypt_mode)? Decryption : Encryption : Idle;
			end
			Encryption: begin
				next_state <= (in_valid_2)? Encryption : (out_valid)? Encryption : Idle;
			end
			Decryption: begin
				next_state <= (in_valid_2)? Decryption : (out_valid)? Decryption : Idle;
			end

			default: begin
				next_state <= current_state;
			end
		endcase
	end
end

//store rotor value
integer i;


always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		counter <= 8'b0;
	end else if (in_valid) begin
		counter <= (counter == 8'd127)? 8'b0 : counter + 8'b1;
	end else begin
		counter <= 8'b0;
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for(i = 0; i < 64; i = i + 1)begin:loop1
			rotor_A[i] <= 6'b0;
		end
	end else if(counter < 64 && in_valid == 1'b1)begin
			rotor_A[counter] <= code_in;
	end else begin
		for(i = 0; i < 64; i = i + 1)begin:loop10
			rotor_A[i] <= next_rotor_A[i];
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for(i = 0; i < 64; i = i + 1)begin:loop20
			rotor_B[i] <= 6'b0;
		end
	end else if(counter > 63 && in_valid == 1'b1)begin
			rotor_B[counter-64] <= code_in;
	end else begin
		for(i = 0; i < 64; i = i + 1)begin:loop21
			rotor_B[i] <= next_rotor_B[i];
		end
	end
end



//counter
// always @(posedge clk or negedge rst_n) begin
	// if(!rst_n)begin
		// count_in <= 0;
		// count_out <= 0;
	// end 
	// else if (current_state == Encryption || current_state == Decryption || in_valid_2 == 1'b1) begin
		// count_in <= (in_valid_2)? count_in + 1 : 0;
		// count_out <= (count_out > count_in)? 0 : count_out + 1;
	// end
	// else begin
		// count_in <= 0;
		// count_out <= 0;
	// end 
// end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		store_in_valid_2 <= 1'b0;
	end
	else begin
		store_in_valid_2 <= (in_valid_2)? 1'b1 : 1'b0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out_valid <= 1'b0;
	end
	else begin
		out_valid <= (store_in_valid_2)? 1'b1 : 1'b0;
	end
end



//assign out_valid = (count_out > 1)? 1'b1 : 1'b0;

assign rotor_A_change = (current_state == Encryption)? rotor_A_out[1:0] : (current_state == Decryption)? inv_rotor_B_out[1:0] : 2'b0;
assign rotor_B_change = (current_state == Encryption)? rotor_B_out[2:0] : (current_state == Decryption)? reflector_out[2:0] : 3'b0;

always @(*) begin
	if(!rst_n)begin
		for(i = 0; i < 64; i = i + 1) begin:loop17
				next_rotor_A[i] <= 6'b0;
			end
	end
	else if(rotor_A_change==2'b01) begin
		for(i = 0; i < 63; i = i + 1) begin:loop4
					next_rotor_A[i+1] <= rotor_A[i];
				end
				next_rotor_A[0] <= rotor_A[63];
		end
	else if(rotor_A_change==2'b10) begin
		for(i = 0; i < 62; i = i + 1) begin:loop5
					next_rotor_A[i+2] <= rotor_A[i];
				end
				next_rotor_A[1] <= rotor_A[63];
				next_rotor_A[0] <= rotor_A[62];
		end
	else if(rotor_A_change==2'b11) begin
		for(i = 0; i < 61; i = i + 1) begin:loop6
					next_rotor_A[i+3] <= rotor_A[i];
				end
				next_rotor_A[2] <= rotor_A[63];
				next_rotor_A[1] <= rotor_A[62];
				next_rotor_A[0] <= rotor_A[61];
		end
	else begin
		for(i = 0; i < 64; i = i + 1) begin:loop16
					next_rotor_A[i] <= rotor_A[i];
				end
	end
end




//rotor_B change
genvar geni;
generate
for(geni = 0; geni < 8; geni = geni + 1) begin:loop8
	always @(*) begin
		if (!rst_n) begin
			next_rotor_B[8*geni] <= 6'b0;
			next_rotor_B[1+8*geni] <= 6'b0;
			next_rotor_B[2+8*geni] <= 6'b0;
			next_rotor_B[3+8*geni] <= 6'b0;
			next_rotor_B[4+8*geni] <= 6'b0;
			next_rotor_B[5+8*geni] <= 6'b0;
			next_rotor_B[6+8*geni] <= 6'b0;
			next_rotor_B[7+8*geni] <= 6'b0;
		end
		else begin
			case(rotor_B_change)
				3'b001: begin
					next_rotor_B[1+8*geni] <= rotor_B[8*geni];
					next_rotor_B[8*geni] <= rotor_B[1+8*geni];
					next_rotor_B[3+8*geni] <= rotor_B[2+8*geni];
					next_rotor_B[2+8*geni] <= rotor_B[3+8*geni];
					next_rotor_B[5+8*geni] <= rotor_B[4+8*geni];
					next_rotor_B[4+8*geni] <= rotor_B[5+8*geni];
					next_rotor_B[7+8*geni] <= rotor_B[6+8*geni];
					next_rotor_B[6+8*geni] <= rotor_B[7+8*geni];
				end 
				3'b010: begin
					next_rotor_B[2+8*geni] <= rotor_B[8*geni];
					next_rotor_B[3+8*geni] <= rotor_B[1+8*geni];
					next_rotor_B[8*geni] <= rotor_B[2+8*geni];
					next_rotor_B[1+8*geni] <= rotor_B[3+8*geni];
					next_rotor_B[6+8*geni] <= rotor_B[4+8*geni];
					next_rotor_B[7+8*geni] <= rotor_B[5+8*geni];
					next_rotor_B[4+8*geni] <= rotor_B[6+8*geni];
					next_rotor_B[5+8*geni] <= rotor_B[7+8*geni];
				end 
				3'b011: begin
					next_rotor_B[8*geni] <= rotor_B[8*geni];
					next_rotor_B[4+8*geni] <= rotor_B[1+8*geni];
					next_rotor_B[5+8*geni] <= rotor_B[2+8*geni];
					next_rotor_B[6+8*geni] <= rotor_B[3+8*geni];
					next_rotor_B[1+8*geni] <= rotor_B[4+8*geni];
					next_rotor_B[2+8*geni] <= rotor_B[5+8*geni];
					next_rotor_B[3+8*geni] <= rotor_B[6+8*geni];
					next_rotor_B[7+8*geni] <= rotor_B[7+8*geni];
				end 
				3'b100: begin
					next_rotor_B[4+8*geni] <= rotor_B[8*geni];
					next_rotor_B[5+8*geni] <= rotor_B[1+8*geni];
					next_rotor_B[6+8*geni] <= rotor_B[2+8*geni];
					next_rotor_B[7+8*geni] <= rotor_B[3+8*geni];
					next_rotor_B[8*geni] <= rotor_B[4+8*geni];
					next_rotor_B[1+8*geni] <= rotor_B[5+8*geni];
					next_rotor_B[2+8*geni] <= rotor_B[6+8*geni];
					next_rotor_B[3+8*geni] <= rotor_B[7+8*geni];
				end 
				3'b101: begin
					next_rotor_B[5+8*geni] <= rotor_B[8*geni];
					next_rotor_B[6+8*geni] <= rotor_B[1+8*geni];
					next_rotor_B[7+8*geni] <= rotor_B[2+8*geni];
					next_rotor_B[3+8*geni] <= rotor_B[3+8*geni];
					next_rotor_B[4+8*geni] <= rotor_B[4+8*geni];
					next_rotor_B[8*geni] <= rotor_B[5+8*geni];
					next_rotor_B[1+8*geni] <= rotor_B[6+8*geni];
					next_rotor_B[2+8*geni] <= rotor_B[7+8*geni];
				end 
				3'b110: begin
					next_rotor_B[6+8*geni] <= rotor_B[8*geni];
					next_rotor_B[7+8*geni] <= rotor_B[1+8*geni];
					next_rotor_B[3+8*geni] <= rotor_B[2+8*geni];
					next_rotor_B[2+8*geni] <= rotor_B[3+8*geni];
					next_rotor_B[5+8*geni] <= rotor_B[4+8*geni];
					next_rotor_B[4+8*geni] <= rotor_B[5+8*geni];
					next_rotor_B[8*geni] <= rotor_B[6+8*geni];
					next_rotor_B[1+8*geni] <= rotor_B[7+8*geni];
				end 
				3'b111: begin
					next_rotor_B[7+8*geni] <= rotor_B[8*geni];
					next_rotor_B[6+8*geni] <= rotor_B[1+8*geni];
					next_rotor_B[5+8*geni] <= rotor_B[2+8*geni];
					next_rotor_B[4+8*geni] <= rotor_B[3+8*geni];
					next_rotor_B[3+8*geni] <= rotor_B[4+8*geni];
					next_rotor_B[2+8*geni] <= rotor_B[5+8*geni];
					next_rotor_B[1+8*geni] <= rotor_B[6+8*geni];
					next_rotor_B[8*geni] <= rotor_B[7+8*geni];
				end 
				default: begin
					next_rotor_B[8*geni] <= rotor_B[8*geni];
					next_rotor_B[1+8*geni] <= rotor_B[1+8*geni];
					next_rotor_B[2+8*geni] <= rotor_B[2+8*geni];
					next_rotor_B[3+8*geni] <= rotor_B[3+8*geni];
					next_rotor_B[4+8*geni] <= rotor_B[4+8*geni];
					next_rotor_B[5+8*geni] <= rotor_B[5+8*geni];
					next_rotor_B[6+8*geni] <= rotor_B[6+8*geni];
					next_rotor_B[7+8*geni] <= rotor_B[7+8*geni];
				end
			endcase
		end
	end
end
endgenerate


//store code_in
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		_code_in <= 6'b0;
	end 
	else if (in_valid_2)begin
		_code_in <= code_in;
	end
	else begin
		_code_in <= 6'b0;
	end
end

//rotor_A_out
always @(*) begin
	if(!rst_n)begin
		rotor_A_out <= 6'b0;
	end
	else begin
		case(_code_in)
			6'h00 : rotor_A_out <= rotor_A[0];
			6'h01 : rotor_A_out <= rotor_A[1];
			6'h02 : rotor_A_out <= rotor_A[2];
			6'h03 : rotor_A_out <= rotor_A[3];
			6'h04 : rotor_A_out <= rotor_A[4];
			6'h05 : rotor_A_out <= rotor_A[5];
			6'h06 : rotor_A_out <= rotor_A[6];
			6'h07 : rotor_A_out <= rotor_A[7];
			6'h08 : rotor_A_out <= rotor_A[8];
			6'h09 : rotor_A_out <= rotor_A[9];
			6'h0A : rotor_A_out <= rotor_A[10];
			6'h0B : rotor_A_out <= rotor_A[11];
			6'h0C : rotor_A_out <= rotor_A[12];
			6'h0D : rotor_A_out <= rotor_A[13];
			6'h0E : rotor_A_out <= rotor_A[14];
			6'h0F : rotor_A_out <= rotor_A[15];
			6'h10 : rotor_A_out <= rotor_A[16];
			6'h11 : rotor_A_out <= rotor_A[17];
			6'h12 : rotor_A_out <= rotor_A[18];
			6'h13 : rotor_A_out <= rotor_A[19];
			6'h14 : rotor_A_out <= rotor_A[20];
			6'h15 : rotor_A_out <= rotor_A[21];
			6'h16 : rotor_A_out <= rotor_A[22];
			6'h17 : rotor_A_out <= rotor_A[23];
			6'h18 : rotor_A_out <= rotor_A[24];
			6'h19 : rotor_A_out <= rotor_A[25];
			6'h1A : rotor_A_out <= rotor_A[26];
			6'h1B : rotor_A_out <= rotor_A[27];
			6'h1C : rotor_A_out <= rotor_A[28];
			6'h1D : rotor_A_out <= rotor_A[29];
			6'h1E : rotor_A_out <= rotor_A[30];
			6'h1F : rotor_A_out <= rotor_A[31];
			6'h20 : rotor_A_out <= rotor_A[32];
			6'h21 : rotor_A_out <= rotor_A[33];
			6'h22 : rotor_A_out <= rotor_A[34];
			6'h23 : rotor_A_out <= rotor_A[35];
			6'h24 : rotor_A_out <= rotor_A[36];
			6'h25 : rotor_A_out <= rotor_A[37];
			6'h26 : rotor_A_out <= rotor_A[38];
			6'h27 : rotor_A_out <= rotor_A[39];
			6'h28 : rotor_A_out <= rotor_A[40];
			6'h29 : rotor_A_out <= rotor_A[41];
			6'h2A : rotor_A_out <= rotor_A[42];
			6'h2B : rotor_A_out <= rotor_A[43];
			6'h2C : rotor_A_out <= rotor_A[44];
			6'h2D : rotor_A_out <= rotor_A[45];
			6'h2E : rotor_A_out <= rotor_A[46];
			6'h2F : rotor_A_out <= rotor_A[47];
			6'h30 : rotor_A_out <= rotor_A[48];
			6'h31 : rotor_A_out <= rotor_A[49];
			6'h32 : rotor_A_out <= rotor_A[50];
			6'h33 : rotor_A_out <= rotor_A[51];
			6'h34 : rotor_A_out <= rotor_A[52];
			6'h35 : rotor_A_out <= rotor_A[53];
			6'h36 : rotor_A_out <= rotor_A[54];
			6'h37 : rotor_A_out <= rotor_A[55];
			6'h38 : rotor_A_out <= rotor_A[56];
			6'h39 : rotor_A_out <= rotor_A[57];
			6'h3A : rotor_A_out <= rotor_A[58];
			6'h3B : rotor_A_out <= rotor_A[59];
			6'h3C : rotor_A_out <= rotor_A[60];
			6'h3D : rotor_A_out <= rotor_A[61];
			6'h3E : rotor_A_out <= rotor_A[62];
			6'h3F : rotor_A_out <= rotor_A[63];
			default : rotor_A_out <= 6'b0;
			endcase
	end
end


//rotor_B_out
always @(*) begin
	if(!rst_n)begin
		rotor_B_out <= 6'b0;
	end
	else begin
		case(rotor_A_out)
			6'h00 : rotor_B_out <= rotor_B[0];
			6'h01 : rotor_B_out <= rotor_B[1];
			6'h02 : rotor_B_out <= rotor_B[2];
			6'h03 : rotor_B_out <= rotor_B[3];
			6'h04 : rotor_B_out <= rotor_B[4];
			6'h05 : rotor_B_out <= rotor_B[5];
			6'h06 : rotor_B_out <= rotor_B[6];
			6'h07 : rotor_B_out <= rotor_B[7];
			6'h08 : rotor_B_out <= rotor_B[8];
			6'h09 : rotor_B_out <= rotor_B[9];
			6'h0A : rotor_B_out <= rotor_B[10];
			6'h0B : rotor_B_out <= rotor_B[11];
			6'h0C : rotor_B_out <= rotor_B[12];
			6'h0D : rotor_B_out <= rotor_B[13];
			6'h0E : rotor_B_out <= rotor_B[14];
			6'h0F : rotor_B_out <= rotor_B[15];
			6'h10 : rotor_B_out <= rotor_B[16];
			6'h11 : rotor_B_out <= rotor_B[17];
			6'h12 : rotor_B_out <= rotor_B[18];
			6'h13 : rotor_B_out <= rotor_B[19];
			6'h14 : rotor_B_out <= rotor_B[20];
			6'h15 : rotor_B_out <= rotor_B[21];
			6'h16 : rotor_B_out <= rotor_B[22];
			6'h17 : rotor_B_out <= rotor_B[23];
			6'h18 : rotor_B_out <= rotor_B[24];
			6'h19 : rotor_B_out <= rotor_B[25];
			6'h1A : rotor_B_out <= rotor_B[26];
			6'h1B : rotor_B_out <= rotor_B[27];
			6'h1C : rotor_B_out <= rotor_B[28];
			6'h1D : rotor_B_out <= rotor_B[29];
			6'h1E : rotor_B_out <= rotor_B[30];
			6'h1F : rotor_B_out <= rotor_B[31];
			6'h20 : rotor_B_out <= rotor_B[32];
			6'h21 : rotor_B_out <= rotor_B[33];
			6'h22 : rotor_B_out <= rotor_B[34];
			6'h23 : rotor_B_out <= rotor_B[35];
			6'h24 : rotor_B_out <= rotor_B[36];
			6'h25 : rotor_B_out <= rotor_B[37];
			6'h26 : rotor_B_out <= rotor_B[38];
			6'h27 : rotor_B_out <= rotor_B[39];
			6'h28 : rotor_B_out <= rotor_B[40];
			6'h29 : rotor_B_out <= rotor_B[41];
			6'h2A : rotor_B_out <= rotor_B[42];
			6'h2B : rotor_B_out <= rotor_B[43];
			6'h2C : rotor_B_out <= rotor_B[44];
			6'h2D : rotor_B_out <= rotor_B[45];
			6'h2E : rotor_B_out <= rotor_B[46];
			6'h2F : rotor_B_out <= rotor_B[47];
			6'h30 : rotor_B_out <= rotor_B[48];
			6'h31 : rotor_B_out <= rotor_B[49];
			6'h32 : rotor_B_out <= rotor_B[50];
			6'h33 : rotor_B_out <= rotor_B[51];
			6'h34 : rotor_B_out <= rotor_B[52];
			6'h35 : rotor_B_out <= rotor_B[53];
			6'h36 : rotor_B_out <= rotor_B[54];
			6'h37 : rotor_B_out <= rotor_B[55];
			6'h38 : rotor_B_out <= rotor_B[56];
			6'h39 : rotor_B_out <= rotor_B[57];
			6'h3A : rotor_B_out <= rotor_B[58];
			6'h3B : rotor_B_out <= rotor_B[59];
			6'h3C : rotor_B_out <= rotor_B[60];
			6'h3D : rotor_B_out <= rotor_B[61];
			6'h3E : rotor_B_out <= rotor_B[62];
			6'h3F : rotor_B_out <= rotor_B[63];
			default : rotor_B_out <= 6'b0;
			endcase
	end
end

//reflector_out
always @(*) begin
	if(!rst_n)begin
		reflector_out <= 6'b0;
	end
	else begin
		reflector_out <= 63 - rotor_B_out;
	end
end

//inv_rotor_B_out

always @(*) begin
	if(!rst_n)begin
		inv_rotor_B_out <= 6'b0;
	end
	else begin
		case(reflector_out)
			rotor_B[0] : inv_rotor_B_out <= 6'h00;
			rotor_B[1] : inv_rotor_B_out <= 6'h01;
			rotor_B[2] : inv_rotor_B_out <= 6'h02;
			rotor_B[3] : inv_rotor_B_out <= 6'h03;
			rotor_B[4] : inv_rotor_B_out <= 6'h04;
			rotor_B[5] : inv_rotor_B_out <= 6'h05;
			rotor_B[6] : inv_rotor_B_out <= 6'h06;
			rotor_B[7] : inv_rotor_B_out <= 6'h07;
			rotor_B[8] : inv_rotor_B_out <= 6'h08;
			rotor_B[9] : inv_rotor_B_out <= 6'h09;
			rotor_B[10] : inv_rotor_B_out <= 6'h0A;
			rotor_B[11] : inv_rotor_B_out <= 6'h0B;
			rotor_B[12] : inv_rotor_B_out <= 6'h0C;
			rotor_B[13] : inv_rotor_B_out <= 6'h0D;
			rotor_B[14] : inv_rotor_B_out <= 6'h0E;
			rotor_B[15] : inv_rotor_B_out <= 6'h0F;
			rotor_B[16] : inv_rotor_B_out <= 6'h10;
			rotor_B[17] : inv_rotor_B_out <= 6'h11;
			rotor_B[18] : inv_rotor_B_out <= 6'h12;
			rotor_B[19] : inv_rotor_B_out <= 6'h13;
			rotor_B[20] : inv_rotor_B_out <= 6'h14;
			rotor_B[21] : inv_rotor_B_out <= 6'h15;
			rotor_B[22] : inv_rotor_B_out <= 6'h16;
			rotor_B[23] : inv_rotor_B_out <= 6'h17;
			rotor_B[24] : inv_rotor_B_out <= 6'h18;
			rotor_B[25] : inv_rotor_B_out <= 6'h19;
			rotor_B[26] : inv_rotor_B_out <= 6'h1A;
			rotor_B[27] : inv_rotor_B_out <= 6'h1B;
			rotor_B[28] : inv_rotor_B_out <= 6'h1C;
			rotor_B[29] : inv_rotor_B_out <= 6'h1D;
			rotor_B[30] : inv_rotor_B_out <= 6'h1E;
			rotor_B[31] : inv_rotor_B_out <= 6'h1F;
			rotor_B[32] : inv_rotor_B_out <= 6'h20;
			rotor_B[33] : inv_rotor_B_out <= 6'h21;
			rotor_B[34] : inv_rotor_B_out <= 6'h22;
			rotor_B[35] : inv_rotor_B_out <= 6'h23;
			rotor_B[36] : inv_rotor_B_out <= 6'h24;
			rotor_B[37] : inv_rotor_B_out <= 6'h25;
			rotor_B[38] : inv_rotor_B_out <= 6'h26;
			rotor_B[39] : inv_rotor_B_out <= 6'h27;
			rotor_B[40] : inv_rotor_B_out <= 6'h28;
			rotor_B[41] : inv_rotor_B_out <= 6'h29;
			rotor_B[42] : inv_rotor_B_out <= 6'h2A;
			rotor_B[43] : inv_rotor_B_out <= 6'h2B;
			rotor_B[44] : inv_rotor_B_out <= 6'h2C;
			rotor_B[45] : inv_rotor_B_out <= 6'h2D;
			rotor_B[46] : inv_rotor_B_out <= 6'h2E;
			rotor_B[47] : inv_rotor_B_out <= 6'h2F;
			rotor_B[48] : inv_rotor_B_out <= 6'h30;
			rotor_B[49] : inv_rotor_B_out <= 6'h31;
			rotor_B[50] : inv_rotor_B_out <= 6'h32;
			rotor_B[51] : inv_rotor_B_out <= 6'h33;
			rotor_B[52] : inv_rotor_B_out <= 6'h34;
			rotor_B[53] : inv_rotor_B_out <= 6'h35;
			rotor_B[54] : inv_rotor_B_out <= 6'h36;
			rotor_B[55] : inv_rotor_B_out <= 6'h37;
			rotor_B[56] : inv_rotor_B_out <= 6'h38;
			rotor_B[57] : inv_rotor_B_out <= 6'h39;
			rotor_B[58] : inv_rotor_B_out <= 6'h3A;
			rotor_B[59] : inv_rotor_B_out <= 6'h3B;
			rotor_B[60] : inv_rotor_B_out <= 6'h3C;
			rotor_B[61] : inv_rotor_B_out <= 6'h3D;
			rotor_B[62] : inv_rotor_B_out <= 6'h3E;
			rotor_B[63] : inv_rotor_B_out <= 6'h3F;
			default : inv_rotor_B_out <= 6'b0;
			endcase
	end
end

 
//inv_rotor_A_out

always @(*) begin
	if(!rst_n)begin
		inv_rotor_A_out <= 6'b0;
	end
	else begin
		case(inv_rotor_B_out)
			rotor_A[0] : inv_rotor_A_out <= 6'h00;
			rotor_A[1] : inv_rotor_A_out <= 6'h01;
			rotor_A[2] : inv_rotor_A_out <= 6'h02;
			rotor_A[3] : inv_rotor_A_out <= 6'h03;
			rotor_A[4] : inv_rotor_A_out <= 6'h04;
			rotor_A[5] : inv_rotor_A_out <= 6'h05;
			rotor_A[6] : inv_rotor_A_out <= 6'h06;
			rotor_A[7] : inv_rotor_A_out <= 6'h07;
			rotor_A[8] : inv_rotor_A_out <= 6'h08;
			rotor_A[9] : inv_rotor_A_out <= 6'h09;
			rotor_A[10] : inv_rotor_A_out <= 6'h0A;
			rotor_A[11] : inv_rotor_A_out <= 6'h0B;
			rotor_A[12] : inv_rotor_A_out <= 6'h0C;
			rotor_A[13] : inv_rotor_A_out <= 6'h0D;
			rotor_A[14] : inv_rotor_A_out <= 6'h0E;
			rotor_A[15] : inv_rotor_A_out <= 6'h0F;
			rotor_A[16] : inv_rotor_A_out <= 6'h10;
			rotor_A[17] : inv_rotor_A_out <= 6'h11;
			rotor_A[18] : inv_rotor_A_out <= 6'h12;
			rotor_A[19] : inv_rotor_A_out <= 6'h13;
			rotor_A[20] : inv_rotor_A_out <= 6'h14;
			rotor_A[21] : inv_rotor_A_out <= 6'h15;
			rotor_A[22] : inv_rotor_A_out <= 6'h16;
			rotor_A[23] : inv_rotor_A_out <= 6'h17;
			rotor_A[24] : inv_rotor_A_out <= 6'h18;
			rotor_A[25] : inv_rotor_A_out <= 6'h19;
			rotor_A[26] : inv_rotor_A_out <= 6'h1A;
			rotor_A[27] : inv_rotor_A_out <= 6'h1B;
			rotor_A[28] : inv_rotor_A_out <= 6'h1C;
			rotor_A[29] : inv_rotor_A_out <= 6'h1D;
			rotor_A[30] : inv_rotor_A_out <= 6'h1E;
			rotor_A[31] : inv_rotor_A_out <= 6'h1F;
			rotor_A[32] : inv_rotor_A_out <= 6'h20;
			rotor_A[33] : inv_rotor_A_out <= 6'h21;
			rotor_A[34] : inv_rotor_A_out <= 6'h22;
			rotor_A[35] : inv_rotor_A_out <= 6'h23;
			rotor_A[36] : inv_rotor_A_out <= 6'h24;
			rotor_A[37] : inv_rotor_A_out <= 6'h25;
			rotor_A[38] : inv_rotor_A_out <= 6'h26;
			rotor_A[39] : inv_rotor_A_out <= 6'h27;
			rotor_A[40] : inv_rotor_A_out <= 6'h28;
			rotor_A[41] : inv_rotor_A_out <= 6'h29;
			rotor_A[42] : inv_rotor_A_out <= 6'h2A;
			rotor_A[43] : inv_rotor_A_out <= 6'h2B;
			rotor_A[44] : inv_rotor_A_out <= 6'h2C;
			rotor_A[45] : inv_rotor_A_out <= 6'h2D;
			rotor_A[46] : inv_rotor_A_out <= 6'h2E;
			rotor_A[47] : inv_rotor_A_out <= 6'h2F;
			rotor_A[48] : inv_rotor_A_out <= 6'h30;
			rotor_A[49] : inv_rotor_A_out <= 6'h31;
			rotor_A[50] : inv_rotor_A_out <= 6'h32;
			rotor_A[51] : inv_rotor_A_out <= 6'h33;
			rotor_A[52] : inv_rotor_A_out <= 6'h34;
			rotor_A[53] : inv_rotor_A_out <= 6'h35;
			rotor_A[54] : inv_rotor_A_out <= 6'h36;
			rotor_A[55] : inv_rotor_A_out <= 6'h37;
			rotor_A[56] : inv_rotor_A_out <= 6'h38;
			rotor_A[57] : inv_rotor_A_out <= 6'h39;
			rotor_A[58] : inv_rotor_A_out <= 6'h3A;
			rotor_A[59] : inv_rotor_A_out <= 6'h3B;
			rotor_A[60] : inv_rotor_A_out <= 6'h3C;
			rotor_A[61] : inv_rotor_A_out <= 6'h3D;
			rotor_A[62] : inv_rotor_A_out <= 6'h3E;
			rotor_A[63] : inv_rotor_A_out <= 6'h3F;
			default : inv_rotor_A_out <= 6'b0;
			endcase
	end
end

//out_code
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out_code <= 6'b0;
	end 
	else if(store_in_valid_2)begin
		out_code <= inv_rotor_A_out;
	end
	else begin
		out_code <= 6'b0;
	end
end




endmodule












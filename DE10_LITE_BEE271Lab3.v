//BEE271 Winter 2024
//Lab 3 Sequential Logic Units: Flip-Flops & Counters

//Jason T. & Adrian C.
//February 19th, 2024
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module DE10_LITE_BEE271Lab3(

	//////////// CLOCK //////////
	input 		          		ADC_CLK_10,
	input 		          		MAX10_CLK1_50,
	input 		          		MAX10_CLK2_50,

	//////////// SEG7 //////////
	output		     [7:0]		HEX0,
	output		     [7:0]		HEX1,
	output		     [7:0]		HEX2,
	output		     [7:0]		HEX3,
	output		     [7:0]		HEX4,
	output		     [7:0]		HEX5,

	//////////// KEY //////////
	input 		     [1:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW
);



//=======================================================
//  REG/WIRE declarations
//=======================================================
// UNUSED manual clock generation, using RS-NAND module

// start by perssing KEY[0]
// fixed or variable delay resets it
//reg[31:0] CDIV;	// define 32-bit counter
//wire DCLK;			// clock output to other modules
//always@(*)begin	// start always block
//	if (DCLK == 0) CDIV = 0;	//if CLK was off, reset counter
//	else CDIV = CDIV + 1;		//otherwise count up
//	end								//end clock counter
//RSNAND CLK(KEY[0],CRES,DCLK,LEDR[9]);

// Automatic Clock Generation, using operators
reg Clk;
reg Clock_50;
always @(*) Clock_50 = MAX10_CLK1_50;
reg [31:0]ClkCounter;
always @(posedge Clock_50) begin // 250 ms
	if (ClkCounter == 0) begin
		ClkCounter <= 12500000;
		Clk <= ~Clk;						//Toggle 2Hz Clock
	end else begin
	ClkCounter <= ClkCounter -1;	//Count Down
	end
end

assign LEDR[9] = Clk;

//=======================================================
//  Structural coding
//=======================================================
//wire[7:0] HEXOFF;
//assign HEXOFF = ~0;	//define HEX blanking variable
//assign HEX5 = HEXOFF;
//assign HEX4 = HEXOFF;
//assign HEX3 = HEXOFF;
//assign HEX2 = HEXOFF;
//assign HEX1 = HEXOFF;
//assign HEX0 = HEXOFF;

RSNAND	LED01(KEY[1],KEY[0],LEDR[1:0]);
RSNOR		LED23(~KEY[1],~KEY[0],LEDR[3:2]);
DL			LED4(KEY[1],SW[4],LEDR[4]);
DFFP		LED5(Clk,SW[5],LEDR[5]);
DFFN		LED6(Clk,SW[6],LEDR[6]);
TF			LED7(Clk,SW[7],LEDR[7]);
JK_FF		LED8(Clk,SW[9],SW[8],LEDR[8]);

//Extending to 12-bit Binary Counter
//Extending to 9-bit Polynomial Counter
reg BCTR;
reg PCTR;
reg PCTRN;

wire [11:0]BC;		// define a binary counter
always @(posedge Clk) BCTR = BCTR + 1;

wire [8:0]POLYNOMIAL;	// define a polynomial counter and next value
reg PFB; 		// define feedback into the polynomial counter

always @(posedge Clk) begin
	PFB <= ~(POLYNOMIAL[8]^POLYNOMIAL[7]);		// Polynomial counter feedback
	PCTRN <= {POLYNOMIAL[7:0], PFB};	//	Concatenate and Shift PCTR
	end
always @(negedge Clk)	PCTR <= PCTRN; //reload polynomial counter

//Initialising Ripple Counter
//wire [3:0]t;
//RIPPLE	RIPCNT0(Clk,KEY[0],t);
RIPPLE	RIPCNT1(Clk,KEY[0],BC);

//Initialising Polynomial Counter
//wire [3:0]p;
//POLYNOMIAL	CNT1(Clk,KEY[0],p);
POLYNOMIAL	POLCNT0(Clk,KEY[0],POLYNOMIAL);

Seg7 digit0(BC[3:0],HEX0);
Seg7 digit1(BC[6:4],HEX1);
Seg7 digit2(BC[11:7],HEX2);
Seg7 digit3(POLYNOMIAL[2:0],HEX3);
Seg7 digit4(POLYNOMIAL[5:3],HEX4);
Seg7 digit5(POLYNOMIAL[8:6],HEX5);
endmodule

//RS-NAND Latch Gate
module RSNAND(set, reset, q, qn);
input wire set, reset;
output reg q, qn;
always@(*) begin
	q <= ~(set & qn);
	qn <= ~(reset & q);
	end
endmodule

//RS-NOR Latch Gate
module RSNOR(set, reset, q, qn);
input wire set, reset;
output reg q, qn;
always@(*) begin
	q <= ~(reset & qn);
	qn <= ~(set & q);
	end
endmodule

//D-Latch
module DL(enable, d, q);
input wire enable, d;
output reg q;
always@(*) begin
	if (enable) q = d;
	end
endmodule

//Flip-flop pos
//Re-using this one
module DFFP(clk, d, q);
input wire clk, d;
output reg q;
always@(posedge clk) q = d;
endmodule

//Flip-flop neg
module DFFN(clk, d, q);
input wire clk, d;
output reg q;
always@(negedge clk) q = d;
endmodule

//T-Flip-Flop
module TF(clk, t, q);
input wire clk, t;
output reg q;
always@(posedge clk) begin
	if (t) q <= ~q;
	end
endmodule

//JK FF
module JK_FF(clk, j, k, q);
input wire clk, j, k;
output reg q;
always@(posedge clk) begin
	case ({j, k})
	2'b00	:	q <= q;
	2'b01	:	q <= 0;
	2'b10	:	q <= 1;
	2'b11	:	q <= ~q;
	endcase
end
endmodule

//4-bit counter
//EXTENDED TO 12-BIT*
module RIPPLE(clk, reset, out);
input wire clk, reset;
output wire [11:0]out;

//Initiating 12*-TFF
TF BC0(clk,	1, out[0]); 		//1st Stage
TF BC1(clk, out[0], out[1]);	//2nd Stage
TF BC2(clk, &out[1:0], out[2]);	//3rd Stage
TF BC3(clk, &out[2:0], out[3]);	//4th Stage
TF BC4(clk, &out[3:0], out[4]);	//5th Stage
TF BC5(clk, &out[4:0], out[5]);	//6th Stage
TF BC6(clk, &out[5:0], out[6]);	//7th Stage
TF BC7(clk, &out[6:0], out[7]);	//8th Stage
TF BC8(clk, &out[7:0], out[8]);	//11th Stage
TF BC9(clk, &out[8:0], out[9]);	//12th Stage
TF BC10(clk, &out[9:0], out[10]);	//13th Stage
TF BC11(clk, &out[10:0], out[11]);	//14th Stage
endmodule

//Polynomial 4-bit Counter
//EXTENDED TO 9-BIT*
module POLYNOMIAL(clk, reset, pout);
input wire clk, reset;
output wire [8:0]pout;

//Initiating 9*-DF
DFFP PC0(clk, (~pout[2]^pout[3]), pout[0]);	//1st STAGE
// FF Data is XNOR of last bits
DFFP PC1(clk, pout[0], pout[1]);				//2nd Stage FF
DFFP PC2(clk, pout[1], pout[2]);				//3rd Stage FF
DFFP PC3(clk, pout[2], pout[3]);				//4th Stage FF
DFFP PC4(clk, pout[3], pout[4]);				//5th Stage FF
DFFP PC5(clk, pout[4], pout[5]);				//6th Stage FF
DFFP PC6(clk, pout[5], pout[6]);				//7th Stage FF
DFFP PC7(clk, pout[6], pout[7]);				//8th Stage FF
DFFP PC8(clk, pout[7], pout[8]);				//9th Stage FF
endmodule

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//	7 Segment Display 4-Switch Assignment
// @Lab 1
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

module Seg7 (hex, Seg);
input wire [3:0] hex;
output wire [6:0] Seg;

assign x0 = hex[0];
assign x1 = hex[1];
assign x2 = hex[2];
assign x3 = hex[3];

assign Seg[0]= ~(x1 & x2 | ~x1 & ~x2 & x3 | ~x0 & x3 | ~x0 & ~x2 | 
	x0 & x2 & ~x3 | x1 & ~x3);
assign Seg[1]= ~(~x0 & ~x2 | ~x2 & ~x3 | x0 & x1 & ~x3 | ~x0 & ~x1 & ~x3 |
	x0 & ~x1 & x3);
assign Seg[2]=	~(~x1 & ~x3 | x0 & ~x3 | x0 & ~x1 | x2 & ~x3 | ~x2 & x3);
assign Seg[3]=	~(x2 & ~x1 & x0 | ~x2 & x1 & x0 | ~x3 & ~x2 & ~x0 |
	x2 & x1 & ~x0 | x3 & ~x1 & ~x0);
assign Seg[4]=	~(~x0 & ~x2 | ~x0 & x1 | x2 & x3 | x1 & x3);
assign Seg[5]=	~(~x0 & ~x1 | ~x1 & x2 & ~x3 | ~x0 & x2 | x1 & x3 | ~x2 & x3);
assign Seg[6]=	~(~x2 & x1 | x3 & ~x2 | ~x3 & x2 & ~x1 | x1 & ~x0 | x3 & x0);
endmodule //Seg7
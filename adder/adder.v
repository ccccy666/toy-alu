//Ci+1 = Gi + PiCi

//Gi = Ai * Bi(基础的Gi)
//Pi = Ai + Bi(基础的Pi)
//信号连线用wire 
module Add
(
	input [31:0]a,
	input [31:0]b,
	input C_in,
	output reg [31:0]sum
	//output C_out
);
wire [3:0]G;
wire [3:0]P;
assign G[3:2]=2'b00;
assign P[3:2]=2'b00;
wire C_16;
wire [31:0] F;

always @(*) begin
	 sum <= F;
end 
	 
Add16_head add16_1(.a(a[15:0]),.b(b[15:0]),.C_in(1'b0),.F(F[15:0]),.Gm(G[0]),.Pm(P[0]));
assign C_16=G[0]|P[0]&C_in;
Add16_head add16_2(.a(a[31:16]),.b(b[31:16]),.C_in(C_16),.F(F[31:16]),.Gm(G[1]),.Pm(P[1]));
 
//assign C_out=G[1]|P[1]&G[0]|P[1]&P[0]&C_in;
endmodule
//G0 = g3 + p3g2 + p3p2g1 + p3p2p1g0
//P0 = p3p2p1p0
//G1 = g7 + p7g6 + p7p6g5 + p7p6p5g4
//P1 = p7p6p5p4
//之后每次下标+4
 //16位
 module Add16_head
 (
	input [15:0]a,
	input [15:0]b,
	input C_in,
	output [15:0] F,
	output Gm,
	output Pm
	//output C_out
 );
 wire [3:0]G;
 wire [3:0]P;
 wire [4:1]C;
 Add4_head A0(.a(a[3:0]),.b(b[3:0]),.C_in(C_in),.F(F[3:0]),.Gm(G[0]),.Pm(P[0]));//得到G0，P0
 Add4_head A1(.a(a[7:4]),.b(b[7:4]),.C_in(C[1]),.F(F[7:4]),.Gm(G[1]),.Pm(P[1]));//G1,P1
 Add4_head A3(.a(a[11:8]),.b(b[11:8]),.C_in(C[2]),.F(F[11:8]),.Gm(G[2]),.Pm(P[2]));
 Add4_head A4(.a(a[15:12]),.b(b[15:12]),.C_in(C[3]),.F(F[15:12]),.Gm(G[3]),.Pm(P[3]));
 CLA_4 AAt(.P(P),.G(G),.C_in(C_in),.Ci(C),.Gm(Gm),.Pm(Pm));
 //assign C_out=C[4];
 endmodule
module Add4_head
(
	input [3:0]a,
	input [3:0]b,
	input C_in,
	output [3:0]F,
	output Gm,
	output Pm
	//output C_out
);
	wire [3:0] G;
	wire [3:0] P;
	wire [4:1] C;
   Add1 u1(.a(a[0]),.b(b[0]),.C_in(C_in),.f(F[0]),.g(G[0]),.p(P[0]));//算pi,gi
   Add1 u2(.a(a[1]),.b(b[1]),.C_in(C[1]),.f(F[1]),.g(G[1]),.p(P[1]));//
   Add1 u3(.a(a[2]),.b(b[2]),.C_in(C[2]),.f(F[2]),.g(G[2]),.p(P[2]));
   Add1 u4(.a(a[3]),.b(b[3]),.C_in(C[3]),.f(F[3]),.g(G[3]),.p(P[3]));

  CLA_4 uut(.P(P),.G(G),.C_in(C_in),.Ci(C),.Gm(Gm),.Pm(Pm));//Gm,Pm,进位c
  //assign C_out=C[4];
 endmodule
module CLA_4(
	input [3:0]P,
	input [3:0]G,
	input C_in,//c0
	output [4:1]Ci,
	output Gm,
	output Pm
);
assign Ci[1]=G[0]|P[0]&C_in;
assign Ci[2]=G[1]|P[1]&G[0]|P[1]&P[0]&C_in;
assign Ci[3]=G[2]|P[2]&G[1]|P[2]&P[1]&G[0]|P[2]&P[1]&P[0]&C_in;
assign Ci[4]=G[3]|P[3]&G[2]|P[3]&P[2]&G[1]|P[3]&P[2]&P[1]&G[0]|P[3]&P[2]&P[1]&P[0]&C_in;

assign Gm=G[3]|P[3]&G[2]|P[3]&P[2]&G[1]|P[3]&P[2]&P[1]&G[0];//CLA16用的
assign Pm=P[3]&P[2]&P[1]&P[0];
endmodule
module Add1
(
	input a,
	input b,
	input C_in,
	output f,
	output g,
	output p
);
assign f=a^b^C_in;
assign g=a&b;
assign p=a|b;
endmodule



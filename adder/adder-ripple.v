module Add(
        input       [31:0]          a,
        input       [31:0]          b,
        output reg  [31:0]          sum
    );
    wire [31:0] s;
    always @(*) #1 sum = s;

    wire c16;
    CLA16 a0(.a(a[15: 0]), .b(b[15: 0]), .s(s[15: 0]), .cin(1'b0), .g(c16));
    CLA16 a1(.a(a[31:16]), .b(b[31:16]), .s(s[31:16]), .cin(c16));

endmodule //Add
module CLA16 (
        input [15:0] a, b,
        input cin,
        output [15:0] s,
        output cout, p, g
    );
    wire [3:0] G;
    wire [3:0] P;
    wire [3:1] c;
    CLA4 a0(.a(a[ 3: 0]), .b(b[ 3: 0]), .s(s[ 3: 0]), .cin(cin),  .p(P[0]), .g(G[0]));
    CLA4 a1(.a(a[ 7: 4]), .b(b[ 7: 4]), .s(s[ 7: 4]), .cin(c[1]), .p(P[1]), .g(G[1]));
    CLA4 a2(.a(a[11: 8]), .b(b[11: 8]), .s(s[11: 8]), .cin(c[2]), .p(P[2]), .g(G[2]));
    CLA4 a3(.a(a[15:12]), .b(b[15:12]), .s(s[15:12]), .cin(c[3]), .p(P[3]), .g(G[3]));
    CLA_processor process(.p(P), .g(G), .c(c), .cin(cin), .cout(cout), .gm(g), .pm(p));
endmodule //CLA16
module CLA_processor(
        input [3:0] p, g,
        input cin,
        output [3:1] c,
        output cout, pm, gm
    );
    assign c[1] = g[0] | cin & p[0];
    assign c[2] = g[1] | g[0] & p[1] | cin  & (&p[1:0]);
    assign c[3] = g[2] | g[1] & p[2] | g[0] & (&p[2:1]) | cin  & (&p[2:0]);
    assign cout = g[3] | g[2] & p[3] | g[1] & (&p[3:2]) | g[0] & (&p[3:1]) | cin & (&p[3:0]);
    assign gm = g[3] | g[2] & p[3] | g[1] & (&p[3:2]) | g[0] & (&p[3:1]);
    assign pm = &p;
endmodule //CLA_processor
module CLA4(
        input [3:0] a, b,
        input cin,
        output [3:0] s,
        output cout, p, g
    );
    wire [3:0] P;
    wire [3:0] G;
    wire [3:1] c;
    assign P = a ^ b;
    assign G = a & b;
    CLA_processor process(.p(P), .g(G), .c(c), .cin(cin), .cout(cout), .gm(g), .pm(p));
    assign s = P ^ {c,cin};
endmodule //CLA4


`include "adder-float.v"
`timescale 1ns/1ps
module floatadd_tb();
    reg clk,rst;
    reg [31:0] x,y;
    wire [31:0] z;
    wire [1:0] overflow;
    
    float_adder floatadd_test(
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .z(z),
        .overflow(overflow)
    );
    always #(10) clk<=~clk;
    initial begin
        clk=0;
        rst=1'b0;
        x=32'b00111111010001111010111000010100;//0.78
        y=32'b00111111000011001100110011001101;//0.55
        #20 rst=1'b1;
        
        //ans=0.78+0.55=1.33 32'b00111111 10101010 00111101 01110001 3faa3d70
        
        #100
        $display("%b + %b = %b", x, y, z);
        
        $stop;
    end
endmodule
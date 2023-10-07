module Add(
    input       [31:0]          a,
    input       [31:0]          b,
    output reg  [31:0]          sum
);
    integer i;
	reg [0:0] c = 0;    // Carry   bit
    reg [0:0] s = 0;    // Current bit
    always@(*)begin
        for(i=0;i<32;i=i+1)begin
            s = c ^ (a[i] ^ b[i]);
            c = (a[i] & b[i]) | (c & (a[i] | b[i]));
			sum[i]=s;
    	end

    end
endmodule
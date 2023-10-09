module float_adder 
(
    input clk,
    input rst,
    input [31:0] x,
    input [31:0] y,
    output reg [31:0] z,
    output reg [1:0] overflow//0-没有溢出;01-上溢;10-下溢;11-非规格化
);
    reg [24:0] m_x,m_y,m_z;//1.F,额外多一位是避免溢出 
    reg [7:0] e_x,e_y,e_z;//指数
    reg [2:0] state_now,state_next;
    reg sign_x,sign_y,sign_z;

    reg [24:0] out_x,out_y,mid_y,mid_x;//右移值，中间值
    reg [7:0] move_tot;//右移长度
    reg [2:0] bigger;//ex<ey,10;ex>ey,01;ex==ey,00

    //parameter 3'b000 = 3'b000,3'b001 = 3'b001,3'b010 = 3'b010,3'b011 = 3'b011,3'b100 = 3'b100,3'b101 = 3'b110;
    //初始化（检查是否无穷大和非数），检查0（数过小则改动m_?，因为是0.F），指数检查，相加，规格化，结束(改动overflow)
    always @(posedge clk) begin
        if(!rst)begin
            state_now<=3'b000;
        end
        else begin
            state_now<=state_next;
        end
    end
    always @(state_now,state_next,e_x,e_y,e_z,m_x,m_y,m_z,out_x,out_y,mid_x,mid_y) begin
        case(state_now)
            3'b000:begin//初始化，分离指数尾数
                bigger<=2'b0;
                e_x<=x[30:23];
                e_y<=y[30:23];
                m_x<={1'b0,1'b1,x[22:0]};//最高位来控制溢出 1.F
                m_y<={1'b0,1'b1,y[22:0]};
                out_x<=25'b0;
                out_y<=25'b0;
                mid_y<={24'b0,1'b1};
                mid_x<={24'b0,1'b1};
                move_tot<=8'b0;
                //只有阶码[1,254]和实数0规格化
                if((e_x==8'd255&&m_x[22:0]!=0)||(e_y==8'd255&&m_y[22:0]!=0))begin
                    overflow<=2'b11;    
                    sign_z<=1'b1;
                    e_z<=8'b11111111;
                    m_z<=23'b11111111111111111111111;
                    state_next<=3'b101;
                end//非数
                else if((e_x==8'd255&&m_x[22:0]==0)||(e_y==8'd255&&m_y[22:0]==0))begin
                    //当x或者y是无穷大的时候，令答案为无穷大，overflow=2'b11，跳转到over
                    overflow<=2'b11;    
                    sign_z<=1'b0;
                    e_z<=8'b11111111;
                    m_z<=23'b0;
                    state_next<=3'b101;
                end
                else begin
                    overflow<=2'b0;
                    state_next<=3'b001;//进入判断0阶段
                end
            end
            3'b001:begin
                if(m_x[22:0]==23'b0&&e_x==8'b0)begin
                    sign_z<=y[31];
                    e_z<=e_y;
                    m_z<=m_y;
                    state_next<=3'b101;
                end
                else if(m_y[22:0]==23'b0&&e_y==8'b0)begin
                    sign_z<=x[31];
                    e_z<=e_x;
                    m_z<=m_x;
                    state_next<=3'b101;
                end
               
                else begin
                    state_next<=3'b010;//进入对阶处理阶段
                end
                if(m_x[22:0]!=23'b0&&e_x==8'b0)begin
                    m_x<={1'b0,1'b0,x[22:0]};//不再是1.F
                end
                if(m_y[22:0]!=23'b0&&e_y==8'b0)begin
                    m_y<={1'b0,1'b0,y[22:0]};
                end
            end
            3'b010:begin
                if(e_x==e_y)begin//e_x == exponent_y的时候需要进行舍入机制判断
                    if(bigger==2'b00)begin
                        state_next<=3'b011;//指数对齐，进入尾数加阶段
                    end
                    else if(bigger==2'b10)begin
                        if(out_y>mid_y)begin
                            m_y<=m_y+1'b1;
                        end
                        else if(out_y<mid_y)begin
                            m_y<=m_y;
                        end
                        else if(out_y==mid_y)begin
                            if(m_y[0]==1)begin
                                m_y<=m_y+1'b1;
                            end
                            else begin
                                m_y<=m_y;
                            end
                        end    
                        state_next<=3'b011;
                    end
                    else if(bigger==2'b01)begin
                        if(out_x>mid_x)begin
                            m_x<=m_x+1'b1;
                        end
                        else if(out_x<mid_x)begin
                            m_x<=m_x;
                        end
                        else if(out_x==mid_x)begin
                            if(m_x[0]==1)begin
                                m_x<=m_x+1'b1;
                            end
                            else begin
                                m_x<=m_x;
                            end
                        end     
                        state_next<=3'b011;
                    end
                end
                else begin
                    if(e_x>e_y)begin
                        bigger<=2'b01;
                        e_y<=e_y+1'b1;
                        m_y[23:0]<={1'b0,m_y[23:1]};//指数+1，尾数右移一位
                        out_y[move_tot]<=m_y[0];
                        mid_y={mid_y[23:0],mid_y[24]};
                        move_tot<=move_tot+1'b1;
                        if(m_y==24'b0)begin//节码差距过大，就不需要考虑太小的
                            sign_z<=sign_x;
                            e_z<=e_x;
                            m_z<=m_x;
                            state_next<=3'b101;
                        end
                        else begin
                            state_next<=3'b010;
                        end
                    end
                    else begin
                        bigger<=2'b10;
                        e_x<=e_x+1'b1;
                        m_x[23:0]<={1'b0,m_x[23:1]};
                        out_x[move_tot]<=m_x[0];
                        mid_x={mid_x[23:0],mid_x[24]};
                        move_tot<=move_tot+1'b1;
                        if(m_x==24'b0)begin
                            sign_z<=sign_y;
                            e_z<=e_y;
                            m_z<=m_y;
                            state_next<=3'b101;
                        end
                        else begin
                            state_next<=3'b010;
                        end
                    end
                end
            end
            3'b011:begin
                if(x[31]^y[31]==1'b0)begin//同号
                    e_z<=e_x;
                    sign_z<=x[31];
                    m_z<=m_x+m_y;
                    state_next<=3'b100;
                end
                else begin
                    if(m_x>m_y)begin
                        e_z<=e_x;
                        sign_z<=x[31];
                        m_z<=m_x-m_y;
                        state_next<=3'b100;
                    end
                    else if(m_x<m_y)begin
                        e_z<=e_x;
                        sign_z<=y[31];
                        m_z<=m_y-m_x;
                        state_next<=3'b100;
                    end
                    else begin
                        e_z<=e_x;
                        m_z<=23'b0;
                        state_next<=3'b101;//全零没必要规格化
                    end
                end
            end
            3'b100:begin
                if(m_z[24]==1'b1)begin// 有进位
                    m_z<={1'b0,m_z[24:1]};
                    e_z<=e_z+1'b1;
                    state_next<=3'b101;
                end
                else begin
                    if(m_z[23]==1'b0&&e_z>=1)begin//规格化处理，0.xxxx转化成1.xxxxx
                        m_z<={m_z[23:0],1'b0};
                        e_z<=e_z-1'b1;
                        state_next<=3'b100;
                    end
                    else begin
                        state_next<=3'b101;
                    end
                end
            end
            3'b101:begin
                z={sign_z,e_z[7:0],m_z[22:0]};
                //溢出：
                //1.大于最大浮点数
                //2.小于最小浮点数直接输出z
                if(overflow)begin
                    overflow<=overflow;
                    state_next<=3'b000;
                end
                else if(e_z==8'd255)begin
                    overflow<=2'b01;
                    state_next<=3'b000;
                end
                else if(e_z==8'd0&&m_z[22:0]!=23'b0)begin
                    overflow<=2'b10;
                    state_next<=3'b000;
                end
                else begin
                    overflow<=2'b00;
		            state_next<=3'b000;
                end 
            end
            default:begin
                state_next<=3'b000;
            end
        endcase
    end

endmodule
//reference:https://blog.csdn.net/Phoenix_ZengHao/article/details/118760774
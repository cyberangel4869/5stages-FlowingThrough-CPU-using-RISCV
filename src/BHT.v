module BHT (
    input clk,
    input rst_n,
    input is_JBtype,//只有在当前指令是分支跳转类时才改变预测状态
    input jump,//当前分支指令需要跳转
    output reg serch_en//预测结果，高电平需要跳转
);
reg [1:0] state;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        state<=2'b01;
        serch_en<=0;
    end
    else begin
        if(is_JBtype)begin//只有在当前指令是跳转分支指令时才改变预测状态
        case (state)//00:坚定预测不跳，01：弱预测不跳，01：弱预测跳，11：强预测跳
            2'b00:state<=jump?2'b01:2'b00;
            2'b01:state<=jump?2'b10:2'b00;
            2'b10:state<=jump?2'b11:2'b01;
            2'b11:state<=jump?2'b11:2'b10;
            default: state<=0;
        endcase
        end
    end
end
always @(*) begin
    case (state)
        2'b00:serch_en=0;
        2'b01:serch_en=0;
        2'b10:serch_en=1;
        2'b11:serch_en=1; 
        default: serch_en<=0;
    endcase
end
endmodule
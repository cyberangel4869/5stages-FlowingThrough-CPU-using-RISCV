module IF_ID_regs(
    input clk,
    input rst_n,
    input Bubble,//bubble信号有效时，输出数据保持
    input clean,//clean有效时，下一个上升沿清空指令数据完成指令冲刷
    input [31:0] IF_instruction,
    input [31:0] IF_PC_add4,
    output reg [31:0] ID_instruction,
    output reg [31:0] ID_PC_add4
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        ID_instruction<=0;
        ID_PC_add4<=0;
    end 
    else begin
        if(!Bubble)begin
            if(clean)begin
                ID_instruction<=0;
                ID_PC_add4<=0;
            end
            else begin 
                ID_instruction<=IF_instruction;
                ID_PC_add4<=IF_PC_add4;
            end
        end
    end
end
    
endmodule
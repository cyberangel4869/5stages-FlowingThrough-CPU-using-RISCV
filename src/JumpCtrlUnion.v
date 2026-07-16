module JumpCtrlUnion (
    input [31:0] instruction,
    input ALU_Zero,//ALU输出为零信号，用于决定BEQ,BNE是否跳转
    input [31:0] ALU_Result,//ALU结果，JAL和JALR的目标程序地址
    input [31:0] PC,//当前程序指针，BEQ,BNE指令的目标地址在本模块内计算
    input [31:0] imm,//立即数地址偏移量
    input [31:0] PC_predict,//预测的PC地址

    output reg jump,//需要跳转
    output reg is_JBtype,//当前指令是跳转类
    output reg PC_update,//跳转预测有误，重新修改PC并冲刷
    output reg clean,//指令冲刷信号
    output reg [31:0] jump_dist//跳转目标地址
);
`include "opcodeList.vh"
wire [6:0] opcode;
assign opcode = instruction[6:0];
wire [2:0] funct3;
assign funct3 = instruction[14:12];
always @(*) begin
    case (opcode)
        J_type:begin//JAL
            is_JBtype=1;
            jump=1;
            jump_dist=ALU_Result;//ALU计算PC加立即数得到目标程序地址
        end
        I_type_JALR:begin//JALR
            is_JBtype=1;
            jump=1;
            jump_dist=ALU_Result;//ALU计算rs1加立即数得到目标程序地址
        end
        B_type:begin//BEQ,BNE
            is_JBtype=1;
            case (funct3)
            3'b000:begin//BEQ
                if(ALU_Zero)begin//rs1=rs2,减法结果为0，跳转
                    jump=1;
                    jump_dist=PC+imm;
                end
                else begin
                    jump=0;
                    jump_dist=PC+4;
                end
            end
            3'b001:begin//BNE
                if(!ALU_Zero)begin//rs1!=rs2,减法结果不为零，跳转
                    jump=1;
                    jump_dist=PC+imm;
                end
                else begin
                    jump=0;
                    jump_dist=PC+4;
                end
            end  
            default:begin
                jump=0;
                jump_dist=0;
            end 
            endcase 
        end
        default: begin
            is_JBtype=0;
            jump=0;
            jump_dist=0;
        end
    endcase
end

always @(*) begin
    if(is_JBtype)begin//当前指令是跳转类指令
        if(jump)begin//当前指令需要跳转
            if(PC_predict==jump_dist)begin//预测正确，目标指令已经进入流水
                PC_update=0;clean=0;
            end
            else begin
                PC_update=1;clean=1;
            end
        end
        else begin//当前指令无需跳转
            if(PC_predict==PC+3'd4)begin//预测无需跳转正确，下一条指令已经进入流水
                PC_update=0;clean=0;
            end
            else begin
                PC_update=1;clean=1;
            end
        end
    end
    else begin
        PC_update=0;clean=0;
    end
end
    
endmodule
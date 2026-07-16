module WritebackControlLogic (
    input [31:0] instruction,
    input [31:0] Result,
    input [31:0] LOAD_data,
    input [31:0] PC_add4,
    output reg [31:0] wdata,
    output reg [4:0] waddr,
    output reg we//RF写使能
);
`include "opcodeList.vh"
wire [6:0] opcode;//操作数提取
assign opcode=instruction[6:0];
wire [4:0] rd;//目的寄存器地址提取
assign rd=instruction[11:7];
always @(*) begin
    case (opcode)
        R_type:begin//R型指令，需要rs1和rw2运算的结果写回rd地址的寄存器
            wdata=Result;
            waddr=rd;
            we=1;
        end
        I_type_ARITH:begin//I型基本运算指令，需要将rs1和立即数的运算结果写回寄存器
            wdata=Result;
            waddr=rd;
            we=1;
        end
        I_type_LOAD:begin//LW加载指令，需要把MEM中读取的数据写回寄存器组
            wdata=LOAD_data;
            waddr=rd;
            we=1;
        end
        J_type:begin//JAL跳转并链接，需要把当前指令的下一条指令地址PC+4写入rd
            wdata=PC_add4;
            waddr=rd;
            we=1;
        end
        I_type_JALR:begin//JALR跳转并链接寄存器，将当前PC+4写入rd
            wdata=PC_add4;
            waddr=rd;
            we=1;
        end
        default:begin//其余情况不需要写回寄存器  
            we=0;
            wdata=0;
            waddr=0;
        end
    endcase
end
endmodule
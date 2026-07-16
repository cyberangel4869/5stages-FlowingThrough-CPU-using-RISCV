module ForwardingCtrlUnion (
    input clk,
    input rst_n,
    input [31:0] instruction_EX,//当前执行的指令，位于ID-EX寄存器中
    input [31:0] instruction_MEM,//上一条指令，位于EX-MEM寄存器中
    input [31:0] instruction_WB,//上上条指令，位于MEM-WB寄存器中
    input [31:0] Result_MEM,//上一次运算的结果
    input [31:0] Result_WB,//上上次运算的结果
    input [31:0] LOAD_data_MEM,//上条指令从内存中取出的数
    output reg data1_update,
    output reg data2_update,
    output reg [31:0] rs1_update_data,
    output reg [31:0] rs2_update_data,
    output reg Bubble//暂停运行一个周期
);
`include "opcodeList.vh"
wire [6:0] opcode_EX;
assign opcode_EX=instruction_EX[6:0];
wire [6:0] opcode_MEM;
assign opcode_MEM=instruction_MEM[6:0];
wire [6:0] opcode_WB;
assign opcode_WB=instruction_WB[6:0];
reg [4:0] rs1_EX,rs2_EX;
reg [4:0] rd_MEM,rd_WB;
//对之前的指令进行译码确定rd
always @(*) begin//对上一条指令译码，确认rd
    case (opcode_MEM)
        R_type:rd_MEM=instruction_MEM[11:7];
        I_type_ARITH:rd_MEM=instruction_MEM[11:7];
        I_type_LOAD:rd_MEM=instruction_MEM[11:7];
        S_type:rd_MEM=0; //STOR类指令没有rd
        default: rd_MEM=0;
    endcase
end
always @(*) begin//对上上条指令译码，确认rd
    case (opcode_WB)
        R_type:rd_WB=instruction_WB[11:7];
        I_type_ARITH:rd_WB=instruction_WB[11:7];
        I_type_LOAD:rd_WB=instruction_WB[11:7]; 
        S_type:rd_WB=0;//STOR类指令没有rd
        default:rd_WB=0;
    endcase
end
always @(*) begin//通过指令类型确定rs1,rs2
    case (opcode_EX)
        R_type:begin//当前在执行R型指令，需要rs1,rs2两个数参与运算
            rs1_EX=instruction_EX[19:15];
            rs2_EX=instruction_EX[24:20];
        end 
        I_type_ARITH:begin//当前在执行I型运算指令，只需要rs1
            rs1_EX=instruction_EX[19:15];
            rs2_EX=0;
        end
        S_type:begin//存储指令，需要数据rs2和基址rs1
            rs1_EX=instruction_EX[19:15];
            rs2_EX=instruction_EX[24:20];
        end
        B_type:begin//分支指令，需要数据rs1与rs2
            rs1_EX=instruction_EX[19:15];
            rs2_EX=instruction_EX[24:20];
        end
        default:begin
            rs1_EX=0;rs2_EX=0;
        end
    endcase
end
//bubble停机一周期控制电路
reg Bubble_clr;
always @(posedge clk or negedge rst_n) begin//暂停状态跳出模块
    if(!rst_n)Bubble_clr=0;
    else if(opcode_MEM==I_type_LOAD)Bubble_clr=1;
    else Bubble_clr=0;
end
always @(*) begin//暂停状态产生电路
    if(opcode_MEM==I_type_LOAD&&Bubble_clr==1'b0)begin//MEM阶段执行的指令为LOAD指令，第一个周期将进入本分支
        Bubble=1;//全部的中间寄存器停止数据传输
    end
    else begin
        Bubble=0;
    end
end

//rs1数据更新电路
always @(*) begin
    if(rs1_EX==rd_MEM&&rd_MEM!=0)begin
        if(opcode_MEM==S_type)begin
            data1_update=1;
            rs1_update_data=LOAD_data_MEM;
        end
        else begin
            data1_update=1;
            rs1_update_data=Result_MEM;
        end
    end
    else if(rs1_EX==rd_WB&&rd_WB!=0)begin
        data1_update=1;
        rs1_update_data=Result_WB;
    end
    else begin
        data1_update=0;
        rs1_update_data=0;
    end
end

//rs2数据更新电路
always @(*) begin
    if(rs2_EX==rd_MEM&&rd_MEM!=0)begin
        if(opcode_MEM==S_type)begin
            data2_update=1;
            rs2_update_data=LOAD_data_MEM;
        end
        else begin
            data2_update=1;
            rs2_update_data=Result_MEM;
        end
    end
    else if(rs2_EX==rd_WB&&rd_WB!=0)begin
        data2_update=1;
        rs2_update_data=Result_WB;
    end
    else begin
        data2_update=0;
        rs2_update_data=0;
    end
end
endmodule
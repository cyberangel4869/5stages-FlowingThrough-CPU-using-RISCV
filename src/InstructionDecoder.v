// 指令译码器
// 控制ALU的运算模式
/*imm_type含义：
00-无立即数
01-I/S型（立即数代表地址偏移，需要与rs1中的地址求和）
10-B型（用ALU判断rs1,rs2是否相等）
11-U/J型（立即数需要和PC求和得到新的程序指针）
*/
module InstructionDecoder (
    input [31:0] instruction,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] rd,
    output reg [31:0] imm,        // 立即数输出
    output reg [3:0] ALU_ctrl,
    output reg rs1_PC_select,
    output reg rs2_imm_select,
    output reg mem_re,//内存读使能
    output reg mem_we//内存写使能
);

wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode = instruction[6:0];
assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];

`include "opcodeList.vh"
`include "ALU_ctrl_list.vh"

always @(*) begin
    case (opcode)
        // R-type指令
        R_type: begin
            rs1 = instruction[19:15];
            rs2 = instruction[24:20];
            rd = instruction[11:7];
            imm=32'd0;
            rs1_PC_select=0;//rs1,rs2接入ALU
            rs2_imm_select=0;
            mem_re=0;
            mem_we=0;
            
            case (funct3)//funct7只有一位不同，可最后考虑
                // ADD/SUB
                3'b000: ALU_ctrl = (funct7[5]) ? OP_SUB : OP_ADD;
                // SLL
                3'b001: ALU_ctrl = OP_SLL;
                // SLT/SLTU,比较大小，用减法实现
                3'b010: ALU_ctrl = OP_SUB;
                3'b011: ALU_ctrl = OP_SUB;
                // XOR
                3'b100: ALU_ctrl = OP_XOR;
                // SRL/SRA
                3'b101: ALU_ctrl = (funct7[5]) ? OP_SRA : OP_SRL;
                // OR
                3'b110: ALU_ctrl = OP_OR;
                // AND
                3'b111: ALU_ctrl = OP_AND;
                default: ALU_ctrl = 4'b0;
            endcase
        end
        
        // I-type基本运算
        I_type_ARITH: begin
            rs1 = instruction[19:15];
            rs2 = 0;//立即数指令不需要rs2，指定为0，寄存器0里的数据恒为0
            rd = instruction[11:7];
            rs1_PC_select=0;//rs1和imm接入ALU
            rs2_imm_select=1;
            
            // 立即数符号扩展
            imm = {{20{instruction[31]}}, instruction[31:20]};
            mem_re=0;
            mem_we=0;
            
            case (funct3)
                3'b000: ALU_ctrl = OP_ADD;   // ADDI
                3'b001: ALU_ctrl = OP_SLL;   // SLLI
                3'b010: ALU_ctrl = OP_SUB;   // SLTI
                3'b011: ALU_ctrl = OP_SUB;  // SLTIU
                3'b100: ALU_ctrl = OP_XOR;   // XORI
                3'b101: ALU_ctrl = (funct7[5]) ? OP_SRA : OP_SRL;// SRLI/SRAI在funct7[5]区分
                3'b110: ALU_ctrl = OP_OR;    // ORI
                3'b111: ALU_ctrl = OP_AND;   // ANDI
                
                default: ALU_ctrl = 4'b0;
            endcase
        end
        
        // 加载指令LW
        I_type_LOAD: begin
            if (funct3 == 3'b010) begin  // LW
                rs1 = instruction[19:15];//rs1存放基地址
                rs2 = 0;
                rd = instruction[11:7];
                rs1_PC_select=0;//rs1基地址输入ALU
                rs2_imm_select=1;//立即数地址偏移量输入ALU
                //立即数合成，符号位扩展
                imm = {{20{instruction[31]}}, instruction[31:20]};
                ALU_ctrl = OP_ADD;  // 计算内存地址
                mem_re = 1;//RAM读使能有效
                mem_we=0;
            end
        end
        
        // 存储指令SW
        S_type: begin
            if (funct3 == 3'b010) begin  // SW
                rs1 = instruction[19:15];//rs1存放基地址
                rs2 = instruction[24:20];//rs2存放要写入内存的数据
                rd=0;
                rs1_PC_select=0;//rs1基地址输入ALU
                rs2_imm_select=1;//立即数地址偏移量输入ALU
                // S型立即数合成，由funct7和rd拼接而成，符号扩展
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                ALU_ctrl = OP_ADD;  // 加法计算内存地址
                mem_we= 1;//RAM写使能有效
                mem_re=0;
            end
        end
        
        // 分支指令
        B_type: begin
            mem_re=0;
            mem_we=0;
            if (funct3 == 3'b000) begin  // BEQ
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
                rs1_PC_select=0;//rs1和rs2进入ALU做减法
                rs2_imm_select=0;
                // B型立即数合成，按编码规则还原offset立即数，末位补0，符号位扩展
                imm = {{19{instruction[31]}}, instruction[31], instruction[7], 
                       instruction[30:25], instruction[11:8], 1'b0};
                ALU_ctrl = OP_SUB;  // 用减法比较是否相等
            end
            else if (funct3==3'b001) begin  //BNE
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
                rs1_PC_select=0;//rs1和rs2进入ALU做减法
                rs2_imm_select=0;
                // B型立即数合成，按编码规则还原offset立即数，末位补0，符号位扩展
                imm = {{20{instruction[31]}}, instruction[7], 
                       instruction[30:25], instruction[11:8], 1'b0};
                ALU_ctrl = OP_SUB;  // 用减法比较是否相等
            end
        end

        //无条件跳转并链接JAL
        J_type:begin
            rs1=0;
            rs2=0;
            rd=instruction[11:7];
            rs1_PC_select=1;//PC指针和立即数偏移量输入ALU做加法
            rs2_imm_select=1;
            imm[31:21]={11{instruction[31]}};//符号扩展
            imm[20]=instruction[31];
            imm[19:12]=instruction[19:12];
            imm[11]=instruction[20];
            imm[10:1]=instruction[30:21];
            imm[0]=1'b0;
            ALU_ctrl=OP_ADD;//最终地址是当前PC加imm
            mem_re=0;
            mem_we=0;
        end
        //跳转并链接寄存器JALR
        I_type_JALR:begin
            rs1 = instruction[19:15];
            rs2 = 0;//不需要rs2，指定为0，寄存器0里的数据恒为0
            rd = instruction[11:7];
            rs1_PC_select=0;//rs1基址输入ALU
            rs2_imm_select=1;//imm立即数偏移量输入ALU
            // 立即数符号扩展
            imm = {{20{instruction[31]}}, instruction[31:20]};
            mem_re=0;
            mem_we=0;
            ALU_ctrl=OP_ADD;//最终地址是rs1的数据加偏移量
        end
        default: begin
            rs1=0;rs2=0;imm=0;rs1_PC_select=0;rs2_imm_select=0;ALU_ctrl=0;rd=0;mem_re=0;mem_we=0;
        end
    endcase
end

endmodule
//更新于2026.2.24
/*
模块内连线太多，线的命名需遵循以下准则：
* 一个流水阶段占用芯片的一个区域，流水阶段之间用D触发器隔开以保证时序正确
* 所有不跨区域的内部连线，命名时都要加上线所在区域的缩写作为前缀
* D触发器组命名时，模块名由其前后两个阶段名拼接而成
* 控制信号的名字比它控制的模块名多一个_ctrl后缀
* 写回控制，forwarding控制等全局控制信号另外命名
*/

module CPU (
    input clk,
    input rst_n
);
//==========================全局控制信号====================================
wire Bubble;//停机一周期
wire [31:0] rs1_update_data,rs2_update_data;//需前传的数据
wire data1_update,data2_update;//数据前传控制
wire we;//写回寄存器控制
wire [31:0] wdata;//写回数据
wire [4:0] waddr;//写回寄存器地址
wire is_JBtype;//EX阶段运行指令是跳转类指令
wire jump;//需要跳转
wire [31:0] jump_PC;//分支指令自身的PC地址
wire [31:0] PC_predict;//预测的目标跳转PC值
wire PC_update;//更新PC寄存器的值
wire serch_en;//BTB搜索使能
wire clean;//指令冲刷，高有效，时钟上升沿清空IF-ID于ID-EX
wire [31:0] jump_dist;//目标跳转地址

//==========================IF=============================================
wire [31:0] IF_PC,IF_PC_add4;

PC_BTB pc_btb(
    .clk(clk),
    .rst_n(rst_n),
    .Bubble(Bubble),
    .PC_update(PC_update),
    .serch_en(serch_en),
    .jump_PC(jump_PC),
    .jump_dist(jump_dist),

    .PC(IF_PC),
    .PC_add4(IF_PC_add4)
);

wire [31:0] IF_instruction;
ROM ROM(
    .PC(IF_PC),
    .instruction(IF_instruction)
);

//=========================IF-ID==============================================
wire [31:0] ID_instruction,ID_PC_add4;
IF_ID_regs IF_ID(
    .clk(clk),
    .rst_n(rst_n),
    .Bubble(Bubble),
    .clean(clean),

    .IF_instruction(IF_instruction),
    .ID_instruction(ID_instruction),

    .IF_PC_add4(IF_PC_add4),
    .ID_PC_add4(ID_PC_add4)
);
//=========================ID==================================================
wire [4:0] ID_rs1,ID_rs2;
wire [31:0] ID_imm;
wire [3:0] ID_ALU_ctrl;
wire ID_rs1_PC_select,ID_rs2_imm_select;
wire ID_mem_re;
wire ID_mem_we;

SUBB4 predicPCsub4(
    .in(ID_PC_add4),
    .out(PC_predict)
);

InstructionDecoder IDU(
    .instruction(ID_instruction),
    .rs1(ID_rs1),
    .rs2(ID_rs2),

    .imm(ID_imm),
    .ALU_ctrl(ID_ALU_ctrl),
    .rs1_PC_select(ID_rs1_PC_select),
    .rs2_imm_select(ID_rs2_imm_select),

    .mem_re(ID_mem_re),
    .mem_we(ID_mem_we)
);

wire[31:0] ID_data1,ID_data2;
RegisterFile RF(
    .clk(clk),
    .rst_n(rst_n),

    .rs1(ID_rs1),
    .rdata1(ID_data1),

    .rs2(ID_rs2),
    .rdata2(ID_data2),

    .we(we),
    .waddr(waddr),
    .wdata(wdata)
);
//=============================ID-EX========================================
wire [31:0] EX_PC_add4,EX_instruction;
wire [31:0] EX_data1,EX_data2,EX_imm;
wire EX_rs1_PC_select,EX_rs2_imm_select;
wire [3:0] EX_ALU_ctrl;
wire EX_mem_re;
wire EX_mem_we;
ID_EX_regs ID_EX(
    .clk(clk),
    .rst_n(rst_n),
    .Bubble(Bubble),
    .clean(clean),

    .ID_PC_add4(ID_PC_add4),
    .EX_PC_add4(EX_PC_add4),

    .ID_instruction(ID_instruction),
    .EX_instruction(EX_instruction),

    .ID_data1(ID_data1),
    .EX_data1(EX_data1),

    .ID_data2(ID_data2),
    .EX_data2(EX_data2),

    .ID_imm(ID_imm),
    .EX_imm(EX_imm),

    .ID_rs1_PC_select(ID_rs1_PC_select),
    .EX_rs1_PC_select(EX_rs1_PC_select),

    .ID_rs2_imm_select(ID_rs2_imm_select),
    .EX_rs2_imm_select(EX_rs2_imm_select),

    .ID_ALU_ctrl(ID_ALU_ctrl),
    .EX_ALU_ctrl(EX_ALU_ctrl),

    .ID_mem_re(ID_mem_re),
    .EX_mem_re(EX_mem_re),

    .ID_mem_we(ID_mem_we),
    .EX_mem_we(EX_mem_we)
);
//====================================EX=======================================
wire [31:0] EX_ALU_data_A,EX_ALU_data_B,EX_rs1_update_data,EX_rs2_update_data;
wire [31:0] EX_Result,EX_PC;
wire EX_Zero,EX_Overflow,EX_Carry_out,EX_Negative;

SUBB4 jumpPCsub4(
    .in(EX_PC_add4),
    .out(jump_PC)
);

MUX rs1_data_MUX(//选择是否更新rs1的数据
    .select(data1_update),
    .in0(EX_data1),
    .in1(rs1_update_data),
    .out(EX_rs1_update_data)
);
MUX rs2_data_MUX(//选择是否更新rs2的数据
    .select(data2_update),
    .in0(EX_data2),
    .in1(rs2_update_data),
    .out(EX_rs2_update_data)
);
SUBB4 PC_sub4(
    .in(EX_PC_add4),
    .out(EX_PC)
);
MUX A_select(//从更新后的rs1数据和PC中选择输入ALU的数据
    .select(EX_rs1_PC_select),
    .in0(EX_rs1_update_data),
    .in1(EX_PC),
    .out(EX_ALU_data_A)
);
MUX B_select(//从更新后的rs2数据和imm中选择输入ALU的数据
    .select(EX_rs2_imm_select),
    .in0(EX_rs2_update_data),
    .in1(EX_imm),
    .out(EX_ALU_data_B)
);
ALU ALU(
    .A(EX_ALU_data_A),
    .B(EX_ALU_data_B),
    .ALU_ctrl(EX_ALU_ctrl),

    .Result(EX_Result),
    .Zero(EX_Zero),
    .Overflow(EX_Overflow),
    .Carry_out(EX_Carry_out),
    .Negative(EX_Negative)
);
JumpCtrlUnion JCU(
    .instruction(EX_instruction),
    .ALU_Zero(EX_Zero),
    .ALU_Result(EX_Result),
    .PC(EX_PC),
    .imm(EX_imm),
    .PC_predict(PC_predict),

    .jump(jump),
    .is_JBtype(is_JBtype),
    .PC_update(PC_update),
    .clean(clean),
    .jump_dist(jump_dist)

);
//====================================EX-MEM====================================
wire [31:0] MEM_instruction,MEM_PC_add4;
wire [31:0] MEM_Result;
wire [31:0] MEM_STOR_DATA;
wire MEM_mem_re;
wire MEM_mem_we;

EX_MEM_regs EX_MEM(
    .clk(clk),
    .rst_n(rst_n),
    .Bubble(Bubble),

    .EX_instruction(EX_instruction),
    .MEM_instruction(MEM_instruction),

    .EX_Result(EX_Result),
    .MEM_Result(MEM_Result),

    .EX_PC_add4(EX_PC_add4),
    .MEM_PC_add4(MEM_PC_add4),

    .EX_mem_re(EX_mem_re),
    .MEM_mem_re(MEM_mem_re),

    .EX_mem_we(EX_mem_we),
    .MEM_mem_we(MEM_mem_we),

    .EX_STOR_DATA(EX_rs2_update_data),//SW指令，rs2更新后的数据写入内存
    .MEM_STOR_DATA(MEM_STOR_DATA)
);
//==================================MEM==========================================
wire [31:0] MEM_LOAD_data;//内除读出数据
RAM RAM(
    .clk(clk),
    .rst_n(rst_n),

    .addr(MEM_Result),//ALU计算目标内存地址
    .cs(1'b0),//只用一片RAM，片选信号始终为0
    .mem_re(MEM_mem_re),
    .mem_we(MEM_mem_we),
    .mem_rdata(MEM_LOAD_data),//读出内存的数据
    .mem_wdata(MEM_STOR_DATA)//写入内存的数据
);
//=================================MEM-WB============================================
wire [31:0] WB_instruction;
wire [31:0] WB_Result,WB_PC_add4;
wire [31:0] WB_LOAD_data;
MEM_WB_regs MEM_WB(
    .clk(clk),
    .rst_n(rst_n),
    .Bubble(Bubble),

    .MEM_PC_add4(MEM_PC_add4),
    .WB_PC_add4(WB_PC_add4),

    .MEM_instruction(MEM_instruction),
    .WB_instruction(WB_instruction),

    .MEM_Result(MEM_Result),
    .WB_Result(WB_Result),

    .MEM_LOAD_data(MEM_LOAD_data),
    .WB_LOAD_data(WB_LOAD_data)

);
//=================================WB===============================================
WritebackControlLogic WBCL(
    .instruction(WB_instruction),
    .Result(WB_Result),
    .LOAD_data(WB_LOAD_data),
    .PC_add4(WB_PC_add4),

    .wdata(wdata),
    .waddr(waddr),
    .we(we)
);

//=============================ForwardingUnion======================================
ForwardingCtrlUnion FCU(
    .clk(clk),
    .rst_n(rst_n),
    .instruction_EX(EX_instruction),
    .instruction_MEM(MEM_instruction),
    .instruction_WB(WB_instruction),
    .Result_MEM(MEM_Result),
    .Result_WB(WB_Result),
    .LOAD_data_MEM(MEM_LOAD_data),

    .data1_update(data1_update),
    .data2_update(data2_update),
    .rs1_update_data(rs1_update_data),
    .rs2_update_data(rs2_update_data),
    .Bubble(Bubble)
);

//================================BHT==========================================
BHT BHT(
    .clk(clk),
    .rst_n(rst_n),
    .is_JBtype(is_JBtype),
    .jump(jump),
    .serch_en(serch_en)
);
endmodule
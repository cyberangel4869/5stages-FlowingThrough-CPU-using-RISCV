module ID_EX_regs (
    input clk,
    input rst_n,
    input Bubble,//有效时停止数据传输
    input clean,//有效时清空指令
    
    input [31:0] ID_PC_add4,
    output reg [31:0] EX_PC_add4,

    input [31:0] ID_instruction,
    output reg [31:0] EX_instruction,

    input [31:0] ID_data1,
    output reg [31:0] EX_data1,

    input [31:0] ID_data2,
    output reg [31:0] EX_data2,

    input [31:0] ID_imm,
    output reg [31:0] EX_imm,

    input ID_rs1_PC_select,
    output reg EX_rs1_PC_select,

    input ID_rs2_imm_select,
    output reg EX_rs2_imm_select,

    input [3:0] ID_ALU_ctrl,
    output reg [3:0] EX_ALU_ctrl,

    input ID_mem_re,
    output reg EX_mem_re,

    input ID_mem_we,
    output reg EX_mem_we


);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        EX_ALU_ctrl<=0;
        EX_data1<=0;
        EX_data2<=0;
        EX_imm<=0;
        EX_rs1_PC_select<=0;
        EX_rs2_imm_select<=0;
        EX_instruction<=0;
        EX_PC_add4<=0;
        EX_mem_re<=0;
        EX_mem_we<=0;
    end
    else begin
        if(!Bubble)begin
            if(clean)begin
                EX_ALU_ctrl<=0;
                EX_data1<=0;
                EX_data2<=0;
                EX_imm<=0;
                EX_rs1_PC_select<=0;
                EX_rs2_imm_select<=0;
                EX_instruction<=0;
                EX_PC_add4<=0;
                EX_mem_re<=0;
                EX_mem_we<=0;
            end
            else begin 
            EX_ALU_ctrl<=ID_ALU_ctrl;
            EX_data1<=ID_data1;
            EX_data2<=ID_data2;
            EX_imm<=ID_imm;
            EX_rs1_PC_select<=ID_rs1_PC_select;
            EX_rs2_imm_select<=ID_rs2_imm_select;
            EX_instruction<=ID_instruction;
            EX_PC_add4<=ID_PC_add4;
            EX_mem_re<=ID_mem_re;
            EX_mem_we<=ID_mem_we;
            end 
        end
    end
end
endmodule
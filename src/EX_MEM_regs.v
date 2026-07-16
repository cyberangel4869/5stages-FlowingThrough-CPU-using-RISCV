module EX_MEM_regs (
    input clk,
    input rst_n,
    input Bubble,

    input [31:0] EX_instruction,
    output reg [31:0] MEM_instruction,

    input [31:0] EX_Result,
    output reg [31:0] MEM_Result,

    input [31:0] EX_PC_add4,
    output reg [31:0] MEM_PC_add4,

    input EX_mem_re,
    output reg MEM_mem_re,

    input EX_mem_we,
    output reg MEM_mem_we,

    input [31:0] EX_STOR_DATA,
    output reg [31:0] MEM_STOR_DATA
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        MEM_instruction<=0;
        MEM_PC_add4<=0;
        MEM_Result<=0;
        MEM_mem_re<=0;
        MEM_mem_we<=0;
        MEM_STOR_DATA<=0;
    end
    else begin
        if(!Bubble)begin
            MEM_instruction<=EX_instruction;
            MEM_Result<=EX_Result;
            MEM_PC_add4<=EX_PC_add4;
            MEM_mem_we<=EX_mem_we;
            MEM_mem_re<=EX_mem_re;
            MEM_STOR_DATA<=EX_STOR_DATA;
        end
    end
end
endmodule
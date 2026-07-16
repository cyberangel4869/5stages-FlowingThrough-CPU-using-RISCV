module MEM_WB_regs (
    input clk,
    input rst_n,
    input Bubble,

    input [31:0] MEM_PC_add4,
    output reg [31:0] WB_PC_add4,

    input [31:0] MEM_instruction,
    output reg [31:0] WB_instruction,

    input [31:0] MEM_Result,
    output reg [31:0] WB_Result,

    input [31:0] MEM_LOAD_data,
    output reg [31:0] WB_LOAD_data
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        WB_instruction<=0;
        WB_LOAD_data<=0;
        WB_Result<=0;
        WB_PC_add4<=0;
    end
    else begin
        if(!Bubble)begin
            WB_instruction<=MEM_instruction;
            WB_LOAD_data<=MEM_LOAD_data;
            WB_Result<=MEM_Result;
            WB_PC_add4<=MEM_PC_add4;
        end
    end
end
endmodule
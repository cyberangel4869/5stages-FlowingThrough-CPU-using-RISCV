module ROM (
    input [31:0] PC,
    output reg [31:0] instruction
);
reg [31:0] rom [0:255];

//========================从ROM_data.hex文件中读入ROM数据=================
initial begin
    $readmemh("ROM_data.hex",rom,0,255);
end
//=======================================================================


always @(PC) begin
    instruction=rom[PC/4];//4个8bit寄存器组成一个指令存储单元
end
endmodule
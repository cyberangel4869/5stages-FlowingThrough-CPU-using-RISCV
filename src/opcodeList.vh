localparam R_type = 7'b011_0011;
localparam I_type_ARITH = 7'b001_0011;//基本运算型
localparam I_type_LOAD = 7'b000_0011;//LOAD型，LW
localparam I_type_JALR = 7'b110_0111;//跳转型，JALR
localparam S_type = 7'b010_0011;//储存型，SW
localparam B_type = 7'b110_0011;//分支指令,BEQ,BNE
localparam J_type = 7'b110_1111;//跳转指令，JAL
module MUX_A (
    input A_forward,//Forwarding Union判断A的数据存在指令冲突
    input [1:0] imm_type,//IDU生成的立即数类型
    input [31:0] data1,//rs1寄存器中的数据
    input [31:0] PC,//程序指针PC+4
    input [31:0] forwarding_data_A,//ForwardiongUnion传递的数据
    output reg [31:0] ALU_data_A
);
always @(*) begin
    if(A_forward)ALU_data_A=forwarding_data_A;
    else begin
        case (imm_type)
            2'b00:ALU_data_A=data1;//无立即数，直接传递寄存器数据
            2'b01:ALU_data_A=data1;//I型指令的立即数由B接收，A依然接收rs1的数据
            2'b10:ALU_data_A=data1;//B型指令，由ALU做减法判断是否跳转
            2'b11:ALU_data_A=PC-3'd4;//J型跳转指令，立即数接入B，当前指针接入A
            default: ALU_data_A=0;
        endcase
    end
end
endmodule
module MUX_B (
    input B_forward,//Forwarding Union判断A的数据存在指令冲突
    input [1:0] imm_type,//IDU生成的立即数类型
    input [31:0] data2,//rs1寄存器中的数据
    input [31:0] imm,
    input [31:0] forwarding_data_B,//ForwardiongUnion传递的数据
    output reg [31:0] ALU_data_B
);
always @(*) begin
    if(B_forward)ALU_data_B=forwarding_data_B;
    else begin
        case (imm_type)
            2'b00:ALU_data_B=data2;//无立即数，直接传递寄存器数据
            2'b01:ALU_data_B=imm;//I型指令的立即数由B接收
            2'b10:ALU_data_B=data2;//B型指令，ALU减法判断是否跳转，rs2传入B
            2'b11:ALU_data_B=imm;//J型跳转指令，立即数接入B，当前指针接入A
            default: ALU_data_B=0;
        endcase
    end
end
endmodule
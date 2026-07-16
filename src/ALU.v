module ALU (
    input [31:0] A,        // 32位有符号输入A
    input [31:0] B,        // 32位有符号输入B
    input [3:0] ALU_ctrl,  // 4位ALU控制信号
    output reg [31:0] Result, // 32位结果输出
    output reg Zero,       // 结果为零标志
    output reg Overflow,   // 溢出标志
    output reg Carry_out,  // 进位/借位标志
    output reg Negative    // 负标志
);

    // 内部临时信号
    reg [32:0] temp_result; // 33位用于检测溢出和进位
    reg [31:0] slt_result;  // 用于有符号比较
    
    // ALU操作编码定义
    localparam [3:0]
        OP_ADD      = 4'b0000,  // 加法 A + B
        OP_SUB      = 4'b0001,  // 减法 A - B
        OP_AND      = 4'b0010,  // 按位与 A & B
        OP_OR       = 4'b0011,  // 按位或 A | B
        OP_XOR      = 4'b0100,  // 按位异或 A ^ B
        OP_NOR      = 4'b0101,  // 按位或非 ~(A | B)
        OP_SLT      = 4'b0110,  // 有符号小于设置 (A < B) ? 1 : 0
        OP_SLL      = 4'b0111,  // 逻辑左移 A << B[4:0]
        OP_SRL      = 4'b1000,  // 逻辑右移 A >> B[4:0]
        OP_SRA      = 4'b1001,  // 算术右移 A >>> B[4:0]
        OP_LUI      = 4'b1010,  // 加载高位立即数 {B[15:0], 16'b0}
        OP_EQ       = 4'b1011,  // 等于比较 (A == B) ? 1 : 0
        OP_NE       = 4'b1100,  // 不等于比较 (A != B) ? 1 : 0
        OP_MAX      = 4'b1101,  // 取最大值 max(A, B)
        OP_MIN      = 4'b1110,  // 取最小值 min(A, B)
        OP_NOT      = 4'b1111;  // 按位取反 ~A

    // 移位量（只使用B的低5位，支持0-31位移位）
    wire [4:0] shift_amount = B[4:0];

    always @(*) begin
        // 初始化标志位
        Zero = 1'b0;
        Overflow = 1'b0;
        Carry_out = 1'b0;
        Negative = 1'b0;
        temp_result = 33'b0;
        
        case (ALU_ctrl)
            // 加法操作
            OP_ADD: begin
                temp_result = {A[31], A} + {B[31], B};
                Result = temp_result[31:0];
                Carry_out = temp_result[32];
                // 有符号溢出检测：正+正得负 或 负+负得正
                Overflow = (A[31] == B[31]) && (Result[31] != A[31]);
                Negative=Result[31];
            end
            
            // 减法操作
            OP_SUB: begin
                temp_result = {A[31], A} - {B[31], B};
                Result = temp_result[31:0];
                Carry_out = temp_result[32];
                // 有符号溢出检测：正-负得负 或 负-正得正
                Overflow = (A[31] != B[31]) && (Result[31] != A[31]);
            end
            
            // 按位与
            OP_AND: begin
                Result = A & B;
                Negative = Result[31];
            end
            
            // 按位或
            OP_OR: begin
                Result = A | B;
                Negative = Result[31];
            end
            
            // 按位异或
            OP_XOR: begin
                Result = A ^ B;
                Negative = Result[31];
            end
            
            // 按位或非
            OP_NOR: begin
                Result = ~(A | B);
                Negative = Result[31];
            end
            
            // 有符号小于设置（Set Less Than）
            OP_SLT: begin
                slt_result = A - B;
                // 如果A<B（有符号比较），结果为1，否则为0
                Result = (A[31] && ~B[31]) ||  // A负B正
                         (A[31] == B[31] && slt_result[31]) ? 32'd1 : 32'd0;
            end
            
            // 逻辑左移
            OP_SLL: begin
                Result = A << shift_amount;
                Negative = Result[31];
            end
            
            // 逻辑右移
            OP_SRL: begin
                Result = A >> shift_amount;
                Negative = Result[31];
            end
            
            // 算术右移（保持符号位）
            OP_SRA: begin
                Result = $signed(A) >>> shift_amount;
                Negative = Result[31];
            end
            
            // 加载高位立即数（用于LUI指令）
            OP_LUI: begin
                Result = {B[15:0], 16'b0};
                Negative = Result[31];
            end
            
            // 等于比较
            OP_EQ: begin
                Result = (A == B) ? 32'd1 : 32'd0;
            end
            
            // 不等于比较
            OP_NE: begin
                Result = (A != B) ? 32'd1 : 32'd0;
            end
            
            // 取最大值（有符号）
            OP_MAX: begin
                if ($signed(A) > $signed(B))
                    Result = A;
                else
                    Result = B;
                Negative = Result[31];
            end
            
            // 取最小值（有符号）
            OP_MIN: begin
                if ($signed(A) < $signed(B))
                    Result = A;
                else
                    Result = B;
                Negative = Result[31];
            end
            
            // 按位取反
            OP_NOT: begin
                Result = ~A;
                Negative = Result[31];
            end
            
            default: begin
                Result = 32'b0;
            end
        endcase
        
        // 设置Zero标志（结果全为0）
        Zero = (Result == 32'b0);
    end

endmodule

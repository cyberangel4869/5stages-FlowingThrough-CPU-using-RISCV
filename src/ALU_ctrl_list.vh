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
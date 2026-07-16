// ============================================================
// RISC-V 寄存器文件（Register File）
// 32个32位寄存器，x0固定为0
// 支持：2读端口 + 1写端口
// 支持同一时钟周期内的先写后读（Write-First 行为）
// ============================================================

module RegisterFile (
    input wire clk,           // 时钟
    input wire rst_n,         // 异步复位，低有效
    
    // 读端口1
    input wire [4:0] rs1,  // 读地址1
    output reg [31:0] rdata1, // 读数据1
    
    // 读端口2  
    input wire [4:0] rs2,  // 读地址2
    output reg [31:0] rdata2, // 读数据2
    
    // 写端口
    input wire we,            // 写使能
    input wire [4:0] waddr,   // 写地址
    input wire [31:0] wdata,   // 写数据

    output wire [31:0] x_0,
    output wire [31:0] x_1,
    output wire [31:0] x_2,
    output wire [31:0] x_3,
    output wire [31:0] x_4,
    output wire [31:0] x_5,
    output wire [31:0] x_6,
    output wire [31:0] x_7,
    output wire [31:0] x_8,
    output wire [31:0] x_9
);

// ============================================================
// 寄存器定义
// ============================================================
reg [31:0] registers [0:31];  // 32个32位寄存器
assign x_0=registers[0];
assign x_1=registers[1];
assign x_2=registers[2];
assign x_3=registers[3];
assign x_4=registers[4];
assign x_5=registers[5];
assign x_6=registers[6];
assign x_7=registers[7];
assign x_8=registers[8];
assign x_9=registers[9];

integer i;

// ============================================================
// 写操作（同步，时钟上升沿触发）
// ============================================================
always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 异步复位：所有寄存器清零（包括x0，虽然x0总是读为0）
        for (i = 0; i < 32; i = i + 1) begin
            if(i!=2)registers[i] <= 32'b0;
            else registers[2]<=32'h7FFFFFF0;
        end
    end
    else if (we && (waddr != 5'b0)) begin
        // 写使能有效且目标地址不是x0（x0只读，永远为0）
        registers[waddr] <= wdata;
    end
end

// ============================================================
// 读操作1（组合逻辑 + 写前传）
// ============================================================
always @(*) begin
    if (!rst_n) begin
        rdata1 = 32'b0;
    end
    else if (rs1 == 5'b0) begin
        // x0寄存器永远返回0
        rdata1 = 32'b0;
    end
    else if (we && (waddr == rs1)) begin
        // 先写后读：如果正在写入同一地址，直接返回要写入的数据
        rdata1 = wdata;
    end
    else begin
        // 正常读操作
        rdata1 = registers[rs1];
    end
end

// ============================================================
// 读操作2（组合逻辑 + 写前传）
// ============================================================
always @(*) begin
    if (!rst_n) begin
        rdata2 = 32'b0;
    end
    else if (rs2 == 5'b0) begin
        // x0寄存器永远返回0
        rdata2 = 32'b0;
    end
    else if (we && (waddr == rs2)) begin
        // 先写后读：如果正在写入同一地址，直接返回要写入的数据
        rdata2 = wdata;
    end
    else begin
        // 正常读操作
        rdata2 = registers[rs2];
    end
end


// ============================================================
// 监视模块：寄存器数据显示于REG_data.log文件
// ============================================================
integer reg_file;
integer cycle_count;

initial begin
    reg_file = $fopen("REG_data.log", "w");
    if (reg_file) begin
        // 写入格式化的表头
        $fwrite(reg_file,"|-Cycles-");
        for (i = 0; i < 32; i = i + 1) begin
            if(i<=9)$fwrite(reg_file, "|---x%0d---", i);
            else $fwrite(reg_file,"|---x%0d--",i);
        end
        $fwrite(reg_file,"\n");
    end
end

always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            cycle_count<=0;
        end
        else begin
        if (reg_file) begin
            // 写入周期数和16个寄存器值（十六进制格式）
            // 写入所有32个寄存器
            cycle_count<=cycle_count+1;
            $fwrite(reg_file,"%9d",cycle_count);
            for (i = 0; i < 32; i = i + 1) begin
                $fwrite(reg_file, " %h", registers[i]);
            end
            $fwrite(reg_file,"\n");
        end
        end
end

endmodule
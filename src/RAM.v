
// Memory simulation, support LW/SW instructions, 4-byte addressing
module RAM (
    input clk,
    input rst_n,

    input [31:0] addr,        // address
    input cs,                  // chip select, low active
    input mem_re,              // read enable
    output reg [31:0] mem_rdata,
    input mem_we,              // write enable
    input [31:0] mem_wdata,

    output [31:0] ram_0x00,
    output [31:0] ram_0x01,
    output [31:0] ram_0x02,
    output [31:0] ram_0x03,
    output [31:0] ram_0x04,
    output [31:0] ram_0x05,
    output [31:0] ram_0x06,
    output [31:0] ram_0x07,
    output [31:0] ram_0x08,
    output [31:0] ram_0x09,
    output [31:0] ram_0x0a
);
reg [31:0] ram [0:255];
assign ram_0x00=ram[0];
assign ram_0x01=ram[1];
assign ram_0x02=ram[2];
assign ram_0x03=ram[3];
assign ram_0x04=ram[4];
assign ram_0x05=ram[5];
assign ram_0x06=ram[6];
assign ram_0x07=ram[7];
assign ram_0x08=ram[8];
assign ram_0x09=ram[9];
assign ram_0x0a=ram[10];
integer m;
always @(negedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(m=0;m<256;m++)begin
            ram[m]<=32'b0;
        end
    end
    else if(mem_re)begin
        mem_rdata<=ram[addr];
    end
    else if(mem_we)begin
        ram[addr]<=mem_wdata;
    end
end


// ============================================================
// 监视模块：内存数据显示于RAM_data.log文件
// ============================================================
integer ram_file;
integer cycle_count;
reg [7:0] i;

initial begin
    ram_file = $fopen("RAM_data.log", "w");
    if (ram_file) begin
        // 写入格式化的表头
        $fwrite(ram_file,"|-Cycles-");
        for (i = 0; i < 32; i = i + 1) begin
            $fwrite(ram_file,"|--0x%02h--",i);
        end
        $fwrite(ram_file,"\n");
    end
end

always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            cycle_count<=0;
        end
        else begin
        if (ram_file) begin
            // 写入周期数和16个寄存器值（十六进制格式）
            // 写入所有32个寄存器
            cycle_count<=cycle_count+1;
            $fwrite(ram_file,"%9d",cycle_count);
            for (i = 0; i < 32; i = i + 1) begin
                $fwrite(ram_file, " %h", ram[i]);
            end
            $fwrite(ram_file,"\n");
        end
        end
end
endmodule
module PC_BTB (
    input clk,
    input rst_n,
    input Bubble,
    input PC_update,
    input serch_en,
    input [31:0] jump_PC,
    input [31:0] jump_dist,
    output reg [31:0] PC,
    output [31:0] PC_add4
);
    assign PC_add4 = PC + 3'd4;
    
    wire [7:0] index;
    assign index = PC[9:2];
    
    reg [21:0] tag [0:255];
    reg [31:0] target [0:255];
    
    wire [21:0] PC_tag;
    assign PC_tag = PC[31:10];
    
    wire BTB_hit;
    assign BTB_hit = ((tag[index] == PC_tag) && (target[index] != 0));
    
    // PC 更新逻辑 - 使用组合逻辑计算下一个 PC
    wire [31:0] next_PC;
    assign next_PC = PC_update ? jump_dist :
                    (serch_en && BTB_hit) ? target[index] :
                    PC + 3'd4;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            PC <= 32'd0;
        end
        else if(!Bubble) begin
            PC <= next_PC;  // 只在非气泡时更新
        end
    end
    
    // BTB 更新逻辑
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i = 0; i < 256; i = i + 1) begin
                tag[i] <= 0;
                target[i] <= 0;
            end
        end
        else if(PC_update) begin
            tag[jump_PC[9:2]] <= jump_PC[31:10];
            target[jump_PC[9:2]] <= jump_dist;  // 存储跳转目标
        end
    end
    
endmodule
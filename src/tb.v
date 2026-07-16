`timescale 1ns/1ps
module tb ();
reg clk;
reg rst_n;
CPU cpu(
    .clk(clk),
    .rst_n(rst_n)
);

initial begin
    $dumpfile("wave.vcd");    // 指定输出的波形文件名
    $dumpvars(0, tb); 
    clk=0;rst_n=1;
    #10 rst_n=0;
    #10 rst_n=1;
    #100000 $finish;
end
initial begin
    forever begin
        #50 clk=~clk;
    end
end

integer PC_file,Cycles;
initial begin
    PC_file=$fopen("./Printer_data.log");
    if(PC_file)begin
        $fwrite(PC_file,"|-Cycles-|---IF---|---ID---|---EX---|---MEM--|---WB---|\n");
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)Cycles<=0;
    else begin
        Cycles<=Cycles+1;
        $fwrite(PC_file,"%9d",Cycles);
        $fwrite(PC_file," %h",cpu.IF_PC_add4);
        $fwrite(PC_file," %h",cpu.ID_PC_add4);
        $fwrite(PC_file," %h",cpu.EX_PC_add4);
        $fwrite(PC_file," %h",cpu.MEM_PC_add4);
        $fwrite(PC_file," %h\n",cpu.WB_PC_add4);
    end
end

endmodule
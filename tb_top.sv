`timescale 1ns/1ps
module tb_top;

    reg  clk_50 = 0;
    reg  rst_n  = 0;
    wire [3:0] led;

    always #10 clk_50 = ~clk_50;   // 50 МГц = период 20 нс

    top_cyclone dut (
        .clk_50(clk_50),
        .rst_n (rst_n),
        .led   (led)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
        repeat(5) @(posedge clk_50);
        rst_n = 1;
        repeat(2000) @(posedge clk_50);
        $finish;
    end

endmodule
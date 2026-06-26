`timescale 1ns/1ps
module tb_sim;

    reg clk = 0;
    reg rst_n = 0;
    wire [3:0] led;

    always #10 clk = ~clk;

    top_cyclone dut (
        .clk_50(clk),
        .rst_n (rst_n),
        .led   (led)
    );

    initial begin
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5000) @(posedge clk);
        $finish;
    end

endmodule
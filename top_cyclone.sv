module top_cyclone (
    input  wire       clk_50,
    input  wire       rst_n,
    output reg  [3:0] led
);
    localparam NUM_M  = 4;
    localparam PERIOD = 50;

    wire [NUM_M-1:0]      in_valid;
    wire [NUM_M-1:0][7:0] in_data;
    wire [NUM_M-1:0]      in_ready;
    wire                  out_valid;
    wire [7:0]            out_data;

    reg [31:0]      counter;
    reg [1:0]       master_sel;
    reg [NUM_M-1:0] in_valid_r;
    reg [7:0]       in_data_r [0:NUM_M-1];

    integer k;
    always @(posedge clk_50 or negedge rst_n) begin
        if (!rst_n) begin
            counter    <= 0;
            master_sel <= 0;
            in_valid_r <= 0;
            for (k = 0; k < NUM_M; k = k + 1)
                in_data_r[k] <= 8'h00;
        end else begin
            if (counter >= PERIOD - 1) begin
                counter <= 0;
                if (!in_valid_r[master_sel]) begin
                    in_valid_r[master_sel] <= 1'b1;
                    in_data_r[master_sel]  <= {6'b0, master_sel} + 8'h01;
                    master_sel             <= master_sel + 1;
                end
            end else begin
                counter <= counter + 1;
            end

            for (k = 0; k < NUM_M; k = k + 1)
                if (in_valid_r[k] && in_ready[k] &&
                    !(counter >= PERIOD-1 && master_sel == k))
                    in_valid_r[k] <= 1'b0;
        end
    end

    genvar g;
    generate
        for (g = 0; g < NUM_M; g = g + 1) begin : gen_assign
            assign in_valid[g] = in_valid_r[g];
            assign in_data[g]  = in_data_r[g];
        end
    endgenerate

    top #(
        .DATA_WIDTH (8),
        .FIFO_DEPTH (16),
        .NUM_MASTERS(NUM_M)
    ) u_top (
        .clk      (clk_50),
        .rst_n    (rst_n),
        .in_valid (in_valid),
        .in_data  (in_data),
        .in_ready (in_ready),
        .out_valid(out_valid),
        .out_data (out_data),
        .out_ready(1'b1)
    );

    always @(posedge clk_50 or negedge rst_n) begin
        if (!rst_n) begin
            led <= 4'b0;
        end else if (out_valid) begin
            led <= 4'b0;
            led[out_data[1:0]] <= 1'b1;
        end
    end

endmodule
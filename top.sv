module top #(
    parameter DATA_WIDTH  = 8,
    parameter FIFO_DEPTH  = 16,
    parameter NUM_MASTERS = 4
)(
    input  wire                                       clk,
    input  wire                                       rst_n,

    input  wire [NUM_MASTERS-1:0]                     in_valid,
    input  wire [NUM_MASTERS-1:0][DATA_WIDTH-1:0]     in_data,
    output wire [NUM_MASTERS-1:0]                     in_ready,

    output reg                                        out_valid,
    output reg  [DATA_WIDTH-1:0]                      out_data,
    input  wire                                       out_ready
);
    wire [NUM_MASTERS-1:0]                   fifo_empty;
    wire [NUM_MASTERS-1:0]                   fifo_rd_valid;
    wire [NUM_MASTERS-1:0][DATA_WIDTH-1:0]   fifo_rdata;
    wire [NUM_MASTERS-1:0]                   grant;

    // rd_ready для каждого FIFO: читаем только победителя гранта
    // и только когда выходной интерфейс принимает данные (или выход свободен)
    wire do_read;
    assign do_read = out_ready || !out_valid;   // можно поставить новые данные

    wire [NUM_MASTERS-1:0] fifo_rd_en;

    genvar i;
    generate
        for (i = 0; i < NUM_MASTERS; i = i + 1) begin : gen_fifo
            assign fifo_rd_en[i] = grant[i] && do_read;

            fifo #(
                .WIDTH (DATA_WIDTH),
                .DEPTH (FIFO_DEPTH)
            ) u_fifo (
                .clk      (clk),
                .rst_n    (rst_n),
                .wr_valid (in_valid[i]),
                .wr_data  (in_data[i]),
                .wr_ready (in_ready[i]),
                .rd_valid (fifo_rd_valid[i]),
                .rd_data  (fifo_rdata[i]),
                .rd_ready (fifo_rd_en[i]),
                .empty    (fifo_empty[i]),
                .full     ()
            );
        end
    endgenerate

    arbiter #(.NUM_REQ(NUM_MASTERS)) u_arb (
        .clk   (clk),
        .rst_n (rst_n),
        .req   (~fifo_empty),
        .grant (grant)
    );

    // Регистровый выход — стабилен для Cyclone V
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data  <= '0;
        end else begin
            if (do_read) begin
                out_valid <= |grant;
                out_data  <= '0;
                for (j = 0; j < NUM_MASTERS; j = j + 1)
                    if (grant[j])
                        out_data <= fifo_rdata[j];
            end
        end
    end

endmodule
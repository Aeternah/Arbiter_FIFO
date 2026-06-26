module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire             clk,
    input  wire             rst_n,

    // Write port
    input  wire             wr_valid,
    input  wire [WIDTH-1:0] wr_data,
    output wire             wr_ready,   // == !full

    // Read port
    output wire             rd_valid,   // == !empty
    output wire [WIDTH-1:0] rd_data,
    input  wire             rd_ready,   // consumer pulls data

    output wire             empty,
    output wire             full
);
    localparam ADDR = $clog2(DEPTH);

    // Запрещаем использовать M10K-блоки (для симуляции в ModelSim)
    (* ramstyle = "logic" *) reg [WIDTH-1:0] mem [0:DEPTH-1];

    reg [ADDR:0]    wr_ptr, rd_ptr;     // extra bit для детекта full/empty

    wire do_write = wr_valid && wr_ready;
    wire do_read  = rd_valid && rd_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (do_write) begin
                mem[wr_ptr[ADDR-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1;
            end
            if (do_read)
                rd_ptr <= rd_ptr + 1;
        end
    end

    assign empty    = (wr_ptr == rd_ptr);
    assign full     = (wr_ptr[ADDR] != rd_ptr[ADDR]) &&
                      (wr_ptr[ADDR-1:0] == rd_ptr[ADDR-1:0]);
    assign wr_ready = !full;
    assign rd_valid = !empty;
    assign rd_data  = mem[rd_ptr[ADDR-1:0]];

endmodule
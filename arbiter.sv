// Round-robin арбитр с корректным движением pointer
// pointer указывает на СЛЕДУЮЩЕГО кандидата после последнего гранта
module arbiter #(
    parameter NUM_REQ = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [NUM_REQ-1:0]       req,
    output reg  [NUM_REQ-1:0]       grant
);
    localparam PTR = $clog2(NUM_REQ);

    reg [PTR-1:0] pointer;

    // Комбинационный priority encoder, стартующий с pointer
    function automatic [NUM_REQ-1:0] round_robin;
        input [NUM_REQ-1:0]  r;
        input [PTR-1:0]      start;
        integer k;
        begin
            round_robin = 0;
            for (k = 0; k < NUM_REQ; k = k + 1) begin
                automatic int idx = (start + k) % NUM_REQ;
                if (r[idx] && round_robin == 0)
                    round_robin[idx] = 1'b1;
            end
        end
    endfunction

    reg [NUM_REQ-1:0] next_grant;
    reg [PTR-1:0]     next_ptr;
    integer j;

    always @(*) begin
        next_grant = round_robin(req, pointer);
        // pointer двигается на позицию ПОСЛЕ выбранного гранта
        next_ptr = pointer;
        for (j = 0; j < NUM_REQ; j = j + 1)
            if (next_grant[j])
                next_ptr = (j + 1) % NUM_REQ;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant   <= '0;
            pointer <= '0;
        end else begin
            if (|req) begin
                grant   <= next_grant;
                pointer <= next_ptr;
            end else begin
                grant <= '0;
                // pointer не сбрасываем — помним очередь
            end
        end
    end

endmodule
module fsm (
    input logic clk,
    input logic reset,
    input int data [4],
    output int o
);

    typedef enum int unsigned { S0 = 0, S1 = 2, S2 = 4, S3 = 8 } state_t;
    state_t state, next_state;

    always_ff @(posedge clk or negedge reset) begin
        if(~reset)
            state <= S0;
        else
            state <= next_state;
    end

    always_comb begin : next_state_logic
        case (state)
            S0: begin
                next_state = S1;
            end S1: begin
                next_state = S2;
            end S2: begin
                next_state = S3;
            end S3: begin
                next_state = S3;
            end default: begin
                next_state = S0;
            end
        endcase
    end

    always_comb begin
        case (state)
            S0: o = data[0];
            S1: o = data[1];
            S2: o = data[2];
            S3: o = data[3];
        endcase
    end

endmodule
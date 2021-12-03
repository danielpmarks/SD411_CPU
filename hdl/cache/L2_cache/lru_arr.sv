module lru_arr_l2 (
    input clk,
    input load,
    input [1:0] mru,
    output [1:0] lru_index
);
logic [1:0] queue [3:0] = '{3, 2, 1, 0};
logic [1:0] queue_in [3:0];
logic [3:0] shift;
assign lru_index = queue[0];
always_comb begin
    queue_in = queue;
    if (load) begin
        for (int i = 3; i > 0; i--) begin
            if (shift[i-1]) begin
                queue_in[i-1] = queue[i];
            end
        end
        queue_in[3] = mru;            
    end 
end

always_comb begin
    shift = '0;
    if (queue[0] == mru) begin
        shift[0] = 1'b1;
    end 
    for (int i = 1; i < 4; i++) begin
        if ((queue[i] == mru) || shift[i-1]) begin
            shift[i] = 1'b1;
        end 
    end
end

always_ff @(posedge clk) begin
    queue <= queue_in;
end
endmodule : lru_arr_l2
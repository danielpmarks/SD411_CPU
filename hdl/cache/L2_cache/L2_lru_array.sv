module L2_lru_array (
    input clk,
    input load,
    input [2:0] index,
    input [1:0] mru,
    output [1:0] lru_out
);

logic [7:0] i_load, i_load_in;
logic [1:0] i_mru, i_mru_in;
logic [1:0] i_out [7:0];
assign i_mru_in = mru;
assign lru_out = i_out[index];
lru_arr_l2 arr [7:0] (
	.clk(clk),
	.load(i_load),
	.mru(i_mru),
	.lru_index(i_out)
);

always_comb begin
    i_load_in = '0;
    i_load_in[index] = load;
end

always_ff @(posedge clk) begin
    i_load <= i_load_in;
    i_mru <= i_mru_in;
end

endmodule : L2_lru_array
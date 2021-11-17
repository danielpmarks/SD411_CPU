/* A special register array specifically for your
data arrays. This module supports a write mask to
help you update the values in the array. */

module icache_data_array (
  input clk,
  input logic [31:0] load,
  input logic [2:0] rindex,
  input logic [2:0] windex,
  input logic [255:0] datain,
  output logic [255:0] dataout
);

logic [255:0] data [8] = '{default: '0};

always_comb begin
  dataout = (load & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk) begin
	data[windex] <= load ? datain : data[windex];  
end

endmodule : data_array



module btb_array #(parameter width = 1, parameter bits = 5)
(
  input clk,
  input rst,
  input logic load,
  input logic [bits-1:0] rindex,
  input logic [bits-1:0] windex,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

logic [width-1:0] data [2**bits];

always_comb begin
  dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk)
begin
  if(rst) begin
    for(int i = 0; i < 2**bits; i++)
      data[i] <= {width{1'b0}};
  end
  else if(load)
    data[windex] <= datain;
end

endmodule : btb_array

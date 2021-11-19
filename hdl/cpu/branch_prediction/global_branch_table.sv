import rv32i_types::*;

module global_branch_table #(parameter num_bits = 5, parameter past_branch_bits = 2)
(
    input clk,
    input rst,
    input update,
    input correct,
    input [past_branch_bits-1:0] past_branches,
    input [31:0] current_pc,
    input [31:0] pc_update,
    input prediction_t previous_prediction,
    input [31:0] calculated_target,
    output prediction_t prediction,
    output logic [31:0] pc_prediction
);

logic valid_out;
prediction_t new_prediction;
logic [31:0] target;
logic [1:0] prediction_out;

assign prediction = prediction_t'(prediction_out);
assign pc_prediction = valid_out ? target : current_pc + 4;

btb_array #(.width(1),.bits(num_bits + past_branch_bits)) valid(
    .*,
    .load(update),
    .rindex({past_branches,current_pc[num_bits+1:2]}),
    .windex({past_branches,pc_update[num_bits+1:2]}),
    .datain(1'b1),
    .dataout(valid_out)
);

btb_array #(.width(2),.bits(num_bits + past_branch_bits)) predictions(
    .*,
    .load(update),
    .rindex({past_branches,current_pc[num_bits+1:2]}),
    .windex({past_branches,pc_update[num_bits+1:2]}),
    .datain(new_prediction),
    .dataout(prediction_out)
);

btb_array #(.width(32),.bits(num_bits + past_branch_bits)) targets(
    .*,
    .load(update),
    .rindex({past_branches,current_pc[num_bits+1:2]}),
    .windex({past_branches,pc_update[num_bits+1:2]}),
    .datain(calculated_target),
    .dataout(target)
);

always_comb begin
    new_prediction = previous_prediction;
    if(correct) begin
        unique case(previous_prediction)
            snt, st: new_prediction = previous_prediction;
            wnt: new_prediction = snt;
            wt: new_prediction = st;
        endcase
    end
    else begin
        unique case(previous_prediction)
            snt, wt: new_prediction = wnt;
            st, wnt: new_prediction = wt;
        endcase
    end
end
    
endmodule
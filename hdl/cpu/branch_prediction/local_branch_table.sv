import rv32i_types::*;

module local_branch_table #(parameter num_bits = 5)
(
    input clk,
    input rst,
    input update,
    input correct,
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

btb_array #(1) valid(
    .*,
    .load(update),
    .rindex(current_pc[num_bits+1:2]),
    .windex(pc_update[num_bits+1:2]),
    .datain(1'b1),
    .dataout(valid_out)
);

btb_array #(2) predictions(
    .*,
    .load(update),
    .rindex(current_pc[num_bits+1:2]),
    .windex(pc_update[num_bits+1:2]),
    .datain(new_prediction),
    .dataout(prediction_out)
);

btb_array #(32) targets(
    .*,
    .load(update),
    .rindex(current_pc[num_bits+1:2]),
    .windex(pc_update[num_bits+1:2]),
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
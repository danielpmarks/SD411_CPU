import rv32i_types::*;

module cmp(
    input [31:0] a,
    input [31:0] b,
    input [2:0] cmpop,
    output logic br_en
);

branch_funct3_t branch_op;

    always_comb begin
        branch_op = branch_funct3_t'(cmpop);

        if(cmpop == 3'b011)
            br_en = a < b;
        else if(cmpop == 3'b010)
            br_en = $signed(a) < $signed(b);
        else begin
            unique case(branch_op)
                beq: br_en = a == b;
                bne: br_en = a != b;
                blt: br_en = $signed(a) < $signed(b);
                bge: br_en = $signed(a) >= $signed(b);
                bltu: br_en = a < b;
                bgeu: br_en = a >= b;
                default: ;
            endcase
        end
    end

endmodule : cmp
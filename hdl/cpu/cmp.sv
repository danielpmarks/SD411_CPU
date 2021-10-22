
import rv32i_types::*;
module cmp
(
    input branch_funct3_t cmpop,
	input rv32i_word cmp_a,
	input rv32i_word cmp_b,
	output logic br_en
);

always_comb
begin
	unique case (cmpop)
		beq: br_en = (cmp_a == cmp_b); 
		bne: br_en = (cmp_a != cmp_b);
		blt: br_en = ($signed(cmp_a) < $signed(cmp_b));
		bltu: br_en = (cmp_a < cmp_b);
		bge: br_en = ($signed(cmp_a) >= $signed(cmp_b));
		bgeu: br_en = (cmp_a >= cmp_b);
		default: br_en = 0;
	endcase
end

endmodule : cmp
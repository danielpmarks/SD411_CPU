IF_ID stage_if_id(
    .clk(clk),
    .rst(rst),
    .load(load_if_id),
    
    .ir_in(ir_in),
    .pc_in(pc_in),

    .funct3 (funct3),
    .funct7 (funct7),
    .opcode (opcode),
    .i_imm (i_imm),
    .s_imm (s_imm),
    .b_imm (b_imm),
    .u_imm (u_imm),
    .j_imm (j_imm),
    .rs1 (rs1),
    .rs2 (rs2),
    .rd (rd),
    .pc_out (pc_out)
);
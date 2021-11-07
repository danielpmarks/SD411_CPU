import rv32i_types::*;

module ID_EX(
    input clk,
    input rst,
    input load,
    
    input [31:0] rs1_in,
    input [31:0] rs2_in,
    input [31:0] rs1_addr_in,
    input [31:0] rs2_addr_in,
    output [31:0] rs1_addr_out,
    output [31:0] rs2_addr_out,
    output [31:0] rs1_out,
    output [31:0] rs2_out,

    input packed_imm imm_in,
    output packed_imm imm_out,

    input rv32i_control_word control_word_in,
    output rv32i_control_word control_word_out,
    
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output branch_funct3_t cmpop,

    output [31:0] pc_out
);

logic [31:0] rs1, rs2;
packed_imm imm;
rv32i_control_word control_word;
assign rs1_addr_out = rs1_addr_in;
assign rs2_addr_out = rs2_addr_in;
assign imm_out = imm;
assign rs1_out = rs1;
assign rs2_out = rs2;
assign control_word_out = control_word;

assign alumux1_sel = control_word.alumux1_sel;
assign alumux2_sel = control_word.alumux2_sel;
assign cmpmux_sel = control_word.cmpmux_sel;
assign aluop = control_word.aluop;
assign cmpop = branch_funct3_t'(control_word.funct3);
assign pc_out = control_word.pc;

always_ff@(posedge clk) begin
    if(rst) begin
        rs1 <= 32'd0;
        rs2 <= 32'd0;
        imm.i_imm <= 32'd0;
        imm.s_imm <= 32'd0;
        imm.b_imm <= 32'd0;
        imm.u_imm <= 32'd0;
        imm.j_imm <= 32'd0;

        control_word.opcode <= rv32i_opcode'(0);
        control_word.aluop <= alu_ops'(0);
        control_word.mem_read <= 0;
        control_word.mem_write <= 0;
        control_word.regfilemux_sel <= regfilemux::regfilemux_sel_t'(0);
        control_word.pcmux_sel <= pcmux::pcmux_sel_t'(0);
        control_word.alumux1_sel <= alumux::alumux1_sel_t'(0);
        control_word.alumux2_sel <= alumux::alumux2_sel_t'(0);
        control_word.cmpmux_sel <= cmpmux::cmpmux_sel_t'(0);
        //control_word.mem_byte_enable <= 0;
        control_word.rd <= 0;
        control_word.funct3 <= 0;
        control_word.funct7 <= 0;
        control_word.pc <= 0;
    end
    else if(load) begin
        rs1 <= rs1_in;
        rs2 <= rs2_in;
        imm <= imm_in;
        control_word <= control_word_in;
    end
    else begin 
        rs1 <= rs1;
        rs2 <= rs2;
        imm <= imm;
        control_word <= control_word;
    end
end


endmodule

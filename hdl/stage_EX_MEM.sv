import rv32i_types::*;

module EX_MEM(
    input clk,
    input rst,
    input load,

    input rv32i_control_word control_word_in,
    output rv32i_control_word control_word_out,

    input logic [31:0] rs2_in,
    input logic [31:0] alu_in,
    input logic [31:0] mar_in,
    input logic br_en_in,
    input packed_imm imm_in,

    output logic mem_read,
    output logic mem_write,
    output logic [31:0] mem_wdata,
    output logic [31:0] alu_out,
    output logic [31:0] mar_out,
    output logic br_en_out,
     
    output packed_imm imm_out
);

rv32i_control_word control_word;
logic [31:0] rs2, alu, mar;
logic br_en;
packed_imm imm;

assign control_word_out = control_word;
assign mem_wdata = rs2;
assign alu_out = alu;
assign mar_out = mar;
assign br_en_out = br_en;
assign imm_out = imm;

assign mem_read = control_word.mem_read;
assign mem_write = control_word.mem_write;
//assign mem_byte_enable = control_word.mem_byte_enable;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        rs2 <= 0;
        alu <= 0;
        mar <= 0;
        br_en <= 0;

        imm.i_imm <= 32'b0;
        imm.s_imm <= 32'b0;
        imm.b_imm <= 32'b0;
        imm.u_imm <= 32'b0;
        imm.j_imm <= 32'b0;

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
        control_word.mem_addr_bits <= 0;
        control_word.rd <= 0;
        control_word.funct3 <= 0;
        control_word.funct7 <= 0;
        control_word.pc <= 0;
    end
    else if (load == 1)
    begin
        control_word <= control_word_in;
        rs2 <= rs2_in;
        alu <= alu_in;
        mar <= mar_in;
        br_en <= br_en_in;
        imm <= imm_in;
    end
    else
    begin
        control_word <= control_word;
        rs2 <= rs2;
        alu <= alu;
        mar <= mar;
        br_en <= br_en;
        imm <= imm;
    end
end

endmodule
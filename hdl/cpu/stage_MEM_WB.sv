import rv32i_types::*;

module MEM_WB(
    input clk,
    input rst,
    input load,

    input rv32i_control_word control_word_in,

    input logic [31:0] alu_in,
    input logic [31:0] mdr_in,
    input logic br_en_in,
    input packed_imm imm_in,

    output logic load_regfile,
    output logic [4:0] rd,
    output logic [31:0] pc,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output logic [31:0] alu_out,
    output logic [31:0] mdr_out,
    output logic br_en_out,
    output [31:0] u_imm,

    input monitor_t monitor_in,
    output monitor_t monitor_out
);

rv32i_control_word control_word;
logic [31:0] alu, mdr;
logic br_en;
packed_imm imm;
monitor_t monitor;

assign monitor_out = monitor;

assign rd = control_word.rd;
assign load_regfile = control_word.load_regfile;
assign regfilemux_sel = control_word.regfilemux_sel;
assign pc = control_word.pc;

assign alu_out = alu;
assign mdr_out = mdr;
assign br_en_out = br_en;
assign u_imm = imm.u_imm;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        alu <= 0;
        mdr <= 0;
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
        control_word.rd <= 0;
        control_word.funct3 <= 0;
        control_word.funct7 <= 0;
        control_word.pc <= 0;
    end
    else if (load == 1)
    begin
        control_word <= control_word_in;
        alu <= alu_in;
        mdr <= mdr_in;
        br_en <= br_en_in;
        imm <= imm_in;

        // Load signals from monitor_in
        monitor.commit <= monitor_in.commit;
        monitor.pc_rdata <= monitor_in.pc_rdata;
        monitor.pc_wdata <= monitor_in.pc_wdata;
        monitor.instruction <= monitor_in.instruction;
        monitor.trap <= monitor_in.trap;
        monitor.rs1_addr <= monitor_in.rs1_addr;
        monitor.rs2_addr <= monitor_in.rs2_addr;
        monitor.rs1_rdata <= monitor_in.rs1_rdata;
        monitor.rs2_rdata <= monitor_in.rs2_rdata;
        monitor.mem_addr <= monitor_in.mem_addr;
        monitor.mem_wdata <= monitor_in.mem_wdata;
        monitor.mem_wmask <= monitor_in.mem_wmask;
        
        
        //Load in new monitor signals
        monitor.rd_addr <= control_word_in.rd;
        if(control_word_in.opcode == op_load) begin
            monitor.mem_rdata <= mdr_in;
            unique case(load_funct3_t'(control_word_in.funct3))
                lw: monitor.mem_rmask <= 4'b1111;
                lh: monitor.mem_rmask <= 4'b0011 << {alu_in[1], 1'b0};
                lb: monitor.mem_rmask <= 4'b0001 << alu_in[1:0];
					 default: monitor.mem_rmask <= 4'b1111;
            endcase
        end

    end
    else
    begin
        control_word <= control_word;
        alu <= alu;
        mdr <= mdr;
        br_en <= br_en;
        imm <= imm;
    end
end

endmodule
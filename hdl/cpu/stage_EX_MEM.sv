import rv32i_types::*;

module EX_MEM(
    input clk,
    input rst,
    input load,
    input bubble,

    input rv32i_control_word control_word_in,
    output rv32i_control_word control_word_out,

    input logic [31:0] rs1_in,
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
    
    input monitor_t monitor_in,
    output monitor_t monitor_out,

    output packed_imm imm_out,
    output logic flush
);

rv32i_control_word control_word;
logic [31:0] rs2, alu, mar;
logic br_en;
packed_imm imm;
monitor_t monitor;

assign monitor_out = monitor;
assign flush = ~monitor.commit;

assign control_word_out = control_word;
assign mem_wdata = rs2;
assign alu_out = alu;
assign mar_out = mar;
assign br_en_out = br_en;
assign imm_out = imm;

assign mem_read = monitor.commit && control_word.mem_read;
assign mem_write = monitor.commit && control_word.mem_write;
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
        control_word.rd <= 0;
        control_word.funct3 <= 0;
        control_word.funct7 <= 0;
        control_word.pc <= 0;
    end
    else if (load == 1)
    begin
        if(bubble) begin
            control_word.opcode <= op_imm;
            control_word.aluop <= alu_add;
            control_word.regfilemux_sel <= regfilemux::alu_out;
            control_word.rd <= '0;
            rs2 <= '0;
            br_en <= '0;

            monitor.commit <= '0;
        end
        else begin
            control_word <= control_word_in;
            rs2 <= rs2_in;
            alu <= alu_in;
            mar <= mar_in;
            br_en <= br_en_in;
            imm <= imm_in;

            // Load signals from monitor_in
            monitor.commit <= monitor_in.commit;
            monitor.pc_rdata <= monitor_in.pc_rdata;
            monitor.instruction <= monitor_in.instruction;
            monitor.trap <= monitor_in.trap;
            monitor.rs1_addr <= monitor_in.rs1_addr;
            monitor.rs2_addr <= monitor_in.rs2_addr;

            monitor.rs1_rdata <= rs1_in;
            monitor.rs2_rdata <= rs2_in;
            monitor.mem_addr <= 32'd0;
            monitor.mem_wmask <= 4'd0;
            monitor.mem_rmask <= 4'd0;
            

            if((br_en_in && control_word_in.opcode == op_br) || control_word_in.opcode == op_jal) begin
                monitor.pc_wdata <= alu_in;
            end
            else if(control_word_in.opcode == op_jalr) begin
                monitor.pc_wdata <= {alu_in[31:1], 1'b0};
            end
            else begin
                monitor.pc_wdata <= monitor_in.pc_wdata;
            end
            if(control_word_in.opcode == op_store) begin
                monitor.mem_addr <= alu_in;
        
                unique case(store_funct3_t'(control_word_in.funct3))
                    sw: begin 
                        monitor.mem_wmask <= 4'b1111;
                        monitor.mem_wdata <= rs2_in;
                    end
                    sh: begin 
                        monitor.mem_wmask <= 4'b0011 << {alu_in[1], 1'b0};
                        unique case(mar_in[1])
                            1'b1: monitor.mem_wdata = rs2_in << 16;
                            1'b0: monitor.mem_wdata = rs2_in;
                        endcase
                    end
                    sb: begin 
                        monitor.mem_wmask <= 4'b0001 << alu_in[1:0];
                        unique case(mar_in[1:0])
                            2'b11: monitor.mem_wdata = rs2_in << 24;
                            2'b10: monitor.mem_wdata = rs2_in << 16;
                            2'b01: monitor.mem_wdata = rs2_in << 8;
                            2'b00: monitor.mem_wdata = rs2_in;
                        endcase
                    end
                        default: monitor.mem_wmask <= 4'b1111;
                endcase
            end
            else if(control_word_in.opcode == op_load) begin
                monitor.mem_addr <= alu_in;
            end
            else begin
                monitor.mem_wdata <= 32'd0;
            end
        end
    end
    else
    begin
        control_word <= control_word;
        rs2 <= rs2;
        alu <= alu;
        mar <= mar;
        br_en <= br_en;
        imm <= imm;

        monitor <= monitor;
    end
end

endmodule
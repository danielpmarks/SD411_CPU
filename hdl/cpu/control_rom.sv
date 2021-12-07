/*TODO*/
import rv32i_types::*;
module control_rom(
    input clk,
    input rst,
    input logic [4:0] rd,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [31:0] PC,
    input logic [31:0] pc_target,
    input prediction_t prediction,
    output rv32i_control_word word,

    input [31:0] instruction,
    output monitor_t monitor,
    input commit_in,
    input flush

);
logic [3:0] mem_byte_enable;
logic mem_read;
logic mem_write;
logic write_reg;
logic trap;
logic commit;

regfilemux::regfilemux_sel_t regfilemux_sel;
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
logic load_regfile;
alu_ops aluop;

assign word.opcode = opcode;
assign word.aluop = aluop;
assign word.load_regfile = load_regfile;
assign word.regfilemux_sel = regfilemux_sel;
assign word.pcmux_sel = pcmux_sel;
assign word.alumux1_sel = alumux1_sel;
assign word.alumux2_sel = alumux2_sel;
assign word.cmpmux_sel = cmpmux_sel;
assign word.mem_read = mem_read;
assign word.mem_write = mem_write;
assign word.rd = opcode == op_store || opcode == op_br ? 0 : rd;
assign word.funct3 = funct3;
assign word.pc = PC;
assign word.funct7 = funct7;
assign word.pc_target = pc_target;
assign word.prediction = prediction;

assign commit = commit_in & (~trap && (load_regfile | (opcode == op_br) | (opcode == op_store)));

always_comb
begin : word_generator
    
    monitor.commit = commit;
    monitor.pc_rdata = PC;
    monitor.pc_wdata = PC + 4;
    monitor.instruction = instruction;
    monitor.trap = trap;


    mem_read = 1'b0;
	mem_write = 1'b0;
    regfilemux_sel = regfilemux::alu_out;
    pcmux_sel = pcmux::pc_plus4;
    alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    cmpmux_sel = cmpmux::rs2_out;
    aluop = alu_ops'(funct3);
    load_regfile = 1'b0;
    trap = 0;
    
    if(!flush) begin
        case (opcode)
            op_br: begin
                unique case(branch_funct3_t'(funct3))
                    beq, bne, blt, bge, bltu, bgeu:;
                    default: trap = 1;
                endcase
                alumux1_sel = alumux::pc_out;
                alumux2_sel = alumux::b_imm;
                aluop = alu_add;
            end
            op_load: begin
                aluop = alu_add;
                load_regfile = 1;
                mem_read = 1;
                //marmux_sel = marmux::alu_out;
                case (load_funct3_t'(funct3))
                    lw: begin
                        regfilemux_sel = regfilemux::lw;
                    end
                    lh :begin
                        regfilemux_sel = regfilemux::lh;
                    end
                    lhu: begin
                        regfilemux_sel = regfilemux::lhu;
                    end 
                    lbu: begin
                        regfilemux_sel = regfilemux::lbu;
                    end
                    lb:begin
                        regfilemux_sel = regfilemux::lb;
                    end
                    default: trap = 1;
                endcase
            end

            op_store: begin
                alumux2_sel = alumux::s_imm;
                aluop = alu_add;
                mem_write = 1;
                unique case(store_funct3_t'(funct3))
                    sw, sh, sb:;
                    default: trap = 1;
                endcase
            end
            
            op_imm: begin
                load_regfile = 1'b1;
                alumux1_sel = alumux::rs1_out;
                alumux2_sel = alumux::i_imm;
                unique case(arith_funct3_t'(funct3))
                    slt: begin
                        regfilemux_sel = regfilemux::br_en;
                        cmpmux_sel = cmpmux::i_imm;
                    end
                    sltu: begin
                        regfilemux_sel = regfilemux::br_en;
                        cmpmux_sel = cmpmux::i_imm;
                    end
                    sr: begin
                        unique case(funct7[5])
                            0: aluop = alu_srl;
                            1: aluop = alu_sra;
                        endcase
                        regfilemux_sel = regfilemux::alu_out;
                    end
                    default: begin 
                        aluop = alu_ops'(funct3);
                        regfilemux_sel = regfilemux::alu_out;
                    end
                endcase
            end
            op_lui: begin
                load_regfile = 1;
                regfilemux_sel = regfilemux::u_imm;
            end
            op_reg: begin
                load_regfile = 1'b1;
                alumux1_sel = alumux::rs1_out;
                alumux2_sel = alumux::rs2_out;
                unique case(arith_funct3_t'(funct3))
                    add: begin
                        unique case(funct7[5])
                            0: aluop = alu_add;
                            1: aluop = alu_sub;
                        endcase
                        regfilemux_sel = regfilemux::alu_out;
                    end
                    slt: begin
                        regfilemux_sel = regfilemux::br_en;
                        cmpmux_sel = cmpmux::rs2_out;
                    end
                    sltu: begin
                        regfilemux_sel = regfilemux::br_en;
                        cmpmux_sel = cmpmux::rs2_out;
                    end
                    sr: begin
                        unique case(funct7[5])
                            0: aluop = alu_srl;
                            1: aluop = alu_sra;
                        endcase
                        regfilemux_sel = regfilemux::alu_out;
                    end
                    default: begin 
                        aluop = alu_ops'(funct3);
                        regfilemux_sel = regfilemux::alu_out;
                    end
                endcase
            end
            op_auipc: begin
                alumux1_sel = alumux::pc_out;
                alumux2_sel = alumux::u_imm;
                aluop = alu_add;
                load_regfile = 1'b1;
            end
            op_jal: begin
                pcmux_sel = pcmux::alu_out;
                load_regfile = 1'b1;
                alumux1_sel = alumux::pc_out;
                alumux2_sel = alumux::j_imm;
                regfilemux_sel = regfilemux::pc_plus4;
                aluop = alu_add;
            end
            op_jalr:begin
                pcmux_sel = pcmux::alu_mod2;
                load_regfile = 1'b1;
                alumux1_sel = alumux::rs1_out;
                alumux2_sel = alumux::i_imm;
                regfilemux_sel = regfilemux::pc_plus4;
                aluop = alu_add;
            end
            default: begin 
                trap = 1;
            end
        endcase
    end else begin
        monitor.trap = 0;
    end
end

endmodule : control_rom
/*TODO*/
import rv32i_types::*;
module control_rom(
    input clk,
    input rst,
    output rv32i_control_word words

);
assign mem_byte_enable = 4'b1111; // shift after obtaining the addr
always_comb
begin : words_generator
    

    case (opcode)
        op_br: begin
            pcmux_sel = pcmux::pcmux_sel_t'(br_en);
            load_pc = 1;
            alumux1_sel = alumux::pc_out;
            alumux2_sel = alumux::b_imm;
            aluop = alu_add;
        end

        op_load: begin
            aluop = alu_add;
            load_mar = 1;
            marmux_sel = marmux::alu_out;
            case (load_funct3)
                lw: begin
                    regfilemux_sel = regfilemux::lw;
                    mem_byte_enable = 4'b1111;
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
            load_mar = 1;
            load_data_out = 1;
            
            marmux_sel = marmux::alu_out;
        end
        
        op_imm: begin
            if (funct3 == slt) begin
                load_regfile = 1'b1;
                load_pc = 1'b1;
                cmpop = blt;
                regfilemux_sel = regfilemux::br_en;
                cmpmux_sel = cmpmux::i_imm;
            end else if (funct3 == sltu) begin
                load_regfile = 1'b1;
                load_pc = 1'b1;
                cmpop = bltu;
                regfilemux_sel = regfilemux::br_en;
                cmpmux_sel = cmpmux::i_imm;
            end else if (funct3 == 3'b101 && funct7 == 7'b0100000) begin // srai
                load_regfile = 1;
                load_pc = 1;
                aluop = alu_sra;
                
            end else begin
                load_regfile = 1;
                load_pc = 1;
                aluop = alu_ops' (funct3);
                
            end
        end
        op_lui: begin
            load_regfile = 1;
            load_pc = 1;
            regfilemux_sel = regfilemux::u_imm;
        end
        op_reg: begin
            if (funct3 == 3'b000 && funct7 == 7'b0100000) begin
                load_regfile = 1'b1;
                load_pc = 1'b1;
                alumux2_sel = alumux::rs2_out;
                aluop = alu_sub;
            end else if (funct3 == 3'b101 && funct7 == 7'b0100000) begin
                load_regfile = 1'b1;
                load_pc = 1'b1;
                alumux2_sel = alumux::rs2_out;
                aluop = alu_sra;
            end else begin
                load_regfile = 1;
                load_pc = 1;
				alumux2_sel = alumux::rs2_out;
                aluop = alu_ops' (funct3);
            end
        end
        op_auipc: begin
            
        end
        op_jal: begin
            pcmux_sel = pcmux::alu_out;
            load_regfile = 1'b1;
            load_pc = 1'b1;
            alumux1_sel = alumux::pc_out;
            alumux2_sel = alumux::j_imm;
			regfilemux_sel = regfilemux::pc_plus4;
            aluop = alu_add;
        end
        op_jalr:begin
            pcmux_sel = pcmux::alu_out;
            load_regfile = 1'b1;
            load_pc = 1'b1;
            alumux1_sel = alumux::rs1_out;
            alumux2_sel = alumux::i_imm;
			regfilemux_sel = regfilemux::pc_plus4;
            aluop = alu_add;
            

        end
        default: /*doom*/;
    endcase
end

endmodule : control_rom
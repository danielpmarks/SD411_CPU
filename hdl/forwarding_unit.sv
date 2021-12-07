import rv32i_types::*;
`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)
module forwarding_unit
(
    input regfilemux::regfilemux_sel_t MEM_WB_regfile_sel,
    input regfilemux::regfilemux_sel_t EX_MEM_regfile_sel,
    input logic mem_load_inst,
    input logic [4:0] MEM_WB_rd,
    input logic [4:0] EX_MEM_rd,
    input logic [4:0] rs1, // reg addr from ID/EX stage
    input logic [4:0] rs2, // reg addr from ID/EX stage
    input logic [31:0] rs1_out,
    input logic [31:0] rs2_out,
    input logic [31:0] u_imm_mem,
    input logic [31:0] u_imm_wb,
    input logic [31:0] EX_MEM_alu_out,
    //input logic [31:0] EX_MEM_mem_out,
    input logic [31:0] MEM_WB_alu_out,
    input logic [31:0] MEM_WB_mem_out,
    output logic [31:0] forward_mux1_out,
    output logic [31:0] forward_mux2_out,

    input logic [31:0] pc_mem,
    input logic [31:0] pc_wb,

    input logic br_en_mem,
    input logic br_en_wb,

    input logic flush_ex_mem,
    input logic flush_mem_wb,

    output logic bubble
);
logic MEM_WB_rd_rs1; // comparing result of MEM_WB_rd == rs1
logic EX_MEM_rd_rs1;// comparing result of EX_MEM_rd == rs1
logic MEM_WB_rd_rs2;// comparing result of MEM_WB_rd == rs2
logic EX_MEM_rd_rs2;// comparing result of EX_MEM_rd == rs2
logic [1:0] combine_rs1; // concatenation of MEM_WB_rd_rs1 and EX_MEM_rd_rs1
logic [1:0] combine_rs2;// concatenation of MEM_WB_rd_rs2 and EX_MEM_rd_rs2
//logic [31:0] EX_MEM_true_mem_out; // masked mem_out in turns of lb, lbu, lhu, lh or lw.
logic [31:0] MEM_WB_true_mem_out;
always_comb begin : cmp
    MEM_WB_rd_rs1 = 0;
    EX_MEM_rd_rs1 = 0;
    MEM_WB_rd_rs2 = 0;
    EX_MEM_rd_rs2 = 0;
    if (rs1 != 0 && rs1 == MEM_WB_rd && ~flush_mem_wb) begin
        MEM_WB_rd_rs1 = 1;
    end

    if (rs1 != 0 && rs1 == EX_MEM_rd && ~flush_ex_mem) begin
        MEM_WB_rd_rs1 = 0;
        EX_MEM_rd_rs1 = 1;
    end

    if (rs2 != 0 && rs2 == MEM_WB_rd && ~flush_mem_wb) begin
        MEM_WB_rd_rs2 = 1;
    end

    if (rs2 != 0 && rs2 == EX_MEM_rd && ~flush_ex_mem) begin
        MEM_WB_rd_rs2 = 0;
        EX_MEM_rd_rs2 = 1;
    end
end

always_comb begin : MEM_WB_true_mem_out_mux
    MEM_WB_true_mem_out = {32{1'b0}};
    unique case (MEM_WB_regfile_sel)
        regfilemux::lw: MEM_WB_true_mem_out = MEM_WB_mem_out;
        regfilemux::lb: begin 
            unique case(MEM_WB_alu_out[1:0])
                2'b11: MEM_WB_true_mem_out = {{24{MEM_WB_mem_out[31]}}, MEM_WB_mem_out[31:24]};
                2'b10: MEM_WB_true_mem_out = {{24{MEM_WB_mem_out[23]}}, MEM_WB_mem_out[23:16]};
                2'b01: MEM_WB_true_mem_out = {{24{MEM_WB_mem_out[15]}}, MEM_WB_mem_out[15:8]};
                2'b00: MEM_WB_true_mem_out = {{24{MEM_WB_mem_out[7]}}, MEM_WB_mem_out[7:0]};
                default: ;
            endcase
        end
        regfilemux::lbu: begin 
            unique case(MEM_WB_alu_out[1:0])
                2'b11: MEM_WB_true_mem_out = {24'd0, MEM_WB_mem_out[31:24]};
                2'b10: MEM_WB_true_mem_out = {24'd0, MEM_WB_mem_out[23:16]};
                2'b01: MEM_WB_true_mem_out = {24'd0, MEM_WB_mem_out[15:8]};
                2'b00: MEM_WB_true_mem_out = {24'd0, MEM_WB_mem_out[7:0]};
                default: ;
           endcase
        end
        regfilemux::lh: begin 
            unique case(MEM_WB_alu_out[1])
                1'b1: MEM_WB_true_mem_out = {{16{MEM_WB_mem_out[31]}}, MEM_WB_mem_out[31:16]};
                1'b0: MEM_WB_true_mem_out = {{16{MEM_WB_mem_out[15]}}, MEM_WB_mem_out[15:0]}; 
                default: ; 
            endcase
        end
        regfilemux::lhu: begin 
            unique case(MEM_WB_alu_out[1])
                1'b1: MEM_WB_true_mem_out = {16'd0, MEM_WB_mem_out[31:16]};
                1'b0: MEM_WB_true_mem_out = {16'd0, MEM_WB_mem_out[15:0]};  
                default: ;
            endcase 
        end
        default: MEM_WB_true_mem_out = {32{1'b0}};
    endcase
end

/*always_comb begin : EX_MEM_true_mem_out_mux
    EX_MEM_true_mem_out = {32{1'b0}};
    unique case (EX_MEM_regfile_sel)
        regfilemux::lw: EX_MEM_true_mem_out = EX_MEM_mem_out;
        regfilemux::lb: begin 
            unique case(EX_MEM_alu_out[1:0])
                2'b11: EX_MEM_true_mem_out = {{24{EX_MEM_mem_out[31]}}, EX_MEM_mem_out[31:24]};
                2'b10: EX_MEM_true_mem_out = {{24{EX_MEM_mem_out[23]}}, EX_MEM_mem_out[23:16]};
                2'b01: EX_MEM_true_mem_out = {{24{EX_MEM_mem_out[15]}}, EX_MEM_mem_out[15:8]};
                2'b00: EX_MEM_true_mem_out = {{24{EX_MEM_mem_out[7]}}, EX_MEM_mem_out[7:0]};
                default: ;
            endcase
        end
        regfilemux::lbu: begin 
            unique case(EX_MEM_alu_out[1:0])
                2'b11: EX_MEM_true_mem_out = {24'd0, EX_MEM_mem_out[31:24]};
                2'b10: EX_MEM_true_mem_out = {24'd0, EX_MEM_mem_out[23:16]};
                2'b01: EX_MEM_true_mem_out = {24'd0, EX_MEM_mem_out[15:8]};
                2'b00: EX_MEM_true_mem_out = {24'd0, EX_MEM_mem_out[7:0]};
                default: ;
           endcase
        end
        regfilemux::lh: begin 
            unique case(EX_MEM_alu_out[1])
                1'b1: EX_MEM_true_mem_out = {{16{EX_MEM_mem_out[31]}}, EX_MEM_mem_out[31:16]};
                1'b0: EX_MEM_true_mem_out = {{16{EX_MEM_mem_out[15]}}, EX_MEM_mem_out[15:0]}; 
                default: ; 
            endcase
        end
        regfilemux::lhu: begin 
            unique case(EX_MEM_alu_out[1])
                1'b1: EX_MEM_true_mem_out = {16'd0, EX_MEM_mem_out[31:16]};
                1'b0: EX_MEM_true_mem_out = {16'd0, EX_MEM_mem_out[15:0]};  
                default: ;
            endcase 
        end
        default: EX_MEM_true_mem_out = {32{1'b0}};
    endcase
end*/

always_comb begin : forwarding_muxes
    bubble = 1'b0;

    combine_rs1 = {MEM_WB_rd_rs1, EX_MEM_rd_rs1};
    forward_mux1_out = rs1_out;
    unique case (combine_rs1)
        2'b10: begin
            // not sure if we need to consider cases other than load and alu instructions
            case (MEM_WB_regfile_sel)
                regfilemux::alu_out: forward_mux1_out = MEM_WB_alu_out;
                regfilemux::pc_plus4: forward_mux1_out = pc_wb + 4;
                regfilemux::u_imm:  forward_mux1_out = u_imm_wb;
                regfilemux::lhu: forward_mux1_out = MEM_WB_true_mem_out;
                regfilemux::lh: forward_mux1_out = MEM_WB_true_mem_out;
                regfilemux::lbu: forward_mux1_out = MEM_WB_true_mem_out;
                regfilemux::lb: forward_mux1_out = MEM_WB_true_mem_out;
                regfilemux::lw: forward_mux1_out = MEM_WB_true_mem_out;
                regfilemux::br_en: forward_mux1_out = br_en_wb;
					 default:;
            endcase
        end
        2'b01: begin
            if(mem_load_inst) begin
                bubble = 1'b1;
            end
            case (EX_MEM_regfile_sel)
                regfilemux::alu_out: forward_mux1_out = EX_MEM_alu_out;
                regfilemux::pc_plus4: forward_mux1_out = pc_mem + 4;
                regfilemux::u_imm:  forward_mux1_out = u_imm_mem;
                regfilemux::br_en: forward_mux1_out = br_en_mem;
                //regfilemux::lhu: forward_mux1_out = EX_MEM_true_mem_out;
                //regfilemux::lh: forward_mux1_out = EX_MEM_true_mem_out;
                //regfilemux::lbu: forward_mux1_out = EX_MEM_true_mem_out;
                //regfilemux::lb: forward_mux1_out = EX_MEM_true_mem_out;
                //regfilemux::lw: forward_mux1_out = EX_MEM_true_mem_out;
					 default:;
            endcase
        end
        2'b00: forward_mux1_out = rs1_out;
        default: ;//`BAD_MUX_SEL;
    endcase

    combine_rs2 = {MEM_WB_rd_rs2, EX_MEM_rd_rs2};
    forward_mux2_out = rs2_out;
    unique case (combine_rs2)
        2'b10: begin
            case (MEM_WB_regfile_sel)
                regfilemux::alu_out: forward_mux2_out = MEM_WB_alu_out;
                regfilemux::u_imm:  forward_mux2_out = u_imm_wb;
                regfilemux::pc_plus4: forward_mux2_out = pc_wb + 4;
                regfilemux::lhu: forward_mux2_out = MEM_WB_true_mem_out;
                regfilemux::lh: forward_mux2_out = MEM_WB_true_mem_out;
                regfilemux::lbu: forward_mux2_out = MEM_WB_true_mem_out;
                regfilemux::lb: forward_mux2_out = MEM_WB_true_mem_out;
                regfilemux::lw: forward_mux2_out = MEM_WB_true_mem_out;
                regfilemux::br_en: forward_mux2_out = br_en_wb;
					 default:;
            endcase
        end
        2'b01: begin
            if(mem_load_inst) begin
                bubble = 1'b1;
            end
            case (EX_MEM_regfile_sel)
                regfilemux::alu_out: forward_mux2_out = EX_MEM_alu_out;
                regfilemux::pc_plus4: forward_mux2_out = pc_mem + 4;
                regfilemux::u_imm:  forward_mux2_out = u_imm_mem;
                regfilemux::br_en: forward_mux2_out = br_en_mem;
                //regfilemux::lhu: forward_mux2_out = EX_MEM_true_mem_out;
                //regfilemux::lh: forward_mux2_out = EX_MEM_true_mem_out;
                //regfilemux::lbu: forward_mux2_out = EX_MEM_true_mem_out;
                //regfilemux::lb: forward_mux2_out = EX_MEM_true_mem_out;
                //regfilemux::lw: forward_mux2_out = EX_MEM_true_mem_out;
					 default:;
            endcase
        end
        2'b00: forward_mux2_out = rs2_out;
        default: ;//`BAD_MUX_SEL;
    endcase
end
endmodule : forwarding_unit
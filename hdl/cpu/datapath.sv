<<<<<<< HEAD:hdl/cpu/datapath.sv
import rv32i_types::*;
`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)


module datapath(
    input clk,
    input rst,
    
    /* I Cache Ports */
    output logic inst_read,
    output logic [31:0] inst_addr,
    input logic inst_resp,
    input logic [31:0] inst_rdata,

    /* D Cache Ports */
    output logic data_read,
    output logic data_write,
    output logic [3:0] data_mbe,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    input logic data_resp,
    input logic [31:0] data_rdata
);
rv32i_control_word control_word_init;
rv32i_control_word control_words[2:0];
packed_imm immediates[2:0];

/* IF Signals */
logic load_pc;
logic [31:0] pc_in, pc_out;

/* IF/ID Signals */
logic load_if_id;
rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic [4:0] rs1, rs2, rd;
logic [31:0] pc_id;

/* Decode Signals */
logic [31:0] rs1_out, rs2_out;

/* ID/EX Signals */
logic load_id_ex;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
alu_ops aluop;
branch_funct3_t cmpop;
logic [31:0] pc_ex, rs1_ex, rs2_ex;

/* Execution Signals */
logic [31:0] alumux1_out, alumux2_out, cmpmux_out;
logic [31:0] alu_out;
logic br_en;

/* EX/MEM Signals */
logic load_ex_mem;
logic mem_read, mem_write;
logic [1:0] mem_byte_enable;
logic [31:0] mem_wdata, alu_out_mem, mar_out;
logic [4:0] wmask;
logic br_en_mem;

/* MEM/WB Signals */
logic load_mem_wb;
logic load_regfile;
logic br_en_wb;
logic [4:0] rd_wb;
logic [31:0] pc_wb, alu_out_wb, mdr_out_wb, u_imm_wb;
regfilemux::regfilemux_sel_t regfilemux_sel;
logic [31:0] regfilemux_out;

/***************************** INSTRUCTION FETCH STAGE *****************************/


assign load_pc = 1'b1;
assign inst_addr = pc_out;
assign inst_read = 1'b1;

pc_register pc(.*,
    .load(load_pc),
    .in(pc_in),
    .out(pc_out)
);

always_comb begin
    if((control_words[1].opcode == op_br && br_en)|| control_words[1].opcode == op_jal)begin
        pc_in = alu_out;
    end
    else if(control_words[1].opcode == op_jalr) begin
        pc_in = {alu_out[31:1], 1'b0};
    end
    else begin
        pc_in = pc_out + 4;
    end
end


/***************************** IF/ID BUFFER *****************************/

assign load_if_id = 1'b1;
logic [31:0] ir_in;
assign ir_in = inst_rdata;

IF_ID stage_if_id(
    .clk(clk),
    .rst(rst),
    .load(load_if_id),
    .ir_in(ir_in),
    .pc_in(pc_out),
    .funct3 (funct3),
    .funct7 (funct7),
    .opcode (opcode),
    .imm(immediates[0]),
    .rs1 (rs1),
    .rs2 (rs2),
    .rd (rd),
    .pc_out (pc_id)
);

/***************************** DECODE STAGE *****************************/


    /********* Control_rom *********/
    control_rom control_rom(
        .clk (clk),
        .rst (rst),
        .rd (rd),
        .opcode (opcode),
        .funct3 (funct3),
        .funct7 (funct7),
        .PC (pc_id),
        .word (control_words[0])
    );

regfile REGFILE(
    .*,
    .load(load_regfile),
    .in(regfilemux_out),
    .src_a(rs1),
    .src_b(rs2),
    .dest(rd_wb),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);

/***************************** ID/EX BUFFER *******************************/

assign load_id_ex = 1'b1;

ID_EX stage_id_ex(.*, 
    .load(load_id_ex),
    .control_word_in(control_words[0]), 
    .control_word_out(control_words[1]),
    .rs1_in(rs1_out),
    .rs2_in(rs2_out),
    .rs1_out(rs1_ex),
    .rs2_out(rs2_ex),
    .imm_in(immediates[0]),
    .imm_out(immediates[1]),
    .alumux1_sel(alumux1_sel),
    .alumux2_sel(alumux2_sel),
    .cmpmux_sel(cmpmux_sel),
    .aluop(aluop),
    .cmpop(cmpop),
    .pc_out(pc_ex));


/***************************** EXECUTION STAGE *****************************/

alu ALU(.a(alumux1_out), .b(alumux2_out), .f(alu_out), .aluop(aluop));
cmp CMP(.a(rs1_ex), .b(cmpmux_out), .cmpop(cmpop), .br_en(br_en));

/* MUXES */
always_comb begin
	/* ALUMUX1 */
    unique case(alumux1_sel) 
        alumux::rs1_out : alumux1_out = rs1_ex;
        alumux::pc_out : alumux1_out = pc_ex;
        default: `BAD_MUX_SEL;
    endcase

	 /* ALUMUX2 */
    unique case(alumux2_sel) 
        alumux::i_imm : alumux2_out = immediates[1].i_imm;
        alumux::u_imm : alumux2_out = immediates[1].u_imm;
        alumux::b_imm : alumux2_out = immediates[1].b_imm;
        alumux::s_imm : alumux2_out = immediates[1].s_imm;
        alumux::j_imm : alumux2_out = immediates[1].j_imm;
        alumux::rs2_out : alumux2_out = rs2_ex;
        default: `BAD_MUX_SEL;
    endcase

	 /* CMPMUX */
    unique case(cmpmux_sel) 
        cmpmux::rs2_out : cmpmux_out = rs2_ex;
        cmpmux::i_imm : cmpmux_out = immediates[1].i_imm;
        default: `BAD_MUX_SEL;
    endcase
end


/***************************** EX/MEM BUFFER ********************************/

assign load_ex_mem = 1'b1;
assign data_addr = {mar_out[31:2], 2'b00};

EX_MEM stage_ex_mem(
    .*,
    .load(load_ex_mem),
    .control_word_in(control_words[1]),
    .control_word_out(control_words[2]),
    .rs2_in(rs2_ex),
    .alu_in(alu_out),
    .mar_in(alu_out),
    .br_en_in(br_en),
    .imm_in(immediates[1]),

    .mem_read(data_read),
    .mem_write(data_write),
    .mem_wdata(mem_wdata),
    .alu_out(alu_out_mem),
    .mar_out(mar_out),
    .br_en_out(br_en_mem),

    .imm_out(immediates[2])
);

always_comb begin
    data_mbe = 4'b1111;
	data_wdata = 32'd0;
    if(control_words[2].opcode == op_store) begin
        unique case(store_funct3_t'(control_words[2].funct3)) 
            sw: begin
                data_wdata = mem_wdata;
                data_mbe = 4'b1111;
            end
            sh: begin
                unique case(mar_out[1])
                    1'b1: data_wdata = mem_wdata << 16;
                    1'b0: data_wdata = mem_wdata;
                endcase
                data_mbe = 4'b0011 << (mar_out[1] << 1);
            end
            sb: begin
                unique case(mar_out[1:0])
                    2'b11: data_wdata = mem_wdata << 24;
                    2'b01: data_wdata = mem_wdata << 16;
                    2'b10: data_wdata = mem_wdata << 8;
                    2'b00: data_wdata = mem_wdata;
                endcase
                data_mbe = 4'b0001 << mar_out[1:0];
            end
            default: ;
        endcase
    end
end

/***************************** MEM/WB BUFFER ********************************/

assign load_mem_wb = 1'b1;

MEM_WB stage_mem_wb(
    .*,
	 .load(load_mem_wb),
    .control_word_in(control_words[2]),
    .alu_in(alu_out_mem),
    .mdr_in(data_rdata),
    .br_en_in(br_en_mem),
    .imm_in(immediates[2]),
    .load_regfile(load_regfile),
    .rd(rd_wb),
    .pc(pc_wb),
    .regfilemux_sel(regfilemux_sel),
    .alu_out(alu_out_wb),
    .mdr_out(mdr_out_wb),
    .br_en_out(br_en_wb),
    .u_imm(u_imm_wb)
);

always_comb begin

    /*assign mem_address = {not_zeroed_mem[31 : 2], 2'd0};
    assign mem_address_2bit = not_zeroed_mem[1:0];*/
    unique case (regfilemux_sel)
        regfilemux::alu_out: regfilemux_out = alu_out_wb;
        regfilemux::br_en: regfilemux_out = {31'd0, br_en_wb};
        regfilemux::u_imm: regfilemux_out = u_imm_wb;
        regfilemux::lw: regfilemux_out = mdr_out_wb;
        regfilemux::pc_plus4: regfilemux_out = pc_out + 4;
        regfilemux::lb: begin 
            unique case(alu_out_wb[1:0])
                2'b11: regfilemux_out = {{24{mdr_out_wb[31]}}, mdr_out_wb[31:24]};
                2'b10: regfilemux_out = {{24{mdr_out_wb[23]}}, mdr_out_wb[23:16]};
                2'b01: regfilemux_out = {{24{mdr_out_wb[15]}}, mdr_out_wb[15:8]};
                2'b00: regfilemux_out = {{24{mdr_out_wb[7]}}, mdr_out_wb[7:0]};
                default: ;
            endcase
        end
        regfilemux::lbu: begin 
            unique case(alu_out_wb[1:0])
                2'b11: regfilemux_out = {24'd0, mdr_out_wb[31:24]};
                2'b10: regfilemux_out = {24'd0, mdr_out_wb[23:16]};
                2'b01: regfilemux_out = {24'd0, mdr_out_wb[15:8]};
                2'b00: regfilemux_out = {24'd0, mdr_out_wb[7:0]};
                default: ;
           endcase
        end
        regfilemux::lh: begin 
            unique case(alu_out_wb[1])
                1'b1: regfilemux_out = {{16{mdr_out_wb[31]}}, mdr_out_wb[31:16]};
                1'b0: regfilemux_out = {{16{mdr_out_wb[15]}}, mdr_out_wb[15:0]}; 
                default: ; 
            endcase
        end
        regfilemux::lhu: begin 
            unique case(alu_out_wb[1])
                1'b1: regfilemux_out = {16'd0, mdr_out_wb[31:16]};
                1'b0: regfilemux_out = {16'd0, mdr_out_wb[15:0]};  
                default: ;
            endcase 
        end
        default: `BAD_MUX_SEL;
    endcase
end


=======
import rv32i_types::*;
`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)


module datapath(
    input clk,
    input rst,
    
    /* I Cache Ports */
    output logic inst_read,
    output logic [31:0] inst_addr,
    input logic inst_resp,
    input logic [31:0] inst_rdata,

    /* D Cache Ports */
    output logic data_read,
    output logic data_write,
    output logic [3:0] data_mbe,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    input logic data_resp,
    input logic [31:0] data_rdata
    
);
rv32i_control_word control_word_init;
rv32i_control_word control_words[2:0];
packed_imm immediates[2:0];

/* IF Signals */
logic load_pc;
logic [31:0] pc_in, pc_out;

/* IF/ID Signals */
logic load_if_id;
rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic [4:0] rs1, rs2, rd;
logic [31:0] pc_id;

/* Decode Signals */
logic [31:0] rs1_out, rs2_out;

/* ID/EX Signals */
logic [4:0] rs1_addr_ex, rs2_addr_ex;
logic load_id_ex;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
alu_ops aluop;
branch_funct3_t cmpop;
logic [31:0] pc_ex, rs1_ex, rs2_ex;
logic [31:0] forward_mux1_out;
logic [31:0] forward_mux2_out;
/* Execution Signals */
logic [31:0] alumux1_out, alumux2_out, cmpmux_out;
logic [31:0] alu_out;
logic br_en;

/* EX/MEM Signals */
logic load_ex_mem;
logic mem_read, mem_write;
logic [1:0] mem_byte_enable;
logic [31:0] mem_wdata, alu_out_mem, mar_out;
logic [4:0] wmask;
logic br_en_mem;

/* MEM/WB Signals */
logic load_mem_wb;
logic load_regfile;
logic br_en_wb;
logic [4:0] rd_wb;
logic [31:0] pc_wb, alu_out_wb, mdr_out_wb, u_imm_wb;
regfilemux::regfilemux_sel_t regfilemux_sel;
logic [31:0] regfilemux_out;

/***************************** INSTRUCTION FETCH STAGE *****************************/


assign load_pc = 1'b1;
assign inst_addr = pc_out;
assign inst_read = 1'b1;

pc_register pc(.*,
    .load(load_pc),
    .in(pc_in),
    .out(pc_out)
);

always_comb begin
    if((control_words[1].opcode == op_br && br_en)|| control_words[1].opcode == op_jal)begin
        pc_in = alu_out;
    end
    else if(control_words[1].opcode == op_jalr) begin
        pc_in = {alu_out[31:1], 1'b0};
    end
    else begin
        pc_in = pc_out + 4;
    end
end


/***************************** IF/ID BUFFER *****************************/

assign load_if_id = 1'b1;
logic [31:0] ir_in;
assign ir_in = inst_rdata;

IF_ID stage_if_id(
    .clk(clk),
    .rst(rst),
    .load(load_if_id),
    .ir_in(ir_in),
    .pc_in(pc_out),
    .funct3 (funct3),
    .funct7 (funct7),
    .opcode (opcode),
    .imm(immediates[0]),
    .rs1 (rs1),
    .rs2 (rs2),
    .rd (rd),
    .pc_out (pc_id)
);

/***************************** DECODE STAGE *****************************/


    /********* Control_rom *********/
    control_rom control_rom(
        .clk (clk),
        .rst (rst),
        .rd (rd),
        .opcode (opcode),
        .funct3 (funct3),
        .funct7 (funct7),
        .PC (pc_id),input logic [31:0] 
regfile REGFILE(
    .*,
    .load(load_regfile),
    .in(regfilemux_out),
    .src_a(rs1),
    .src_b(rs2),
    .dest(rd_wb),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);



/***************************** ID/EX BUFFER *******************************/

assign load_id_ex = 1'b1;

ID_EX stage_id_ex(.*, 
    .load(load_id_ex),
    .control_word_in(control_words[0]), 
    .control_word_out(control_words[1]),
    .rs1_in(rs1_out),
    .rs2_in(rs2_out),
    .rs1_addr_in(rs1),
    .rs2_addr_in(rs2),
    .rs1_addr_out(rs1_addr_ex),
    .rs2_addr_out(rs2_addr_ex),
    .rs1_out(rs1_ex),
    .rs2_out(rs2_ex),

    .imm_in(immediates[0]),
    .imm_out(immediates[1]),
    .alumux1_sel(alumux1_sel),
    .alumux2_sel(alumux2_sel),
    .cmpmux_sel(cmpmux_sel),
    .aluop(aluop),
    .cmpop(cmpop),
    .pc_out(pc_ex));


/***************************** EXECUTION STAGE *****************************/

alu ALU(.a(alumux1_out), .b(alumux2_out), .f(alu_out), .aluop(aluop));
cmp CMP(.a(forward_mux1_out), .b(cmpmux_out), .cmpop(cmpop), .br_en(br_en));

/* MUXES */
always_comb begin
	/* ALUMUX1 */
    unique case(alumux1_sel) 
        alumux::rs1_out : alumux1_out = forward_mux1_out;
        alumux::pc_out : alumux1_out = pc_ex;
        default: `BAD_MUX_SEL;
    endcase

	 /* ALUMUX2 */
    unique case(alumux2_sel) 
        alumux::i_imm : alumux2_out = immediates[1].i_imm;
        alumux::u_imm : alumux2_out = immediates[1].u_imm;
        alumux::b_imm : alumux2_out = immediates[1].b_imm;
        alumux::s_imm : alumux2_out = immediates[1].s_imm;
        alumux::j_imm : alumux2_out = immediates[1].j_imm;
        alumux::rs2_out : alumux2_out = forward_mux2_out;
        default: `BAD_MUX_SEL;
    endcase

	 /* CMPMUX */
    unique case(cmpmux_sel) 
        cmpmux::rs2_out : cmpmux_out = forward_mux2_out;
        cmpmux::i_imm : cmpmux_out = immediates[1].i_imm;
        default: `BAD_MUX_SEL;
    endcase
end


/***************************** EX/MEM BUFFER ********************************/

assign load_ex_mem = 1'b1;
assign data_addr = {mar_out[31:2], 2'b00};

EX_MEM stage_ex_mem(
    .*,
    .load(load_ex_mem),
    .control_word_in(control_words[1]),
    .control_word_out(control_words[2]),
    .rs2_in(forward_mux2_out),
    .alu_in(alu_out),
    .mar_in(alu_out),
    .br_en_in(br_en),
    .imm_in(immediates[1]),

    .mem_read(data_read),
    .mem_write(data_write),
    .mem_wdata(mem_wdata),
    .alu_out(alu_out_mem),
    .mar_out(mar_out),
    .br_en_out(br_en_mem),

    .imm_out(immediates[2])
);

always_comb begin
    data_mbe = 4'b1111;
	data_wdata = 32'd0;
    if(control_words[2].opcode == op_store) begin
        unique case(store_funct3_t'(control_words[2].funct3)) 
            sw: begin
                data_wdata = mem_wdata;
                data_mbe = 4'b1111;
            end
            sh: begin
                unique case(mar_out[1])
                    1'b1: data_wdata = mem_wdata << 16;
                    1'b0: data_wdata = mem_wdata;
                endcase
                data_mbe = 4'b0011 << (mar_out[1] << 1);
            end
            sb: begin
                unique case(mar_out[1:0])
                    2'b11: data_wdata = mem_wdata << 24;
                    2'b01: data_wdata = mem_wdata << 16;
                    2'b10: data_wdata = mem_wdata << 8;
                    2'b00: data_wdata = mem_wdata;
                endcase
                data_mbe = 4'b0001 << mar_out[1:0];
            end
            default: ;
        endcase
    end
end

/***************************** MEM/WB BUFFER ********************************/

assign load_mem_wb = 1'b1;

MEM_WB stage_mem_wb(
    .*,
	 .load(load_mem_wb),
    .control_word_in(control_words[2]),
    .alu_in(alu_out_mem),
    .mdr_in(data_rdata),
    .br_en_in(br_en_mem),
    .imm_in(immediates[2]),
    .load_regfile(load_regfile),
    .rd(rd_wb),
    .pc(pc_wb),
    .regfilemux_sel(regfilemux_sel),
    .alu_out(alu_out_wb),
    .mdr_out(mdr_out_wb),
    .br_en_out(br_en_wb),
    .u_imm(u_imm_wb)
);

forwarding_unit forwarding_unit(
    .MEM_WB_regfile_sel(control_words[2].regfilemux_sel),
    .EX_MEM_regfile_sel(control_words[1].regfilemux_sel),
    .MEM_WB_rd(control_words[2].rd),
    .EX_MEM_rd(control_words[1].rd),
    .rs1(rs1_ex), // reg addr from ID/EX stage
    .rs2(rs2_ex), // reg addr from ID/EX stage
    .rs1_out(rs1_addr_ex),
    .rs2_out(rs2_addr_ex),
    .EX_MEM_alu_out(alu_out_mem),
    .EX_MEM_mem_out(data_rdata),
    .MEM_WB_alu_out(alu_out_wb),
    .MEM_WB_mem_out(mdr_out_wb),
    .forward_mux1_out(forward_mux1_out),
    .forward_mux2_out(forward_mux2_out)

);

always_comb begin

    /*assign mem_address = {not_zeroed_mem[31 : 2], 2'd0};
    assign mem_address_2bit = not_zeroed_mem[1:0];*/
    unique case (regfilemux_sel)
        regfilemux::alu_out: regfilemux_out = alu_out_wb;
        regfilemux::br_en: regfilemux_out = {31'd0, br_en_wb};
        regfilemux::u_imm: regfilemux_out = u_imm_wb;
        regfilemux::lw: regfilemux_out = mdr_out_wb;
        regfilemux::pc_plus4: regfilemux_out = pc_out + 4;
        regfilemux::lb: begin 
            unique case(alu_out_wb[1:0])
                2'b11: regfilemux_out = {{24{mdr_out_wb[31]}}, mdr_out_wb[31:24]};
                2'b10: regfilemux_out = {{24{mdr_out_wb[23]}}, mdr_out_wb[23:16]};
                2'b01: regfilemux_out = {{24{mdr_out_wb[15]}}, mdr_out_wb[15:8]};
                2'b00: regfilemux_out = {{24{mdr_out_wb[7]}}, mdr_out_wb[7:0]};
                default: ;
            endcase
        end
        regfilemux::lbu: begin 
            unique case(alu_out_wb[1:0])
                2'b11: regfilemux_out = {24'd0, mdr_out_wb[31:24]};
                2'b10: regfilemux_out = {24'd0, mdr_out_wb[23:16]};
                2'b01: regfilemux_out = {24'd0, mdr_out_wb[15:8]};
                2'b00: regfilemux_out = {24'd0, mdr_out_wb[7:0]};
                default: ;
           endcase
        end
        regfilemux::lh: begin 
            unique case(alu_out_wb[1])
                1'b1: regfilemux_out = {{16{mdr_out_wb[31]}}, mdr_out_wb[31:16]};
                1'b0: regfilemux_out = {{16{mdr_out_wb[15]}}, mdr_out_wb[15:0]}; 
                default: ; 
            endcase
        end
        regfilemux::lhu: begin 
            unique case(alu_out_wb[1])
                1'b1: regfilemux_out = {16'd0, mdr_out_wb[31:16]};
                1'b0: regfilemux_out = {16'd0, mdr_out_wb[15:0]};  
                default: ;
            endcase 
        end
        default: `BAD_MUX_SEL;
    endcase
end


>>>>>>> b81be9d8197ac7677ed511060b33fc98ff7ddd32:hdl/datapath.sv
endmodule
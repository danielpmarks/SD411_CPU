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

monitor_t monitors[3:0];

logic stall;
logic mem_op;
assign stall = !inst_resp || (monitors[3].commit && mem_op && !data_resp); 

/* IF Signals */
logic load_pc;
logic [31:0] pc_in, pc_out;
logic [31:0] ir_out;
prediction_t global_prediction, local_prediction, prediction;
logic [31:0] global_target_pc, local_target_pc, target_pc;
logic [31:0] ir_in;
logic commit_if;
logic [31:0] target_pc_id;
logic [3:0] past_branches;
logic [1:0] branch_table_select;

/* IF/ID Signals */
logic load_if_id;
logic [31:0] target_pc_out;
prediction_t prediction_out;
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
logic br_en, branch_taken;
logic flush;
logic correct_prediction, correct_target;

assign flush = (control_words[1].opcode == op_br || control_words[1].opcode == op_jal || control_words[1].opcode == op_jalr) && monitors[1].commit && (!correct_prediction || (correct_prediction && (control_words[1].prediction == st || control_words[1].prediction == wt) && !correct_target));  

/* EX/MEM Signals */
logic load_ex_mem;
logic mem_read, mem_write;
logic [1:0] mem_byte_enable;
logic [31:0] mem_wdata, alu_out_mem, mar_out;
logic [4:0] wmask;
logic br_en_mem;
logic bubble;

/* MEM/WB Signals */
logic load_mem_wb;
logic load_regfile;
logic br_en_wb;
logic [4:0] rd_wb;
logic [31:0] pc_wb, alu_out_wb, mdr_out_wb, u_imm_wb;
regfilemux::regfilemux_sel_t regfilemux_sel;
logic [31:0] regfilemux_out;

/***************************** INSTRUCTION FETCH STAGE *****************************/
logic [31:0] inst_addr_in;

assign load_pc = !stall && !bubble;


assign inst_addr = inst_resp && !stall && !bubble ? pc_in : pc_out;
assign inst_read = 1'b1;
//assign inst_read = !stall;

pc_register pc(.*,
    .load(load_pc),
    .in(pc_in),
    .out(pc_out)
);

local_branch_table #(.num_bits(5)) local_branch_predictor(
    .*,
    .update(control_words[1].opcode == op_br || control_words[1].opcode == op_jal || control_words[1].opcode == op_jalr),
    .correct(correct_prediction),
    .current_pc(pc_out),
    .pc_update(control_words[1].pc),
    .previous_prediction(control_words[1].prediction),
    .calculated_target(alu_out),
    .prediction(local_prediction),
    .pc_prediction(local_target_pc)
);


global_branch_table #(.num_bits(5),.past_branch_bits(4))  global_branch_predictor(
    .*,
    .update(control_words[1].opcode == op_br || control_words[1].opcode == op_jal || control_words[1].opcode == op_jalr),
    .correct(correct_prediction),
    .current_pc(pc_out),
    .past_branches(past_branches),
    .pc_update(control_words[1].pc),
    .previous_prediction(control_words[1].prediction),
    .calculated_target(alu_out),
    .prediction(global_prediction),
    .pc_prediction(global_target_pc)
);

always_comb begin
    target_pc = branch_table_select[1] ? global_target_pc : local_target_pc;
    prediction = branch_table_select[1] ? global_prediction : local_prediction;


    if(flush) begin
        if((control_words[1].opcode == op_br && br_en) || control_words[1].opcode == op_jal) begin
            pc_in = alu_out;
        end 
        else if(control_words[1].opcode == op_jalr) begin 
            pc_in = {alu_out[31:1],1'b0};
        end else begin 
            pc_in = control_words[1].pc + 4;
        end
    end
    else begin
        pc_in = pc_out + 4;
        if(rv32i_opcode'(ir_in[6:0]) == op_br) begin
            unique case(prediction)
                st, wt: pc_in = target_pc;
                snt, wnt: pc_in = pc_out + 4;
            endcase
        end else if(rv32i_opcode'(ir_in[6:0]) == op_jal || rv32i_opcode'(ir_in[6:0]) == op_jalr) begin
            pc_in = target_pc;
        end
    end

    
end


/***************************** IF/ID BUFFER *****************************/

assign load_if_id = !stall && !bubble;
assign ir_in = inst_rdata;

IF_ID stage_if_id(
    .flush(flush),
    .clk(clk),
    .rst(rst),
    .load(load_if_id),
    .ir_in(ir_in),
    .pc_in(pc_out),
    .pc_target_in(target_pc),
    .prediction_in(prediction),
    .funct3 (funct3),
    .funct7 (funct7),
    .opcode (opcode),
    .imm(immediates[0]),
    .rs1 (rs1),
    .rs2 (rs2),
    .rd (rd),
    .pc_out (pc_id),
    .pc_target_out(target_pc_out),
    .prediction_out(prediction_out),
    .ir_out(ir_out),
    .commit(commit_if)
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
        .pc_target(target_pc_out),
        .word(control_words[0]),
        .instruction(ir_out),
        .monitor(monitors[0]),
        .commit_in(commit_if),
        .prediction(prediction_out),
        .flush(flush)
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

assign load_id_ex = !stall && !bubble;

ID_EX stage_id_ex(.*, 
    .flush(flush),
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
    .pc_out(pc_ex),
    
    .monitor_in(monitors[0]),
    .monitor_out(monitors[1])
);


/***************************** EXECUTION STAGE *****************************/

alu ALU(.a(alumux1_out), .b(alumux2_out), .f(alu_out), .aluop(aluop));
cmp CMP(.a(forward_mux1_out), .b(cmpmux_out), .cmpop(cmpop), .br_en(br_en));

int branch_hits;

always_ff @(posedge clk) begin
    if(rst)
        branch_hits <= 0;
    else if(monitors[1].commit && ((control_words[1].opcode == op_br || control_words[1].opcode == op_jal || control_words[1].opcode == op_jalr) && !flush)) 
        branch_hits <= branch_hits + 1;
    else
        branch_hits <= branch_hits;

    if(rst)
        past_branches <= 4'd0;
    else if(monitors[1].commit && control_words[1].opcode == op_br)
        past_branches <= {past_branches[2:0], br_en};
    else 
        past_branches <= past_branches;

    if(rst)
        branch_table_select <= 2'd0;
    else if(flush) begin
        unique case(branch_table_select)
            2'b00, 2'b10: branch_table_select <= 2'b01;
            2'b01, 2'b11: branch_table_select <= 2'b10;
        endcase
    end else if(control_words[1].opcode == op_br || control_words[1].opcode == op_jal || control_words[1].opcode == op_jalr) begin
        unique case(branch_table_select)
            2'b01: branch_table_select <= 2'b00;
            2'b10: branch_table_select <= 2'b11;
            default: branch_table_select <= branch_table_select;
        endcase
    end else 
        branch_table_select <= branch_table_select;
end

/* Correct prediction logic */
always_comb begin
	correct_target = 1'b1;
    if(control_words[1].opcode == op_br || control_words[1].opcode == op_jal)
        correct_target = control_words[1].pc_target == alu_out;
    else if(control_words[1].opcode == op_jalr)
        correct_target = control_words[1].pc_target == {alu_out[31:1],1'b0};

    branch_taken = control_words[1].opcode == op_br ? br_en : control_words[1].opcode == op_jal | control_words[1].opcode == op_jalr;
    correct_prediction = 1'b1;
    unique case(control_words[1].prediction)
        st, wt: correct_prediction = branch_taken;
        snt, wnt: correct_prediction = !branch_taken;
        default: correct_prediction = 1'b1;
    endcase

end

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

assign load_ex_mem = !stall;
assign data_addr = {mar_out[31:2], 2'b00};
//assign data_addr = {alu_out_mem[31:2], 2'b00};
logic flush_ex_mem;


EX_MEM stage_ex_mem(
    .*,
    .load(load_ex_mem),
    .control_word_in(control_words[1]),
    .control_word_out(control_words[2]),
    .rs1_in(forward_mux1_out),
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

    .imm_out(immediates[2]),
    .monitor_in(monitors[1]),
    .monitor_out(monitors[2]),
    .flush(flush_ex_mem),
    .bubble(bubble)
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
                /*unique case(mar_out[1])
                    1'b1: data_wdata = mem_wdata << 16;
                    1'b0: data_wdata = mem_wdata;
                endcase*/
                unique case(alu_out[1])
                    1'b1: data_wdata = mem_wdata << 16;
                    1'b0: data_wdata = mem_wdata;
                endcase
                //data_mbe = 4'b0011 << (mar_out[1] << 1);
                data_mbe = 4'b0011 << (alu_out[1] << 1);
            end
            sb: begin
                /*unique case(mar_out[1:0])
                    2'b11: data_wdata = mem_wdata << 24;
                    2'b01: data_wdata = mem_wdata << 16;
                    2'b10: data_wdata = mem_wdata << 8;
                    2'b00: data_wdata = mem_wdata;
                endcase
                data_mbe = 4'b0001 << mar_out[1:0];*/
                unique case(alu_out[1:0])
                    2'b11: data_wdata = mem_wdata << 24;
                    2'b10: data_wdata = mem_wdata << 16;
                    2'b01: data_wdata = mem_wdata << 8;
                    2'b00: data_wdata = mem_wdata;
                endcase
                data_mbe = 4'b0001 << alu_out[1:0];
            end
            default: ;
        endcase
    end
end

/***************************** MEM/WB BUFFER ********************************/

assign load_mem_wb = !stall;
logic flush_mem_wb;


always_ff@(posedge clk) begin
    if(rst)
        mem_op <= 0;
    else if(load_mem_wb)
        mem_op <= control_words[2].opcode == op_load || control_words[2].opcode == op_store;
    
end

MEM_WB stage_mem_wb(
    .*,
	.load(load_mem_wb),
    .control_word_in(control_words[2]),
    .alu_in(alu_out_mem),
    .br_en_in(br_en_mem),
    .imm_in(immediates[2]),
    .load_regfile(load_regfile),
    .rd(rd_wb),
    .pc(pc_wb),
    .regfilemux_sel(regfilemux_sel),
    .alu_out(alu_out_wb),
    .br_en_out(br_en_wb),
    .u_imm(u_imm_wb),

    .monitor_in(monitors[2]),
    .monitor_out(monitors[3]),

    .flush(flush_mem_wb)
);

forwarding_unit forwarding_unit(
    .MEM_WB_regfile_sel(regfilemux_sel),
    .EX_MEM_regfile_sel(control_words[2].regfilemux_sel),
    .MEM_WB_rd(rd_wb),
    .EX_MEM_rd(control_words[2].rd),
    .mem_load_inst(control_words[2].opcode == op_load),
    .rs1(rs1_addr_ex), // reg addr from ID/EX stage
    .rs2(rs2_addr_ex), // reg addr from ID/EX stage
    .rs1_out(rs1_ex),
    .rs2_out(rs2_ex),
    .EX_MEM_alu_out(alu_out_mem),
    .MEM_WB_alu_out(alu_out_wb),
    .MEM_WB_mem_out(data_rdata),
    .forward_mux1_out(forward_mux1_out),
    .forward_mux2_out(forward_mux2_out),

    .flush_ex_mem(flush_ex_mem),
    .flush_mem_wb(flush_mem_wb),

    .bubble(bubble)

);
assign mdr_out_wb = data_rdata;
always_comb begin
    /*assign mem_address = {not_zeroed_mem[31 : 2], 2'd0};
    assign mem_address_2bit = not_zeroed_mem[1:0];*/
    unique case (regfilemux_sel)
        regfilemux::alu_out: regfilemux_out = alu_out_wb;
        regfilemux::br_en: regfilemux_out = {31'd0, br_en_wb};
        regfilemux::u_imm: regfilemux_out = u_imm_wb;
        regfilemux::lw: regfilemux_out = mdr_out_wb;
        regfilemux::pc_plus4: regfilemux_out = pc_wb + 4;
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


endmodule
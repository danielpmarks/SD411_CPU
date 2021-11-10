import rv32i_types::*;

module IF_ID(
    input clk,
    input rst,
    input load,
    input flush,
    
    input [31:0] ir_in,
    input [31:0] pc_in,

    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output rv32i_opcode opcode,

    output packed_imm imm,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [31:0] pc_out,
    output logic [31:0] ir_out,
    output logic commit
);

logic [31:0] ir_data;
logic [31:0] pc_data;
logic commit_data;

assign ir_out = ir_data;
assign commit = commit_data;

assign funct3 = ir_data[14:12];
assign funct7 = ir_data[31:25];
assign opcode = rv32i_opcode'(ir_data[6:0]);
assign imm.i_imm = {{21{ir_data[31]}}, ir_data[30:20]};
assign imm.s_imm = {{21{ir_data[31]}}, ir_data[30:25], ir_data[11:7]};
assign imm.b_imm = {{20{ir_data[31]}}, ir_data[7], ir_data[30:25], ir_data[11:8], 1'b0};
assign imm.u_imm = {ir_data[31:12], 12'h000};
assign imm.j_imm = {{12{ir_data[31]}}, ir_data[19:12], ir_data[20], ir_data[30:21], 1'b0};
assign rs1 = ir_data[19:15];
assign rs2 = ir_data[24:20];
assign rd = ir_data[11:7];

assign pc_out = pc_data;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        ir_data <= '0;
        pc_data <= '0;
    end
    else if (load)
    begin
        ir_data <= ir_in;
        pc_data <= pc_in;
        commit_data <= 1;
        if (flush) begin
            ir_data <= 32'h00000013;
            pc_data <= '0;
            commit_data <= '0;
        end
    end
    else
    begin
        ir_data <= ir_data;
        pc_data <= pc_data;
        commit_data <= commit_data;
    end
end


endmodule
module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = (dut.datapath.br_en & dut.datapath.load_pc) | dut.datapath.load_regfile; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = dut.datapath.load_pc & (dut.datapath.pc_out == dut.datapath.pc_in);   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO


//Instruction and trap:
assign rvfi.inst = dut.datapath.stage_if_id.ir_data;
assign rvfi.trap = dut.datapath.control_rom.trap

//Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

//PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

//Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata


/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/
//riscv_formal_monitor_rv32imc
assign itf.mem_read = 0;
assign itf.mem_write = 0;

mp4 dut (
    .clk(itf.clk),
    .rst(itf.rst),

    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),

    .pmem_rdata(itf.mem_rdata),
    .pmem_wdata(itf.mem_wdata),
    .pmem_address(itf.mem_addr),
    
    .pmem_resp(itf.mem_resp)
);

riscv_formal_monitor_rv32imc monitor(
  .clock(itf.clk),
  .reset(itf.rst),
  .rvfi_valid(rvfi.commit),
  .rvfi_order(rvfi.order),
  .rvfi_insn(dut.datapath.stage_if_id.ir_data),
  .rvfi_trap(dut.datapath.control_rom.trap),
  .rvfi_halt(rvfi.halt),
  .rvfi_intr(1'b0),
  .rvfi_mode(2'b00),
  .rvfi_rs1_addr(dut.datapath.rs1),
  .rvfi_rs2_addr(dut.datapath.rs2),
  .rvfi_rs1_rdata(monitor.rvfi_rs1_addr ? dut.datapath.rs1_out : 0),
  .rvfi_rs2_rdata(monitor.rvfi_rs2_addr ? dut.datapath.rs2_out : 0),
  .rvfi_rd_addr(dut.load_regfile ? dut.datapath.rd_wb : 0),
  .rvfi_rd_wdata(monitor.rvfi_rd_addr ? dut.datapath.regfilemux_out : 0),
  .rvfi_pc_rdata(dut.datapath.pc_out),
  .rvfi_pc_wdata(dut.datapath.pc_in),
  .rvfi_mem_addr(dut.pmem_address),
  .rvfi_mem_rmask(dut.datapath.rmask),
  .rvfi_mem_wmask(dut.datapath.data_mbe),
  .rvfi_mem_rdata(dut.pmem_rdata),
  .rvfi_mem_wdata(dut.pmem_wdata),
  .rvfi_mem_extamo(1'b0),
  .errcode(itf.errcode)
);
/***************************** End Instantiation *****************************/

endmodule

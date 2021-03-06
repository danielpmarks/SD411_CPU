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

assign rvfi.commit = !dut.datapath.stall && dut.datapath.monitors[3].commit; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = dut.datapath.monitors[3].pc_wdata == dut.datapath.monitors[3].pc_rdata && dut.datapath.monitors[3].commit == 1;   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO


//Instruction and trap:
assign rvfi.inst = dut.datapath.monitors[3].instruction;
assign rvfi.trap = dut.datapath.monitors[3].trap;

//Regfile:
assign rvfi.rs1_addr = dut.datapath.monitors[3].rs1_addr;
assign rvfi.rs2_addr = dut.datapath.monitors[3].rs2_addr;
assign rvfi.rs1_rdata = dut.datapath.monitors[3].rs1_rdata;
assign rvfi.rs2_rdata = dut.datapath.monitors[3].rs2_rdata;
assign rvfi.load_regfile = dut.datapath.load_regfile;
assign rvfi.rd_addr = dut.datapath.monitors[3].rd_addr;
assign rvfi.rd_wdata = rvfi.rd_addr ? dut.datapath.regfilemux_out : 0;

//PC:
assign rvfi.pc_rdata = dut.datapath.monitors[3].pc_rdata;
assign rvfi.pc_wdata = dut.datapath.monitors[3].pc_wdata;

//Memory:
assign rvfi.mem_addr = dut.datapath.monitors[3].mem_addr;
assign rvfi.mem_rmask = dut.datapath.monitors[3].mem_rmask;
assign rvfi.mem_wmask = dut.datapath.monitors[3].mem_wmask;
assign rvfi.mem_rdata = dut.datapath.data_rdata;
assign rvfi.mem_wdata = dut.datapath.monitors[3].mem_wdata;


/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
assign itf.inst_read = dut.instruction_cache.mem_read;
assign itf.inst_addr = dut.instruction_cache.req_addr;
assign itf.inst_resp = dut.instruction_cache.mem_resp;
assign itf.inst_rdata = dut.instruction_cache.mem_rdata;

assign itf.data_read = dut.data_cache.mem_read_delayed;
assign itf.data_write = dut.data_cache.mem_write_delayed;
assign itf.data_mbe = dut.data_cache.mem_byte_enable_delayed;
assign itf.data_addr = dut.datapath.monitors[3].mem_addr;
assign itf.data_wdata = dut.datapath.monitors[3].mem_wdata;
assign itf.data_resp = dut.data_cache.mem_resp;
assign itf.data_rdata = dut.datapath.mdr_out_wb;

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.datapath.REGFILE.data;

/*********************** Instantiate your design here ************************/



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


/***************************** End Instantiation *****************************/

endmodule

import rv32i_types::*;

module mp4
(
    input clk,
    input rst,

    input  logic [63:0] pmem_rdata,
    input logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output logic [63:0] pmem_wdata
);

/* I Cache Ports */     
logic inst_read;
logic [31:0] inst_addr;
logic inst_resp;
logic [31:0] inst_rdata;

/* D Cache Ports */
logic data_read, data_write, data_resp;
logic [3:0] data_mbe;
logic [31:0] data_addr, data_wdata, data_rdata;

logic [31:0] pmem_address_c_d; // from llc
logic [255:0] pmem_wdata_c_d, pmem_rdata_c_d; // from llc
logic pmem_read_c_d, pmem_write_c_d, pmem_resp_c_d; // to llc

//Instruction cache
logic pmem_read_c_i, pmem_resp_c_i;
logic [31:0] pmem_address_c_i; //from llc
logic [255:0] pmem_wdata_c_i, pmem_rdata_c_i;//from llc

datapath datapath(
    .*
);


arbiter arbiter(
    .*,
    .pmem_resp_m(pmem_resp),
    .pmem_rdata_m(pmem_rdata),
    .pmem_wdata_m(pmem_wdata),
    .pmem_address_m(pmem_address),
    .pmem_read_m(pmem_read),
    .pmem_write_m(pmem_write)
);

icache instruction_cache(
    .*,
    .mem_read(inst_read),
    .mem_address(inst_addr),
    .mem_rdata(inst_rdata),
    .mem_resp(inst_resp),

    .pmem_address(pmem_address_c_i),
    .pmem_read(pmem_read_c_i),
    .pmem_rdata(pmem_rdata_c_i),
    .pmem_resp(pmem_resp_c_i)
);

dcache data_cache(
    .*,
    .mem_read(data_read),
    .mem_write(data_write),
    .mem_address(data_addr),
    .mem_rdata(data_rdata),
    .mem_wdata(data_wdata),
    .mem_resp(data_resp),
    .mem_byte_enable(data_mbe),

    .pmem_address(pmem_address_c_d),
    .pmem_read(pmem_read_c_d),
    .pmem_write(pmem_write_c_d),
    .pmem_rdata(pmem_rdata_c_d),
    .pmem_wdata(pmem_wdata_c_d),
    .pmem_resp(pmem_resp_c_d)
);


endmodule : mp4

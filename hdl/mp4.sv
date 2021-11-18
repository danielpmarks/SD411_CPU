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

//Cacheline Adaptor wires
logic [255:0] line_i, line_o;
logic [31:0] adaptor_addr;
logic read_i, write_i, resp_o;


datapath datapath(
    .*
);

arbiter arbiter(
    .*,
    .pmem_resp_m(resp_o),
    .pmem_rdata_m(line_o),
    .pmem_wdata_m(line_i),
    .pmem_address_m(adaptor_addr),
    .pmem_read_m(read_i),
    .pmem_write_m(write_i)
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

cache data_cache(
    .*,
    .mem_read(data_read),
    .mem_write(data_write),
    .mem_address(data_addr),
    .mem_rdata_cpu(data_rdata),
    .mem_wdata_cpu(data_wdata),
    .mem_resp(data_resp),
    .mem_byte_enable_cpu(data_mbe),

    .pmem_address(pmem_address_c_d),
    .pmem_read(pmem_read_c_d),
    .pmem_write(pmem_write_c_d),
    .pmem_rdata(pmem_rdata_c_d),
    .pmem_wdata(pmem_wdata_c_d),
    .pmem_resp(pmem_resp_c_d)
);


cacheline_adaptor mem_adaptor(
    .*,
    .reset_n(~rst),
    .line_i(line_i),
    .line_o(line_o),
    .address_i(adaptor_addr),
    .read_i(read_i),
    .write_i(write_i),
    .resp_o(resp_o),

    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule : mp4

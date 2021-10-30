import rv32i_types::*;

module mp4
(
    input clk,
    input rst,

    /*
        input [63:0] pmem_rdata,
        output logic pmem_read,
        output logic pmem_write,
        output rv32i_word pmem_address,
        output [63:0] pmem_wdata
    */

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

datapath datapath(
    .*
);


endmodule : mp4

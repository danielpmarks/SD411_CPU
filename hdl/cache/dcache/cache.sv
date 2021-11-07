/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,
    
    //cpu
    input logic [31:0] mem_address,
    input logic [3:0] mem_byte_enable,
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] mem_wdata,

    output logic [31:0] mem_rdata,
    output logic mem_resp,	 
    
    //memory
    output logic [31:0] pmem_address,

    output logic pmem_read,
    output logic pmem_write,

    input logic [255:0] pmem_rdata,
    output logic [255:0] pmem_wdata,

    input logic pmem_resp
	
);




logic [1:0] hit_datapath;


//lru input
logic set_lru;
logic load_lru;

//dirty input
logic[1:0] load_dirty;
logic[1:0] set_dirty;
    
//valid input
logic[1:0] load_valid;
logic[1:0] set_valid;
    
//tag control
logic[1:0] load_tag;

//data control
logic data_array_select;

//output to control
logic lru_output;
logic[1:0] valid_out;
logic[1:0] dirty_out;
logic [31:0] write_enable_0;
logic [31:0] write_enable_1;
//bus adapter
logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;
logic [31:0] mem_byte_enable256;


	
logic mem_enable_sel;

cache_control control (.*);

cache_datapath datapath(.*);

bus_adapter bus_adapter
(
.mem_wdata256,
.mem_rdata256,
.mem_wdata,
.mem_rdata,
.mem_byte_enable,
.mem_byte_enable256,
.address(mem_address)
);

endmodule : cache

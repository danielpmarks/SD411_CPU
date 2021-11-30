/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module L2cache #(
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
    //L1
    input logic [31:0] mem_address,
    input logic [31:0] mem_byte_enable256,
    input logic L1_read,
    input logic L1_write,
    output logic [255:0] L1_rdata,
    input logic [255:0] L1_wdata,

    output logic L1_resp,
    
    //memory
    output logic [31:0] pmem_address,

    output logic pmem_read,
    output logic pmem_write,

    input logic [255:0] pmem_rdata,
    output logic [255:0] pmem_wdata,

    input logic pmem_resp
	
);

logic [3:0] hit_datapath;
//lru input
logic [2:0] set_lru;
logic load_lru;

//dirty input
logic[3:0] load_dirty;
logic[3:0] set_dirty;
    
//valid input
logic[3:0] load_valid;
logic[3:0] set_valid;
    
//tag control
logic[3:0] load_tag;

//output to control
logic [2:0] lru_output;
logic[3:0] valid_out;
logic[3:0] dirty_out;
logic [31:0] write_enable_0;
logic [31:0] write_enable_1;
logic [31:0] write_enable_2;
logic [31:0] write_enable_3;

logic mem_enable_sel;

L2cache_control L2cache_control (
    .mem_read(L1_read),
    .mem_write(L1_write),
	.clk(clk),
	.pmem_resp(pmem_resp),
    //lru input
    .set_lru(set_lru),
    .load_lru(load_lru),

    //dirty input
    .load_dirty(load_dirty), 
    .set_dirty(set_dirty), 
    
    //valid input
    .load_valid(load_valid), 
    .set_valid(set_valid), 
    
    //tag control
    .load_tag(load_tag),

    //output to control
    .lru_output(lru_output),
    .valid_out(valid_out),
    .dirty_out(dirty_out),
    .hit_datapath(hit_datapath),

    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .mem_resp(L1_resp),	
    .mem_enable_sel(mem_enable_sel),
    .write_enable_0(write_enable_0),
    .write_enable_1(write_enable_1),
    .write_enable_2(write_enable_2),
    .write_enable_3(write_enable_3),
    .mem_byte_enable256(mem_byte_enable256)
    
);

L2cache_datapath L2cache_datapath(
    .clk(clk),
	.rst(rst),

	//signal to control
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .mem_resp(mem_resp),	
    .mem_enable_sel(mem_enable_sel),
    .hit_datapath(hit_datapath),
    .write_enable_0(write_enable_0),
    .write_enable_1(write_enable_1),
    .write_enable_2(write_enable_2),
    .write_enable_3(write_enable_3),
    //lru input
    .set_lru(set_lru),
    .load_lru(load_lru),

    //dirty input
    .load_dirty(load_dirty), 
    .set_dirty(set_dirty), 
    
    //valid input
    .load_valid(load_valid), 
    .set_valid(set_valid), 
    
    //tag control
    .load_tag(load_tag),

    //output to control
    .lru_output(lru_output),
    .valid_out(valid_out),
    .dirty_out(dirty_out),
        
    /* Signals between cache and CPU */
    .mem_write(L1_write),
    .mem_read(L1_read),
    .mem_address(mem_address),
    
    /* Signals between cache and main memory */
    .pmem_address(pmem_address),
    .pmem_wdata(pmem_wdata),
    .pmem_rdata(pmem_rdata),
    
    /* Signals between cache and bus adapter */
    .mem_byte_enable256(mem_byte_enable256),
    .mem_wdata256(L1_wdata),
    .mem_rdata256(L1_rdata)
);

endmodule : L2cache

/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module dcache #(
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



logic [31:0] req_addr;
logic [31:0] next_mem_addr;
logic next_mem_read;
logic next_mem_write;
logic mem_read_delayed;
logic mem_write_delayed;
logic [4:0] mem_byte_enable_delayed;
logic next_mem_byte_enable;

always_ff@(posedge clk) begin
    if(!rst) begin
        if((mem_write_delayed == 1 || mem_read_delayed == 1) && mem_resp || !(mem_write_delayed == 1 || mem_read_delayed == 1) && !mem_resp) begin
            req_addr <= mem_address;
            mem_read_delayed <= mem_read;
            mem_write_delayed <= mem_write;
            mem_byte_enable_delayed <= mem_byte_enable;
        end
    end else begin
        req_addr <= 0;
        mem_read_delayed <= 0;
        mem_write_delayed <= 0;
        mem_byte_enable_delayed <= 0;
    end
end


always_comb begin
    if((mem_read_delayed || mem_write_delayed) && !mem_resp) begin
        next_mem_read = mem_read_delayed;
        next_mem_write = mem_write_delayed;
        next_mem_addr = req_addr;
        next_mem_byte_enable = mem_byte_enable_delayed;
    end
    else begin
        next_mem_read = mem_read;
        next_mem_write = mem_write;
        next_mem_addr = mem_address;
        next_mem_byte_enable = mem_byte_enable;
    end
end

dcache_datapath dcache_datapath(.*,
    .mem_address(req_addr),
    .index_in(next_mem_addr[9:5]),
    .mem_read(next_mem_read),
    .mem_write(next_mem_write),
    .pmem_wdata(pmem_wdata)
);

dcache_control dcache_control (.*,
    .mem_read(next_mem_read),
    .mem_write(next_mem_write)
);

dcache_bus_adapter dcache_bus_adapter
(
.mem_wdata256,
.mem_rdata256,
.mem_wdata,
.mem_rdata,
.mem_byte_enable,
.mem_byte_enable256,
.address(mem_address)
);

endmodule : dcache

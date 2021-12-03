module L2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,

    input mem_write,                // To Lower Level
    input mem_read,
    input [31:0] mem_byte_enable,
    input [31:0] mem_address,
    input [255:0] mem_wdata,
    output [255:0] mem_rdata,
    output mem_resp,
   
    input [255:0] pmem_rdata,       // To Higher Level
    input pmem_resp,
    output pmem_write,
    output pmem_read,
    output [255:0] pmem_wdata,
    output [31:0] pmem_address,
    output logic victim_cache_dirty
);
logic set_valid;
logic set_dirty;
logic clear_dirty;
logic load_tag;
logic bus_sel;
logic load_lru;
logic [1:0] lru_out;
logic [1:0] way_sel;
logic [2:0] pmem_address_sel;
logic [3:0] hit;
logic [3:0] dirty;
logic [3:0] valid_out;
logic [31:0] data_in_sel;
logic [31:0] data_write_en;



L2_cache_control control(
    .clk(clk),

    .set_valid(set_valid),
    .set_dirty(set_dirty),
    .clear_dirty(clear_dirty),
    .load_tag(load_tag),
    .way_sel(way_sel),
    .data_write_en(data_write_en),

    .lru_out(lru_out),
    .load_lru(load_lru),

    .pmem_resp(pmem_resp),
    .pmem_write(pmem_write),
    .pmem_read(pmem_read),
    .victim_cache_dirty(victim_cache_dirty),
	 
	.mem_read(mem_read),
	.mem_write(mem_write),
	.mem_resp(mem_resp),

    .pmem_address_sel(pmem_address_sel),
    .data_in_sel(data_in_sel),
    .bus_sel(bus_sel),

    .hit(hit),
    .dirty(dirty),
	.valid_out(valid_out),

    .mem_byte_enable(mem_byte_enable)
);

L2_cache_datapath datapath(
    .clk(clk),
    .set_valid(set_valid),
    .set_dirty(set_dirty),
    .clear_dirty(clear_dirty),
    .load_tag(load_tag),
    .way_sel(way_sel),
    .data_write_en(data_write_en),
	 
	.bus_sel(bus_sel),

    .load_lru(load_lru),
    .lru_out(lru_out),

    .pmem_address_sel(pmem_address_sel),
    .data_in_sel(data_in_sel),

    .hit(hit),
    .dirty(dirty),
	.valid_out(valid_out),

    .pmem_rdata(pmem_rdata),       // physical
    .pmem_wdata(pmem_wdata),
    .pmem_address(pmem_address),

    .mem_write(mem_write),                //  L1
    .mem_read(mem_read),
    .mem_address(mem_address),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata)
);

endmodule : L2_cache
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

    // Lines to CPU/bus adapter
    input logic [31:0] mem_address,
    input logic [31:0] mem_wdata,
    output logic [31:0] mem_rdata,
    input logic [3:0] mem_byte_enable,
    input mem_read,
    input mem_write,
    output logic mem_resp,

    //Lines to physical memory/cacheline adapter
    output logic [31:0] pmem_address,
    input logic [s_line-1:0] pmem_rdata,
    output logic [s_line-1:0] pmem_wdata,
    output logic pmem_read,
    output logic pmem_write,
    input pmem_resp

);

logic [s_line-1:0] mem_wdata256, mem_rdata256;
logic hit, dirty;

logic set_read, set_write, set_load;
logic load_pmem_data;
    
logic pmem_data_mux_sel, pmem_addr_mux_sel, cache_data_mux_sel;


logic [31:0] mem_byte_enable256;

logic prev_mem_read;
logic prev_mem_write;
logic [3:0] prev_mem_byte_enable_cpu;
logic [31:0] prev_mem_address;
logic [31:0] prev_mem_wdata_cpu;

always_ff@(posedge clk) begin
  if(!rst) begin
    if((prev_mem_write || prev_mem_read) && mem_resp || !(prev_mem_write || prev_mem_read) && !mem_resp) begin
      prev_mem_read <= mem_read;
      prev_mem_write <= mem_write;
      prev_mem_byte_enable_cpu <= mem_byte_enable;
      prev_mem_address <= mem_address;
      prev_mem_wdata_cpu <= mem_wdata_cpu;
    end
  end else begin
    prev_mem_read <= 0;
    prev_mem_write <= 0;
    prev_mem_byte_enable_cpu <= 0;
    prev_mem_address <= 0;
    prev_mem_wdata_cpu <= 0;
  end
end

cache_control control
(
    .*,
    .hit(hit),
    .dirty(dirty),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .pmem_resp(pmem_resp),
    .set_read(set_read),
    .set_write(set_write),
    .pmem_addr_mux_sel(pmem_addr_mux_sel),
	.cache_data_mux_sel(cache_data_mux_sel),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .mem_resp(mem_resp)
);

cache_datapath datapath
(
    .*,
    .mem_address(prev_mem_address),
    .data_in(mem_wdata256),

    .data_from_pmem(pmem_rdata),
    .data_to_pmem(pmem_wdata),

    .data_out(mem_rdata256),
    .hit(hit),
    .dirty(dirty),

    .read(set_read),
    .write(set_write),
    .load(set_load),
    
    .pmem_data_mux_sel(pmem_data_mux_sel),
    .pmem_addr_mux_sel(pmem_addr_mux_sel),
    .cache_data_mux_sel(cache_data_mux_sel),

    .pmem_address_cache(pmem_address),
    .mem_byte_enable256(mem_byte_enable256),
    
    .index_in(mem_address[9:5])
);

bus_adapter bus_adapter
(
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(mem_rdata256),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .address(mem_address)
);

endmodule : cache

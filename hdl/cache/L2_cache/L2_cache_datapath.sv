module L2_cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input logic set_valid,
    input logic set_dirty,
    input logic clear_dirty,
    input logic load_tag,
    input logic [1:0] way_sel,
    input logic [31:0] data_write_en,
	 
	input logic bus_sel,
    input logic load_lru,
    output logic [1:0] lru_out,
    input logic [2:0] pmem_address_sel,
    input logic [31:0] data_in_sel,
    output logic [3:0] hit,
    output logic [3:0] dirty,
	output logic [3:0] valid_out,

    input logic [255:0] pmem_rdata,       // physical
    output logic [255:0] pmem_wdata,
    output logic [31:0] pmem_address,

    input logic mem_write,                //  L1
    input logic mem_read,
    input logic [31:0] mem_address,
    input logic [255:0] mem_wdata,
    output logic [255:0] mem_rdata
);

logic [3:0] dataway_hit;
assign dataway_hit = {(way_sel == 2'b11),(way_sel == 2'b10),(way_sel == 2'b01),(way_sel == 2'b00)};
logic [1:0] mru;

logic [31:0] write_enable_0;
logic [31:0] write_enable_1;
logic [31:0] write_enable_2;
logic [31:0] write_enable_3;
logic load_tag_0;
logic load_tag_1;
logic load_tag_2;
logic load_tag_3;
logic [3:0] clear_dirty_in;
logic set_valid_0;
logic set_valid_1;
logic set_valid_2;
logic set_valid_3;
logic [3:0] load_dirty;

assign write_enable_0 = dataway_hit[0] ? data_write_en : 32'd0;
assign write_enable_1 = dataway_hit[1] ? data_write_en : 32'd0;
assign write_enable_2 = dataway_hit[2] ? data_write_en : 32'd0;
assign write_enable_3 = dataway_hit[3] ? data_write_en : 32'd0;
assign load_tag_0 = dataway_hit[0] ? load_tag : 1'b0;
assign load_tag_1 = dataway_hit[1] ? load_tag : 1'b0;
assign load_tag_2 = dataway_hit[2] ? load_tag : 1'b0;
assign load_tag_3 = dataway_hit[3] ? load_tag : 1'b0;
assign set_valid_0 = dataway_hit[0] & set_valid;
assign set_valid_1 = dataway_hit[1] & set_valid;
assign set_valid_2 = dataway_hit[2] & set_valid;
assign set_valid_3 = dataway_hit[3] & set_valid;
assign set_dirty_0 = dataway_hit[0] & set_dirty;
assign set_dirty_1 = dataway_hit[1] & set_dirty;
assign set_dirty_2 = dataway_hit[2] & set_dirty;
assign set_dirty_3 = dataway_hit[3] & set_dirty;
assign clear_dirty_in = dataway_hit & {4{clear_dirty}};


assign load_dirty = {(set_dirty_3 | clear_dirty_in[3]), (set_dirty_2 | clear_dirty_in[2]), (set_dirty_1 | clear_dirty_in[1]), (set_dirty_0 | clear_dirty_in[0])};

logic [255:0] data_in_mux_out;
logic [255:0] data_out_mux_out;
logic [255:0] data_out_0;
logic [255:0] data_out_1;
logic [255:0] data_out_2;
logic [255:0] data_out_3;
logic [23:0] tag_0_out;
logic [23:0] tag_1_out;
logic [23:0] tag_2_out;
logic [23:0] tag_3_out;
logic valid_out_0;
logic valid_out_1;
logic valid_out_2;
logic valid_out_3;
assign valid_out = {valid_out_3, valid_out_2, valid_out_1, valid_out_0};
logic dirty_out_0;
logic dirty_out_1;
logic dirty_out_2;
logic dirty_out_3;


L2_lru_array lru(
	.clk(clk),
	.load(load_lru),
    .index(mem_address[7:5]),
	.mru(way_sel),
	.lru_out(lru_out)
);

L2_data_array data_array_0(
    .clk(clk),
    .read(1'b1),
    .write_en(write_enable_0),
    .index(mem_address[7:5]),
    .datain(data_in_mux_out),
    .dataout(data_out_0)
);

L2_data_array data_array_1(
    .clk(clk),
    .read(1'b1),
    .write_en(write_enable_1),
    .index(mem_address[7:5]),
    .datain(data_in_mux_out),
    .dataout(data_out_1)
);

L2_data_array data_array_2(
    .clk(clk),
    .read(1'b1),
    .write_en(write_enable_2),
    .index(mem_address[7:5]),
    .datain(data_in_mux_out),
    .dataout(data_out_2)
);

L2_data_array data_array_3(
    .clk(clk),
    .read(1'b1),
    .write_en(write_enable_3),
    .index(mem_address[7:5]),
    .datain(data_in_mux_out),
    .dataout(data_out_3)
);

L2_array #(.width(24)) tag_array_0(
    .clk(clk),
    .read(1'b1),
    .load(load_tag_0),
    .index(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag_0_out)
);

L2_array #(.width(24)) tag_array_1(
    .clk(clk),
    .read(1'b1),
    .load(load_tag_1),
    .index(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag_1_out)
);
L2_array #(.width(24)) tag_array_2(
    .clk(clk),
    .read(1'b1),
    .load(load_tag_2),
    .index(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag_2_out)
);
L2_array #(.width(24)) tag_array_3(
    .clk(clk),
    .read(1'b1),
    .load(load_tag_3),
    .index(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag_3_out)
);

L2_array valid_array_0(
    .clk(clk),
    .read(1'b1),
    .load(set_valid_0),
    .index(mem_address[7:5]),
    .datain(1'b1),
    .dataout(valid_out_0)
);

L2_array valid_array_1(
    .clk(clk),
    .read(1'b1),
    .load(set_valid_1),
    .index(mem_address[7:5]),
    .datain(1'b1),
    .dataout(valid_out_1)
);

L2_array valid_array_2(
    .clk(clk),
    .read(1'b1),
    .load(set_valid_2),
    .index(mem_address[7:5]),
    .datain(1'b1),
    .dataout(valid_out_2)
);

L2_array valid_array_3(
    .clk(clk),
    .read(1'b1),
    .load(set_valid_3),
    .index(mem_address[7:5]),
    .datain(1'b1),
    .dataout(valid_out_3)
);

L2_array dirty_array_0(
    .clk(clk),
    .read(1'b1),
    .load(load_dirty[0]),
    .index(mem_address[7:5]),
    .datain(set_dirty_0),
    .dataout(dirty_out_0)
);

L2_array dirty_array_1(
    .clk(clk),
    .read(1'b1),
    .load(load_dirty[1]),
    .index(mem_address[7:5]),
    .datain(set_dirty_1),
    .dataout(dirty_out_1)
);


L2_array dirty_array_2(
    .clk(clk),
    .read(1'b1),
    .load(load_dirty[2]),
    .index(mem_address[7:5]),
    .datain(set_dirty_2),
    .dataout(dirty_out_2)
);

L2_array dirty_array_3(
    .clk(clk),
    .read(1'b1),
    .load(load_dirty[3]),
    .index(mem_address[7:5]),
    .datain(set_dirty_3),
    .dataout(dirty_out_3)
);

assign dirty = {(dirty_out_3 & valid_out_3), (dirty_out_2 & valid_out_2), (dirty_out_1 & valid_out_1), (dirty_out_0 & valid_out_0)};

always_comb begin : datapath_mux
    unique case(pmem_address_sel)
        3'd0:   pmem_address = {mem_address[31:5], 5'd0};               
        3'd2:   pmem_address = {tag_0_out, mem_address[7:5], 5'd0};
        3'd3:   pmem_address = {tag_1_out, mem_address[7:5], 5'd0};
        3'd4:   pmem_address = {tag_2_out, mem_address[7:5], 5'd0};
        3'd5:	pmem_address = {tag_3_out, mem_address[7:5], 5'd0};
        default: pmem_address = {mem_address[31:5], 5'd0};
    endcase

    for (int i = 0; i < 32; i++) begin
        data_in_mux_out[8*i +: 8] = (data_in_sel[i]) ? mem_wdata[8*i +: 8] : pmem_rdata[8*i +: 8];
    end

    unique case(hit)
        4'b0001: data_out_mux_out = data_out_0;
        4'b0010: data_out_mux_out = data_out_1;
        4'b0100: data_out_mux_out = data_out_2;
        4'b1000: data_out_mux_out = data_out_3;
        default: data_out_mux_out = 256'd0;
    endcase

    unique case(lru_out)
        2'b00: pmem_wdata = data_out_0;
        2'b01: pmem_wdata = data_out_1;
        2'b10: pmem_wdata = data_out_2;
        2'b11: pmem_wdata = data_out_3; 
        default: pmem_wdata = 256'd0;
    endcase

	 unique case (bus_sel)
		  1'b0: mem_rdata = data_out_mux_out;
		  1'b1: mem_rdata = pmem_rdata;
		  default: mem_rdata = data_out_mux_out;
	 endcase
end

assign hit[0] = valid_out_0 & (mem_address[31:8] == tag_0_out);
assign hit[1] = valid_out_1 & (mem_address[31:8] == tag_1_out);
assign hit[2] = valid_out_2 & (mem_address[31:8] == tag_2_out);
assign hit[3] = valid_out_3 & (mem_address[31:8] == tag_3_out);

endmodule : L2_cache_datapath
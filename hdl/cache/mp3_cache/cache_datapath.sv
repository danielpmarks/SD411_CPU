/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
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
    input logic [31:0] mem_address,
    input logic [s_line-1:0] data_in,

    input logic [s_line-1:0] data_from_pmem,
    output logic [s_line-1:0] data_to_pmem,

    output logic [s_line-1:0] data_out,
    output logic hit,
    output logic dirty,

    input read,
    input write,
    input load,
    
    input pmem_data_mux_sel,
    input pmem_addr_mux_sel,
    input cache_data_mux_sel,

    output logic [31:0] pmem_address_cache,
    input logic [s_mask-1:0] mem_byte_enable256,

    input index_in
);

logic [s_line-1:0] cache_data_in;
logic [31:0] replace_address;

logic [s_index-1:0] set_idx;
logic [s_offset-1:0] offset;
logic [s_tag-1:0] tag;


logic [s_tag-1:0] tag_out_0, tag_out_1;
logic [s_line-1:0] data_out_0, data_out_1;
logic load_tag_0, load_tag_1, write_data_0, write_data_1, load_valid_0, load_valid_1, load_dirty_0, load_dirty_1;
logic valid_in, valid_out_0, valid_out_1;
logic dirty_in, dirty_out_0, dirty_out_1;
logic load_data_0, load_data_1;
logic lru_in, lru_out, load_lru;

assign set_idx = mem_address[s_offset + s_index - 1 -: s_index];
assign offset = mem_address[s_offset - 1 : 0];
assign tag = mem_address[31-:s_tag];

assign data_to_pmem = data_out;

icache_array #(.width(1))
lru (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_lru),
    .rindex(index_in),
    .windex(index_in),
    .datain(set_lru),
    .dataout(lru_output)
);

icache_array #(.width(1))
valid_array_0(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid_0),
    .rindex(index_in),
    .windex(index_in),
    .datain(1'b1),
    .dataout(valid_out[0])
);

icache_array #(.width(1))
valid_array_1(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid_1),
    .rindex(index_in),
    .windex(index_in),
    .datain(1'b1),
    .dataout(valid_out[1])
);

tag_array_22_5 tag_array_0(
    .address(index_in),
	.clock(clk),
	.data(input_tag),
    .rden(1'b1),
	.wren(load_tag_0),
	.q(tag_output_0)
);

tag_array_22_5 tag_array_1(
    .address(index_in),
	.clock(clk),
	.data(input_tag),
    .rden(1'b1),
	.wren(load_tag_1),
	.q(tag_output_1)
);

data_array_32 data_array_0 (
    .address(index_in),
	.byteena(load_data_0 ? write_data_0 ? mem_byte_enable256 : 32'd0),
    .clock(clk),
	.data(data_from_pmem),
    .rden(1'b1),
	.wren(load_data_0 || write_data_0),
	.q(output_data_0)
);

data_array_32 data_array_1 (
    .address(index_in),
	.byteena(load_data_1 ? write_data_1 ? mem_byte_enable256 : 32'd0),
    .clock(clk),
	.data(data_from_pmem),
    .rden(1'b1),
	.wren(load_data_1 || write_data_1),
	.q(output_data_1)
);
always_comb begin
    data_out = 0;
    load_lru = 0;
    write_data_0 = 0;
    write_data_1 = 0;
    load_valid_0 = 0;
    load_valid_1 = 0;
    load_dirty_0 = 0;
    load_dirty_1 = 0;
    load_data_0 = 0;
    load_data_1 = 0;
    load_tag_0 = 0;
    load_tag_1 = 0;
    replace_address = 0;
    dirty = 0;
    hit = 0;
    dirty_in = 0;
    valid_in = 0;
    lru_in = 0;
    if(tag == tag_out_0 && valid_out_0 == 1) begin
        // Hit - read from cacheline for read op and write to cacheline for write op
        hit = 1;
        dirty = dirty_out_0;
        load_lru = 1;
        lru_in = 1;
        if(read) begin
            data_out = data_out_0;
        end
        else if(write) begin
            write_data_0 = 1;
            load_dirty_0 = 1;
            dirty_in = 1;
        end
    end
    else if(tag == tag_out_1 && valid_out_1 == 1) begin
        // Hit - read from cacheline for read op and write to cacheline for write op
        
        hit = 1;
        dirty = dirty_out_1;
        load_lru = 1;
        lru_in = 0;
        if(read) begin
                data_out = data_out_1;
        end
        else if(write) begin
                write_data_1 = 1;
                load_dirty_0 = 1;
                dirty_in = 1;
        end
    end
    else begin
        // Miss - replace least recent cacheline with data from pmem
        hit = 0;
        //If way 0 is open, fill this first
        if(valid_out_0 == 0) begin
            //Wait for load signal
            if(load == 1) begin
                load_data_0 = 1;
                load_valid_0 = 1;
                load_dirty_0 = 1;
                load_data_0 = 1;
                load_tag_0 = 1;
                load_lru = 1;

                lru_in = 1;
                valid_in = 1;
                dirty_in = 0;
            end
        end
        //If way 0 is full but way 1 is open, fill way 1
        else if (valid_out_1 == 0) begin
            //Wait for load signal
            if(load == 1) begin
                load_data_1 = 1;
                load_valid_1 = 1;
                load_dirty_1 = 1;
                load_data_1 = 1;
                load_tag_1= 1;
                load_lru = 1;

                lru_in = 0;
                valid_in = 1;
                dirty_in = 0;
            end
        end
        //Neither way is open, replace the least recent way
        else begin
                if(lru_out == 0) begin
                    //Read data from way 0 to store to memory
                    data_out = data_out_0;
                    //Set dirty out
                    dirty = dirty_out_0;
                    //Output the address of this cacheline to store into pmem
                    replace_address = {tag_out_0, set_idx, 5'd0};
                    //Wait for write signal to store data from pmem
                    if(load == 1) begin
                        load_data_0 = 1;
                        load_valid_0 = 1;
                        load_dirty_0 = 1;
                        load_tag_0 = 1;
                        load_lru = 1;

                        lru_in = 1;
                        valid_in = 1;
                        dirty_in = 0;
                    end
                end
                else begin
                    //Read data from way 0 to store to memory
                    data_out = data_out_1;
                    //Set dirty out
                    dirty = dirty_out_1;
                    //Output the address of this cacheline to store into pmem
                    replace_address = {tag_out_1, set_idx, 5'd0};
                    //Wait for write signal to store data from pmem
                    if(load == 1) begin
                        load_data_1 = 1;
                        load_valid_1 = 1;
                        load_dirty_1 = 1;
                        load_tag_1= 1;
                        load_lru = 1;

                        lru_in = 0;
                        valid_in = 1;
                        dirty_in = 0;
                    end
                end
        end
	  
    end
end


/******************************** Muxes **************************************/
always_comb begin : MUXES
    unique case(pmem_addr_mux_sel)
        0: pmem_address_cache = mem_address;
        1: pmem_address_cache = replace_address;
    endcase

    unique case(cache_data_mux_sel)
        0: cache_data_in = data_in;
        1: cache_data_in = data_from_pmem;
    endcase
end

endmodule : cache_datapath

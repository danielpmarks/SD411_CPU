/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module dcache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 5,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
	input rst,

	//signal to control
    input logic pmem_read,
    input logic pmem_write,
    input logic mem_resp,	
    input logic mem_enable_sel,
    output logic[1:0] hit_datapath,
    input logic [31:0] write_enable_0,
    input logic [31:0] write_enable_1,
    //lru input
    input logic set_lru,
    input logic load_lru,

    //dirty input
    input logic[1:0] load_dirty, 
    input logic[1:0] set_dirty, 
    
    //valid input
    input logic[1:0] load_valid, 
    input logic[1:0] set_valid, 
    
    //tag control
    input logic[1:0] load_tag,

    //data control
    input logic data_array_select,

    //output to control
    output logic lru_output,
    output logic[1:0] valid_out,
    output logic[1:0] dirty_out,
        
    /* Signals between cache and CPU */
    input logic mem_write,
    input logic mem_read,
    input logic mem_write_delayed,
    input logic mem_read_delayed,
    input logic [31:0] mem_address,
    input logic [4:0] index_in,

    /* Signals between cache and main memory */
    output logic [31:0] pmem_address,
    output logic [255:0] pmem_wdata,
    input logic [255:0] pmem_rdata,
    
    /* Signals between cache and bus adapter */
    input logic [31:0] mem_byte_enable256,
    input logic [255:0] mem_wdata256,
    output logic [255:0] mem_rdata256,

    input logic [1:0] wren
);

//internal signal
logic [21:0] input_tag;
logic [4:0] input_index;
logic hit_0, hit_1;
logic [255:0] data_array_in;
logic [255:0] output_data_0;
logic [255:0] output_data_1;
logic [21:0] tag_output_0;
logic [21:0] tag_output_1;

//breaking down mem_address
assign input_tag = mem_address[31:10];
assign input_index = index_in;


//hit
assign hit_0 = (mem_write_delayed | mem_read_delayed) && valid_out[0] && (tag_output_0 == input_tag);
assign hit_1 = (mem_write_delayed | mem_read_delayed) && valid_out[1] && (tag_output_1 == input_tag);
assign hit_datapath = {hit_1, hit_0};

logic [255:0] data_in;

assign data_in = hit_0 || hit_1 ? mem_wdata256 : pmem_rdata;

dcache_array #(.s_index(s_index), .width(1))
lru (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_lru),
    .rindex(input_index),
    .windex(mem_address[9:5]),
    .datain(set_lru),
    .dataout(lru_output)
);

dcache_array #(.s_index(s_index), .width(1))
valid_array_0(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid[0]),
    .rindex(input_index),
    .windex(input_index),
    .datain(1'b1),
    .dataout(valid_out[0])
);

dcache_array #(.s_index(s_index), .width(1))
valid_array_1(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid[1]),
    .rindex(input_index),
    .windex(input_index),
    .datain(1'b1),
    .dataout(valid_out[1])
);

dcache_array #(.s_index(s_index), .width(1))
dirty_array_0(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty[0]),
    .rindex(input_index),
    .windex(input_index),
    .datain(set_dirty[0]),
    .dataout(dirty_out[0])
);


dcache_array #(.s_index(s_index), .width(1))
dirty_array_1(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty[1]),
    .rindex(input_index),
    .windex(input_index),
    .datain(set_dirty[1]),
    .dataout(dirty_out[1])
);


tag_array_22_5 tag_array_0(
    .address(input_index),
	.clock(clk),
	.data(input_tag),
    .rden(1'b1),
	.wren(load_tag[0]),
	.q(tag_output_0)
);

tag_array_22_5 tag_array_1(
    .address(input_index),
	.clock(clk),
	.data(input_tag),
    .rden(1'b1),
	.wren(load_tag[1]),
	.q(tag_output_1)
);

data_array_32 data_array_0 (
    .address(input_index),
	.byteena(write_enable_0),
    .clock(clk),
	.data(data_in),
    .rden(1'b1),
	.wren(wren[0]),
	.q(output_data_0)
);

data_array_32 data_array_1 (
    .address(input_index),
	.byteena(write_enable_1),
    .clock(clk),
	.data(data_in),
    .rden(1'b1),
	.wren(wren[1]),
	.q(output_data_1)
);
/*data_array_64 data_array_0 (
    .address(input_index),
	.byteena(write_enable_0),
    .clock(clk),
	.data(pmem_rdata),
	.wren(1'b1),
	.q(output_data_0)
);

data_array_64 data_array_1 (
    .address(input_index),
	.byteena(write_enable_1),
    .clock(clk),
	.data(pmem_rdata),
	.wren(1'b1),
	.q(output_data_1)
);*/


always_comb begin

    pmem_wdata = 32'd0;
    mem_rdata256 = 256'd0;
    
    unique case (hit_datapath)
        //miss
        2'b00: begin
            //check which is LRU
            unique case(lru_output) 
                //first data
                1'b0: begin
                    pmem_wdata = output_data_0;
                end
                //second data
                1'b1: begin
                    pmem_wdata = output_data_1;
                end
            endcase
            mem_rdata256 = pmem_rdata;
        end

        //hit_0
        2'b01: begin      
            mem_rdata256 = output_data_0;           
        end

        //hit_1
        2'b10: begin
            mem_rdata256 = output_data_1;
        end
        default: ;
    endcase
end


always_comb begin
    //input to data array
    unique case (mem_enable_sel)
		1'b1 : data_array_in = pmem_rdata;
		1'b0 : data_array_in = mem_wdata256;
        default: data_array_in = mem_wdata256;
	endcase

    //output to physical memory tag when write back
    unique case ({pmem_write, pmem_read})
		2'b10: begin
			case (lru_output)
				1'b0: pmem_address = {tag_output_0, input_index, 5'h0};
				1'b1: pmem_address = {tag_output_1, input_index, 5'h0};
			endcase		
		end
		2'b01:	pmem_address = mem_address;
		default: pmem_address = 32'h0;
	endcase
end
endmodule : dcache_datapath

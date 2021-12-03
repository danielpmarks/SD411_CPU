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
    output logic[3:0] hit_datapath,
    input logic [31:0] write_enable_0,
    input logic [31:0] write_enable_1,
    input logic [31:0] write_enable_2,
    input logic [31:0] write_enable_3,
    //lru input
    input logic [2:0] set_lru,
    input logic load_lru,

    //dirty input
    input logic[3:0] load_dirty, 
    input logic set_dirty, 
    
    //valid input
    input logic[3:0] load_valid, 
    
    //tag control
    input logic[3:0] load_tag,

    //data control
    input logic data_array_select,

    //output to control
    output logic [2:0] lru_output,
    output logic[3:0] valid_out,
    output logic[3:0] dirty_out,
        
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

    input logic [3:0] wren
);

//internal signal
logic [21:0] input_tag;
logic [4:0] input_index;
logic hit_0, hit_1, hit_2, hit_3;
logic [255:0] data_array_in;
logic [255:0] output_data_0;
logic [255:0] output_data_1;
logic [255:0] output_data_2;
logic [255:0] output_data_3;
logic [21:0] tag_output_0;
logic [21:0] tag_output_1;
logic [21:0] tag_output_2;
logic [21:0] tag_output_3;

//breaking down mem_address
assign input_tag = mem_address[31:10];
assign input_index = index_in;


//hit
assign hit_0 = (mem_write_delayed | mem_read_delayed) && valid_out[0] && (tag_output_0 == input_tag);
assign hit_1 = (mem_write_delayed | mem_read_delayed) && valid_out[1] && (tag_output_1 == input_tag);
assign hit_2 = (mem_write_delayed | mem_read_delayed) && valid_out[2] && (tag_output_2 == input_tag);
assign hit_3 = (mem_write_delayed | mem_read_delayed) && valid_out[3] && (tag_output_3 == input_tag);
assign hit_datapath = {hit_3, hit_2, hit_1, hit_0};

logic [255:0] data_in;

assign data_in = hit_0 || hit_1 || hit_2 || hit_3 ? mem_wdata256 : pmem_rdata;

dcache_array #(.s_index(s_index), .width(3))
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
    .windex(mem_address[9:5]),
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
    .windex(mem_address[9:5]),
    .datain(1'b1),
    .dataout(valid_out[1])
);

dcache_array #(.s_index(s_index), .width(1))
valid_array_2(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid[2]),
    .rindex(input_index),
    .windex(mem_address[9:5]),
    .datain(1'b1),
    .dataout(valid_out[2])
);

dcache_array #(.s_index(s_index), .width(1))
valid_array_3(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid[3]),
    .rindex(input_index),
    .windex(mem_address[9:5]),
    .datain(1'b1),
    .dataout(valid_out[3])
);

dcache_array #(.s_index(s_index), .width(1))
dirty_array_0(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty[0]),
    .rindex(input_index),
    .windex(mem_address[9:5]),
    .datain(set_dirty),
    .dataout(dirty_out[0])
);


dcache_array #(.s_index(s_index), .width(1))
dirty_array_1(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty[1]),
    .rindex(input_index),
    .windex(mem_address[9:5]),
    .datain(set_dirty),
    .dataout(dirty_out[1])
);

dcache_array #(.s_index(s_index), .width(1))
dirty_array_2(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty[2]),
    .rindex(input_index),
    .windex(mem_address[9:5]),
    .datain(set_dirty),
    .dataout(dirty_out[2])
);


dcache_array #(.s_index(s_index), .width(1))
dirty_array_3(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty[3]),
    .rindex(input_index),
    .windex(mem_address[9:5]),
    .datain(set_dirty),
    .dataout(dirty_out[3])
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

tag_array_22_5 tag_array_2(
    .address(input_index),
	.clock(clk),
	.data(input_tag),
    .rden(1'b1),
	.wren(load_tag[2]),
	.q(tag_output_2)
);

tag_array_22_5 tag_array_3(
    .address(input_index),
	.clock(clk),
	.data(input_tag),
    .rden(1'b1),
	.wren(load_tag[3]),
	.q(tag_output_3)
);

dcache_data_array_32 data_array_0 (
    .rdaddress(input_index),
    .wraddress(mem_address[9:5]),
	.byteena_a(write_enable_0),
    .clock(clk),
	.data(data_in),
    .rden(1'b1),
	.wren(wren[0]),
	.q(output_data_0)
);

dcache_data_array_32 data_array_1 (
    .rdaddress(input_index),
    .wraddress(mem_address[9:5]),
	.byteena_a(write_enable_1),
    .clock(clk),
	.data(data_in),
    .rden(1'b1),
	.wren(wren[1]),
	.q(output_data_1)
);
dcache_data_array_32 data_array_2 (
    .rdaddress(input_index),
    .wraddress(mem_address[9:5]),
	.byteena_a(write_enable_2),
    .clock(clk),
	.data(data_in),
    .rden(1'b1),
	.wren(wren[2]),
	.q(output_data_2)
);

dcache_data_array_32 data_array_3 (
    .rdaddress(input_index),
    .wraddress(mem_address[9:5]),
	.byteena_a(write_enable_3),
    .clock(clk),
	.data(data_in),
    .rden(1'b1),
	.wren(wren[3]),
	.q(output_data_3)
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
        4'b0000: begin
            //check which is LRU
            unique case(lru_output[0]) 
                
                1'b0: begin
                    pmem_wdata = lru_output[1] ? output_data_1 : output_data_0;
                end
                1'b1: begin
                    pmem_wdata = lru_output[2] ? output_data_3 : output_data_2;
                end
            endcase
            mem_rdata256 = pmem_rdata;
        end

        //hit_0
        4'b0001: begin      
            mem_rdata256 = output_data_0;           
        end

        //hit_1
        4'b0010: begin
            mem_rdata256 = output_data_1;
        end
        
        //hit_2
        4'b0100: begin
            mem_rdata256 = output_data_2;
        end
        
        //hit_3
        4'b1000: begin
            mem_rdata256 = output_data_3;
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
			case (lru_output[0])
				1'b0: pmem_address = lru_output[1] ? {tag_output_1, input_index, 5'h0} : {tag_output_0, input_index, 5'h0};
				1'b1: pmem_address = lru_output[2] ? {tag_output_3, input_index, 5'h0} : {tag_output_2, input_index, 5'h0};
			endcase		
		end
		2'b01:	pmem_address = mem_address;
		default: pmem_address = 32'h0;
	endcase
end
endmodule : dcache_datapath

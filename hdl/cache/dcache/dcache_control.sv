/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module dcache_control (
    input logic mem_read,
    input logic mem_write,
	input logic clk,
	input logic pmem_resp,
    //lru input
    output logic set_lru,
    output logic load_lru,

    //dirty input
    output logic[1:0] load_dirty, 
    output logic[1:0] set_dirty, 
    
    //valid input
    output logic[1:0] load_valid, 
    output logic[1:0] set_valid, 
    
    //tag control
    output logic[1:0] load_tag,

    //data control
    output logic data_array_select,

    //output to control
    input logic lru_output,
    input logic[1:0] valid_out,
    input logic[1:0] dirty_out,
    input logic [1:0] hit_datapath,


    output logic pmem_read,
    output logic pmem_write,
    output logic mem_resp,	
    output logic mem_enable_sel,
    output logic [31:0] write_enable_0,
    output logic [31:0] write_enable_1,
    input logic [31:0] mem_byte_enable256,

    output logic[1:0] wren
    
);

logic writing, next_writing;

enum int unsigned {
    /* List of states */
	
    hit,
    write_back,
    write_cache
} state, next_states;

function void set_defaults();
    set_lru = 0;
    load_lru = 0;
    load_dirty = 0; 
    set_dirty = 0;
    load_valid = 0;
    set_valid = 0;
    load_tag = 0;
    data_array_select = 0;
    pmem_read = 0;
    pmem_write = 0;
    mem_resp = 0;	
    mem_enable_sel = 0;
    write_enable_0 = {32{1'b1}};
    write_enable_1 = {32{1'b1}};
    next_writing = 0;
    wren = 0;
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */

    unique case (state) 
        

        hit: begin
            //miss
        
            

            //hit first way
            if (hit_datapath == 2'b01) begin
                //first data
                set_lru = 1;
                
                if (mem_read) begin
                    mem_enable_sel = 1'b0;
                    write_enable_0 = 32'd0;
                    mem_resp = 1'b1;
                    load_lru = 1'b1;
                end
                else if (mem_write) begin
                
                    //set the first dirty
                    set_dirty = 2'b01;
                    load_dirty = 2'b01;
                    mem_enable_sel = 1'b0;
                    write_enable_0 = mem_byte_enable256;
                    wren[0] = 1'b1;
                    //set lru at the end of the write
                    load_lru = 1'b1;
                    next_writing = 1'b1;
                
                    mem_resp = 1'b1;
                    next_writing = 1'b0;
                    
                end
            end

            //hit second way
            else if (hit_datapath == 2'b10) begin
                //second data
                set_lru = 0;
                
                if (mem_read) begin
                    mem_enable_sel = 1'b0;
                    write_enable_1 = 32'd0;
                    mem_resp = 1'b1;
                    load_lru = 1'b1;
                end
                else if (mem_write) begin
                    //set the first dirty
                    set_dirty = 2'b10;
                    load_dirty = 2'b10;
                    mem_enable_sel = 1'b0;
                    write_enable_1 = mem_byte_enable256;
                    wren[1] = 1'b1;
                    //set lru at the end of the write
                    load_lru = 1'b1;
                    next_writing = 1'b1;
                    mem_resp = 1'b1;
                    next_writing = 1'b0;
                end
            end
        end

        write_back: begin
            pmem_write = 1'b1;
            //if (lru_output)
            if (pmem_resp) begin
                //set lru to be the other one
                set_lru = ~lru_output;
                if (dirty_out[lru_output]) begin
                    //mem_enable_sel = 1'b1;
                    set_dirty[lru_output] = 0;
                    load_dirty[lru_output] = 1;
                end
            end
        end

        write_cache: begin
            pmem_read = 1'b1;
            mem_enable_sel = 1'b1;
            if (lru_output) begin
                write_enable_1 = 32'hffffffff;
            end
            else begin
                write_enable_0 = 32'hffffffff;
            end
            
            
            pmem_write = 1'b0;
            if (pmem_resp) begin
                set_valid[lru_output] = 1'b1;
                load_valid[lru_output] = 1'b1;
                mem_enable_sel = 1'b1;
                load_tag[lru_output] = 1'b1;
                load_lru = 1'b1;
                wren[lru_output] = 1'b1;
            end
        end

    endcase

end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    next_states = state;
    unique case (state)
        /*idle: begin
            if (mem_read | mem_write) next_states = hit;
            else next_states = idle;
        end*/

        hit: begin
            if(mem_read | mem_write) begin
                if (hit_datapath == 0) begin
                    if(dirty_out[lru_output]) next_states = write_back;
                    else next_states = write_cache;
                end
                else begin
                    next_states = hit;
                end
            end
        end

        write_back: begin
            if (pmem_resp) next_states = write_cache;
            else next_states = write_back;
        end

        write_cache: begin
            if (pmem_resp) next_states = hit;
            else next_states = write_cache;
        end
		
        default: next_states = hit;
	
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_states;
    writing <= next_writing;
end

endmodule : dcache_control

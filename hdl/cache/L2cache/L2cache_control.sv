/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */



module L2cache_control (
    input logic mem_read,
    input logic mem_write,
	input logic clk,
	input logic pmem_resp,
    //lru input
    output logic [2:0] set_lru,
    output logic load_lru,

    //dirty input
    output logic[3:0] load_dirty, 
    output logic[3:0] set_dirty, 
    
    //valid input
    output logic[3:0] load_valid, 
    output logic[3:0] set_valid, 
    
    //tag control
    output logic[3:0] load_tag,

    //output to control
    input logic [2:0] lru_output,
    input logic[3:0] valid_out,
    input logic[3:0] dirty_out,
    input logic [3:0] hit_datapath,


    output logic pmem_read,
    output logic pmem_write,
    output logic mem_resp,	
    output logic mem_enable_sel,
    output logic [31:0] write_enable_0,
    output logic [31:0] write_enable_1,
    output logic [31:0] write_enable_2,
    output logic [31:0] write_enable_3,
    input logic [31:0] mem_byte_enable256
    
);
int index;
int translated_index;
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
    pmem_read = 0;
    pmem_write = 0;
    mem_resp = 0;
    index = 0;
    mem_enable_sel = 0;
    write_enable_0 = 0;
    write_enable_1 = 0;
    write_enable_2 = 0;
    write_enable_3 = 0;
endfunction


always_comb
begin : current_lru_index
    case (lru_output)
        3'b000: translated_index = 0;
        3'b010: translated_index = 1;
        3'b001: translated_index = 0;
        3'b011: translated_index = 1;
        3'b100: translated_index = 2;
        3'b101: translated_index = 3;
        3'b110: translated_index = 2;
        3'b111: translated_index = 3;
    endcase
end
always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    set_lru = lru_output;
    unique case (state)
        hit: begin
            //miss
            if (mem_read | mem_write) begin
                if (hit_datapath == 0) begin
                    //set lru to be the other one
                    case (translated_index)
                        0: begin
                            set_lru[2] = 1'b1;
                            set_lru[1] = 1'b1;
                        end
                        1:begin
                            set_lru[2] = 1'b1;
                            set_lru[1] = 1'b0;
                        end
                        2:begin
                            set_lru[2] = 1'b0;
                            set_lru[0] = 1'b1;
                        end
                        3:begin
                            set_lru[2] = 1'b0;
                            set_lru[0] = 1'b0;
                        end
                        default: ;
                    endcase
                    if (dirty_out[translated_index]) begin
                        //mem_enable_sel = 1'b1;
                        set_dirty[translated_index] = 1'b0;
                        load_dirty[translated_index] = 1'b1;
                    end
                end

                //hit first way
                if (hit_datapath == 4'b0001) begin
                    //first data
                    set_lru[2] = 1'b1;
                    set_lru[1] = 1'b1;
                    
                    if (mem_read) begin
                        mem_enable_sel = 1'b0;
                        write_enable_0 = 32'd0;
                        mem_resp = 1'b1;
                        load_lru = 1'b1;
                    end
                    else if (mem_write) begin
                        mem_resp = 1'b1;
                        //set the first dirty
                        set_dirty = 4'b0001;
                        load_dirty = 4'b0001;
                        mem_enable_sel = 1'b0;
                        write_enable_0 = mem_byte_enable256;
                        //set lru at the end of the write
                        load_lru = 1'b1;
                    end
                end

                //hit second way
                if (hit_datapath == 4'b0010) begin
                    //second data
                    set_lru[2] = 1'b1;
                    set_lru[1] = 1'b0;
                    
                    if (mem_read) begin
                        mem_enable_sel = 1'b0;
                        write_enable_1 = 32'd0;
                        mem_resp = 1'b1;
                        load_lru = 1'b1;
                    end
                    else if (mem_write) begin
                        mem_resp = 1'b1;
                        //set the second dirty
                        set_dirty = 4'b0010;
                        load_dirty = 4'b0010;
                        mem_enable_sel = 1'b0;

                        write_enable_1 = mem_byte_enable256;

                        //set lru at the end of the write
                        load_lru = 1'b1;
                    end
                end

                if (hit_datapath == 4'b0100) begin
                    //third data
                    set_lru[2] = 1'b0;
                    set_lru[0] = 1'b1;
                    
                    if (mem_read) begin
                        mem_enable_sel = 1'b0;
                        write_enable_2 = 32'd0;
                        mem_resp = 1'b1;
                        load_lru = 1'b1;
                    end
                    else if (mem_write) begin
                        mem_resp = 1'b1;
                        //set the third dirty
                        set_dirty = 4'b0100;
                        load_dirty = 4'b0100;
                        mem_enable_sel = 1'b0;

                        write_enable_2 = mem_byte_enable256;

                        //set lru at the end of the write
                        load_lru = 1'b1;
                    end
                end

                if (hit_datapath == 4'b1000) begin
                    //fourth data
                    set_lru[2] = 1'b0;
                    set_lru[0] = 1'b0;
                    
                    if (mem_read) begin
                        mem_enable_sel = 1'b0;
                        write_enable_3 = 32'd0;
                        mem_resp = 1'b1;
                        load_lru = 1'b1;
                    end
                    else if (mem_write) begin
                        mem_resp = 1'b1;
                        //set the fourth dirty
                        set_dirty = 4'b1000;
                        load_dirty = 4'b1000;
                        mem_enable_sel = 1'b0;

                        write_enable_3 = mem_byte_enable256;

                        //set lru at the end of the write
                        load_lru = 1'b1;
                    end
                end
            end
        end

        write_back: begin
            pmem_write = 1'b1;
            //if (lru_output)
        end

        write_cache: begin
            pmem_read = 1'b1;
            mem_enable_sel = 1'b1;
            case (translated_index)
                0: write_enable_0 = 32'hffffffff;
                1: write_enable_1 = 32'hffffffff;
                2: write_enable_2 = 32'hffffffff;
                3: write_enable_3 = 32'hffffffff;
            endcase
            

            set_valid[translated_index] = 1'b1;
            load_valid[translated_index] = 1'b1;
            
            pmem_write = 1'b0;
            if (pmem_resp) begin
                //pmem_write = 1'b0;
                //mem_resp = 1'b1;
                mem_enable_sel = 1'b1;
                load_tag[translated_index] = 1'b1;
                //set lru to the opposite way at the end of the write
                //set_lru = ~lru_output
                load_lru = 1'b1;
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
                    if(dirty_out[translated_index]) next_states = write_back;
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
end

endmodule : L2cache_control

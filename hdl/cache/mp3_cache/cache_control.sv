/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input clk,
    input rst,
    input hit,
    input dirty,

    input mem_read,
    input mem_write,

    input logic pmem_resp,

    output logic set_read,
    output logic set_write,
    output logic set_load,
    
    output logic pmem_addr_mux_sel,
	output logic cache_data_mux_sel,
    output logic pmem_read,
    output logic pmem_write,
    
    output logic mem_resp

);

// Buffer is used to make sure that a second read/write is not
// performed after mem_resp is asserted and mem_read/mem_write is still high


enum int unsigned {
    HIT_RW,
    BUFFER,
    LOAD_FROM_PMEM,
    STORE_TO_PMEM
} state, next_state;

always_ff @(posedge clk) begin
    if(rst) begin
        state <= BUFFER;
    end
    else begin
        state <= next_state;
    end
end

always_comb begin: state_control_logic
	set_read = 0;
	set_write = 0;
	set_load = 0;
	mem_resp = 0;
	pmem_read = 0;
	pmem_write = 0;
	pmem_addr_mux_sel = 0;
	cache_data_mux_sel = 0;
    unique case(state)
        HIT_RW: begin
            if(hit) begin
                if(mem_read) begin
                    set_read = 1;
                    mem_resp = 1;
                end
                else if(mem_write) begin
                    set_write = 1;
                    mem_resp = 1;
                end
            end
        end
        STORE_TO_PMEM: begin
            pmem_addr_mux_sel = 1;
            pmem_write = 1;
            set_read = 1;
        end
        LOAD_FROM_PMEM: begin
            pmem_read = 1;
            pmem_addr_mux_sel = 0;
            if(pmem_resp) begin
                set_load = 1;
                cache_data_mux_sel = 1;
            end
        end
        default: ;
    endcase

end

always_comb begin : next_state_logic
    next_state = BUFFER;
    unique case(state)
        BUFFER:  begin
            if(mem_read || mem_write)
                next_state = HIT_RW;
            else begin
                next_state = BUFFER;
            end
        end
        HIT_RW: begin
            if(mem_read) begin
                next_state = hit ? BUFFER : dirty ? STORE_TO_PMEM : LOAD_FROM_PMEM;
            end 
            else if (mem_write) begin
                next_state = hit ? BUFFER : dirty ? STORE_TO_PMEM : LOAD_FROM_PMEM;
            end
        end
        STORE_TO_PMEM: begin
            if(pmem_resp == 1)
                next_state = LOAD_FROM_PMEM;
            else 
                next_state = STORE_TO_PMEM;
        end
        LOAD_FROM_PMEM: begin
            if(pmem_resp == 1)
                next_state = HIT_RW;
            else 
                next_state = LOAD_FROM_PMEM;
        end
        default: next_state = HIT_RW;
    endcase
end

endmodule : cache_control

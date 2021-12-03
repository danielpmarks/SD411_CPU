module L2_cache_control (
    input clk,
    output logic set_valid,
    output logic set_dirty,
    output logic clear_dirty,
    output logic load_tag,
    output logic [1:0] way_sel,
    output logic [31:0] data_write_en,
    input logic [1:0] lru_out,
    output logic load_lru,

    input logic pmem_resp,
    output logic pmem_write,
    output logic pmem_read,
    output logic victim_cache_dirty,
	 
	input logic mem_read,
	input logic mem_write,
	output logic mem_resp,

    output logic [2:0] pmem_address_sel,
    output logic [31:0] data_in_sel,
    output logic bus_sel,
    input logic [3:0] hit,
    input logic [3:0] dirty,
	input logic [3:0] valid_out,
    input logic [31:0] mem_byte_enable
);

logic lru [3:0];  
assign lru[0] = lru_out == 2'b00;
assign lru[1] = lru_out == 2'b01;
assign lru[2] = lru_out == 2'b10;
assign lru[3] = lru_out == 2'b11;

logic lru_valid;  
assign lru_valid = (lru[0] & valid_out[0]) | (lru[1] & valid_out[1]) | (lru[2] & valid_out[2]) | (lru[3] & valid_out[3]);

logic lru_dirty; 
assign lru_dirty = (lru[0] & dirty[0]) | (lru[1] & dirty[1]) | (lru[2] & dirty[2]) | (lru[3] & dirty[3]);

enum int unsigned 
{
    idle,hit_target,read,write,load_data
} state, next_state;

function void set_defaults();
    way_sel = 2'b0;
    set_valid = 1'b0;
    set_dirty = 1'b0;
    clear_dirty = 1'b0;
    load_tag = 1'b0;
    load_lru = 1'b0;
    data_in_sel = 32'hFFFFFFFF;
    data_write_en = 32'd0;

    pmem_address_sel = 3'd0;
    pmem_write = 1'b0;
    pmem_read = 1'b0;
	mem_resp = 1'b0;
	bus_sel = 1'b0;
	victim_cache_dirty = 1'b0;
endfunction

always_comb begin : next_state_logic
    unique case (state)
        idle: next_state = (mem_read | mem_write) ? hit_target : idle;
        hit_target: begin
            if (hit[0] | hit[1] | hit[2] | hit[3]) begin
                next_state = idle;
            end else begin				 
				if (lru_valid) begin
					next_state = write;
				end else begin
					next_state = read;
				end
            end
        end
        read: begin
            if (pmem_resp) begin
                next_state =idle;
            end else begin
                next_state = read;
            end
        end
            //next_state = (pmem_resp) ? idle : read;
        write: begin
            if (pmem_resp) begin
                if (mem_write) begin
                    next_state = load_data;
                end else begin
                    next_state = read;
                end
            end else begin
                next_state = write;
            end
        end
            //next_state = pmem_resp ? (mem_write ? load_data : read) : write;
        load_data: next_state = idle;
        default: next_state = idle;
    endcase
end

always_comb begin : state_actions
    set_defaults();
    unique case (state)
        idle: begin
        end
        hit_target: begin
            if (hit[0] | hit[1] | hit[2] | hit[3]) begin
                mem_resp = 1'b1;
                load_lru = 1'b1;
                if (mem_write) begin
                    if (hit[0]) begin
                        way_sel = 2'b00;
                    end 
                    else if (hit[1]) begin
                        way_sel = 2'b01;
                    end 
                    else if (hit[2]) begin
                        way_sel = 2'b10;
                    end 
                    else if (hit[3]) begin
                        way_sel = 2'b11;
                    end
                    set_dirty = 1'b1;
                    data_in_sel = 32'hFFFFFFFF;
                    data_write_en = mem_byte_enable;
                end
            end else begin
                if (lru_valid) begin
                    pmem_address_sel = lru_out + 3'd2;
                    victim_cache_dirty = lru_dirty;
                end else begin
                    data_write_en = 32'hFFFFFFFF;
                    way_sel = lru_out;
                    load_tag = 1'b1;
                    clear_dirty = 1'b1;
                    data_in_sel = 32'd0;
                    pmem_address_sel = 3'd0;
                end
            end
        end
        read: begin
            data_write_en = 32'h00000000;
			way_sel = lru_out;
			pmem_read = 1'b1;
            data_in_sel = 32'd0;
            pmem_address_sel = 3'd0;
            if (pmem_resp) begin
                data_write_en = 32'hFFFFFFFF;                      
                load_lru = 1'b1;
                set_valid = 1'd1;
                way_sel = lru_out;
                bus_sel = 1'b1;					 
                if (mem_write) begin                  
                    data_in_sel = mem_byte_enable;
                    set_dirty = 1'b1; 
                end
                mem_resp = 1'b1;
            end
        end
        write: begin
			pmem_address_sel = lru_out + 3'd2;
            victim_cache_dirty = lru_dirty;				            
            pmem_write = 1'b1;
            if (pmem_resp) begin            
			    way_sel = lru_out;
                load_tag = 1'b1;
                clear_dirty = 1'b1;
                data_in_sel = 32'd0;               
            end
        end
        load_data: begin
            load_lru = 1'b1;
            way_sel = lru_out;
            data_in_sel = mem_byte_enable;
            set_valid = 1'd1;
            data_write_en = 32'hFFFFFFFF;
            set_dirty = 1'b1; 
            mem_resp = 1'b1;
        end
        default: set_defaults();
    endcase
end


always_ff @(posedge clk) begin : state_update
    state <= next_state;
end

endmodule : L2_cache_control
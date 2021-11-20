/* A register array to be used for tag arrays, LRU array, etc. */

module victim_cache #(
    parameter s_index = 4,
    parameter width = 256
)
(
    clk,
    rst,
    request_from_cache,
    address,
    is_dirty,
    evicted_data,
    pmem_resp,
    resp,
    found,
    dataout,
    pmem_write,
    mem_address,
    pmem_write_data,
);

localparam num_sets = 2**s_index;

input clk;
input rst;
input request_from_cache; // tempt from cache for finding data and store evicted data
input logic [31:0] address; // the address of the missed
input logic is_dirty; // indicating if the evicted data is dirty
input logic [width-1:0] evicted_data; // the evicted data that will be replaced by missed data
input logic pmem_resp; // resp from main memory
output logic resp; // resp to cache
output logic found; // indicating if successfully find the missed data in victim cache
output logic [width-1:0] dataout; // the missed data if found
output logic pmem_write; // write request to main memory
output logic [31:0] mem_address;
output logic [width-1:0] pmem_write_data; // write_data


int write_back_index;
logic [width-1:0] write_back_data;

logic lru_arr [15]; // the 15 bits pesudo lru
logic dirty_arr [num_sets-1:0]; // dirty bit indicator
logic valid_arr [num_sets-1:0]; // indicated the if the cell is occupied i.e. need for writeback

logic [width-1:0] data_arr [num_sets-1:0] ; // work as the value of the dictionary
logic [31:0] address_arr [num_sets-1:0]; // work as key of the dictionary
logic [width-1:0] _dataout; // if "hit" return read_data as dataout
assign dataout = _dataout;

/**
update the lru according to the recently used data index
this is a binary search tree represented by nested if-statement
*/
function void set_lru(int index);
    if (index <= 7) begin
        lru_arr[0] = 1;
        if (index <= 3) begin
            lru_arr[1] = 1;
            if (index <= 1) begin
                lru_arr[2] = 1;
                if (index == 1)begin
                    lru_arr[3] = 0;
                end
                else begin
                    lru_arr[3] = 1;
                end
            end
            else begin
                lru_arr[2] = 0;
                if (index == 3)begin
                    lru_arr[4] = 0;
                end
                else begin
                    lru_arr[4] = 1;
                end
            end
        end
        else begin
            lru_arr[1] = 0;
            if (index <= 5) begin
                lru_arr[5] = 1;
                if (index == 5)begin
                    lru_arr[6] = 0;
                end
                else begin
                    lru_arr[6] = 1;
                end
            end
            else begin
                lru_arr[5] = 0;
                if (index == 7)begin
                    lru_arr[7] = 0;
                end
                else begin
                    lru_arr[7] = 1;
                end
            end
        end
    end
    else begin
        lru_arr[0] = 0
        if (index <= 11) begin
            lru_arr[8] = 1;
            if (index <= 9) begin
                lru_arr[9] = 1;
                if (index == 9)begin
                    lru_arr[10] = 0;
                end
                else begin
                    lru_arr[10] = 1;
                end
            end
            else begin
                lru_arr[9] = 0;
                if (index == 11)begin
                    lru_arr[11] = 0;
                end
                else begin
                    lru_arr[11] = 1;
                end
            end
        end
        else begin
            lru_arr[8] = 0;
            if (index <= 13) begin
                lru_arr[12] = 1;
                if (index == 13)begin
                    lru_arr[13] = 0;
                end
                else begin
                    lru_arr[13] = 1;
                end
            end
            else begin
                lru_arr[12] = 0;
                if (index == 15)begin
                    lru_arr[14] = 0;
                end
                else begin
                    lru_arr[14] = 1;
                end
            end
        end
    end
endfunction

/**
get the index of lru data according to the current lru_arr
*/
function int get_iru_index();
    int idx = 0;
    if (iru_arr[0]) begin
        idx = idx + 8;
    end
    else begin
        idx = idx + 1;
    end

    if (iru_arr[idx]) begin
        idx = idx + 4;
    end
    else begin
        idx = idx + 1;
    end

    if (iru_arr[idx]) begin
        idx = idx + 2;
    end
    else begin
        idx = idx + 1;
    end
    
    case (idx)
        3: begin
            if (lru_arr[idx]) begin
                return 1;
            end
            else begin
                return 0;
            end
        end
        4: begin
            if (lru_arr[idx]) begin
                return 3;
            end
            else begin
                return 2;
            end
        end
        6: begin
            if (lru_arr[idx]) begin
                return 5;
            end
            else begin
                return 4;
            end
        end
        7: begin
            if (lru_arr[idx]) begin
                return 7;
            end
            else begin
                return 6;
            end
        end
        10: begin
            if (lru_arr[idx]) begin
                return 9;
            end
            else begin
                return 8;
            end
        end
        11: begin
            if (lru_arr[idx]) begin
                return 11;
            end
            else begin
                return 10;
            end
        end
        13: begin
            if (lru_arr[idx]) begin
                return 13;
            end
            else begin
                return 12;
            end
        end
        14: begin
            if (lru_arr[idx]) begin
                return 15;
            end
            else begin
                return 14;
            end
        end
    endcase

endfunction


enum int unsigned
{
    idle,
    write_back
} state, next_state;

always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i = 0; i < num_sets; ++i)
            data_arr[i] <= '0;
            dirty_arr[i] <= '0;
            address_arr[i] <= '0;
            valid_arr[i] <= '0;
            if (i != 15)
                lru_arr[i] <= '0;
        state <= idle;
    end else begin
        state <= next_state;
    end

end
/*
always_comb begin : next_state_logic
    if(request_from_cache) begin
        for (int i = 0; i < 16; ++i)
            if (address == address_arr[i])
                _dataout = data_arr[i];
                set_lru(i);
    end
end
*/
always_comb begin: next_state_logic
    write_back_data = '0;
    pmem_write = 0;
    pmem_write_data = '0;
    _dataout = '0;
    found = 0;
    resp = 0;
    next_state = state;
    write_back_index = '0;
    mem_address = '0;
    case(state):
        idle: begin
            if(request_from_cache) begin // start working by the request from cache
                write_back_index = get_iru_index();
                for (int i = 0; i < 16; ++i) // search if missed data is in the data_arr
                    if (address == address_arr[i])
                        found = 1;
                        _dataout = data_arr[i];
                        set_lru(i);
                // if the iru data is dirty and valid, then we write it back to main memory
                if (valid_arr[write_back_index] && dirty_arr[write_back_index]) begin
                    pmem_write = 1;
                    pmem_write_data = data_arr[write_back_index];
                    mem_address = address;
                    next_state = write_back;
                    valid_arr[write_back_index] = 1;
                    dirty_arr[write_back_index] = is_dirty;
                    address_arr[write_back_index] = address;
                    data_arr[write_back_index] = evicted_data;
                end else begin // otherwise we only overwrite the iru with evicted data
                    valid_arr[write_back_index] = 1;
                    dirty_arr[write_back_index] = is_dirty;
                    address_arr[write_back_index] = address;
                    data_arr[write_back_index] = evicted_data;
                    resp = 1;
                end
                
            end
            
        end
        write_back: begin
            if (pmem_resp)begin
                next_state = idle;
                resp = 1;
            end
        end
    endcase
    

end

endmodule : victim_cache

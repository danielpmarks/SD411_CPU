module arbiter(
    input clk,
    input rst,

    //data cache
    input logic [31:0] pmem_address_c_d, // from llc
    input logic [255:0] pmem_wdata_c_d, // from llc
    input logic pmem_read_c_d, // from llc
    input logic pmem_write_c_d,// from llc
    output logic pmem_resp_c_d, // to llc
    output logic [255:0] pmem_rdata_c_d,// to llc

    //Instruction cache
    input logic pmem_read_c_i,
    input logic [31:0] pmem_address_c_i, //from llc
    output logic pmem_resp_c_i,//to llc
    output logic [255:0] pmem_rdata_c_i,//to llc

    // memory
    input logic pmem_resp_m,//from memory
    input logic [255:0] pmem_rdata_m,//from memory
    output logic [31:0] pmem_address_m,//to memory
    output logic [255:0] pmem_wdata_m,//to memory
    output logic pmem_read_m,
    output logic pmem_write_m
);

enum int unsigned
{
    idle,
    data_cache,
    instruction_cache
} state, next_state;


always_comb begin

	/* Default */
    pmem_read_m = 0;
    pmem_write_m = 0;
    pmem_address_m = 0;
    pmem_wdata_m = 0;
    pmem_resp_c_i = 0;
    pmem_rdata_c_i = 0;
    pmem_resp_c_d  = 0;
    pmem_rdata_c_d  = 0;

	case(state)
        idle: begin
            if (pmem_read_c_d || pmem_write_c_d) begin
                pmem_read_m = pmem_read_c_d;
                pmem_write_m = pmem_write_c_d;
                pmem_address_m = pmem_address_c_d;
                pmem_wdata_m = pmem_wdata_c_d;
            end else if (pmem_read_c_i) begin
                pmem_read_m = pmem_read_c_i;
                pmem_address_m = pmem_address_c_i;
                pmem_wdata_m = pmem_wdata_c_i;
            end
        end

        instruction_cache: begin
            if (pmem_resp_m) begin
                pmem_resp_c_i = pmem_resp_m;
                pmem_rdata_c_i = pmem_rdata_m;
            end
        end

        data_cache: begin
            if (pmem_resp_m) begin
                pmem_resp_c_d = pmem_resp_m;
                pmem_rdata_c_d = pmem_rdata_m;
            end
        end
	endcase
end

/* Next State Logic */
always_comb begin : next_state_logic

	/* Default state transition */
	next_state = state;

	case(state)
        idle: begin
            if (pmem_read_c_d || pmem_write_c_d) begin
                next_state = data_cache;
            end else if (pmem_read_c_i) begin
                next_state = instruction_cache;
            end
        end

        instruction_cache: begin
            if (pmem_read_c_d || pmem_write_c_d) begin
                next_state = data_cache;
            end
            else begin
                next_state = idle;
            end
        end

        data_cache: begin
            if (pmem_resp_m) begin
                next_state = idle;
            end
        end
	endcase
end

always_ff @(posedge clk) begin: next_state_assignment
    if (rst) begin
        state <= idle;
    end else begin
        state <= next_state;
    end
	 
end

endmodule : arbiter
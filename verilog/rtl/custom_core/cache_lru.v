module cache_lru (
	clock,
	reset,
	victim_req,
	victim_set,
	victim_way,
	update_req,
	update_set,
	update_way
);
	parameter NUM_SET = 2;
	parameter NUM_WAYS = 2;
	parameter WAYS_PER_SET = 1;
	function [31:0] clog2;
		input reg [31:0] value;
		integer i;
		reg [31:0] j;
		begin
			j = value - 1;
			clog2 = 0;
			for (i = 0; i < 31; i = i + 1)
				if (j[i])
					clog2 = i + 1;
		end
	endfunction
	parameter NUM_SET_W = clog2(NUM_SET);
	parameter NUM_WAYS_W = clog2(NUM_WAYS);
	parameter WAYS_PER_SET_W = clog2(WAYS_PER_SET);
	input wire clock;
	input wire reset;
	input wire victim_req;
	input wire [NUM_SET_W - 1:0] victim_set;
	output wire [WAYS_PER_SET_W - 1:0] victim_way;
	input wire update_req;
	input wire [NUM_SET_W - 1:0] update_set;
	input wire [WAYS_PER_SET_W - 1:0] update_way;
	reg [WAYS_PER_SET_W - 1:0] victim_per_set [NUM_SET - 1:0];
	assign victim_way = victim_per_set[victim_set];
	genvar gen_it;
	generate
		for (gen_it = 0; gen_it < NUM_SET; gen_it = gen_it + 1) begin : gen_set_lru
			reg [(WAYS_PER_SET >= 1 ? (WAYS_PER_SET_W >= 1 ? (WAYS_PER_SET * WAYS_PER_SET_W) - 1 : (WAYS_PER_SET * (2 - WAYS_PER_SET_W)) + (WAYS_PER_SET_W - 2)) : (WAYS_PER_SET_W >= 1 ? ((2 - WAYS_PER_SET) * WAYS_PER_SET_W) + (((WAYS_PER_SET - 1) * WAYS_PER_SET_W) - 1) : ((2 - WAYS_PER_SET) * (2 - WAYS_PER_SET_W)) + (((WAYS_PER_SET_W - 1) + ((WAYS_PER_SET - 1) * (2 - WAYS_PER_SET_W))) - 1))):(WAYS_PER_SET >= 1 ? (WAYS_PER_SET_W >= 1 ? 0 : WAYS_PER_SET_W - 1) : (WAYS_PER_SET_W >= 1 ? (WAYS_PER_SET - 1) * WAYS_PER_SET_W : (WAYS_PER_SET_W - 1) + ((WAYS_PER_SET - 1) * (2 - WAYS_PER_SET_W))))] counter;
			reg [(WAYS_PER_SET >= 1 ? (WAYS_PER_SET_W >= 1 ? (WAYS_PER_SET * WAYS_PER_SET_W) - 1 : (WAYS_PER_SET * (2 - WAYS_PER_SET_W)) + (WAYS_PER_SET_W - 2)) : (WAYS_PER_SET_W >= 1 ? ((2 - WAYS_PER_SET) * WAYS_PER_SET_W) + (((WAYS_PER_SET - 1) * WAYS_PER_SET_W) - 1) : ((2 - WAYS_PER_SET) * (2 - WAYS_PER_SET_W)) + (((WAYS_PER_SET_W - 1) + ((WAYS_PER_SET - 1) * (2 - WAYS_PER_SET_W))) - 1))):(WAYS_PER_SET >= 1 ? (WAYS_PER_SET_W >= 1 ? 0 : WAYS_PER_SET_W - 1) : (WAYS_PER_SET_W >= 1 ? (WAYS_PER_SET - 1) * WAYS_PER_SET_W : (WAYS_PER_SET_W - 1) + ((WAYS_PER_SET - 1) * (2 - WAYS_PER_SET_W))))] counter_ff;
			reg [WAYS_PER_SET_W - 1:0] max_count;
			always @(posedge clock)
				if (reset)
					counter_ff <= {(WAYS_PER_SET >= 1 ? WAYS_PER_SET : 2 - WAYS_PER_SET) * (WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W) {1'sb0}};
				else
					counter_ff <= counter;
			integer i;
			integer j;
			always @(*) begin
				counter = counter_ff;
				if (victim_req && (victim_set == gen_it)) begin
					max_count = {(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W) {1'sb0}};
					victim_per_set[gen_it] = {(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W) {1'sb0}};
					for (i = 0; i < WAYS_PER_SET; i = i + 1)
						if (max_count < counter_ff[(WAYS_PER_SET_W >= 1 ? 0 : WAYS_PER_SET_W - 1) + ((WAYS_PER_SET >= 1 ? i : (WAYS_PER_SET - 1) - i) * (WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W))+:(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W)]) begin
							max_count = counter_ff[(WAYS_PER_SET_W >= 1 ? 0 : WAYS_PER_SET_W - 1) + ((WAYS_PER_SET >= 1 ? i : (WAYS_PER_SET - 1) - i) * (WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W))+:(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W)];
							victim_per_set[gen_it] = i;
						end
				end
				if (update_req && (update_set == gen_it)) begin
					for (j = 0; j < WAYS_PER_SET; j = j + 1)
						if (counter_ff[(WAYS_PER_SET_W >= 1 ? 0 : WAYS_PER_SET_W - 1) + ((WAYS_PER_SET >= 1 ? j : (WAYS_PER_SET - 1) - j) * (WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W))+:(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W)] <= counter_ff[(WAYS_PER_SET_W >= 1 ? 0 : WAYS_PER_SET_W - 1) + ((WAYS_PER_SET >= 1 ? update_way : (WAYS_PER_SET - 1) - update_way) * (WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W))+:(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W)])
							counter[(WAYS_PER_SET_W >= 1 ? 0 : WAYS_PER_SET_W - 1) + ((WAYS_PER_SET >= 1 ? j : (WAYS_PER_SET - 1) - j) * (WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W))+:(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W)] = counter_ff[(WAYS_PER_SET_W >= 1 ? 0 : WAYS_PER_SET_W - 1) + ((WAYS_PER_SET >= 1 ? j : (WAYS_PER_SET - 1) - j) * (WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W))+:(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W)] + 1'b1;
					counter[(WAYS_PER_SET_W >= 1 ? 0 : WAYS_PER_SET_W - 1) + ((WAYS_PER_SET >= 1 ? update_way : (WAYS_PER_SET - 1) - update_way) * (WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W))+:(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W)] = {(WAYS_PER_SET_W >= 1 ? WAYS_PER_SET_W : 2 - WAYS_PER_SET_W) {1'sb0}};
				end
			end
		end
	endgenerate
endmodule

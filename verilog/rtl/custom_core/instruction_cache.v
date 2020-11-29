module instruction_cache (
	clock,
	reset,
	icache_ready,
	xcpt_bus_error,
	req_addr,
	req_valid,
	rsp_data,
	rsp_valid,
	req_valid_miss,
	req_info_miss,
	rsp_data_miss,
	rsp_bus_error,
	rsp_valid_miss
);
	input wire clock;
	input wire reset;
	output wire icache_ready;
	output reg xcpt_bus_error;
	input wire [19:0] req_addr;
	input wire req_valid;
	output reg [127:0] rsp_data;
	output reg rsp_valid;
	output reg req_valid_miss;
	output reg [148:0] req_info_miss;
	input wire [127:0] rsp_data_miss;
	input wire rsp_bus_error;
	input wire rsp_valid_miss;
	reg [511:0] instMem_data;
	reg [511:0] instMem_data_ff;
	reg [59:0] instMem_tag;
	reg [59:0] instMem_tag_ff;
	reg [3:0] instMem_valid;
	reg [3:0] instMem_valid_ff;
	always @(posedge clock) instMem_data_ff <= instMem_data;
	always @(posedge clock) instMem_tag_ff <= instMem_tag;
	always @(posedge clock)
		if (reset)
			instMem_valid_ff <= {4 {1'sb0}};
		else
			instMem_valid_ff <= instMem_valid;
	reg icache_hit;
	reg [0:0] hit_way;
	reg [14:0] req_addr_tag;
	reg [1:0] req_addr_pos;
	reg [1:0] miss_icache_pos;
	reg [0:0] req_addr_set;
	reg [0:0] miss_icache_set_ff;
	wire [0:0] miss_icache_way;
	reg [0:0] miss_icache_way_ff;
	always @(posedge clock)
		if (reset)
			miss_icache_set_ff <= 1'sb0;
		else if (!icache_hit)
			miss_icache_set_ff <= req_addr_set;
	always @(posedge clock)
		if (reset)
			miss_icache_way_ff <= 1'sb0;
		else if (!icache_hit)
			miss_icache_way_ff <= miss_icache_way;
	reg icache_ready_next;
	reg icache_ready_ff;
	assign icache_ready = icache_ready_next;
	always @(posedge clock)
		if (reset)
			icache_ready_ff <= 1'b0;
		else
			icache_ready_ff <= icache_ready_next;
	reg pendent_req;
	reg pendent_req_ff;
	always @(posedge clock)
		if (reset)
			pendent_req_ff <= 1'b0;
		else
			pendent_req_ff <= pendent_req;
	integer iter;
	always @(*) begin
		instMem_valid = instMem_valid_ff;
		instMem_tag = instMem_tag_ff;
		instMem_data = instMem_data_ff;
		icache_ready_next = icache_ready_ff;
		pendent_req = pendent_req_ff;
		req_addr_tag = req_addr[19:5];
		req_addr_set = req_addr[4:4];
		hit_way = 1'sb0;
		req_addr_pos = {2 {1'sb0}};
		req_valid_miss = 1'b0;
		req_info_miss[127-:128] = {128 {1'sb0}};
		icache_hit = 1'b0;
		rsp_valid = 1'b0;
		xcpt_bus_error = 1'b0;
		if (req_valid & !pendent_req_ff) begin
			for (iter = 0; iter < 2; iter = iter + 1)
				if ((instMem_tag_ff[(iter + (req_addr_set * 2)) * 15+:15] == req_addr_tag) & (instMem_valid_ff[iter + (req_addr_set * 2)] == 1'b1)) begin
					req_addr_pos = iter + (req_addr_set * 2);
					icache_hit = 1'b1;
					hit_way = iter;
					rsp_data = instMem_data_ff[req_addr_pos * 128+:128];
					rsp_valid = 1'b1;
				end
			if (!icache_hit) begin
				pendent_req = 1'b1;
				req_info_miss[148-:20] = req_addr >> 4;
				req_info_miss[128] = 1'b0;
				req_valid_miss = !reset;
				icache_ready_next = 1'b0;
			end
		end
		if (rsp_valid_miss) begin
			xcpt_bus_error = rsp_bus_error;
			if (!rsp_bus_error) begin
				miss_icache_pos = miss_icache_way_ff + (miss_icache_set_ff * 2);
				instMem_tag[miss_icache_pos * 15+:15] = req_addr_tag;
				instMem_data[miss_icache_pos * 128+:128] = rsp_data_miss;
				instMem_valid[miss_icache_pos] = 1'b1;
				pendent_req = 1'b0;
				icache_ready_next = 1'b1;
			end
			rsp_valid = 1'b1;
			rsp_data = instMem_data[miss_icache_pos * 128+:128];
		end
	end
	wire [0:0] update_set;
	wire [0:0] update_way;
	assign update_set = (rsp_valid_miss & !rsp_bus_error ? miss_icache_set_ff : (icache_hit ? req_addr_set : 1'sb0));
	assign update_way = (rsp_valid_miss & !rsp_bus_error ? miss_icache_way_ff : (icache_hit ? hit_way : 1'sb0));
	cache_lru #(
		.NUM_SET(2),
		.NUM_WAYS(4),
		.WAYS_PER_SET(2)
	) icache_lru(
		.clock(clock),
		.reset(reset),
		.victim_req(!icache_hit),
		.victim_set(req_addr_set),
		.victim_way(miss_icache_way),
		.update_req((rsp_valid_miss & !rsp_bus_error) | icache_hit),
		.update_set(update_set),
		.update_way(update_way)
	);
endmodule

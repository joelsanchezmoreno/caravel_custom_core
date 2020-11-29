module tlb_cache (
	clock,
	reset,
	req_valid,
	req_virt_addr,
	priv_mode,
	rsp_valid,
	tlb_miss,
	rsp_phy_addr,
	writePriv,
	new_tlb_entry,
	new_tlb_info
);
	input wire clock;
	input wire reset;
	input wire req_valid;
	input wire [31:0] req_virt_addr;
	input wire [0:0] priv_mode;
	output reg rsp_valid;
	output reg tlb_miss;
	output reg [19:0] rsp_phy_addr;
	output reg writePriv;
	input wire new_tlb_entry;
	input wire [52:0] new_tlb_info;
	reg [115:0] tlb_cache;
	reg [115:0] tlb_cache_ff;
	reg [3:0] tlb_valid;
	reg [3:0] tlb_valid_ff;
	always @(posedge clock) tlb_cache_ff <= tlb_cache;
	always @(posedge clock)
		if (reset)
			tlb_valid_ff <= {4 {1'sb0}};
		else
			tlb_valid_ff <= tlb_valid;
	reg [0:0] hit_way;
	reg [19:0] req_virt_tag;
	reg [1:0] req_addr_pos;
	reg [1:0] replace_tlb_pos;
	reg [1:0] req_addr_set;
	wire [0:0] victim_way;
	integer iter;
	localparam [0:0] Supervisor = 1'b1;
	always @(*) begin
		tlb_valid = tlb_valid_ff;
		tlb_cache = tlb_cache_ff;
		req_virt_tag = req_virt_addr[31:12];
		hit_way = 1'sb0;
		req_addr_pos = {2 {1'sb0}};
		tlb_miss = 1'b0;
		rsp_valid = 1'b0;
		if (req_valid)
			if (priv_mode == Supervisor) begin
				rsp_valid = 1'b1;
				tlb_miss = 1'b0;
				rsp_phy_addr = req_virt_addr[19:0];
				writePriv = 1'b1;
			end
			else begin
				req_addr_set = req_virt_addr[12:12];
				tlb_miss = 1'b1;
				for (iter = 0; iter < 1; iter = iter + 1)
					if ((tlb_cache_ff[((iter + ((req_addr_set * 2) / 2)) * 29) + 28-:20] == req_virt_tag) & tlb_valid_ff[iter + ((req_addr_set * 2) / 2)]) begin
						req_addr_pos = iter + ((req_addr_set * 2) / 2);
						hit_way = iter;
						rsp_valid = 1'b1;
						tlb_miss = 1'b0;
						rsp_phy_addr = {tlb_cache_ff[(req_addr_pos * 29) + 8-:8], req_virt_addr[11:0]};
						writePriv = tlb_cache_ff[req_addr_pos * 29];
					end
			end
		if (new_tlb_entry) begin
			req_addr_set = new_tlb_info[33:33];
			replace_tlb_pos = victim_way + ((req_addr_set * 2) / 2);
			tlb_valid[replace_tlb_pos] = 1'b1;
			tlb_cache[(replace_tlb_pos * 29) + 28-:20] = new_tlb_info[52:33];
			tlb_cache[(replace_tlb_pos * 29) + 8-:8] = new_tlb_info[20:13];
			tlb_cache[replace_tlb_pos * 29] = 1'b1;
		end
	end
	wire update_en;
	wire [0:0] update_way;
	assign update_en = (req_valid & !tlb_miss) | new_tlb_entry;
	assign update_way = (req_valid & !tlb_miss ? hit_way : victim_way);
	cache_lru #(
		.NUM_SET(2),
		.NUM_WAYS(2),
		.WAYS_PER_SET(1)
	) tlb_lru(
		.clock(clock),
		.reset(reset),
		.victim_req(new_tlb_entry),
		.victim_set(req_addr_set),
		.victim_way(victim_way),
		.update_req(update_en),
		.update_set(req_addr_set),
		.update_way(update_way)
	);
endmodule

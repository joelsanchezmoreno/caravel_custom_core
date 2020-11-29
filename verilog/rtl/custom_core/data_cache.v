module data_cache (
	clock,
	reset,
	dcache_ready,
	xcpt_bus_error,
	req_info,
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
	output wire dcache_ready;
	output reg xcpt_bus_error;
	input wire [238:0] req_info;
	input wire req_valid;
	output reg [31:0] rsp_data;
	output reg rsp_valid;
	output reg req_valid_miss;
	output reg [148:0] req_info_miss;
	input wire [127:0] rsp_data_miss;
	input wire rsp_bus_error;
	input wire rsp_valid_miss;
	reg [511:0] dCache_data;
	reg [511:0] dCache_data_ff;
	reg [59:0] dCache_tag;
	reg [59:0] dCache_tag_ff;
	reg [3:0] dCache_dirty;
	reg [3:0] dCache_dirty_ff;
	reg [3:0] dCache_valid;
	reg [3:0] dCache_valid_ff;
	always @(posedge clock) dCache_data_ff <= dCache_data;
	always @(posedge clock) dCache_tag_ff <= dCache_tag;
	always @(posedge clock)
		if (reset)
			dCache_valid_ff <= {4 {1'sb0}};
		else
			dCache_valid_ff <= dCache_valid;
	always @(posedge clock)
		if (reset)
			dCache_dirty_ff <= {4 {1'sb0}};
		else
			dCache_dirty_ff <= dCache_dirty;
	reg dcache_tags_hit;
	reg [0:0] hit_way;
	reg [54:0] store_buffer_push_info;
	wire [54:0] store_buffer_pop_info;
	wire store_buffer_perform;
	wire store_buffer_pending;
	wire store_buffer_full;
	assign store_buffer_perform = (store_buffer_pending & !req_valid) & dcache_ready;
	reg [1:0] req_target_pos;
	reg [1:0] req_target_pos_ff;
	always @(posedge clock) req_target_pos_ff <= req_target_pos;
	reg [0:0] req_set;
	wire [0:0] miss_dcache_way;
	reg dcache_ready_next;
	reg dcache_ready_ff;
	always @(posedge clock)
		if (reset)
			dcache_ready_ff <= 1'sb0;
		else
			dcache_ready_ff <= dcache_ready_next;
	assign dcache_ready = dcache_ready_ff;
	reg search_store_buffer;
	reg [14:0] search_tag;
	wire store_buffer_hit_tag;
	reg store_buffer_hit_tag_ff;
	wire store_buffer_hit_way;
	reg store_buffer_hit_way_ff;
	always @(posedge clock)
		if (reset)
			store_buffer_hit_tag_ff <= 1'sb0;
		else if (search_store_buffer)
			store_buffer_hit_tag_ff <= store_buffer_hit_tag;
	always @(posedge clock)
		if (reset)
			store_buffer_hit_way_ff <= 1'sb0;
		else if (search_store_buffer)
			store_buffer_hit_way_ff <= store_buffer_hit_way;
	wire [54:0] pending_store_req;
	reg [54:0] pending_store_req_ff;
	always @(posedge clock)
		if (reset)
			pending_store_req_ff <= {55 {1'sb0}};
		else if (store_buffer_hit_tag | store_buffer_hit_way)
			pending_store_req_ff <= pending_store_req;
	reg [238:0] pending_req;
	reg [238:0] pending_req_ff;
	always @(posedge clock) pending_req_ff <= pending_req;
	reg [3:0] req_offset;
	reg [14:0] req_tag;
	reg [1:0] req_size;
	reg [1:0] dcache_state;
	reg [1:0] dcache_state_ff;
	always @(posedge clock)
		if (reset)
			dcache_state_ff <= {2 {1'sb0}};
		else
			dcache_state_ff <= dcache_state;
	integer iter;
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
	localparam [1:0] Byte = 2'b00;
	localparam [1:0] bring_line = 2'b10;
	localparam [1:0] evict_line = 2'b01;
	localparam [1:0] idle = 2'b00;
	localparam [1:0] write_cache_line = 2'b11;
	always @(*) begin
		dcache_ready_next = dcache_ready_ff;
		dcache_state = dcache_state_ff;
		dCache_valid = dCache_valid_ff;
		dCache_tag = dCache_tag_ff;
		dCache_data = dCache_data_ff;
		dCache_dirty = dCache_dirty_ff;
		req_target_pos = req_target_pos_ff;
		search_store_buffer = 1'b0;
		xcpt_bus_error = 1'b0;
		pending_req = pending_req_ff;
		case (dcache_state_ff)
			idle: begin
				dcache_ready_next = !store_buffer_full;
				rsp_valid = 1'b0;
				req_valid_miss = 1'b0;
				dcache_tags_hit = 1'b0;
				req_tag = req_info[186:172];
				req_set = req_info[171:171];
				req_offset = req_info[170:167] >> clog2(req_info[166-:2] + 1);
				if (req_valid) begin
					for (iter = 0; iter < 2; iter = iter + 1)
						if ((dCache_tag_ff[(iter + (req_set * 2)) * 15+:15] == req_tag) & (dCache_valid[iter + (req_set * 2)] == 1'b1)) begin
							req_target_pos = iter + (req_set * 2);
							dcache_tags_hit = 1'b1;
							hit_way = iter;
						end
					if (!dcache_tags_hit)
						req_target_pos = miss_dcache_way + (req_set * 2);
					search_store_buffer = (req_info[164] & dcache_tags_hit ? 1'b0 : (!req_info[164] & dcache_tags_hit ? 1'b1 : dCache_dirty_ff[req_target_pos]));
					search_tag = req_info[186:172];
					if (dcache_tags_hit & req_info[164]) begin
						rsp_valid = 1'b1;
						store_buffer_push_info[54-:20] = req_info[198-:32];
						store_buffer_push_info[34] = hit_way;
						store_buffer_push_info[33-:2] = req_info[166-:2];
						store_buffer_push_info[31-:32] = req_info[163-:32];
					end
					else if (dcache_tags_hit & !req_info[164]) begin
						if (!store_buffer_hit_tag) begin
							if (req_info[166-:2] == Byte) begin
								req_offset = req_info[170:167];
								rsp_data = {{24 {1'b0}}, dCache_data[(req_target_pos * 128) + (8 * req_offset)+:8]};
							end
							else begin
								req_offset = req_info[170:167] >> clog2(req_info[166-:2] + 1);
								rsp_data = dCache_data[(req_target_pos * 128) + (32 * req_offset)+:32];
							end
							rsp_valid = 1'b1;
						end
						else begin
							dcache_ready_next = 1'b0;
							pending_req = req_info;
							dcache_state = write_cache_line;
						end
					end
					else begin
						dcache_ready_next = 1'b0;
						if (store_buffer_hit_way) begin
							pending_req = req_info;
							dcache_state = write_cache_line;
						end
						else if (dCache_dirty_ff[req_target_pos]) begin
							req_info_miss[148-:20] = {dCache_tag[req_target_pos * 15+:15], req_set, {4 {1'b0}}} >> 4;
							req_info_miss[128] = 1'b1;
							req_info_miss[127-:128] = dCache_data_ff[req_target_pos * 128+:128];
							req_valid_miss = 1'b1;
							dCache_valid[req_target_pos] = 1'b0;
							dCache_dirty[req_target_pos] = 1'b0;
							pending_req = req_info;
							dcache_state = evict_line;
						end
						else begin
							req_info_miss[148-:20] = req_info[198-:32] >> 4;
							req_info_miss[128] = 1'b0;
							req_valid_miss = 1'b1;
							pending_req = req_info;
							dcache_state = bring_line;
						end
					end
				end
				else begin
					req_tag = store_buffer_pop_info[54:40];
					req_set = store_buffer_pop_info[39:39];
					req_size = store_buffer_pop_info[33-:2];
					req_target_pos = store_buffer_pop_info[34] + (req_set * 2);
					if (store_buffer_pending) begin
						dCache_tag[req_target_pos * 15+:15] = req_tag;
						dCache_dirty[req_target_pos] = 1'b1;
						if (req_size == Byte) begin
							req_offset = store_buffer_pop_info[38:35];
							dCache_data[(req_target_pos * 128) + (8 * req_offset)+:8] = store_buffer_pop_info[7:0];
						end
						else begin
							req_offset = store_buffer_pop_info[38:35] >> clog2(store_buffer_pop_info[33-:2] + 1);
							dCache_data[(req_target_pos * 128) + (32 * req_offset)+:32] = store_buffer_pop_info[31:0];
						end
					end
				end
			end
			evict_line: begin
				req_valid_miss = 1'b0;
				if (rsp_valid_miss) begin
					req_info_miss[148-:20] = pending_req_ff[198-:32] >> 4;
					req_info_miss[128] = 1'b0;
					req_valid_miss = 1'b1;
					dcache_state = bring_line;
				end
			end
			bring_line: begin
				req_valid_miss = 1'b0;
				if (rsp_valid_miss) begin
					xcpt_bus_error = rsp_bus_error;
					rsp_valid = 1'b1;
					if (!rsp_bus_error) begin
						req_tag = pending_req_ff[186:172];
						req_set = pending_req_ff[171:171];
						req_size = pending_req_ff[166-:2];
						if (pending_req_ff[164]) begin
							dCache_data[req_target_pos_ff * 128+:128] = rsp_data_miss;
							dCache_dirty[req_target_pos_ff] = 1'b1;
							if (req_size == Byte) begin
								req_offset = pending_req_ff[170:167];
								dCache_data[(req_target_pos_ff * 128) + (8 * req_offset)+:8] = pending_req_ff[139:132];
							end
							else begin
								req_offset = pending_req_ff[170:167] >> clog2(pending_req_ff[166-:2] + 1);
								dCache_data[(req_target_pos_ff * 128) + (32 * req_offset)+:32] = pending_req_ff[163:132];
							end
						end
						else begin
							dCache_data[req_target_pos_ff * 128+:128] = rsp_data_miss;
							if (req_size == Byte) begin
								req_offset = pending_req_ff[170:167];
								rsp_data = {{24 {1'b0}}, rsp_data_miss[8 * req_offset+:8]};
							end
							else begin
								req_offset = pending_req_ff[170:167] >> clog2(pending_req_ff[166-:2] + 1);
								rsp_data = rsp_data_miss[32 * req_offset+:32];
							end
						end
						dCache_tag[req_target_pos_ff * 15+:15] = req_tag;
						dCache_valid[req_target_pos_ff] = 1'b1;
					end
					dcache_ready_next = 1'b1;
					dcache_state = idle;
				end
			end
			write_cache_line: begin
				req_valid_miss = 1'b0;
				dcache_ready_next = 1'b0;
				if (store_buffer_hit_tag_ff | store_buffer_hit_way_ff) begin
					req_tag = pending_store_req_ff[54:40];
					req_size = pending_store_req_ff[33-:2];
					dCache_tag[req_target_pos_ff * 15+:15] = req_tag;
					dCache_dirty[req_target_pos_ff] = 1'b1;
					dCache_valid[req_target_pos_ff] = 1'b1;
					if (req_size == Byte) begin
						req_offset = pending_store_req_ff[38:35];
						dCache_data[(req_target_pos_ff * 128) + (8 * req_offset)+:8] = pending_store_req_ff[7:0];
					end
					else begin
						req_offset = pending_store_req_ff[38:35] >> clog2(pending_req_ff[166-:2] + 1);
						dCache_data[(req_target_pos_ff * 128) + (32 * req_offset)+:32] = pending_store_req_ff[31:0];
					end
					search_store_buffer = 1'b1;
					search_tag = pending_req_ff[186:172];
					if (store_buffer_hit_tag | store_buffer_hit_way)
						dcache_state = write_cache_line;
					else if (store_buffer_hit_tag_ff) begin
						req_size = pending_req_ff[166-:2];
						if (!pending_req_ff[164]) begin
							if (req_size == Byte) begin
								req_offset = pending_req_ff[170:167];
								rsp_data = dCache_data[req_target_pos_ff * 128+:128] >> (((req_size + 1) * 8) * req_offset);
								rsp_data = {{24 {1'b0}}, rsp_data[7:0]};
							end
							else begin
								req_offset = pending_req_ff[170:167] >> clog2(pending_req_ff[166-:2] + 1);
								rsp_data = dCache_data[req_target_pos_ff * 128+:128] >> (((req_size + 1) * 8) * req_offset);
								rsp_data = rsp_data[31:0];
							end
							rsp_valid = 1'b1;
						end
						dcache_ready_next = 1'b1;
						dcache_state = idle;
					end
					else begin
						req_info_miss[148-:20] = pending_store_req_ff[54-:20] >> 4;
						req_info_miss[128] = 1'b1;
						req_info_miss[127-:128] = dCache_data[req_target_pos_ff * 128+:128];
						req_valid_miss = 1'b1;
						dCache_valid[req_target_pos_ff] = 1'b0;
						dCache_dirty[req_target_pos_ff] = 1'b0;
						dcache_state = evict_line;
					end
				end
			end
		endcase
	end
	wire [0:0] update_set;
	wire [0:0] update_way;
	wire update_dcache_lru;
	assign update_dcache_lru = dcache_tags_hit | ((dcache_state_ff == bring_line) & rsp_valid_miss);
	assign update_set = req_set;
	assign update_way = (dcache_tags_hit ? hit_way : req_target_pos_ff - (((req_size + 1) * 8) * 2));
	cache_lru #(
		.NUM_SET(2),
		.NUM_WAYS(4),
		.WAYS_PER_SET(2)
	) dcache_lru(
		.clock(clock),
		.reset(reset),
		.victim_req(!dcache_tags_hit),
		.victim_set(req_info[171:171]),
		.victim_way(miss_dcache_way),
		.update_req(update_dcache_lru),
		.update_set(update_set),
		.update_way(update_way)
	);
	store_buffer store_buffer(
		.clock(clock),
		.reset(reset),
		.buffer_empty(store_buffer_pending),
		.buffer_full(store_buffer_full),
		.get_oldest(store_buffer_perform),
		.oldest_info(store_buffer_pop_info),
		.push_valid(dcache_tags_hit & req_info[164]),
		.push_info(store_buffer_push_info),
		.search_valid(search_store_buffer),
		.search_tag(search_tag),
		.search_way(miss_dcache_way),
		.search_rsp_hit_tag(store_buffer_hit_tag),
		.search_rsp_hit_way(store_buffer_hit_way),
		.search_rsp(pending_store_req)
	);
endmodule

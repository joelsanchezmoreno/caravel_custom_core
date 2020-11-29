module store_buffer (
	clock,
	reset,
	buffer_empty,
	buffer_full,
	get_oldest,
	oldest_info,
	push_valid,
	push_info,
	search_valid,
	search_tag,
	search_way,
	search_rsp_hit_tag,
	search_rsp_hit_way,
	search_rsp
);
	input wire clock;
	input wire reset;
	output wire buffer_empty;
	output wire buffer_full;
	input wire get_oldest;
	output wire [55:0] oldest_info;
	input wire push_valid;
	input wire [55:0] push_info;
	input wire search_valid;
	input wire [14:0] search_tag;
	input wire [0:0] search_way;
	output reg search_rsp_hit_tag;
	output reg search_rsp_hit_way;
	output reg [55:0] search_rsp;
	function automatic [0:0] get_first_free_position;
		input reg [1:0] buffer_valid;
		reg found;
		begin
			get_first_free_position = 1'sb0;
			found = 1'b0;
			begin : sv2v_autoblock_1
				reg signed [31:0] it;
				for (it = 0; it < 2; it = it + 1)
					if (!found && !buffer_valid[it]) begin
						get_first_free_position = it;
						found = 1'b1;
					end
			end
		end
	endfunction
	reg [111:0] store_buffer_info;
	reg [111:0] store_buffer_info_ff;
	reg [1:0] store_buffer_valid;
	reg [1:0] store_buffer_valid_ff;
	always @(posedge clock) store_buffer_info_ff <= store_buffer_info;
	always @(posedge clock)
		if (reset)
			store_buffer_valid_ff <= {2 {1'sb0}};
		else
			store_buffer_valid_ff <= store_buffer_valid;
	localparam TREE_SIZE = 3;
	wire [0:0] oldest_id;
	wire [TREE_SIZE - 1:0] oldest_id_tree;
	wire [TREE_SIZE - 1:0] maxcount_tree;
	reg [1:0] counter;
	reg [1:0] counter_ff;
	assign buffer_empty = |store_buffer_valid_ff;
	assign buffer_full = store_buffer_valid_ff == {2 {1'sb1}};
	assign oldest_info = store_buffer_info_ff[oldest_id * 56+:56];
	reg [0:0] max_count_search_tag;
	reg [0:0] max_count_search_way;
	reg [0:0] search_oldest;
	genvar NODE_ID;
	generate
		for (NODE_ID = 0; NODE_ID < TREE_SIZE; NODE_ID = NODE_ID + 1) begin : TREE_GEN
			localparam left_child = (2 * NODE_ID) + 1;
			localparam right_child = (2 * NODE_ID) + 2;
			if (NODE_ID >= (TREE_SIZE - 2)) begin
				assign maxcount_tree[NODE_ID+:1] = counter_ff[NODE_ID - 1+:1];
				assign oldest_id_tree[NODE_ID+:1] = NODE_ID - 1;
			end
			else begin
				assign maxcount_tree[NODE_ID+:1] = (maxcount_tree[left_child+:1] <= maxcount_tree[right_child+:1] ? maxcount_tree[left_child+:1] : maxcount_tree[right_child+:1]);
				assign oldest_id_tree[NODE_ID+:1] = (maxcount_tree[left_child+:1] <= maxcount_tree[right_child+:1] ? oldest_id_tree[left_child+:1] : oldest_id_tree[right_child+:1]);
			end
		end
	endgenerate
	assign oldest_id = oldest_id_tree[0+:1];
	generate
		genvar i;
		for (i = 0; i < 2; i = i + 1) always @(posedge clock)
			if (reset)
				counter_ff[i+:1] <= 1'sb1;
			else
				counter_ff[i+:1] <= counter[i+:1];
	endgenerate
	integer j;
	integer k;
	reg [0:0] free_pos;
	always @(*) begin
		store_buffer_info = store_buffer_info_ff;
		store_buffer_valid = store_buffer_valid_ff;
		search_rsp_hit_tag = 1'b0;
		search_rsp_hit_way = 1'b0;
		free_pos = 1'sb0;
		counter = counter_ff;
		if (get_oldest)
			store_buffer_valid[oldest_id] = 1'b0;
		if (push_valid) begin
			free_pos = get_first_free_position(store_buffer_valid_ff);
			store_buffer_valid[free_pos] = 1'b1;
			store_buffer_info[free_pos * 56+:56] = push_info;
			for (j = 0; j < 2; j = j + 1)
				counter[j+:1] = counter_ff[j+:1] + 1'b1;
			counter[free_pos+:1] = 1'sb0;
		end
		max_count_search_tag = 1'sb0;
		max_count_search_way = 1'sb0;
		if (search_valid) begin
			for (k = 0; k < 2; k = k + 1)
				begin
					if ((search_tag == store_buffer_info_ff[(k * 56) + 55-:15]) & store_buffer_valid_ff[k]) begin
						search_rsp_hit_tag = 1'b1;
						if (max_count_search_tag <= counter_ff[k+:1]) begin
							max_count_search_tag = counter_ff[k+:1];
							search_rsp = store_buffer_info_ff[k * 56+:56];
							search_oldest = k;
						end
					end
					if ((search_way == store_buffer_info_ff[(k * 56) + 35-:2]) & store_buffer_valid_ff[k]) begin
						search_rsp_hit_way = 1'b1;
						if (!search_rsp_hit_tag & (max_count_search_way <= counter_ff[k+:1])) begin
							max_count_search_way = counter_ff[k+:1];
							search_rsp = store_buffer_info_ff[k * 56+:56];
							search_oldest = k;
						end
					end
				end
			if (search_rsp_hit_way | search_rsp_hit_tag)
				store_buffer_valid[search_oldest] = 1'b0;
		end
	end
endmodule

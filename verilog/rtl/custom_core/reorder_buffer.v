module reorder_buffer (
	clock,
	reset,
	reorder_buffer_full,
	reorder_buffer_oldest,
	invalidate_buffer,
	alu_req_valid,
	alu_req_info,
	mem_instr_blocked,
	mem_instr_info,
	mul_req_valid,
	mul_req_info,
	cache_req_valid,
	cache_req_info,
	cache_stage_ready,
	req_to_dcache_valid,
	req_to_dcache_info,
	req_to_RF_writeEn,
	req_to_RF_data,
	req_to_RF_dest,
	req_to_RF_instr_id,
	xcpt_valid,
	xcpt_type,
	xcpt_pc,
	xcpt_addr,
	new_tlb_entry,
	new_tlb_id,
	new_tlb_info,
	mul_src1_id,
	mul_src2_id,
	mul_src1_hit,
	mul_src2_hit,
	mul_src1_data,
	mul_src2_data,
	alu_src1_id,
	alu_src2_id,
	alu_src1_hit,
	alu_src2_hit,
	alu_src1_data,
	alu_src2_data
);
	input wire clock;
	input wire reset;
	output wire reorder_buffer_full;
	output wire [1:0] reorder_buffer_oldest;
	input wire invalidate_buffer;
	input wire alu_req_valid;
	input wire [358:0] alu_req_info;
	input wire mem_instr_blocked;
	input wire [237:0] mem_instr_info;
	input wire mul_req_valid;
	input wire [358:0] mul_req_info;
	input wire cache_req_valid;
	input wire [358:0] cache_req_info;
	input wire cache_stage_ready;
	output reg req_to_dcache_valid;
	output reg [237:0] req_to_dcache_info;
	output reg req_to_RF_writeEn;
	output reg [31:0] req_to_RF_data;
	output reg [4:0] req_to_RF_dest;
	output reg [1:0] req_to_RF_instr_id;
	output reg xcpt_valid;
	output reg [2:0] xcpt_type;
	output reg [31:0] xcpt_pc;
	output reg [31:0] xcpt_addr;
	output reg new_tlb_entry;
	output reg new_tlb_id;
	output reg [52:0] new_tlb_info;
	input wire [1:0] mul_src1_id;
	input wire [1:0] mul_src2_id;
	output reg mul_src1_hit;
	output reg mul_src2_hit;
	output reg [31:0] mul_src1_data;
	output reg [31:0] mul_src2_data;
	input wire [1:0] alu_src1_id;
	input wire [1:0] alu_src2_id;
	output reg alu_src1_hit;
	output reg alu_src2_hit;
	output reg [31:0] alu_src1_data;
	output reg [31:0] alu_src2_data;
	wire [67:0] alu_reorder_buffer_xcpt_info;
	wire [67:0] mul_reorder_buffer_xcpt_info;
	wire [67:0] cache_reorder_buffer_xcpt_info;
	writeback_xcpt writeback_xcpt(
		.alu_req_info(alu_req_info),
		.mul_req_info(mul_req_info),
		.cache_req_info(cache_req_info),
		.alu_rob_xcpt_info(alu_reorder_buffer_xcpt_info),
		.mul_rob_xcpt_info(mul_reorder_buffer_xcpt_info),
		.cache_rob_xcpt_info(cache_reorder_buffer_xcpt_info)
	);
	reg [3:0] reorder_buffer_valid;
	reg [3:0] reorder_buffer_valid_ff;
	reg [1067:0] reorder_buffer_data;
	reg [1067:0] reorder_buffer_data_ff;
	always @(posedge clock)
		if (reset | invalidate_buffer)
			reorder_buffer_valid_ff <= {4 {1'sb0}};
		else
			reorder_buffer_valid_ff <= reorder_buffer_valid;
	always @(posedge clock) reorder_buffer_data_ff <= reorder_buffer_data;
	reg [3:0] reorder_buffer_mem_instr_blocked;
	reg [3:0] reorder_buffer_mem_instr_blocked_ff;
	reg [655:0] rob_dcache_request;
	reg [655:0] rob_dcache_request_ff;
	always @(posedge clock)
		if (reset | invalidate_buffer)
			reorder_buffer_mem_instr_blocked_ff <= {4 {1'sb0}};
		else
			reorder_buffer_mem_instr_blocked_ff <= reorder_buffer_mem_instr_blocked;
	always @(posedge clock) rob_dcache_request_ff <= rob_dcache_request;
	assign reorder_buffer_full = (reorder_buffer_valid_ff | reorder_buffer_mem_instr_blocked_ff) == {4 {1'sb1}};
	reg [1:0] reorder_buffer_tail;
	reg [1:0] reorder_buffer_tail_ff;
	always @(posedge clock)
		if (reset | invalidate_buffer)
			reorder_buffer_tail_ff <= {2 {1'sb0}};
		else
			reorder_buffer_tail_ff <= reorder_buffer_tail;
	assign reorder_buffer_oldest = reorder_buffer_tail_ff;
	reg [1:0] alu_free_pos;
	reg [1:0] mul_free_pos;
	reg [1:0] cache_free_pos;
	reg [1:0] oldest_pos;
	always @(*) begin
		reorder_buffer_data = reorder_buffer_data_ff;
		reorder_buffer_valid = reorder_buffer_valid_ff;
		reorder_buffer_tail = reorder_buffer_tail_ff;
		reorder_buffer_mem_instr_blocked = reorder_buffer_mem_instr_blocked_ff;
		req_to_RF_writeEn = 1'b0;
		xcpt_valid = 1'b0;
		new_tlb_entry = 1'b0;
		req_to_dcache_valid = 1'b0;
		alu_free_pos = alu_req_info[358-:2];
		mul_free_pos = mul_req_info[358-:2];
		cache_free_pos = cache_req_info[358-:2];
		oldest_pos = reorder_buffer_tail_ff;
		if (reorder_buffer_valid_ff[oldest_pos]) begin
			reorder_buffer_valid[oldest_pos] = 1'b0;
			reorder_buffer_tail = reorder_buffer_tail_ff + 1'b1;
			req_to_RF_writeEn = reorder_buffer_data_ff[(oldest_pos * 267) + 209] & !reorder_buffer_data_ff[(oldest_pos * 267) + 171];
			req_to_RF_dest = reorder_buffer_data_ff[(oldest_pos * 267) + 208-:5];
			req_to_RF_data = reorder_buffer_data_ff[(oldest_pos * 267) + 203-:32];
			req_to_RF_instr_id = reorder_buffer_data_ff[(oldest_pos * 267) + 266-:2];
			new_tlb_entry = reorder_buffer_data_ff[(oldest_pos * 267) + 264] & !reorder_buffer_data_ff[(oldest_pos * 267) + 171];
			new_tlb_id = reorder_buffer_data_ff[(oldest_pos * 267) + 263];
			new_tlb_info = reorder_buffer_data_ff[(oldest_pos * 267) + 262-:53];
			xcpt_valid = reorder_buffer_data_ff[(oldest_pos * 267) + 171];
			xcpt_type = reorder_buffer_data_ff[(oldest_pos * 267) + 106-:3];
			xcpt_pc = reorder_buffer_data_ff[(oldest_pos * 267) + 138-:32];
			xcpt_addr = reorder_buffer_data_ff[(oldest_pos * 267) + 170-:32];
		end
		else if (((alu_req_valid & (oldest_pos == alu_req_info[358-:2])) | (mul_req_valid & (oldest_pos == mul_req_info[358-:2]))) | (cache_req_valid & (oldest_pos == cache_req_info[358-:2]))) begin
			reorder_buffer_valid[oldest_pos] = 1'b0;
			reorder_buffer_tail = reorder_buffer_tail_ff + 1'b1;
			if (alu_req_valid & (oldest_pos == alu_req_info[358-:2])) begin
				req_to_RF_writeEn = alu_req_info[269] & !alu_reorder_buffer_xcpt_info[67];
				req_to_RF_dest = alu_req_info[268-:5];
				req_to_RF_data = alu_req_info[263-:32];
				req_to_RF_instr_id = alu_req_info[358-:2];
				new_tlb_entry = alu_req_info[324] & !alu_reorder_buffer_xcpt_info[67];
				new_tlb_id = alu_req_info[323];
				new_tlb_info = alu_req_info[322-:53];
				xcpt_valid = alu_reorder_buffer_xcpt_info[67];
				xcpt_type = alu_reorder_buffer_xcpt_info[2-:3];
				xcpt_pc = alu_reorder_buffer_xcpt_info[34-:32];
				xcpt_addr = alu_reorder_buffer_xcpt_info[66-:32];
			end
			else if (mul_req_valid & (oldest_pos == mul_req_info[358-:2])) begin
				req_to_RF_writeEn = mul_req_info[269] & !mul_reorder_buffer_xcpt_info[67];
				req_to_RF_dest = mul_req_info[268-:5];
				req_to_RF_data = mul_req_info[263-:32];
				req_to_RF_instr_id = mul_req_info[358-:2];
				new_tlb_entry = 1'b0;
				xcpt_valid = mul_reorder_buffer_xcpt_info[67];
				xcpt_type = mul_reorder_buffer_xcpt_info[2-:3];
				xcpt_pc = mul_reorder_buffer_xcpt_info[34-:32];
				xcpt_addr = mul_reorder_buffer_xcpt_info[66-:32];
			end
			else begin
				req_to_RF_writeEn = cache_req_info[269] & !cache_reorder_buffer_xcpt_info[67];
				req_to_RF_dest = cache_req_info[268-:5];
				req_to_RF_data = cache_req_info[263-:32];
				req_to_RF_instr_id = cache_req_info[358-:2];
				new_tlb_entry = 1'b0;
				xcpt_valid = cache_reorder_buffer_xcpt_info[67];
				xcpt_type = cache_reorder_buffer_xcpt_info[2-:3];
				xcpt_pc = cache_reorder_buffer_xcpt_info[34-:32];
				xcpt_addr = cache_reorder_buffer_xcpt_info[66-:32];
			end
		end
		if (cache_stage_ready & (reorder_buffer_mem_instr_blocked_ff[oldest_pos] | reorder_buffer_mem_instr_blocked_ff[reorder_buffer_tail]))
			if (reorder_buffer_mem_instr_blocked_ff[oldest_pos]) begin
				reorder_buffer_mem_instr_blocked[oldest_pos] = 1'b0;
				req_to_dcache_valid = 1'b1;
				req_to_dcache_info[237-:2] = reorder_buffer_data_ff[(oldest_pos * 267) + 266-:2];
				req_to_dcache_info[203-:5] = reorder_buffer_data_ff[(oldest_pos * 267) + 71-:5];
				req_to_dcache_info[198-:32] = reorder_buffer_data_ff[(oldest_pos * 267) + 103-:32];
				req_to_dcache_info[166-:2] = reorder_buffer_data_ff[(oldest_pos * 267) + 34-:2];
				req_to_dcache_info[164] = reorder_buffer_data_ff[(oldest_pos * 267) + 32];
				req_to_dcache_info[163-:32] = reorder_buffer_data_ff[(oldest_pos * 267) + 31-:32];
				req_to_dcache_info[235-:32] = rob_dcache_request_ff[(oldest_pos * 164) + 163-:32];
				req_to_dcache_info[131-:66] = rob_dcache_request_ff[(oldest_pos * 164) + 131-:66];
				req_to_dcache_info[65-:33] = rob_dcache_request_ff[(oldest_pos * 164) + 65-:33];
				req_to_dcache_info[32-:33] = rob_dcache_request_ff[(oldest_pos * 164) + 32-:33];
			end
			else begin
				reorder_buffer_mem_instr_blocked[reorder_buffer_tail] = 1'b0;
				req_to_dcache_valid = 1'b1;
				req_to_dcache_info[237-:2] = reorder_buffer_data_ff[(reorder_buffer_tail * 267) + 266-:2];
				req_to_dcache_info[203-:5] = reorder_buffer_data_ff[(reorder_buffer_tail * 267) + 71-:5];
				req_to_dcache_info[198-:32] = reorder_buffer_data_ff[(reorder_buffer_tail * 267) + 103-:32];
				req_to_dcache_info[166-:2] = reorder_buffer_data_ff[(reorder_buffer_tail * 267) + 34-:2];
				req_to_dcache_info[164] = reorder_buffer_data_ff[(reorder_buffer_tail * 267) + 32];
				req_to_dcache_info[163-:32] = reorder_buffer_data_ff[(reorder_buffer_tail * 267) + 31-:32];
				req_to_dcache_info[235-:32] = rob_dcache_request_ff[(reorder_buffer_tail * 164) + 163-:32];
				req_to_dcache_info[131-:66] = rob_dcache_request_ff[(reorder_buffer_tail * 164) + 131-:66];
				req_to_dcache_info[65-:33] = rob_dcache_request_ff[(reorder_buffer_tail * 164) + 65-:33];
				req_to_dcache_info[32-:33] = rob_dcache_request_ff[(reorder_buffer_tail * 164) + 32-:33];
			end
		if (!reorder_buffer_full & (alu_req_valid | mem_instr_blocked))
			if (!mem_instr_blocked) begin
				reorder_buffer_valid[alu_free_pos] = oldest_pos != alu_req_info[358-:2];
				reorder_buffer_data[(alu_free_pos * 267) + 266-:2] = alu_req_info[358-:2];
				reorder_buffer_data[(alu_free_pos * 267) + 264] = alu_req_info[324];
				reorder_buffer_data[(alu_free_pos * 267) + 263] = alu_req_info[323];
				reorder_buffer_data[(alu_free_pos * 267) + 262-:53] = alu_req_info[322-:53];
				reorder_buffer_data[(alu_free_pos * 267) + 209] = alu_req_info[269];
				reorder_buffer_data[(alu_free_pos * 267) + 208-:5] = alu_req_info[268-:5];
				reorder_buffer_data[(alu_free_pos * 267) + 203-:32] = alu_req_info[263-:32];
				reorder_buffer_data[(alu_free_pos * 267) + 171-:68] = alu_reorder_buffer_xcpt_info;
			end
			else begin
				alu_free_pos = mem_instr_info[237-:2];
				reorder_buffer_mem_instr_blocked[alu_free_pos] = 1'b1;
				reorder_buffer_data[(alu_free_pos * 267) + 266-:2] = mem_instr_info[237-:2];
				reorder_buffer_data[(alu_free_pos * 267) + 71-:5] = mem_instr_info[203-:5];
				reorder_buffer_data[(alu_free_pos * 267) + 103-:32] = mem_instr_info[198-:32];
				reorder_buffer_data[(alu_free_pos * 267) + 34-:2] = mem_instr_info[166-:2];
				reorder_buffer_data[(alu_free_pos * 267) + 32] = mem_instr_info[164];
				reorder_buffer_data[(alu_free_pos * 267) + 31-:32] = mem_instr_info[163-:32];
				rob_dcache_request[(alu_free_pos * 164) + 163-:32] = mem_instr_info[235-:32];
				rob_dcache_request[(alu_free_pos * 164) + 131-:66] = mem_instr_info[131-:66];
				rob_dcache_request[(alu_free_pos * 164) + 65-:33] = mem_instr_info[65-:33];
				rob_dcache_request[(alu_free_pos * 164) + 32-:33] = mem_instr_info[32-:33];
			end
		if (!reorder_buffer_full & mul_req_valid) begin
			reorder_buffer_valid[mul_free_pos] = oldest_pos != mul_req_info[358-:2];
			reorder_buffer_data[(mul_free_pos * 267) + 266-:2] = mul_req_info[358-:2];
			reorder_buffer_data[(mul_free_pos * 267) + 264] = mul_req_info[324];
			reorder_buffer_data[(mul_free_pos * 267) + 263] = mul_req_info[323];
			reorder_buffer_data[(mul_free_pos * 267) + 262-:53] = mul_req_info[322-:53];
			reorder_buffer_data[(mul_free_pos * 267) + 209] = mul_req_info[269];
			reorder_buffer_data[(mul_free_pos * 267) + 208-:5] = mul_req_info[268-:5];
			reorder_buffer_data[(mul_free_pos * 267) + 203-:32] = mul_req_info[263-:32];
			reorder_buffer_data[(mul_free_pos * 267) + 171-:68] = mul_reorder_buffer_xcpt_info;
		end
		if (!reorder_buffer_full & cache_req_valid) begin
			reorder_buffer_valid[cache_free_pos] = oldest_pos != cache_req_info[358-:2];
			reorder_buffer_data[(cache_free_pos * 267) + 266-:2] = cache_req_info[358-:2];
			reorder_buffer_data[(cache_free_pos * 267) + 264] = cache_req_info[324];
			reorder_buffer_data[(cache_free_pos * 267) + 263] = cache_req_info[323];
			reorder_buffer_data[(cache_free_pos * 267) + 262-:53] = cache_req_info[322-:53];
			reorder_buffer_data[(cache_free_pos * 267) + 209] = cache_req_info[269];
			reorder_buffer_data[(cache_free_pos * 267) + 208-:5] = cache_req_info[268-:5];
			reorder_buffer_data[(cache_free_pos * 267) + 203-:32] = cache_req_info[263-:32];
			reorder_buffer_data[(cache_free_pos * 267) + 171-:68] = cache_reorder_buffer_xcpt_info;
		end
	end
	always @(*) begin
		mul_src1_hit = 1'b0;
		mul_src2_hit = 1'b0;
		alu_src1_hit = 1'b0;
		alu_src2_hit = 1'b0;
		if (reorder_buffer_valid_ff[mul_src1_id]) begin
			mul_src1_hit = 1'b1;
			mul_src1_data = reorder_buffer_data[(mul_src1_id * 267) + 203-:32];
		end
		else if ((!reorder_buffer_full & alu_req_valid) & alu_req_info[269]) begin
			mul_src1_hit = (mul_src1_id == alu_req_info[358-:2] ? 1'b1 : 1'b0);
			mul_src1_data = alu_req_info[263-:32];
		end
		else if ((!reorder_buffer_full & mul_req_valid) & mul_req_info[269]) begin
			mul_src1_hit = (mul_src1_id == mul_req_info[358-:2] ? 1'b1 : 1'b0);
			mul_src1_data = mul_req_info[263-:32];
		end
		else if ((!reorder_buffer_full & cache_req_valid) & cache_req_info[269]) begin
			mul_src1_hit = (mul_src1_id == cache_req_info[358-:2] ? 1'b1 : 1'b0);
			mul_src1_data = cache_req_info[263-:32];
		end
		if (reorder_buffer_valid_ff[mul_src2_id]) begin
			mul_src2_hit = 1'b1;
			mul_src2_data = reorder_buffer_data[(mul_src2_id * 267) + 203-:32];
		end
		else if ((!reorder_buffer_full & alu_req_valid) & alu_req_info[269]) begin
			mul_src2_hit = (mul_src2_id == alu_req_info[358-:2] ? 1'b1 : 1'b0);
			mul_src2_data = alu_req_info[263-:32];
		end
		else if ((!reorder_buffer_full & mul_req_valid) & mul_req_info[269]) begin
			mul_src2_hit = (mul_src2_id == mul_req_info[358-:2] ? 1'b1 : 1'b0);
			mul_src2_data = mul_req_info[263-:32];
		end
		else if ((!reorder_buffer_full & cache_req_valid) & cache_req_info[269]) begin
			mul_src2_hit = (mul_src2_id == cache_req_info[358-:2] ? 1'b1 : 1'b0);
			mul_src2_data = cache_req_info[263-:32];
		end
		if (reorder_buffer_valid_ff[alu_src1_id]) begin
			alu_src1_hit = 1'b1;
			alu_src1_data = reorder_buffer_data[(alu_src1_id * 267) + 203-:32];
		end
		else if ((!reorder_buffer_full & alu_req_valid) & alu_req_info[269]) begin
			alu_src1_hit = (alu_src1_id == alu_req_info[358-:2] ? 1'b1 : 1'b0);
			alu_src1_data = alu_req_info[263-:32];
		end
		else if ((!reorder_buffer_full & mul_req_valid) & mul_req_info[269]) begin
			alu_src1_hit = (alu_src1_id == mul_req_info[358-:2] ? 1'b1 : 1'b0);
			alu_src1_data = mul_req_info[263-:32];
		end
		else if ((!reorder_buffer_full & cache_req_valid) & cache_req_info[269]) begin
			alu_src1_hit = (alu_src1_id == cache_req_info[358-:2] ? 1'b1 : 1'b0);
			alu_src1_data = cache_req_info[263-:32];
		end
		if (reorder_buffer_valid_ff[alu_src2_id]) begin
			alu_src2_hit = 1'b1;
			alu_src2_data = reorder_buffer_data[(alu_src2_id * 267) + 203-:32];
		end
		else if ((!reorder_buffer_full & alu_req_valid) & alu_req_info[269]) begin
			alu_src2_hit = (alu_src2_id == alu_req_info[358-:2] ? 1'b1 : 1'b0);
			alu_src2_data = alu_req_info[263-:32];
		end
		else if ((!reorder_buffer_full & mul_req_valid) & mul_req_info[269]) begin
			alu_src2_hit = (alu_src2_id == mul_req_info[358-:2] ? 1'b1 : 1'b0);
			alu_src2_data = mul_req_info[263-:32];
		end
		else if ((!reorder_buffer_full & cache_req_valid) & cache_req_info[269]) begin
			alu_src2_hit = (alu_src2_id == cache_req_info[358-:2] ? 1'b1 : 1'b0);
			alu_src2_data = cache_req_info[263-:32];
		end
	end
endmodule

module wb_top (
	clock,
	reset,
	reorder_buffer_full,
	reorder_buffer_oldest,
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
	output wire [2:0] reorder_buffer_oldest;
	input wire alu_req_valid;
	input wire [359:0] alu_req_info;
	input wire mem_instr_blocked;
	input wire [238:0] mem_instr_info;
	input wire mul_req_valid;
	input wire [359:0] mul_req_info;
	input wire cache_req_valid;
	input wire [359:0] cache_req_info;
	input wire cache_stage_ready;
	output wire req_to_dcache_valid;
	output wire [238:0] req_to_dcache_info;
	output wire req_to_RF_writeEn;
	output wire [31:0] req_to_RF_data;
	output wire [4:0] req_to_RF_dest;
	output wire [2:0] req_to_RF_instr_id;
	output wire xcpt_valid;
	output wire [2:0] xcpt_type;
	output wire [31:0] xcpt_pc;
	output wire [31:0] xcpt_addr;
	output wire new_tlb_entry;
	output wire new_tlb_id;
	output wire [52:0] new_tlb_info;
	input wire [2:0] mul_src1_id;
	input wire [2:0] mul_src2_id;
	output wire mul_src1_hit;
	output wire mul_src2_hit;
	output wire [31:0] mul_src1_data;
	output wire [31:0] mul_src2_data;
	input wire [2:0] alu_src1_id;
	input wire [2:0] alu_src2_id;
	output wire alu_src1_hit;
	output wire alu_src2_hit;
	output wire [31:0] alu_src1_data;
	output wire [31:0] alu_src2_data;
	reg invalidate_buffer;
	always @(posedge clock)
		if (reset)
			invalidate_buffer <= 1'sb0;
		else
			invalidate_buffer <= xcpt_valid;
	reorder_buffer reorder_buffer(
		.clock(clock),
		.reset(reset),
		.reorder_buffer_full(reorder_buffer_full),
		.reorder_buffer_oldest(reorder_buffer_oldest),
		.invalidate_buffer(invalidate_buffer),
		.alu_req_valid(alu_req_valid),
		.alu_req_info(alu_req_info),
		.mem_instr_blocked(mem_instr_blocked),
		.mem_instr_info(mem_instr_info),
		.mul_req_valid(mul_req_valid),
		.mul_req_info(mul_req_info),
		.cache_req_valid(cache_req_valid),
		.cache_req_info(cache_req_info),
		.cache_stage_ready(cache_stage_ready),
		.req_to_dcache_valid(req_to_dcache_valid),
		.req_to_dcache_info(req_to_dcache_info),
		.req_to_RF_writeEn(req_to_RF_writeEn),
		.req_to_RF_data(req_to_RF_data),
		.req_to_RF_dest(req_to_RF_dest),
		.req_to_RF_instr_id(req_to_RF_instr_id),
		.xcpt_valid(xcpt_valid),
		.xcpt_type(xcpt_type),
		.xcpt_pc(xcpt_pc),
		.xcpt_addr(xcpt_addr),
		.new_tlb_entry(new_tlb_entry),
		.new_tlb_id(new_tlb_id),
		.new_tlb_info(new_tlb_info),
		.mul_src1_id(mul_src1_id),
		.mul_src2_id(mul_src2_id),
		.mul_src1_hit(mul_src1_hit),
		.mul_src2_hit(mul_src2_hit),
		.mul_src1_data(mul_src1_data),
		.mul_src2_data(mul_src2_data),
		.alu_src1_id(alu_src1_id),
		.alu_src2_id(alu_src2_id),
		.alu_src1_hit(alu_src1_hit),
		.alu_src2_hit(alu_src2_hit),
		.alu_src1_data(alu_src1_data),
		.alu_src2_data(alu_src2_data)
	);
endmodule

module core_top (
	clock,
	reset,
	thread_enable,
	boot_addr,
	program_counter_o,
	dcache_req_valid_miss,
	dcache_req_info_miss,
	icache_req_valid_miss,
	icache_req_info_miss,
	rsp_data_miss,
	rsp_bus_error,
	rsp_valid_miss,
	rsp_cache_id
);
	input wire clock;
	input wire reset;
	input wire thread_enable;
	input wire [31:0] boot_addr;
	output wire [31:0] program_counter_o;
	output wire dcache_req_valid_miss;
	output wire [148:0] dcache_req_info_miss;
	output wire icache_req_valid_miss;
	output wire [148:0] icache_req_info_miss;
	input wire [127:0] rsp_data_miss;
	input wire rsp_bus_error;
	input wire rsp_valid_miss;
	input wire rsp_cache_id;
	wire fetch_instr_valid;
	wire [31:0] fetch_instr_data;
	wire [31:0] decode_instr_pc;
	wire [65:0] xcpt_fetch_to_decode;
	wire req_to_alu_valid;
	wire [113:0] req_to_alu_info;
	wire [2:0] req_to_alu_instr_id;
	wire [31:0] req_to_alu_pc;
	wire [65:0] xcpt_fetch_to_alu;
	wire [32:0] xcpt_decode_to_alu;
	wire req_to_mul_valid;
	wire [86:0] req_to_mul_info;
	wire [2:0] req_to_mul_instr_id;
	wire [31:0] req_to_mul_pc;
	wire [65:0] xcpt_fetch_to_mul;
	wire [32:0] xcpt_decode_to_mul;
	wire [0:0] priv_mode;
	wire mul_stall_pipeline;
	wire mul_req_to_wb_valid;
	wire [359:0] mul_req_to_wb_info;
	wire [2:0] rob_mul_src1_id;
	wire [2:0] rob_mul_src2_id;
	wire rob_mul_src1_hit;
	wire rob_mul_src2_hit;
	wire [31:0] rob_mul_src1_data;
	wire [31:0] rob_mul_src2_data;
	wire alu_stall_pipeline;
	wire alu_req_wb_valid;
	wire [359:0] alu_req_wb_info;
	wire alu_req_wb_mem_blocked;
	wire [238:0] alu_req_wb_dcache_info;
	wire [238:0] alu_req_to_dcache_info;
	wire alu_req_to_dcache_valid;
	wire alu_take_branch;
	wire alu_iret_instr;
	wire [31:0] alu_branch_pc;
	wire alu_cache_stage_free;
	wire [2:0] rob_alu_src1_id;
	wire [2:0] rob_alu_src2_id;
	wire rob_alu_src1_hit;
	wire rob_alu_src2_hit;
	wire [31:0] rob_alu_src1_data;
	wire [31:0] rob_alu_src2_data;
	wire dcache_ready;
	wire cache_req_to_wb_valid;
	wire [359:0] cache_req_to_wb_info;
	wire [238:0] wb_req_to_dcache_info;
	wire wb_req_to_dcache_valid;
	wire [31:0] wb_writeValRF;
	wire wb_writeEnRF;
	wire [4:0] wb_destRF;
	wire [2:0] wb_write_id;
	wire wb_xcpt_valid;
	wire [2:0] wb_xcpt_type;
	wire [31:0] wb_rmPC;
	wire [31:0] wb_rmAddr;
	wire wb_new_tlb_entry;
	wire wb_new_tlb_id;
	wire [52:0] wb_new_tlb_info;
	wire reorder_buffer_full;
	wire [2:0] rob_tail;
	wire [31:0] branch_pc;
	assign branch_pc = (wb_xcpt_valid ? 32'h2000 : alu_branch_pc);
	fetch_top fetch_top(
		.clock(clock),
		.reset(reset),
		.boot_addr(boot_addr),
		.program_counter_o(program_counter_o),
		.priv_mode(priv_mode),
		.xcpt_fetch(xcpt_fetch_to_decode),
		.take_branch(alu_take_branch | wb_xcpt_valid),
		.branch_pc(branch_pc),
		.stall_fetch(((!thread_enable | alu_stall_pipeline) | mul_stall_pipeline) | reorder_buffer_full),
		.decode_instr_data(fetch_instr_data),
		.decode_instr_valid(fetch_instr_valid),
		.decode_instr_pc(decode_instr_pc),
		.req_valid_miss(icache_req_valid_miss),
		.req_info_miss(icache_req_info_miss),
		.rsp_data_miss(rsp_data_miss),
		.rsp_bus_error(!rsp_cache_id & rsp_bus_error),
		.rsp_valid_miss(!rsp_cache_id & rsp_valid_miss),
		.new_tlb_entry(wb_new_tlb_entry & !wb_new_tlb_id),
		.new_tlb_info(wb_new_tlb_info)
	);
	decode_top decode_top(
		.clock(clock),
		.reset(reset),
		.priv_mode(priv_mode),
		.iret_instr(alu_iret_instr),
		.stall_decode(((!thread_enable | alu_stall_pipeline) | mul_stall_pipeline) | reorder_buffer_full),
		.flush_decode(alu_take_branch | wb_xcpt_valid),
		.flush_rob(wb_xcpt_valid),
		.xcpt_fetch_in(xcpt_fetch_to_decode),
		.fetch_instr_valid(fetch_instr_valid),
		.fetch_instr_data(fetch_instr_data),
		.fetch_instr_pc(decode_instr_pc),
		.req_to_alu_valid(req_to_alu_valid),
		.req_to_alu_info(req_to_alu_info),
		.req_to_alu_instr_id(req_to_alu_instr_id),
		.req_to_alu_pc(req_to_alu_pc),
		.alu_xcpt_fetch_out(xcpt_fetch_to_alu),
		.alu_decode_xcpt(xcpt_decode_to_alu),
		.req_to_mul_valid(req_to_mul_valid),
		.req_to_mul_info(req_to_mul_info),
		.req_to_mul_instr_id(req_to_mul_instr_id),
		.req_to_mul_pc(req_to_mul_pc),
		.mul_xcpt_fetch_out(xcpt_fetch_to_mul),
		.mul_decode_xcpt(xcpt_decode_to_mul),
		.writeValRF(wb_writeValRF),
		.writeEnRF(wb_writeEnRF),
		.destRF(wb_destRF),
		.write_idRF(wb_write_id),
		.xcpt_valid(wb_xcpt_valid),
		.rmPC(wb_rmPC),
		.rmAddr(wb_rmAddr),
		.xcpt_type(wb_xcpt_type)
	);
	mul_top mul_top(
		.clock(clock),
		.reset(reset),
		.flush_mul(wb_xcpt_valid),
		.stall_decode(!thread_enable | mul_stall_pipeline),
		.req_mul_valid(req_to_mul_valid),
		.req_mul_info(req_to_mul_info),
		.req_mul_instr_id(req_to_mul_instr_id),
		.req_mul_pc(req_to_mul_pc),
		.xcpt_fetch_in(xcpt_fetch_to_mul),
		.xcpt_decode_in(xcpt_decode_to_mul),
		.req_wb_valid(mul_req_to_wb_valid),
		.req_wb_info(mul_req_to_wb_info),
		.rob_src1_id(rob_mul_src1_id),
		.rob_src2_id(rob_mul_src2_id),
		.rob_src1_hit(rob_mul_src1_hit),
		.rob_src2_hit(rob_mul_src2_hit),
		.rob_src1_data(rob_mul_src1_data),
		.rob_src2_data(rob_mul_src2_data)
	);
	alu_top alu_top(
		.clock(clock),
		.reset(reset),
		.rob_tail(rob_tail),
		.cache_stage_free(alu_cache_stage_free),
		.dcache_ready(dcache_ready),
		.flush_alu(wb_xcpt_valid),
		.stall_decode(!thread_enable | alu_stall_pipeline),
		.xcpt_fetch_in(xcpt_fetch_to_alu),
		.xcpt_decode_in(xcpt_decode_to_alu),
		.req_alu_valid(req_to_alu_valid),
		.req_alu_info(req_to_alu_info),
		.req_alu_instr_id(req_to_alu_instr_id),
		.req_alu_pc(req_to_alu_pc),
		.req_dcache_valid(alu_req_to_dcache_valid),
		.req_dcache_info(alu_req_to_dcache_info),
		.req_wb_valid(alu_req_wb_valid),
		.req_wb_info(alu_req_wb_info),
		.req_wb_mem_blocked(alu_req_wb_mem_blocked),
		.req_wb_dcache_info(alu_req_wb_dcache_info),
		.branch_pc(alu_branch_pc),
		.take_branch(alu_take_branch),
		.iret_instr(alu_iret_instr),
		.rob_src1_id(rob_alu_src1_id),
		.rob_src2_id(rob_alu_src2_id),
		.rob_src1_hit(rob_alu_src1_hit),
		.rob_src2_hit(rob_alu_src2_hit),
		.rob_src1_data(rob_alu_src1_data),
		.rob_src2_data(rob_alu_src2_data)
	);
	wire [238:0] req_to_dcache_info;
	wire req_to_dcache_valid;
	assign req_to_dcache_valid = wb_req_to_dcache_valid | alu_req_to_dcache_valid;
	assign req_to_dcache_info = (!wb_req_to_dcache_valid & !alu_req_to_dcache_valid ? req_to_dcache_info : (wb_req_to_dcache_valid ? wb_req_to_dcache_info : alu_req_to_dcache_info));
	cache_top cache_top(
		.clock(clock),
		.reset(reset),
		.priv_mode(priv_mode),
		.dcache_ready(dcache_ready),
		.flush_cache(wb_xcpt_valid),
		.req_valid(req_to_dcache_valid),
		.req_info(req_to_dcache_info),
		.req_wb_valid(cache_req_to_wb_valid),
		.req_wb_info(cache_req_to_wb_info),
		.req_valid_miss(dcache_req_valid_miss),
		.req_info_miss(dcache_req_info_miss),
		.rsp_data_miss(rsp_data_miss),
		.rsp_bus_error(rsp_cache_id & rsp_bus_error),
		.rsp_valid_miss(rsp_cache_id & rsp_valid_miss),
		.new_tlb_entry(wb_new_tlb_entry & wb_new_tlb_id),
		.new_tlb_info(wb_new_tlb_info)
	);
	wb_top wb_top(
		.clock(clock),
		.reset(reset),
		.reorder_buffer_full(reorder_buffer_full),
		.reorder_buffer_oldest(rob_tail),
		.alu_req_valid(alu_req_wb_valid),
		.alu_req_info(alu_req_wb_info),
		.mem_instr_blocked(alu_req_wb_mem_blocked),
		.mem_instr_info(alu_req_wb_dcache_info),
		.mul_req_valid(mul_req_to_wb_valid),
		.mul_req_info(mul_req_to_wb_info),
		.cache_req_valid(cache_req_to_wb_valid),
		.cache_req_info(cache_req_to_wb_info),
		.cache_stage_ready(alu_cache_stage_free & dcache_ready),
		.req_to_dcache_valid(wb_req_to_dcache_valid),
		.req_to_dcache_info(wb_req_to_dcache_info),
		.req_to_RF_data(wb_writeValRF),
		.req_to_RF_writeEn(wb_writeEnRF),
		.req_to_RF_dest(wb_destRF),
		.req_to_RF_instr_id(wb_write_id),
		.xcpt_valid(wb_xcpt_valid),
		.xcpt_type(wb_xcpt_type),
		.xcpt_pc(wb_rmPC),
		.xcpt_addr(wb_rmAddr),
		.new_tlb_entry(wb_new_tlb_entry),
		.new_tlb_id(wb_new_tlb_id),
		.new_tlb_info(wb_new_tlb_info),
		.mul_src1_id(rob_mul_src1_id),
		.mul_src2_id(rob_mul_src2_id),
		.mul_src1_hit(rob_mul_src1_hit),
		.mul_src2_hit(rob_mul_src2_hit),
		.mul_src1_data(rob_mul_src1_data),
		.mul_src2_data(rob_mul_src2_data),
		.alu_src1_id(rob_alu_src1_id),
		.alu_src2_id(rob_alu_src2_id),
		.alu_src1_hit(rob_alu_src1_hit),
		.alu_src2_hit(rob_alu_src2_hit),
		.alu_src1_data(rob_alu_src1_data),
		.alu_src2_data(rob_alu_src2_data)
	);
endmodule

module fetch_top (
	clock,
	reset,
	boot_addr,
	priv_mode,
	program_counter_o,
	xcpt_fetch,
	take_branch,
	branch_pc,
	stall_fetch,
	decode_instr_data,
	decode_instr_valid,
	decode_instr_pc,
	req_valid_miss,
	req_info_miss,
	rsp_data_miss,
	rsp_bus_error,
	rsp_valid_miss,
	new_tlb_entry,
	new_tlb_info
);
	input wire clock;
	input wire reset;
	input wire [31:0] boot_addr;
	input wire [0:0] priv_mode;
	output wire [31:0] program_counter_o;
	output reg [65:0] xcpt_fetch;
	input wire take_branch;
	input wire [31:0] branch_pc;
	input wire stall_fetch;
	output wire [31:0] decode_instr_data;
	output wire decode_instr_valid;
	output wire [31:0] decode_instr_pc;
	output wire req_valid_miss;
	output wire [148:0] req_info_miss;
	input wire [127:0] rsp_data_miss;
	input wire rsp_bus_error;
	input wire rsp_valid_miss;
	input wire new_tlb_entry;
	input wire [52:0] new_tlb_info;
	reg mm_pendent_rsp;
	reg mm_pendent_rsp_ff;
	always @(posedge clock)
		if (reset)
			mm_pendent_rsp_ff <= 1'b0;
		else
			mm_pendent_rsp_ff <= mm_pendent_rsp;
	always @(*) begin
		mm_pendent_rsp = mm_pendent_rsp_ff;
		if (req_valid_miss)
			mm_pendent_rsp = 1'b1;
		else if (rsp_valid_miss)
			mm_pendent_rsp = 1'b0;
	end
	wire icache_ready;
	wire icache_rsp_valid;
	wire [127:0] icache_rsp_data;
	reg [3:0] word_in_line;
	reg [31:0] decode_instr_data_next;
	wire iTlb_rsp_valid;
	wire [19:0] iTlb_rsp_phy_addr;
	reg take_branch_ff;
	wire take_branch_update;
	wire branch_executed;
	reg [31:0] branch_pc_ff;
	always @(posedge clock)
		if (reset)
			take_branch_ff <= 1'b0;
		else if (take_branch_update)
			take_branch_ff <= take_branch;
	always @(posedge clock)
		if (take_branch_update)
			branch_pc_ff <= branch_pc;
	assign branch_executed = (take_branch | take_branch_ff) & icache_ready;
	assign take_branch_update = (!take_branch_ff & take_branch ? 1'b1 : (branch_executed ? 1'b1 : 1'b0));
	reg [31:0] program_counter;
	wire [31:0] program_counter_next;
	wire program_counter_update;
	always @(posedge clock)
		if (reset)
			program_counter <= boot_addr;
		else if (program_counter_update)
			program_counter <= program_counter_next;
	assign program_counter_update = ((stall_fetch | !icache_ready) | mm_pendent_rsp ? 1'b0 : 1'b1);
	assign program_counter_next = (take_branch & icache_ready ? branch_pc : (take_branch_ff & icache_ready ? branch_pc_ff : program_counter + 4));
	assign program_counter_o = program_counter;
	reg [65:0] xcpt_fetch_next;
	always @(posedge clock)
		if (!stall_fetch)
			xcpt_fetch <= xcpt_fetch_next;
	wire xcpt_bus_error_aux;
	wire xcpt_itlb_miss;
	always @(*) begin
		xcpt_fetch_next[65] = xcpt_itlb_miss;
		xcpt_fetch_next[64] = xcpt_bus_error_aux;
		xcpt_fetch_next[63-:32] = program_counter;
		xcpt_fetch_next[31-:32] = program_counter;
	end
	wire itlb_req_valid;
	reg itlb_req_valid_ff;
	reg itlb_req_valid_next;
	reg first_req_sent;
	reg first_req_sent_ff;
	always @(posedge clock)
		if (reset)
			first_req_sent_ff <= 1'b0;
		else if (!first_req_sent_ff)
			first_req_sent_ff <= first_req_sent;
	reg stall_fetch_ff;
	always @(posedge clock) stall_fetch_ff <= stall_fetch;
	always @(*) begin
		first_req_sent = first_req_sent_ff;
		if ((program_counter == 32'h1000) & !first_req_sent_ff) begin
			itlb_req_valid_next = 1'b1;
			first_req_sent = 1'b1;
		end
		else
			itlb_req_valid_next = program_counter_update;
	end
	always @(posedge clock)
		if (reset)
			itlb_req_valid_ff <= 1'b0;
		else
			itlb_req_valid_ff <= itlb_req_valid_next;
	assign itlb_req_valid = (stall_fetch ? 1'b0 : (stall_fetch_ff ? 1'b1 : itlb_req_valid_ff));
	wire icache_req_valid;
	assign icache_req_valid = (stall_fetch ? 1'b0 : iTlb_rsp_valid & !xcpt_itlb_miss);
	reg decode_instr_valid_ff;
	wire decode_instr_valid_next;
	reg [31:0] decode_instr_data_ff;
	reg [31:0] decode_instr_pc_ff;
	assign decode_instr_valid_next = (take_branch | take_branch_ff ? 1'b0 : (xcpt_fetch[65] | xcpt_fetch[64] ? 1'b1 : icache_rsp_valid));
	always @(posedge clock)
		if (reset)
			decode_instr_valid_ff <= 1'b0;
		else if (!stall_fetch)
			decode_instr_valid_ff <= decode_instr_valid_next;
	always @(posedge clock)
		if (!stall_fetch)
			decode_instr_data_ff <= decode_instr_data_next;
	always @(posedge clock)
		if (!stall_fetch)
			decode_instr_pc_ff <= program_counter;
	assign decode_instr_valid = (take_branch ? 1'b0 : decode_instr_valid_ff);
	assign decode_instr_data = decode_instr_data_ff;
	assign decode_instr_pc = decode_instr_pc_ff;
	always @(*) begin
		word_in_line = program_counter[5:2];
		decode_instr_data_next = icache_rsp_data[32 * word_in_line+:32];
	end
	instruction_cache icache(
		.clock(clock),
		.reset(reset),
		.icache_ready(icache_ready),
		.xcpt_bus_error(xcpt_bus_error_aux),
		.req_valid(icache_req_valid),
		.req_addr(iTlb_rsp_phy_addr),
		.rsp_valid(icache_rsp_valid),
		.rsp_data(icache_rsp_data),
		.req_info_miss(req_info_miss),
		.req_valid_miss(req_valid_miss),
		.rsp_data_miss(rsp_data_miss),
		.rsp_bus_error(rsp_bus_error),
		.rsp_valid_miss(rsp_valid_miss)
	);
	wire tlb_write_privilege;
	tlb_cache itlb(
		.clock(clock),
		.reset(reset),
		.req_valid(itlb_req_valid),
		.req_virt_addr(program_counter),
		.priv_mode(priv_mode),
		.rsp_valid(iTlb_rsp_valid),
		.tlb_miss(xcpt_itlb_miss),
		.rsp_phy_addr(iTlb_rsp_phy_addr),
		.writePriv(tlb_write_privilege),
		.new_tlb_entry(new_tlb_entry),
		.new_tlb_info(new_tlb_info)
	);
endmodule

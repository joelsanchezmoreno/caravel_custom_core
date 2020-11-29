module cache_top (
	clock,
	reset,
	priv_mode,
	dcache_ready,
	flush_cache,
	req_valid,
	req_info,
	req_wb_valid,
	req_wb_info,
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
	input wire [0:0] priv_mode;
	output wire dcache_ready;
	input wire flush_cache;
	input wire req_valid;
	input wire [238:0] req_info;
	output wire req_wb_valid;
	output wire [359:0] req_wb_info;
	output wire req_valid_miss;
	output wire [148:0] req_info_miss;
	input wire [127:0] rsp_data_miss;
	input wire rsp_bus_error;
	input wire rsp_valid_miss;
	input wire new_tlb_entry;
	input wire [52:0] new_tlb_info;
	wire cache_hazard;
	wire dcache_rsp_valid;
	assign cache_hazard = !dcache_ready & !dcache_rsp_valid;
	reg [66:0] xcpt_cache;
	wire xcpt_bus_error;
	wire xcpt_dtlb_miss;
	wire dTlb_rsp_valid;
	wire dTlb_write_privilege;
	always @(*) begin
		xcpt_cache[65] = xcpt_bus_error;
		xcpt_cache[64] = xcpt_dtlb_miss | ((!dTlb_write_privilege & dTlb_rsp_valid) & req_info[164]);
		xcpt_cache[66] = 1'b0;
		xcpt_cache[63-:32] = req_info[198-:32];
		xcpt_cache[31-:32] = req_info[235-:32];
	end
	wire [31:0] rsp_data_dcache;
	wire req_wb_valid_next;
	reg req_wb_valid_ff;
	reg [359:0] req_wb_info_next;
	reg [359:0] req_wb_info_ff;
	always @(posedge clock)
		if (reset | flush_cache)
			req_wb_valid_ff <= 1'sb0;
		else if (!cache_hazard)
			req_wb_valid_ff <= req_wb_valid_next;
	always @(posedge clock)
		if (reset | flush_cache)
			req_wb_info_ff <= {360 {1'sb0}};
		else if (!cache_hazard | dcache_rsp_valid)
			req_wb_info_ff <= req_wb_info_next;
	assign req_wb_valid = (cache_hazard ? 1'b0 : req_wb_valid_ff);
	assign req_wb_info = req_wb_info_ff;
	always @(*) begin
		req_wb_info_next[359-:3] = req_info[238-:3];
		req_wb_info_next[356-:32] = req_info[235-:32];
		req_wb_info_next[324] = 1'b0;
		req_wb_info_next[323] = 1'sb0;
		req_wb_info_next[322-:53] = {53 {1'sb0}};
		req_wb_info_next[269] = !req_info[164];
		req_wb_info_next[268-:5] = req_info[203-:5];
		req_wb_info_next[263-:32] = rsp_data_dcache;
		req_wb_info_next[231-:66] = req_info[131-:66];
		req_wb_info_next[165-:33] = req_info[65-:33];
		req_wb_info_next[132-:33] = req_info[32-:33];
		req_wb_info_next[99-:33] = {33 {1'sb0}};
		req_wb_info_next[66-:67] = xcpt_cache;
	end
	wire instr_xcpt;
	assign instr_xcpt = (((((req_info[131] | req_info[130]) | req_info[65]) | req_info[32]) | xcpt_cache[65]) | xcpt_cache[64]) | xcpt_cache[66];
	assign req_wb_valid_next = (flush_cache ? 1'b0 : (req_valid & instr_xcpt ? 1'b1 : dcache_rsp_valid));
	wire dtlb_req_valid;
	assign dtlb_req_valid = (flush_cache ? 1'b0 : dcache_ready & req_valid);
	wire [19:0] dTlb_rsp_phy_addr;
	wire dcache_req_valid;
	reg [238:0] req_dcache_info;
	assign dcache_req_valid = (flush_cache ? 1'b0 : dTlb_rsp_valid & !xcpt_dtlb_miss);
	always @(*) begin
		req_dcache_info = req_info;
		req_dcache_info[198-:32] = {{12 {1'b0}}, dTlb_rsp_phy_addr};
	end
	data_cache dcache(
		.clock(clock),
		.reset(reset),
		.dcache_ready(dcache_ready),
		.xcpt_bus_error(xcpt_bus_error),
		.req_valid(dcache_req_valid),
		.req_info(req_dcache_info),
		.rsp_valid(dcache_rsp_valid),
		.rsp_data(rsp_data_dcache),
		.req_info_miss(req_info_miss),
		.req_valid_miss(req_valid_miss),
		.rsp_data_miss(rsp_data_miss),
		.rsp_bus_error(rsp_bus_error),
		.rsp_valid_miss(rsp_valid_miss)
	);
	tlb_cache dtlb(
		.clock(clock),
		.reset(reset),
		.req_valid(dtlb_req_valid),
		.req_virt_addr(req_info[198-:32]),
		.priv_mode(priv_mode),
		.rsp_valid(dTlb_rsp_valid),
		.tlb_miss(xcpt_dtlb_miss),
		.rsp_phy_addr(dTlb_rsp_phy_addr),
		.writePriv(dTlb_write_privilege),
		.new_tlb_entry(new_tlb_entry),
		.new_tlb_info(new_tlb_info)
	);
endmodule

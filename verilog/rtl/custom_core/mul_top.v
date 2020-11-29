module mul_top (
	clock,
	reset,
	flush_mul,
	stall_decode,
	req_mul_valid,
	req_mul_info,
	req_mul_instr_id,
	req_mul_pc,
	xcpt_fetch_in,
	xcpt_decode_in,
	req_wb_valid,
	req_wb_info,
	rob_src1_id,
	rob_src2_id,
	rob_src1_hit,
	rob_src2_hit,
	rob_src1_data,
	rob_src2_data
);
	input wire clock;
	input wire reset;
	input wire flush_mul;
	output reg stall_decode;
	input wire req_mul_valid;
	input wire [86:0] req_mul_info;
	input wire [2:0] req_mul_instr_id;
	input wire [31:0] req_mul_pc;
	input wire [65:0] xcpt_fetch_in;
	input wire [32:0] xcpt_decode_in;
	output reg req_wb_valid;
	output reg [359:0] req_wb_info;
	output reg [2:0] rob_src1_id;
	output reg [2:0] rob_src2_id;
	input wire rob_src1_hit;
	input wire rob_src2_hit;
	input wire [31:0] rob_src1_data;
	input wire [31:0] rob_src2_data;
	wire fetch_xcpt_valid;
	assign fetch_xcpt_valid = req_mul_valid & ((xcpt_fetch_in[65] | xcpt_fetch_in[64]) | xcpt_fetch_in[63-:32]);
	wire decode_xcpt_valid;
	assign decode_xcpt_valid = req_mul_valid & xcpt_decode_in[32];
	reg stall_decode_ff;
	always @(posedge clock)
		if (reset | flush_mul)
			stall_decode_ff <= 1'b0;
		else
			stall_decode_ff <= stall_decode;
	reg [5:0] instr_valid_next;
	reg [5:0] instr_valid_ff;
	always @(posedge clock)
		if (reset | flush_mul)
			instr_valid_ff <= {6 {1'sb0}};
		else
			instr_valid_ff <= instr_valid_next;
	reg [191:0] req_wb_pc_ff;
	reg [191:0] req_wb_pc_next;
	reg [383:0] mul_oper_data_next;
	reg [383:0] mul_oper_data_ff;
	reg [29:0] rd_addr_next;
	reg [29:0] rd_addr_ff;
	reg [17:0] instr_id_next;
	reg [17:0] instr_id_ff;
	always @(posedge clock) req_wb_pc_ff <= req_wb_pc_next;
	always @(posedge clock) mul_oper_data_ff <= mul_oper_data_next;
	always @(posedge clock) rd_addr_ff <= rd_addr_next;
	always @(posedge clock) instr_id_ff <= instr_id_next;
	reg [395:0] mul_xcpt_fetch_next;
	reg [395:0] mul_xcpt_fetch_ff;
	reg [197:0] mul_xcpt_decode_next;
	reg [197:0] mul_xcpt_decode_ff;
	reg [197:0] mul_xcpt_stages_next;
	reg [197:0] mul_xcpt_stages_ff;
	always @(posedge clock)
		if (reset | flush_mul)
			mul_xcpt_fetch_ff <= {396 {1'sb0}};
		else
			mul_xcpt_fetch_ff <= mul_xcpt_fetch_next;
	always @(posedge clock)
		if (reset | flush_mul)
			mul_xcpt_decode_ff <= {198 {1'sb0}};
		else
			mul_xcpt_decode_ff <= mul_xcpt_decode_next;
	always @(posedge clock)
		if (reset | flush_mul)
			mul_xcpt_stages_ff <= {198 {1'sb0}};
		else
			mul_xcpt_stages_ff <= mul_xcpt_stages_next;
	reg [63:0] mul_overflow_data;
	reg [31:0] ra_data;
	reg [31:0] rb_data;
	reg rob_blocks_src1;
	reg rob_blocks_src2;
	reg rob_src1_found_next;
	reg rob_src1_found_ff;
	reg rob_src2_found_next;
	reg rob_src2_found_ff;
	reg [31:0] rob_src1_data_ff;
	reg [31:0] rob_src2_data_ff;
	always @(posedge clock)
		if (reset | flush_mul)
			rob_src1_found_ff <= 1'b0;
		else
			rob_src1_found_ff <= rob_src1_found_next;
	always @(posedge clock)
		if (reset | flush_mul)
			rob_src2_found_ff <= 1'b0;
		else
			rob_src2_found_ff <= rob_src2_found_next;
	always @(posedge clock)
		if (rob_src1_hit)
			rob_src1_data_ff <= rob_src1_data;
	always @(posedge clock)
		if (rob_src2_hit)
			rob_src2_data_ff <= rob_src2_data;
	always @(*) begin
		rob_src1_id = req_mul_info[7-:3];
		rob_src2_id = req_mul_info[3-:3];
		rob_blocks_src1 = req_mul_info[4];
		rob_blocks_src2 = req_mul_info[0];
		rob_src1_found_next = rob_src1_found_ff;
		rob_src2_found_next = rob_src2_found_ff;
		stall_decode = stall_decode_ff;
		if (stall_decode_ff) begin
			if (!rob_src1_found_ff)
				rob_src1_found_next = rob_src1_hit;
			if (!rob_src2_found_ff)
				rob_src2_found_next = rob_src2_hit;
			if (rob_blocks_src1 & rob_blocks_src2)
				stall_decode = !((rob_src1_found_ff | rob_src1_hit) & (rob_src2_found_ff | rob_src2_hit));
			else if (rob_blocks_src1)
				stall_decode = !(rob_src1_found_ff | rob_src1_hit);
			else
				stall_decode = !(rob_src2_found_ff | rob_src2_hit);
		end
		else begin
			rob_src1_found_next = rob_src1_hit;
			rob_src2_found_next = rob_src2_hit;
			stall_decode = (fetch_xcpt_valid | decode_xcpt_valid ? 1'b0 : (req_mul_valid ? ((rob_blocks_src1 & !rob_src1_hit) & (req_mul_info[7-:3] != req_mul_instr_id)) | ((rob_blocks_src2 & !rob_src2_hit) & (req_mul_info[3-:3] != req_mul_instr_id)) : 1'b0));
		end
	end
	always @(*) begin
		ra_data = (rob_blocks_src1 ? (rob_src1_hit ? rob_src1_data : rob_src1_data_ff) : req_mul_info[71-:32]);
		rb_data = (rob_blocks_src2 ? (rob_src2_hit ? rob_src2_data : rob_src2_data_ff) : req_mul_info[39-:32]);
		instr_id_next[0+:3] = req_mul_instr_id;
		instr_valid_next[0] = (flush_mul ? 1'b0 : (stall_decode ? 1'b0 : (stall_decode_ff ? 1'b1 : req_mul_valid)));
		req_wb_pc_next[0+:32] = req_mul_pc;
		mul_overflow_data = {{32 {1'b0}}, ra_data} * {{32 {1'b0}}, rb_data};
		mul_oper_data_next[0+:64] = mul_overflow_data[31:0];
		rd_addr_next[0+:5] = req_mul_info[86-:5];
		mul_xcpt_fetch_next[0+:66] = (instr_valid_next[0] ? xcpt_fetch_in : {66 {1'sb0}});
		mul_xcpt_decode_next[0+:33] = (instr_valid_next[0] ? xcpt_decode_in : {33 {1'sb0}});
		mul_xcpt_stages_next[31-:32] = req_mul_pc;
		mul_xcpt_stages_next[32] = (mul_overflow_data[32+:32] != {32 {1'sb0}}) & instr_valid_next[0];
	end
	genvar mulStage;
	generate
		for (mulStage = 0; mulStage < 2; mulStage = mulStage + 1) begin : gen_mul_stages
			wire instr_valid_aux;
			wire [31:0] req_wb_pc_aux;
			wire [63:0] mul_oper_data_aux;
			wire [4:0] rd_addr_aux;
			wire [2:0] instr_id_aux;
			wire [65:0] mul_xcpt_fetch_aux;
			wire [32:0] mul_xcpt_decode_aux;
			wire [32:0] mul_xcpt_stages_aux;
			assign instr_valid_aux = instr_valid_ff[mulStage];
			assign req_wb_pc_aux = req_wb_pc_ff[mulStage * 32+:32];
			assign mul_oper_data_aux = mul_oper_data_ff[mulStage * 64+:64];
			assign rd_addr_aux = rd_addr_ff[mulStage * 5+:5];
			assign instr_id_aux = instr_id_ff[mulStage * 3+:3];
			assign mul_xcpt_fetch_aux = mul_xcpt_fetch_ff[mulStage * 66+:66];
			assign mul_xcpt_decode_aux = mul_xcpt_decode_ff[mulStage * 33+:33];
			assign mul_xcpt_stages_aux = mul_xcpt_stages_ff[mulStage * 33+:33];
			mul_stage mul_stage(
				.instr_valid_in(instr_valid_aux),
				.instr_id_in(instr_id_aux),
				.program_counter_in(req_wb_pc_aux),
				.dest_reg_in(rd_addr_aux),
				.data_result_in(mul_oper_data_aux),
				.xcpt_fetch_in(mul_xcpt_fetch_aux),
				.xcpt_decode_in(mul_xcpt_decode_aux),
				.xcpt_mul_in(mul_xcpt_stages_aux),
				.instr_valid_out(instr_valid_next[mulStage + 1]),
				.instr_id_out(instr_id_next[(mulStage + 1) * 3+:3]),
				.program_counter_out(req_wb_pc_next[(mulStage + 1) * 32+:32]),
				.dest_reg_out(rd_addr_next[(mulStage + 1) * 5+:5]),
				.data_result_out(mul_oper_data_next[(mulStage + 1) * 64+:64]),
				.xcpt_fetch_out(mul_xcpt_fetch_next[(mulStage + 1) * 66+:66]),
				.xcpt_decode_out(mul_xcpt_decode_next[(mulStage + 1) * 33+:33]),
				.xcpt_mul_out(mul_xcpt_stages_next[(mulStage + 1) * 33+:33])
			);
		end
	endgenerate
	reg req_wb_valid_next;
	reg [359:0] req_wb_info_next;
	always @(posedge clock)
		if (reset | flush_mul)
			req_wb_valid <= 1'b0;
		else
			req_wb_valid <= req_wb_valid_next;
	always @(posedge clock)
		if (reset | flush_mul)
			req_wb_info <= {360 {1'sb0}};
		else
			req_wb_info <= req_wb_info_next;
	always @(*) begin
		req_wb_valid_next = (flush_mul ? 1'b0 : (stall_decode ? 1'b0 : instr_valid_ff[2]));
		req_wb_info_next[359-:3] = instr_id_ff[6+:3];
		req_wb_info_next[356-:32] = req_wb_pc_ff[64+:32];
		req_wb_info_next[324] = 1'b0;
		req_wb_info_next[323] = 1'sb0;
		req_wb_info_next[322-:53] = {53 {1'sb0}};
		req_wb_info_next[269] = 1'b1;
		req_wb_info_next[268-:5] = rd_addr_ff[10+:5];
		req_wb_info_next[263-:32] = mul_oper_data_ff[128+:64];
		req_wb_info_next[231-:66] = mul_xcpt_fetch_ff[132+:66];
		req_wb_info_next[165-:33] = mul_xcpt_decode_ff[66+:33];
		req_wb_info_next[132-:33] = {33 {1'sb0}};
		req_wb_info_next[99-:33] = mul_xcpt_stages_ff[66+:33];
		req_wb_info_next[66-:67] = {67 {1'sb0}};
	end
endmodule

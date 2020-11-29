module alu_top (
	clock,
	reset,
	rob_tail,
	cache_stage_free,
	flush_alu,
	dcache_ready,
	stall_decode,
	xcpt_fetch_in,
	xcpt_decode_in,
	req_alu_valid,
	req_alu_info,
	req_alu_instr_id,
	req_alu_pc,
	req_dcache_valid,
	req_dcache_info,
	req_wb_valid,
	req_wb_info,
	req_wb_mem_blocked,
	req_wb_dcache_info,
	branch_pc,
	take_branch,
	iret_instr,
	rob_src1_id,
	rob_src2_id,
	rob_src1_hit,
	rob_src2_hit,
	rob_src1_data,
	rob_src2_data
);
	input wire clock;
	input wire reset;
	input wire [2:0] rob_tail;
	output wire cache_stage_free;
	input wire flush_alu;
	input wire dcache_ready;
	output reg stall_decode;
	input wire [65:0] xcpt_fetch_in;
	input wire [32:0] xcpt_decode_in;
	input wire req_alu_valid;
	input wire [113:0] req_alu_info;
	input wire [2:0] req_alu_instr_id;
	input wire [31:0] req_alu_pc;
	output wire req_dcache_valid;
	output wire [238:0] req_dcache_info;
	output wire req_wb_valid;
	output wire [359:0] req_wb_info;
	output wire req_wb_mem_blocked;
	output wire [238:0] req_wb_dcache_info;
	output reg [31:0] branch_pc;
	output reg take_branch;
	output reg iret_instr;
	output reg [2:0] rob_src1_id;
	output reg [2:0] rob_src2_id;
	input wire rob_src1_hit;
	input wire rob_src2_hit;
	input wire [31:0] rob_src1_data;
	input wire [31:0] rob_src2_data;
	reg stall_decode_ff;
	always @(posedge clock)
		if (reset | flush_alu)
			stall_decode_ff <= 1'b0;
		else
			stall_decode_ff <= stall_decode;
	reg [32:0] xcpt_alu;
	wire fetch_xcpt_valid;
	assign fetch_xcpt_valid = req_alu_valid & ((xcpt_fetch_in[65] | xcpt_fetch_in[64]) | xcpt_fetch_in[63-:32]);
	wire decode_xcpt_valid;
	assign decode_xcpt_valid = req_alu_valid & xcpt_decode_in[32];
	assign cache_stage_free = req_wb_valid | !req_alu_valid;
	wire req_dcache_valid_next;
	reg req_dcache_valid_ff;
	wire req_wb_mem_blocked_next;
	reg req_wb_mem_blocked_ff;
	reg [238:0] req_dcache_info_next;
	reg [238:0] req_dcache_info_ff;
	always @(posedge clock) req_dcache_info_ff <= req_dcache_info_next;
	always @(posedge clock)
		if (reset | flush_alu)
			req_dcache_valid_ff <= 1'b0;
		else
			req_dcache_valid_ff <= req_dcache_valid_next;
	always @(posedge clock)
		if (reset | flush_alu)
			req_wb_mem_blocked_ff <= 1'b0;
		else
			req_wb_mem_blocked_ff <= req_wb_mem_blocked_next;
	wire wb_mem_blocked_type;
	function automatic is_m_type_instr;
		input reg [6:0] opcode;
		begin
			is_m_type_instr = 1'b0;
			if ((((opcode == 7'h10) | (opcode == 7'h11)) | (opcode == 7'h12)) | (opcode == 7'h13))
				is_m_type_instr = 1'b1;
		end
	endfunction
	assign wb_mem_blocked_type = is_m_type_instr(req_alu_info[14-:7]) & ((rob_tail != req_alu_instr_id) | !dcache_ready);
	assign req_wb_mem_blocked_next = (flush_alu ? 1'b0 : (stall_decode ? 1'b0 : (stall_decode_ff ? wb_mem_blocked_type : req_alu_valid & wb_mem_blocked_type)));
	assign req_wb_mem_blocked = req_wb_mem_blocked_ff;
	assign req_wb_dcache_info = req_dcache_info_ff;
	wire dcache_mem_type;
	assign dcache_mem_type = (is_m_type_instr(req_alu_info[14-:7]) & dcache_ready) & (rob_tail == req_alu_instr_id);
	assign req_dcache_valid_next = (flush_alu ? 1'b0 : (stall_decode ? 1'b0 : (stall_decode_ff ? dcache_mem_type : (fetch_xcpt_valid | decode_xcpt_valid ? 1'b0 : req_alu_valid & dcache_mem_type))));
	assign req_dcache_valid = req_dcache_valid_ff;
	assign req_dcache_info = req_dcache_info_ff;
	wire alu_to_wb_intr;
	function automatic is_branch_type_instr;
		input reg [6:0] opcode;
		begin
			is_branch_type_instr = 1'b0;
			if ((((((opcode == 7'h30) | (opcode == 7'h34)) | (opcode == 7'h35)) | (opcode == 7'h36)) | (opcode == 7'h37)) | (opcode == 7'h38))
				is_branch_type_instr = 1'b1;
		end
	endfunction
	function automatic is_iret_instr;
		input reg [6:0] opcode;
		begin
			is_iret_instr = 1'b0;
			if (opcode == 7'h33)
				is_iret_instr = 1'b1;
		end
	endfunction
	function automatic is_jump_instr;
		input reg [6:0] opcode;
		begin
			is_jump_instr = 1'b0;
			if (opcode == 7'h31)
				is_jump_instr = 1'b1;
		end
	endfunction
	function automatic is_mov_instr;
		input reg [6:0] opcode;
		begin
			is_mov_instr = 1'b0;
			if (opcode == 7'h14)
				is_mov_instr = 1'b1;
		end
	endfunction
	function automatic is_r_type_instr;
		input reg [6:0] opcode;
		begin
			is_r_type_instr = 1'b0;
			if (((((opcode == 7'h00) | (opcode == 7'h01)) | (opcode == 7'h04)) | (opcode == 7'h05)) | (opcode == 7'h03))
				is_r_type_instr = 1'b1;
		end
	endfunction
	function automatic is_tlb_instr;
		input reg [6:0] opcode;
		begin
			is_tlb_instr = 1'b0;
			if (opcode == 7'h32)
				is_tlb_instr = 1'b1;
		end
	endfunction
	assign alu_to_wb_intr = ((((is_r_type_instr(req_alu_info[14-:7]) | is_mov_instr(req_alu_info[14-:7])) | is_branch_type_instr(req_alu_info[14-:7])) | is_jump_instr(req_alu_info[14-:7])) | is_iret_instr(req_alu_info[14-:7])) | is_tlb_instr(req_alu_info[14-:7]);
	reg tlb_req_valid_next;
	reg tlb_id_next;
	reg [52:0] tlb_req_info_next;
	wire req_wb_valid_next;
	reg req_wb_valid_ff;
	reg [359:0] req_wb_info_next;
	reg [359:0] req_wb_info_ff;
	always @(posedge clock)
		if (reset | flush_alu)
			req_wb_valid_ff <= 1'b0;
		else
			req_wb_valid_ff <= req_wb_valid_next;
	always @(posedge clock)
		if (reset | flush_alu)
			req_wb_info_ff <= {360 {1'sb0}};
		else
			req_wb_info_ff <= req_wb_info_next;
	assign req_wb_valid_next = (flush_alu ? 1'b0 : (stall_decode ? 1'b0 : (stall_decode_ff ? alu_to_wb_intr : (fetch_xcpt_valid | decode_xcpt_valid ? 1'b1 : req_alu_valid & alu_to_wb_intr))));
	assign req_wb_valid = req_wb_valid_ff;
	assign req_wb_info = req_wb_info_ff;
	reg [31:0] rf_data;
	always @(*) begin
		req_wb_info_next[359-:3] = req_alu_instr_id;
		req_wb_info_next[356-:32] = req_alu_pc;
		req_wb_info_next[324] = tlb_req_valid_next;
		req_wb_info_next[323] = tlb_id_next;
		req_wb_info_next[322-:53] = tlb_req_info_next;
		req_wb_info_next[269] = is_r_type_instr(req_alu_info[14-:7]) | is_mov_instr(req_alu_info[14-:7]);
		req_wb_info_next[268-:5] = req_alu_info[113-:5];
		req_wb_info_next[263-:32] = rf_data;
		req_wb_info_next[231-:66] = xcpt_fetch_in;
		req_wb_info_next[165-:33] = xcpt_decode_in;
		req_wb_info_next[132-:33] = xcpt_alu;
		req_wb_info_next[99-:33] = {33 {1'sb0}};
		req_wb_info_next[66-:67] = {67 {1'sb0}};
	end
	reg [31:0] branch_pc_next;
	reg take_branch_next;
	reg iret_instr_next;
	always @(posedge clock)
		if (reset)
			take_branch <= 1'b0;
		else
			take_branch <= take_branch_next;
	always @(posedge clock)
		if (reset)
			iret_instr <= 1'b0;
		else
			iret_instr <= iret_instr_next;
	always @(posedge clock) branch_pc <= branch_pc_next;
	reg [31:0] ra_data;
	reg [31:0] rb_data;
	reg [63:0] oper_data;
	reg [63:0] oper_data_2;
	reg rob_blocks_src1;
	reg rob_blocks_src2;
	reg rob_src1_found_next;
	reg rob_src1_found_ff;
	reg rob_src2_found_next;
	reg rob_src2_found_ff;
	reg [31:0] rob_src1_data_ff;
	reg [31:0] rob_src2_data_ff;
	always @(posedge clock)
		if (reset | flush_alu)
			rob_src1_found_ff <= 1'b0;
		else
			rob_src1_found_ff <= rob_src1_found_next;
	always @(posedge clock)
		if (reset | flush_alu)
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
		rob_src1_id = req_alu_info[7-:3];
		rob_src2_id = req_alu_info[3-:3];
		rob_blocks_src1 = req_alu_info[4];
		rob_blocks_src2 = req_alu_info[0];
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
			stall_decode = (fetch_xcpt_valid | decode_xcpt_valid ? 1'b0 : (!req_alu_valid ? 1'b0 : (rob_blocks_src1 & !rob_src1_hit) | (rob_blocks_src2 & !rob_src2_hit)));
		end
	end
	function automatic is_load_instr;
		input reg [6:0] opcode;
		begin
			is_load_instr = 1'b0;
			if ((opcode == 7'h10) | (opcode == 7'h11))
				is_load_instr = 1'b1;
		end
	endfunction
	localparam [1:0] Byte = 2'b00;
	localparam [1:0] Word = 2'b11;
	always @(*) begin
		rf_data = {32 {1'sb0}};
		take_branch_next = 1'b0;
		iret_instr_next = 1'b0;
		branch_pc_next = {32 {1'sb0}};
		req_dcache_info_next = {239 {1'sb0}};
		req_dcache_info_next[235-:32] = req_alu_pc;
		req_dcache_info_next[238-:3] = req_alu_instr_id;
		req_dcache_info_next[203-:5] = req_alu_info[113-:5];
		req_dcache_info_next[131-:66] = xcpt_fetch_in;
		req_dcache_info_next[65-:33] = xcpt_decode_in;
		xcpt_alu[32] = 1'b0;
		xcpt_alu[31-:32] = req_alu_pc;
		ra_data = (rob_blocks_src1 ? (rob_src1_hit ? rob_src1_data : rob_src1_data_ff) : req_alu_info[98-:32]);
		rb_data = (rob_blocks_src2 ? (rob_src2_hit ? rob_src2_data : rob_src2_data_ff) : req_alu_info[66-:32]);
		tlb_req_valid_next = 1'b0;
		if (req_alu_info[14-:7] == 7'h00) begin
			oper_data = {{32 {1'b0}}, ra_data} + {{32 {1'b0}}, rb_data};
			rf_data = oper_data[31:0];
			xcpt_alu[32] = oper_data[32+:32] != {32 {1'sb0}};
		end
		else if (req_alu_info[14-:7] == 7'h01)
			rf_data = ra_data - rb_data;
		else if (req_alu_info[14-:7] == 7'h03) begin
			oper_data = {{32 {1'b0}}, ra_data} + {{44 {1'b0}}, req_alu_info[34-:20]};
			rf_data = oper_data[31:0];
			xcpt_alu[32] = oper_data[32+:32] != {32 {1'sb0}};
		end
		else if (req_alu_info[14-:7] == 7'h04) begin
			oper_data = {{32 {1'b0}}, ra_data} << {{44 {1'b0}}, req_alu_info[34-:20]};
			rf_data = oper_data[31:0];
			xcpt_alu[32] = oper_data[32+:32] != {32 {1'sb0}};
		end
		else if (req_alu_info[14-:7] == 7'h05) begin
			oper_data = {{32 {1'b0}}, ra_data} >> {{44 {1'b0}}, req_alu_info[34-:20]};
			rf_data = oper_data[31:0];
			xcpt_alu[32] = oper_data[32+:32] != {32 {1'sb0}};
		end
		else if (is_m_type_instr(req_alu_info[14-:7])) begin
			if (is_load_instr(req_alu_info[14-:7]))
				oper_data = {{32 {1'b0}}, ra_data + {{12 {1'b0}}, req_alu_info[34-:20]}};
			else
				oper_data = {{32 {1'b0}}, rb_data + {{12 {1'b0}}, req_alu_info[34-:20]}};
			oper_data_2 = {{32 {1'b0}}, ra_data};
			if (is_load_instr(req_alu_info[14-:7]))
				req_dcache_info_next[164] = 1'b0;
			else
				req_dcache_info_next[164] = 1'b1;
			if ((req_alu_info[14-:7] == 7'h10) | (req_alu_info[14-:7] == 7'h12))
				req_dcache_info_next[166-:2] = Byte;
			else
				req_dcache_info_next[166-:2] = Word;
			req_dcache_info_next[198-:32] = oper_data[31:0];
			req_dcache_info_next[163-:32] = oper_data_2[31:0];
			xcpt_alu[32] = (oper_data[32+:32] != {32 {1'sb0}}) | (oper_data_2[32+:32] != {32 {1'sb0}});
		end
		else if (req_alu_info[14-:7] == 7'h30) begin
			if (ra_data == rb_data) begin
				branch_pc_next = {{12 {1'b0}}, req_alu_info[34-:20]};
				take_branch_next = req_alu_valid;
			end
		end
		else if (req_alu_info[14-:7] == 7'h34) begin
			if (ra_data != rb_data) begin
				branch_pc_next = {{12 {1'b0}}, req_alu_info[34-:20]};
				take_branch_next = req_alu_valid;
			end
		end
		else if (req_alu_info[14-:7] == 7'h35) begin
			if (ra_data < rb_data) begin
				branch_pc_next = {{12 {1'b0}}, req_alu_info[34-:20]};
				take_branch_next = req_alu_valid;
			end
		end
		else if (req_alu_info[14-:7] == 7'h36) begin
			if (ra_data > rb_data) begin
				branch_pc_next = {{12 {1'b0}}, req_alu_info[34-:20]};
				take_branch_next = req_alu_valid;
			end
		end
		else if (req_alu_info[14-:7] == 7'h37) begin
			if (ra_data <= rb_data) begin
				branch_pc_next = {{12 {1'b0}}, req_alu_info[34-:20]};
				take_branch_next = req_alu_valid;
			end
		end
		else if (req_alu_info[14-:7] == 7'h38) begin
			if (ra_data >= rb_data) begin
				branch_pc_next = {{12 {1'b0}}, req_alu_info[34-:20]};
				take_branch_next = req_alu_valid;
			end
		end
		else if (req_alu_info[14-:7] == 7'h31) begin
			branch_pc_next = {{12 {1'b0}}, req_alu_info[34-:20]};
			take_branch_next = req_alu_valid;
		end
		else if (is_mov_instr(req_alu_info[14-:7]))
			rf_data = req_alu_info[98-:32];
		else if (is_tlb_instr(req_alu_info[14-:7])) begin
			tlb_req_valid_next = req_alu_valid;
			tlb_id_next = req_alu_info[15];
			tlb_req_info_next[52-:32] = ra_data;
			tlb_req_info_next[20-:20] = rb_data;
			tlb_req_info_next[0] = 1'b1;
		end
		else if (is_iret_instr(req_alu_info[14-:7])) begin
			branch_pc_next = req_alu_info[98-:32];
			take_branch_next = req_alu_valid;
			iret_instr_next = req_alu_valid;
		end
		req_dcache_info_next[32-:33] = xcpt_alu;
	end
endmodule

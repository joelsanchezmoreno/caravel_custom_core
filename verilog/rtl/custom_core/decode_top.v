module decode_top (
	clock,
	reset,
	priv_mode,
	iret_instr,
	stall_decode,
	flush_decode,
	flush_rob,
	xcpt_fetch_in,
	fetch_instr_valid,
	fetch_instr_data,
	fetch_instr_pc,
	req_to_alu_valid,
	req_to_alu_info,
	req_to_alu_instr_id,
	req_to_alu_pc,
	alu_xcpt_fetch_out,
	alu_decode_xcpt,
	req_to_mul_valid,
	req_to_mul_info,
	req_to_mul_instr_id,
	req_to_mul_pc,
	mul_xcpt_fetch_out,
	mul_decode_xcpt,
	writeEnRF,
	writeValRF,
	destRF,
	write_idRF,
	xcpt_valid,
	rmPC,
	rmAddr,
	xcpt_type
);
	input wire clock;
	input wire reset;
	output wire [0:0] priv_mode;
	input wire iret_instr;
	input wire stall_decode;
	input wire flush_decode;
	input wire flush_rob;
	input wire [65:0] xcpt_fetch_in;
	input wire fetch_instr_valid;
	input wire [31:0] fetch_instr_data;
	input wire [31:0] fetch_instr_pc;
	output wire req_to_alu_valid;
	output wire [113:0] req_to_alu_info;
	output reg [2:0] req_to_alu_instr_id;
	output wire [31:0] req_to_alu_pc;
	output wire [65:0] alu_xcpt_fetch_out;
	output wire [32:0] alu_decode_xcpt;
	output wire req_to_mul_valid;
	output wire [86:0] req_to_mul_info;
	output reg [2:0] req_to_mul_instr_id;
	output wire [31:0] req_to_mul_pc;
	output wire [65:0] mul_xcpt_fetch_out;
	output wire [32:0] mul_decode_xcpt;
	input wire writeEnRF;
	input wire [31:0] writeValRF;
	input wire [4:0] destRF;
	input wire [2:0] write_idRF;
	input wire xcpt_valid;
	input wire [31:0] rmPC;
	input wire [31:0] rmAddr;
	input wire [2:0] xcpt_type;
	wire [4:0] rd_addr;
	wire [4:0] ra_addr;
	wire [4:0] rb_addr;
	wire [6:0] opcode;
	assign rd_addr = fetch_instr_data[24:20];
	assign opcode = fetch_instr_data[31:25];
	assign ra_addr = fetch_instr_data[19:15];
	assign rb_addr = fetch_instr_data[14:10];
	wire mul_instr;
	function automatic is_mul_instr;
		input reg [6:0] opcode;
		begin
			is_mul_instr = 1'b0;
			if (opcode == 7'h02)
				is_mul_instr = 1'b1;
		end
	endfunction
	assign mul_instr = fetch_instr_valid & is_mul_instr(opcode);
	reg [32:0] decode_xcpt_next;
	reg [32:0] decode_xcpt_ff;
	reg [65:0] xcpt_fetch_ff;
	always @(posedge clock)
		if (reset | flush_decode)
			decode_xcpt_ff <= {33 {1'sb0}};
		else if (!stall_decode)
			decode_xcpt_ff <= decode_xcpt_next;
	always @(posedge clock)
		if (reset | flush_decode)
			xcpt_fetch_ff <= {66 {1'sb0}};
		else if (!stall_decode)
			xcpt_fetch_ff <= xcpt_fetch_in;
	assign alu_decode_xcpt = (flush_decode ? {33 {1'sb0}} : (mul_instr ? {33 {1'sb0}} : decode_xcpt_ff));
	assign alu_xcpt_fetch_out = (flush_decode ? {66 {1'sb0}} : (mul_instr ? {66 {1'sb0}} : xcpt_fetch_ff));
	assign mul_decode_xcpt = (flush_decode ? {33 {1'sb0}} : (!mul_instr ? {33 {1'sb0}} : decode_xcpt_ff));
	assign mul_xcpt_fetch_out = (flush_decode ? {66 {1'sb0}} : (!mul_instr ? {66 {1'sb0}} : xcpt_fetch_ff));
	wire req_to_alu_valid_next;
	reg req_to_alu_valid_ff;
	reg [113:0] req_to_alu_info_next;
	reg [113:0] req_to_alu_info_ff;
	reg [31:0] req_to_alu_pc_ff;
	always @(posedge clock)
		if (reset | flush_decode)
			req_to_alu_valid_ff <= 1'sb0;
		else
			req_to_alu_valid_ff <= req_to_alu_valid_next;
	always @(posedge clock)
		if (!stall_decode)
			req_to_alu_pc_ff <= fetch_instr_pc;
	always @(posedge clock)
		if (!stall_decode)
			req_to_alu_info_ff <= req_to_alu_info_next;
	assign req_to_alu_valid_next = (flush_decode ? 1'b0 : (stall_decode ? 1'b0 : (fetch_instr_valid ? !mul_instr : 1'b0)));
	assign req_to_alu_valid = (flush_decode ? 1'b0 : req_to_alu_valid_ff);
	assign req_to_alu_info = req_to_alu_info_ff;
	assign req_to_alu_pc = req_to_alu_pc_ff;
	wire req_to_mul_valid_next;
	reg req_to_mul_valid_ff;
	reg [86:0] req_to_mul_info_next;
	reg [86:0] req_to_mul_info_ff;
	reg [31:0] req_to_mul_pc_ff;
	always @(posedge clock)
		if (reset | flush_decode)
			req_to_mul_valid_ff <= 1'sb0;
		else
			req_to_mul_valid_ff <= req_to_mul_valid_next;
	always @(posedge clock)
		if (!stall_decode)
			req_to_mul_pc_ff <= fetch_instr_pc;
	always @(posedge clock)
		if (!stall_decode)
			req_to_mul_info_ff <= req_to_mul_info_next;
	assign req_to_mul_valid_next = (flush_decode ? 1'b0 : (stall_decode ? 1'b0 : (fetch_instr_valid ? mul_instr : 1'b0)));
	assign req_to_mul_valid = (flush_decode ? 1'b0 : req_to_mul_valid_ff);
	assign req_to_mul_info = req_to_mul_info_ff;
	assign req_to_mul_pc = req_to_mul_pc_ff;
	wire [31:0] rf_reg1_data;
	wire [31:0] rf_reg2_data;
	wire [31:0] rm0_data;
	wire [31:0] rm1_data;
	wire [31:0] rm2_data;
	reg stall_decode_ff;
	always @(posedge clock)
		if (reset | flush_rob)
			stall_decode_ff <= 1'sb0;
		else
			stall_decode_ff <= stall_decode;
	reg [95:0] reg_rob_id_next;
	reg [95:0] reg_rob_id_ff;
	reg flush_decode_ff;
	reg [95:0] reg_rob_id_next_2;
	always @(posedge clock)
		if (!stall_decode)
			reg_rob_id_ff <= (flush_decode_ff ? reg_rob_id_next_2 : reg_rob_id_next);
	reg [31:0] reg_blocked_valid_next;
	reg [31:0] reg_blocked_valid_ff;
	reg [31:0] reg_blocked_valid_next_2;
	always @(posedge clock)
		if (reset | flush_rob)
			reg_blocked_valid_ff <= {32 {1'sb0}};
		else if (!stall_decode)
			reg_blocked_valid_ff <= (flush_decode_ff ? reg_blocked_valid_next_2 : reg_blocked_valid_next);
	reg [2:0] ticket_src1;
	reg rob_blocks_src1;
	reg [2:0] ticket_src2;
	reg rob_blocks_src2;
	reg [2:0] reorder_buffer_tail_next;
	reg [2:0] reorder_buffer_tail_ff;
	always @(posedge clock)
		if (reset | flush_rob)
			reorder_buffer_tail_ff <= {3 {1'sb0}};
		else if (!stall_decode)
			reorder_buffer_tail_ff <= reorder_buffer_tail_next;
	reg [31:0] reg_blocked_valid_ff_2;
	reg [95:0] reg_rob_id_ff_2;
	always @(posedge clock)
		if (reset | flush_rob)
			reg_blocked_valid_ff_2 <= {32 {1'sb0}};
		else
			reg_blocked_valid_ff_2 <= reg_blocked_valid_next_2;
	always @(posedge clock)
		if (reset | flush_rob)
			reg_rob_id_ff_2 <= {96 {1'sb0}};
		else
			reg_rob_id_ff_2 <= reg_rob_id_next_2;
	always @(posedge clock)
		if (reset | flush_rob)
			flush_decode_ff <= 1'sb0;
		else
			flush_decode_ff <= flush_decode;
	function automatic is_addi_type_instr;
		input reg [6:0] opcode;
		begin
			is_addi_type_instr = 1'b0;
			if (opcode == 7'h03)
				is_addi_type_instr = 1'b1;
		end
	endfunction
	function automatic is_branch_type_instr;
		input reg [6:0] opcode;
		begin
			is_branch_type_instr = 1'b0;
			if ((((((opcode == 7'h30) | (opcode == 7'h34)) | (opcode == 7'h35)) | (opcode == 7'h36)) | (opcode == 7'h37)) | (opcode == 7'h38))
				is_branch_type_instr = 1'b1;
		end
	endfunction
	function automatic is_load_instr;
		input reg [6:0] opcode;
		begin
			is_load_instr = 1'b0;
			if ((opcode == 7'h10) | (opcode == 7'h11))
				is_load_instr = 1'b1;
		end
	endfunction
	function automatic is_m_type_instr;
		input reg [6:0] opcode;
		begin
			is_m_type_instr = 1'b0;
			if ((((opcode == 7'h10) | (opcode == 7'h11)) | (opcode == 7'h12)) | (opcode == 7'h13))
				is_m_type_instr = 1'b1;
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
	function automatic is_store_instr;
		input reg [6:0] opcode;
		begin
			is_store_instr = 1'b0;
			if ((opcode == 7'h12) | (opcode == 7'h13))
				is_store_instr = 1'b1;
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
	always @(*) begin
		reg_blocked_valid_next_2 = (flush_decode | flush_decode_ff ? reg_blocked_valid_ff_2 : reg_blocked_valid_ff);
		reg_rob_id_next_2 = (flush_decode | flush_decode_ff ? reg_rob_id_ff_2 : reg_rob_id_ff);
		reg_blocked_valid_next = reg_blocked_valid_ff;
		reg_rob_id_next = reg_rob_id_ff;
		reorder_buffer_tail_next = reorder_buffer_tail_ff;
		rob_blocks_src1 = 1'b0;
		rob_blocks_src2 = 1'b0;
		if ((((is_r_type_instr(opcode) | is_mul_instr(opcode)) | is_m_type_instr(opcode)) | is_branch_type_instr(opcode)) | is_tlb_instr(opcode)) begin
			if (reg_blocked_valid_ff[ra_addr])
				if (writeEnRF & (reg_rob_id_ff[ra_addr * 3+:3] == write_idRF))
					rob_blocks_src1 = 1'b0;
				else
					rob_blocks_src1 = 1'b1;
			ticket_src1 = reg_rob_id_ff[ra_addr * 3+:3];
		end
		if ((((is_r_type_instr(opcode) | is_mul_instr(opcode)) | is_store_instr(opcode)) | is_branch_type_instr(opcode)) | is_tlb_instr(opcode))
			if (is_store_instr(opcode)) begin
				ticket_src2 = reg_rob_id_ff[rd_addr * 3+:3];
				if (reg_blocked_valid_ff[rd_addr])
					if (writeEnRF & (reg_rob_id_ff[rd_addr * 3+:3] == write_idRF))
						rob_blocks_src2 = 1'b0;
					else
						rob_blocks_src2 = 1'b1;
			end
			else begin
				ticket_src2 = reg_rob_id_ff[rb_addr * 3+:3];
				if (!is_addi_type_instr(opcode) & reg_blocked_valid_ff[rb_addr])
					if (writeEnRF & (reg_rob_id_ff[rb_addr * 3+:3] == write_idRF))
						rob_blocks_src2 = 1'b0;
					else
						rob_blocks_src2 = 1'b1;
			end
		if ((req_to_alu_valid | req_to_mul_valid) | (!stall_decode & stall_decode_ff))
			reorder_buffer_tail_next = reorder_buffer_tail_ff + 1'b1;
		if (fetch_instr_valid)
			if (((is_r_type_instr(opcode) | is_mul_instr(opcode)) | is_load_instr(opcode)) | is_mov_instr(opcode)) begin
				reg_blocked_valid_next[rd_addr] = 1'b1;
				reg_rob_id_next[rd_addr * 3+:3] = reorder_buffer_tail_next;
			end
		if (writeEnRF & (reg_rob_id_ff[destRF * 3+:3] == write_idRF))
			reg_blocked_valid_next[destRF] = 1'b0;
		if (writeEnRF & (reg_rob_id_ff_2[destRF * 3+:3] == write_idRF))
			reg_blocked_valid_next_2[destRF] = 1'b0;
	end
	reg [31:0] ra_data;
	reg [31:0] rb_data;
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
	function automatic is_nop_instr;
		input reg [6:0] opcode;
		begin
			is_nop_instr = 1'b0;
			if (opcode == 7'hff)
				is_nop_instr = 1'b1;
		end
	endfunction
	localparam [0:0] User = 1'b0;
	always @(*) begin
		decode_xcpt_next[32] = 1'b0;
		decode_xcpt_next[31-:32] = fetch_instr_pc;
		req_to_alu_instr_id = reorder_buffer_tail_ff;
		req_to_alu_info_next[14-:7] = opcode;
		req_to_alu_info_next[113-:5] = rd_addr;
		req_to_alu_info_next[108-:5] = ra_addr;
		req_to_alu_info_next[103-:5] = rb_addr;
		req_to_alu_info_next[7-:3] = ticket_src1;
		req_to_alu_info_next[4] = rob_blocks_src1;
		req_to_alu_info_next[3-:3] = ticket_src2;
		req_to_alu_info_next[0] = rob_blocks_src2;
		req_to_mul_instr_id = reorder_buffer_tail_ff;
		req_to_mul_info_next[86-:5] = rd_addr;
		req_to_mul_info_next[81-:5] = ra_addr;
		req_to_mul_info_next[76-:5] = rb_addr;
		req_to_mul_info_next[7-:3] = ticket_src1;
		req_to_mul_info_next[4] = rob_blocks_src1;
		req_to_mul_info_next[3-:3] = ticket_src2;
		req_to_mul_info_next[0] = rob_blocks_src2;
		ra_data = (writeEnRF & (destRF == ra_addr) ? writeValRF : rf_reg1_data);
		if (is_store_instr(opcode) & reg_blocked_valid_ff[rd_addr])
			rb_data = (writeEnRF & (destRF == rd_addr) ? writeValRF : rf_reg2_data);
		else
			rb_data = (writeEnRF & (destRF == rb_addr) ? writeValRF : rf_reg2_data);
		req_to_alu_info_next[98-:32] = ra_data;
		req_to_alu_info_next[66-:32] = rb_data;
		req_to_mul_info_next[71-:32] = ra_data;
		req_to_mul_info_next[39-:32] = rb_data;
		req_to_alu_info_next[34-:20] = {{5 {1'b0}}, fetch_instr_data[14:0]};
		if ((is_branch_type_instr(opcode) | is_jump_instr(opcode)) | is_tlb_instr(opcode)) begin
			if (is_branch_type_instr(opcode))
				req_to_alu_info_next[34-:20] = {{5 {1'b0}}, {fetch_instr_data[24:20], fetch_instr_data[9:0]}};
			else if (is_jump_instr(opcode))
				req_to_alu_info_next[34-:20] = {fetch_instr_data[24:20], fetch_instr_data[14:10], fetch_instr_data[9:0]};
			else begin
				req_to_alu_info_next[34-:20] = {{10 {1'b0}}, fetch_instr_data[9:0]};
				decode_xcpt_next[32] = (priv_mode == User ? fetch_instr_valid & !flush_decode : 1'b0);
			end
		end
		else if (is_mov_instr(opcode)) begin
			req_to_alu_info_next[98-:32] = rm1_data;
			if (fetch_instr_data[9:0] == 9'h001)
				req_to_alu_info_next[98-:32] = rm0_data;
			else if (fetch_instr_data[9:0] == 9'h002)
				req_to_alu_info_next[98-:32] = rm2_data;
		end
		else if (is_iret_instr(opcode))
			req_to_alu_info_next[98-:32] = rm0_data;
		else if (((!is_r_type_instr(opcode) & !is_mul_instr(opcode)) & !is_m_type_instr(opcode)) & !is_nop_instr(opcode))
			decode_xcpt_next[32] = fetch_instr_valid & !flush_decode;
	end
	wire [4:0] src1_addr;
	wire [4:0] src2_addr;
	wire [4:0] dest_addr;
	assign src1_addr = fetch_instr_data[19:15];
	assign src2_addr = ((opcode == 7'h12) | (opcode == 7'h13) ? fetch_instr_data[24:20] : fetch_instr_data[14:10]);
	assign dest_addr = destRF;
	regFile registerFile(
		.clock(clock),
		.reset(reset),
		.iret_instr(iret_instr),
		.priv_mode(priv_mode),
		.rm0_data(rm0_data),
		.rm1_data(rm1_data),
		.rm2_data(rm2_data),
		.src1_addr(src1_addr),
		.src2_addr(src2_addr),
		.reg1_data(rf_reg1_data),
		.reg2_data(rf_reg2_data),
		.writeEn(writeEnRF),
		.dest_addr(dest_addr),
		.writeVal(writeValRF),
		.xcpt_valid(xcpt_valid),
		.rmPC(rmPC),
		.rmAddr(rmAddr),
		.xcpt_type(xcpt_type)
	);
endmodule

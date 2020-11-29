module core_top_wrapper (
	vdda1,
	vdda2,
	vssa1,
	vssa2,
	vccd1,
	vccd2,
	vssd1,
	vssd2,
	wb_clk_i,
	wb_rst_i,
	wbs_stb_i,
	wbs_cyc_i,
	wbs_we_i,
	wbs_sel_i,
	wbs_dat_i,
	wbs_adr_i,
	wbs_ack_o,
	wbs_dat_o,
	la_data_in,
	la_data_out,
	la_oen,
	io_in,
	io_out,
	io_oeb,
	analog_io,
	user_clock2
);
	inout vdda1;
	inout vdda2;
	inout vssa1;
	inout vssa2;
	inout vccd1;
	inout vccd2;
	inout vssd1;
	inout vssd2;
	input wb_clk_i;
	input wb_rst_i;
	input wbs_stb_i;
	input wbs_cyc_i;
	input wbs_we_i;
	input [3:0] wbs_sel_i;
	input [31:0] wbs_dat_i;
	input [31:0] wbs_adr_i;
	output wbs_ack_o;
	output [31:0] wbs_dat_o;
	input [127:0] la_data_in;
	output [127:0] la_data_out;
	input [127:0] la_oen;
	input [37:0] io_in;
	output [37:0] io_out;
	output [37:0] io_oeb;
	inout [30:0] analog_io;
	input user_clock2;
	wire clk_i;
	wire reset_i;
	wire thread_enable;
	wire core_reset;
	assign core_reset = reset_i | la_oen[0];
	assign thread_enable = !core_reset & la_oen[1];
	assign clk_i = (~la_oen[64] ? la_data_in[64] : wb_clk_i);
	assign reset_i = (~la_oen[65] ? la_data_in[65] : wb_rst_i);
	wire [31:0] program_counter_o;
	assign la_data_out[31:0] = program_counter_o;
	assign io_out = program_counter_o;
	assign io_oeb = {37 {reset_i}};
	reg [31:0] boot_address;
	reg [31:0] boot_address_next;
	always @(posedge clk_i)
		if (reset_i)
			boot_address <= 32'h1000;
		else
			boot_address <= boot_address_next;
	wire mprj_req_valid;
	wire [31:0] mprj_req_addr;
	wire [3:0] mprj_req_wstrb;
	wire [31:0] mprj_req_wdata;
	reg mprj_rsp_valid;
	reg [31:0] mprj_rsp_data;
	assign mprj_req_valid = wbs_cyc_i && wbs_stb_i;
	assign mprj_req_addr = wbs_adr_i;
	assign mprj_req_wstrb = wbs_sel_i & {4 {wbs_we_i}};
	assign mprj_req_wdata = wbs_dat_i;
	assign wbs_ack_o = mprj_rsp_valid;
	assign wbs_dat_o = mprj_rsp_data;
	wire dcache_req_valid_miss;
	wire [148:0] dcache_req_info_miss;
	wire icache_req_valid_miss;
	wire [148:0] icache_req_info_miss;
	reg [127:0] rsp_data_miss;
	reg rsp_valid_miss;
	reg rsp_cache_id;
	reg rsp_bus_error;
	core_top core_top(
		.clock(clk_i),
		.reset(core_reset),
		.thread_enable(thread_enable),
		.boot_addr(boot_address),
		.program_counter_o(program_counter_o),
		.dcache_req_valid_miss(dcache_req_valid_miss),
		.dcache_req_info_miss(dcache_req_info_miss),
		.icache_req_valid_miss(icache_req_valid_miss),
		.icache_req_info_miss(icache_req_info_miss),
		.rsp_data_miss(rsp_data_miss),
		.rsp_bus_error(rsp_bus_error),
		.rsp_valid_miss(rsp_valid_miss),
		.rsp_cache_id(rsp_cache_id)
	);
	reg [127:0] main_memory [999:0];
	reg req_mm_valid;
	reg [148:0] req_mm_info;
	reg [148:0] req_mm_info_ff;
	always @(posedge clk_i) req_mm_info_ff <= req_mm_info;
	reg rsp_mm_valid;
	reg rsp_mm_bus_error;
	reg [127:0] rsp_mm_data;
	reg [2:0] mem_req_count;
	reg [2:0] mem_req_count_ff;
	always @(posedge clk_i)
		if (reset_i)
			mem_req_count_ff <= {3 {1'sb0}};
		else
			mem_req_count_ff <= mem_req_count;
	reg dcache_req_valid_next;
	reg dcache_req_valid_ff;
	reg [148:0] dcache_req_info_ff;
	reg icache_req_valid_next;
	reg icache_req_valid_ff;
	reg [148:0] icache_req_info_ff;
	always @(posedge clk_i)
		if (reset_i)
			dcache_req_valid_ff <= 1'sb0;
		else
			dcache_req_valid_ff <= dcache_req_valid_next;
	always @(posedge clk_i)
		if (reset_i)
			icache_req_valid_ff <= 1'sb0;
		else
			icache_req_valid_ff <= icache_req_valid_next;
	always @(posedge clk_i)
		if (reset_i)
			dcache_req_info_ff <= {149 {1'sb0}};
		else if (dcache_req_valid_miss)
			dcache_req_info_ff <= dcache_req_info_miss;
	always @(posedge clk_i)
		if (reset_i)
			icache_req_info_ff <= {149 {1'sb0}};
		else if (icache_req_valid_miss)
			icache_req_info_ff <= icache_req_info_miss;
	reg wait_rsp_icache_next;
	reg wait_rsp_icache_ff;
	wire wait_rsp_enable;
	reg wait_icache_rsp_update;
	assign wait_rsp_enable = (!dcache_req_valid_miss & icache_req_valid_miss) | wait_icache_rsp_update;
	always @(posedge clk_i)
		if (reset_i)
			wait_rsp_icache_ff <= 1'sb0;
		else if (wait_rsp_enable)
			wait_rsp_icache_ff <= wait_rsp_icache_next;
	always @(*) begin
		rsp_valid_miss = 1'b0;
		rsp_bus_error = rsp_mm_bus_error;
		dcache_req_valid_next = dcache_req_valid_ff;
		icache_req_valid_next = icache_req_valid_ff;
		req_mm_info = req_mm_info_ff;
		mem_req_count = mem_req_count_ff;
		if (dcache_req_valid_miss)
			dcache_req_valid_next = 1'b1;
		if (icache_req_valid_miss)
			icache_req_valid_next = 1'b1;
		if (dcache_req_valid_ff & !wait_rsp_icache_ff)
			if (mem_req_count_ff < 4)
				mem_req_count = mem_req_count_ff + 1'b1;
			else begin
				req_mm_valid = !rsp_mm_valid;
				req_mm_info = dcache_req_info_ff;
				if (rsp_mm_valid) begin
					req_mm_valid = 1'b0;
					rsp_valid_miss = 1'b1;
					rsp_cache_id = 1'b1;
					rsp_data_miss = rsp_mm_data;
					mem_req_count = {3 {1'sb0}};
					dcache_req_valid_next = dcache_req_valid_miss;
				end
			end
		if ((!dcache_req_valid_ff & icache_req_valid_ff) | wait_rsp_icache_ff) begin
			wait_rsp_icache_next = 1'b1;
			if (mem_req_count_ff < 4)
				mem_req_count = mem_req_count_ff + 1'b1;
			else begin
				req_mm_valid = !rsp_mm_valid;
				req_mm_info = icache_req_info_ff;
				if (rsp_mm_valid) begin
					req_mm_valid = 1'b0;
					rsp_valid_miss = 1'b1;
					rsp_cache_id = 1'b0;
					rsp_data_miss = rsp_mm_data;
					mem_req_count = {3 {1'sb0}};
					wait_rsp_icache_next = 1'b0;
					wait_icache_rsp_update = 1'b1;
					icache_req_valid_next = icache_req_valid_miss;
				end
			end
		end
	end
	reg [2:0] mem_rsp_count;
	always @(posedge clk_i) begin
		boot_address_next <= boot_address;
		if (reset_i) begin
			mprj_rsp_valid <= 1'b0;
			mprj_rsp_data <= {32 {1'sb0}};
			rsp_mm_valid <= 1'b0;
			rsp_mm_bus_error <= 1'b0;
		end
		else begin
			mprj_rsp_valid <= 1'b0;
			rsp_mm_valid <= 1'b0;
			rsp_mm_bus_error <= 1'b0;
			if (mprj_req_valid && !mprj_rsp_valid) begin
				mprj_rsp_valid <= 1'b1;
				mprj_rsp_data <= main_memory[mprj_req_addr];
				if (mprj_req_addr == 32'hffffff00)
					boot_address_next <= mprj_req_wdata;
				else begin
					if (mprj_req_wstrb[0])
						main_memory[mprj_req_addr][7:0] <= mprj_req_wdata[7:0];
					if (mprj_req_wstrb[1])
						main_memory[mprj_req_addr][15:8] <= mprj_req_wdata[15:8];
					if (mprj_req_wstrb[2])
						main_memory[mprj_req_addr][23:16] <= mprj_req_wdata[23:16];
					if (mprj_req_wstrb[3])
						main_memory[mprj_req_addr][31:24] <= mprj_req_wdata[31:24];
				end
			end
			else if (req_mm_valid) begin
				mem_rsp_count <= mem_rsp_count + 1'b1;
				if (mem_rsp_count == 4) begin
					rsp_mm_valid <= 1'b1;
					if (req_mm_info_ff[148-:20] >= 16000)
						rsp_mm_bus_error <= 1'b1;
					else if (!req_mm_info_ff[128])
						rsp_mm_data <= main_memory[req_mm_info_ff[148-:20]];
					else
						main_memory[req_mm_info_ff[148-:20]] <= req_mm_info_ff[127-:128];
					mem_rsp_count <= {3 {1'sb0}};
				end
			end
		end
	end
endmodule

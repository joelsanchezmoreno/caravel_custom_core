module mul_stage (
	instr_valid_in,
	instr_id_in,
	program_counter_in,
	dest_reg_in,
	data_result_in,
	xcpt_fetch_in,
	xcpt_decode_in,
	xcpt_mul_in,
	instr_valid_out,
	instr_id_out,
	program_counter_out,
	dest_reg_out,
	data_result_out,
	xcpt_fetch_out,
	xcpt_decode_out,
	xcpt_mul_out
);
	input wire instr_valid_in;
	input wire [2:0] instr_id_in;
	input wire [31:0] program_counter_in;
	input wire [4:0] dest_reg_in;
	input wire [31:0] data_result_in;
	input wire [65:0] xcpt_fetch_in;
	input wire [32:0] xcpt_decode_in;
	input wire [32:0] xcpt_mul_in;
	output reg instr_valid_out;
	output reg [2:0] instr_id_out;
	output reg [31:0] program_counter_out;
	output reg [4:0] dest_reg_out;
	output reg [31:0] data_result_out;
	output reg [65:0] xcpt_fetch_out;
	output reg [32:0] xcpt_decode_out;
	output reg [32:0] xcpt_mul_out;
	always @(*) begin
		instr_valid_out = instr_valid_in;
		instr_id_out = instr_id_in;
		program_counter_out = program_counter_in;
		dest_reg_out = dest_reg_in;
		data_result_out = data_result_in;
		xcpt_fetch_out = xcpt_fetch_in;
		xcpt_decode_out = xcpt_decode_in;
		xcpt_mul_out = xcpt_mul_in;
	end
endmodule

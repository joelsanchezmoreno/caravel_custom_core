module regFile (
	clock,
	reset,
	src1_addr,
	src2_addr,
	reg1_data,
	reg2_data,
	iret_instr,
	priv_mode,
	rm0_data,
	rm1_data,
	rm2_data,
	writeEn,
	dest_addr,
	writeVal,
	xcpt_valid,
	xcpt_type,
	rmPC,
	rmAddr
);
	input wire clock;
	input wire reset;
	input wire [4:0] src1_addr;
	input wire [4:0] src2_addr;
	output reg [31:0] reg1_data;
	output reg [31:0] reg2_data;
	input wire iret_instr;
	output reg [0:0] priv_mode;
	output reg [31:0] rm0_data;
	output reg [31:0] rm1_data;
	output reg [31:0] rm2_data;
	input wire writeEn;
	input wire [4:0] dest_addr;
	input wire [31:0] writeVal;
	input wire xcpt_valid;
	input wire [2:0] xcpt_type;
	input wire [31:0] rmPC;
	input wire [31:0] rmAddr;
	reg [1023:0] regMem;
	reg [1023:0] regMem_ff;
	reg [31:0] rm0;
	reg [31:0] rm0_ff;
	reg [31:0] rm1;
	reg [31:0] rm1_ff;
	reg [2:0] rm2;
	reg [2:0] rm2_ff;
	reg [0:0] rm4;
	reg [0:0] rm4_ff;
	always @(posedge clock)
		if (reset)
			regMem_ff <= {1024 {1'sb0}};
		else
			regMem_ff <= regMem;
	always @(posedge clock)
		if (reset)
			rm0_ff <= {32 {1'sb0}};
		else
			rm0_ff <= rm0;
	always @(posedge clock)
		if (reset)
			rm1_ff <= {32 {1'sb0}};
		else
			rm1_ff <= rm1;
	always @(posedge clock)
		if (reset)
			rm2_ff <= {3 {1'sb0}};
		else
			rm2_ff <= rm2;
	always @(posedge clock)
		if (reset)
			rm4_ff <= 1'sb1;
		else
			rm4_ff <= rm4;
	localparam [0:0] Supervisor = 1'b1;
	localparam [0:0] User = 1'b0;
	always @(*) begin
		rm0 = rm0_ff;
		rm1 = rm1_ff;
		rm2 = rm2_ff;
		rm4 = rm4_ff;
		regMem = regMem_ff;
		if (writeEn)
			regMem[dest_addr * 32+:32] = writeVal;
		if (xcpt_valid) begin
			rm0 = rmPC;
			rm1 = rmAddr;
			rm2 = xcpt_type;
			rm4 = Supervisor;
		end
		else if (iret_instr)
			rm4 = User;
		reg1_data = regMem_ff[src1_addr * 32+:32];
		reg2_data = regMem_ff[src2_addr * 32+:32];
		rm0_data = rm0_ff;
		rm1_data = rm1_ff;
		rm2_data = rm2_ff;
		priv_mode = rm4_ff;
	end
endmodule

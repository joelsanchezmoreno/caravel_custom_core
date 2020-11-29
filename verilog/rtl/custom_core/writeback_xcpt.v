module writeback_xcpt (
	alu_req_info,
	mul_req_info,
	cache_req_info,
	alu_rob_xcpt_info,
	mul_rob_xcpt_info,
	cache_rob_xcpt_info
);
	input wire [359:0] alu_req_info;
	input wire [359:0] mul_req_info;
	input wire [359:0] cache_req_info;
	output reg [67:0] alu_rob_xcpt_info;
	output reg [67:0] mul_rob_xcpt_info;
	output reg [67:0] cache_rob_xcpt_info;
	localparam [2:0] cache_addr_fault = 3'b110;
	localparam [2:0] cache_bus_error = 3'b101;
	localparam [2:0] dTlb_miss = 3'b100;
	localparam [2:0] fetch_bus_error = 3'b001;
	localparam [2:0] iTlb_miss = 3'b000;
	localparam [2:0] illegal_instr = 3'b010;
	localparam [2:0] overflow = 3'b011;
	always @(*) begin
		alu_rob_xcpt_info[67] = 1'b0;
		if (alu_req_info[231] | alu_req_info[230]) begin
			alu_rob_xcpt_info[67] = 1'b1;
			alu_rob_xcpt_info[2-:3] = (alu_req_info[231] ? iTlb_miss : fetch_bus_error);
			alu_rob_xcpt_info[66-:32] = alu_req_info[229-:32];
			alu_rob_xcpt_info[34-:32] = alu_req_info[197-:32];
		end
		else if (alu_req_info[165]) begin
			alu_rob_xcpt_info[67] = 1'b1;
			alu_rob_xcpt_info[2-:3] = illegal_instr;
			alu_rob_xcpt_info[34-:32] = alu_req_info[164-:32];
		end
		else if (alu_req_info[132]) begin
			alu_rob_xcpt_info[67] = 1'b1;
			alu_rob_xcpt_info[2-:3] = overflow;
			alu_rob_xcpt_info[34-:32] = alu_req_info[131-:32];
		end
		else if (alu_req_info[99]) begin
			alu_rob_xcpt_info[67] = 1'b1;
			alu_rob_xcpt_info[2-:3] = overflow;
			alu_rob_xcpt_info[34-:32] = alu_req_info[98-:32];
		end
		else if ((alu_req_info[66] | alu_req_info[64]) | alu_req_info[65]) begin
			alu_rob_xcpt_info[67] = 1'b1;
			alu_rob_xcpt_info[2-:3] = (alu_req_info[66] ? cache_addr_fault : (alu_req_info[64] ? dTlb_miss : cache_bus_error));
			alu_rob_xcpt_info[66-:32] = alu_req_info[63-:32];
			alu_rob_xcpt_info[34-:32] = alu_req_info[31-:32];
		end
	end
	always @(*) begin
		mul_rob_xcpt_info[67] = 1'b0;
		if (mul_req_info[231] | mul_req_info[230]) begin
			mul_rob_xcpt_info[67] = 1'b1;
			mul_rob_xcpt_info[2-:3] = (mul_req_info[231] ? iTlb_miss : fetch_bus_error);
			mul_rob_xcpt_info[66-:32] = mul_req_info[229-:32];
			mul_rob_xcpt_info[34-:32] = mul_req_info[197-:32];
		end
		else if (mul_req_info[165]) begin
			mul_rob_xcpt_info[67] = 1'b1;
			mul_rob_xcpt_info[2-:3] = illegal_instr;
			mul_rob_xcpt_info[34-:32] = mul_req_info[164-:32];
		end
		else if (mul_req_info[132]) begin
			mul_rob_xcpt_info[67] = 1'b1;
			mul_rob_xcpt_info[2-:3] = overflow;
			mul_rob_xcpt_info[34-:32] = mul_req_info[131-:32];
		end
		else if (mul_req_info[99]) begin
			mul_rob_xcpt_info[67] = 1'b1;
			mul_rob_xcpt_info[2-:3] = overflow;
			mul_rob_xcpt_info[34-:32] = mul_req_info[98-:32];
		end
		else if ((mul_req_info[66] | mul_req_info[64]) | mul_req_info[65]) begin
			mul_rob_xcpt_info[67] = 1'b1;
			mul_rob_xcpt_info[2-:3] = (mul_req_info[66] ? cache_addr_fault : (mul_req_info[64] ? dTlb_miss : cache_bus_error));
			mul_rob_xcpt_info[66-:32] = mul_req_info[63-:32];
			mul_rob_xcpt_info[34-:32] = mul_req_info[31-:32];
		end
	end
	always @(*) begin
		cache_rob_xcpt_info[67] = 1'b0;
		if (cache_req_info[231] | cache_req_info[230]) begin
			cache_rob_xcpt_info[67] = 1'b1;
			cache_rob_xcpt_info[2-:3] = (cache_req_info[231] ? iTlb_miss : fetch_bus_error);
			cache_rob_xcpt_info[66-:32] = cache_req_info[229-:32];
			cache_rob_xcpt_info[34-:32] = cache_req_info[197-:32];
		end
		else if (cache_req_info[165]) begin
			cache_rob_xcpt_info[67] = 1'b1;
			cache_rob_xcpt_info[2-:3] = illegal_instr;
			cache_rob_xcpt_info[34-:32] = cache_req_info[164-:32];
		end
		else if (cache_req_info[132]) begin
			cache_rob_xcpt_info[67] = 1'b1;
			cache_rob_xcpt_info[2-:3] = overflow;
			cache_rob_xcpt_info[34-:32] = cache_req_info[131-:32];
		end
		else if (cache_req_info[99]) begin
			cache_rob_xcpt_info[67] = 1'b1;
			cache_rob_xcpt_info[2-:3] = overflow;
			cache_rob_xcpt_info[34-:32] = cache_req_info[98-:32];
		end
		else if ((cache_req_info[66] | cache_req_info[64]) | cache_req_info[65]) begin
			cache_rob_xcpt_info[67] = 1'b1;
			cache_rob_xcpt_info[2-:3] = (cache_req_info[66] ? cache_addr_fault : (cache_req_info[64] ? dTlb_miss : cache_bus_error));
			cache_rob_xcpt_info[66-:32] = cache_req_info[63-:32];
			cache_rob_xcpt_info[34-:32] = cache_req_info[31-:32];
		end
	end
endmodule

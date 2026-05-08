`timescale 1ps/1ps

module counter (
	input		clk,
	input		rst_n,
	input		clk_ena,

	input	[7:0]	start_counter,
	input		up_down,
	input		load,
	input		enable,

	output	reg	overflow,
	output	reg	underflow
);

reg	[7:0]		reg_TCNT;
reg	[7:0]		reg_TCNT_d1;
always @ (posedge clk) begin
	if (!rst_n) begin
		reg_TCNT			<= 0;
		overflow			<= 0;
		underflow			<= 0;
		reg_TCNT_d1			<= 0;
	end
	else begin
		if (load)
			reg_TCNT		<= start_counter;
		else if (enable & clk_ena) begin
			if (up_down)
				reg_TCNT	<= reg_TCNT + 1;
			else
				reg_TCNT	<= reg_TCNT - 1;
		end

		reg_TCNT_d1			<= reg_TCNT;
		overflow			<= (reg_TCNT == 0) & (reg_TCNT_d1 == 255);
		underflow			<= (reg_TCNT == 255) & (reg_TCNT_d1 == 0);
	end
end

endmodule

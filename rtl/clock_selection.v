`timescale 1ps/1ps

module clock_selection (
	input			clk,
	input			rst_n,

	input		[3:0]	clk_in,
	input		[1:0]	clk_sel,
	output	reg		clk_ena
);

reg	[3:0]		clk_in_d1;
reg	[3:0]		clk_in_ena;
always @ (posedge clk) begin
	clk_in_d1			<= clk_in;
	clk_in_ena			<= clk_in & ~clk_in_d1;
end

//just for simulation
always @ (posedge clk) begin
	if (!rst_n)
		clk_ena			<= 0;
	else begin
		case (clk_sel)
		0: clk_ena		<= clk_in_ena[0];
		1: clk_ena		<= clk_in_ena[1];
		2: clk_ena		<= clk_in_ena[2];
		3: clk_ena		<= clk_in_ena[3];
		default: clk_ena	<= 0;
		endcase
	end
end

/*
reg	[3:0]		clk_cnt;
reg	[3:0]		max_cnt;
always @ (posedge clk) begin
	if (!rst_n) begin
		clk_cnt			<= 0;
		max_cnt			<= 0;
		clk_ena			<= 0;
	end
	else begin
		case (clk_sel)
		0: max_cnt		<= 1;
		1: max_cnt		<= 3;
		2: max_cnt		<= 7;
		3: max_cnt		<= 15;
		default: max_cnt	<= 1;
		endcase
		
		if (enable) begin
			clk_cnt		<= (clk_cnt == max_cnt)? 0 : clk_cnt + 1;
		end
		clk_ena			<= (clk_cnt == max_cnt);
	end
end
*/
endmodule

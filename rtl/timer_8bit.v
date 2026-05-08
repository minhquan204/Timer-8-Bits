`timescale 1ps/1ps

module timer_8bit (
	input		clk,
	input		rst_n,
	input	[3:0]	clk_in,

	input		penable,
	input		psel,
	input		pwrite,
	input	[7:0]	paddr,
	input	[7:0]	pwdata,
	output	[7:0]	prdata,
	output		pready,
	output		pslverr
);

wire	[7:0]		start_counter;
wire			load, up_down, enable;
wire	[1:0]		clk_sel;
wire			overflow, underflow;
wire			clk_ena;
apb_controller apb_controller_i (
	.clk(clk),
	.rst_n(rst_n),
	.penable(penable),
	.psel(psel),
	.pwrite(pwrite),
	.paddr(paddr),
	.pwdata(pwdata),
	.prdata(prdata),
	.pready(pready),
	.pslverr(pslverr),

	.start_counter(start_counter),
	.load(load),
	.up_down(up_down),
	.enable(enable),
	.clk_sel(clk_sel),
	
	.overflow(overflow),
	.underflow(underflow)
);

counter counter_i (
	.clk(clk),
	.rst_n(rst_n),

	.clk_ena(clk_ena),
	.start_counter(start_counter),
	.load(load),
        .up_down(up_down),
        .enable(enable),

        .overflow(overflow),
        .underflow(underflow)	
);

clock_selection clock_selection_i (
	.clk(clk),
        .rst_n(rst_n),

	.clk_in(clk_in),
	.clk_sel(clk_sel),
	.clk_ena(clk_ena)
);

endmodule

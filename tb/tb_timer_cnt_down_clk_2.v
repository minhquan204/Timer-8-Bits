`timescale 1ps/1ps

module tb_timer_cnt_down_clk_2();

localparam	PERIOD	= 10;

reg		clk, rst_n;
reg	[3:0]	clk_in;
reg		psel;
reg		penable;
reg		pwrite;
reg	[7:0]	paddr;
reg	[7:0]	pwdata;
wire	[7:0]	prdata;
wire		pready;
wire		pslverr;
integer		i;
reg	[7:0]	value;
integer		f;

timer_8bit timer_8bit (
	.clk(clk),
	.rst_n(rst_n),
	.clk_in(clk_in),

	.penable(penable),
	.pwrite(pwrite),
	.psel(psel),
	.pwdata(pwdata),
	.paddr(paddr),
	.prdata(prdata),
	.pready(pready),
	.pslverr(pslverr)
);

// clock generator
initial begin
	clk = 1;
	forever #(PERIOD/2) clk = ~clk;
end

initial begin
	clk_in[0] = 1;
	forever #(2*PERIOD/2) clk_in[0] = ~clk_in[0];
end

initial begin
        clk_in[1] = 1;
        forever #(4*PERIOD/2) clk_in[1] = ~clk_in[1];
end

initial begin
        clk_in[2] = 1;
        forever #(8*PERIOD/2) clk_in[2] = ~clk_in[2];
end

initial begin
        clk_in[3] = 1;
        forever #(16*PERIOD/2) clk_in[3] = ~clk_in[3];
end

reg	[15:0]		cnt_debug = 0;
initial begin
	rst_n = 0;
	#200;
	@ (posedge clk);
	rst_n = 1;

	WRITE(10, 0);//TDR
	WRITE(8'b10010010,1);//TCR
	WRITE(8'b00010010,1);//TCR
end

initial begin
        f = $fopen ("output/tb_timer_cnt_down_clk_2.txt", "w");
	wait (tb_timer_cnt_down_clk_2.timer_8bit.counter_i.load == 1);

	repeat (11) begin
		@ (posedge tb_timer_cnt_down_clk_2.timer_8bit.counter_i.clk_ena);
		wait (tb_timer_cnt_down_clk_2.timer_8bit.counter_i.clk_ena & !tb_timer_cnt_down_clk_2.timer_8bit.counter_i.load);
		cnt_debug = cnt_debug + 1;
		if (tb_timer_cnt_down_clk_2.timer_8bit.apb_controller_i.reg_TSR != 0) begin
			$display ("run incorrectly");
   		        $fwrite (f, "FAIL\n");
			$fclose(f);
			#500;
                        $finish;
		end
	end
	repeat (3) begin
                @ (posedge clk);
                if (tb_timer_cnt_down_clk_2.timer_8bit.apb_controller_i.reg_TSR != 0) begin
                        $display ("run incorrectly");
                        $fwrite (f, "FAIL\n");
                        $fclose(f);
                        #500;
                        $finish;
                end
	end
	@ (posedge clk);
	if (tb_timer_cnt_down_clk_2.timer_8bit.apb_controller_i.reg_TSR != 2) begin
                $display ("run incorrectly");
                $fwrite (f, "FAIL\n");
                $fclose(f);
		#500;
                $finish;
	end

	READ(2, value);
	if (value == 2) begin
		$display ("run correctly");
		$fwrite (f, "PASS\n");
	end
	else begin
		$display ("run incorrectly");
		$fwrite (f, "FAIL\n");
	end

	$fclose(f);
	#500;
	$finish;
end

task WRITE;
	input	[7:0]	data_in;
	input	[7:0]	addr;
	begin
		@ (posedge clk);
		penable = 0;
		pwrite	= 0;
		psel	= 0;
		pwdata	= 0;
		paddr	= 0;
		@ (posedge clk);//setup
		pwrite	= 1;
		psel	= 1;
		pwdata	= data_in;
		paddr	= addr;
		@ (posedge clk);//access
		penable	= 1;
		wait (pready == 1);
		@ (posedge clk);
		penable = 0;
                pwrite  = 0;
                psel    = 0;
                pwdata  = 0;
                paddr   = 0;
		if (pslverr == 0)
			$display ("write %d to %d successfully\n", data_in, addr);
		else
			$display ("write %d to %d unsuccessfully\n", data_in, addr);
	end
endtask

task READ;
	input	[7:0]	addr;
	output	[7:0]	data_out;
	begin
                @ (posedge clk);
                penable = 0;
                pwrite  = 0;
                psel    = 0;
                pwdata  = 0;
                paddr   = 0;
                @ (posedge clk);//setup
                psel    = 1;
                paddr   = addr;
		@ (posedge clk);//access
		penable	= 1;
		wait (pready == 1);
		@ (posedge clk);
		penable = 0;
                pwrite  = 0;
                psel    = 0;
                pwdata  = 0;
                paddr   = 0;
		data_out= prdata;
                if (pslverr == 0)
                        $display ("read from %d successfully\n", addr);
                else
                        $display ("read from %d unsuccessfully\n", addr);
	end
endtask

endmodule

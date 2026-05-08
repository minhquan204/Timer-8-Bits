`timescale 1ns/1ps
module tb_fpga_top;

reg        CLOCK_50;
reg  [3:0] KEY;
reg [11:0] SW;
wire [6:0] SEG;
wire [2:0] DIG;
wire [9:0] LEDR;
wire [3:0] GPIO_CLK_IN;
assign GPIO_CLK_IN = 4'b0;

fpga_top_sim dut (
    .CLOCK_50    (CLOCK_50),
    .KEY         (KEY),
    .SW          (SW),
    .SEG         (SEG),
    .DIG         (DIG),
    .LEDR        (LEDR),
    .GPIO_CLK_IN (GPIO_CLK_IN)
);

always #10 CLOCK_50 = ~CLOCK_50;

always @(posedge CLOCK_50) begin
    if (dut.psel & dut.penable & dut.pwrite & dut.pready)
        $display("[APB WR] t=%0t addr=%0d data=8'h%02h (%08b)",
                 $time, dut.paddr, dut.pwdata, dut.pwdata);
end

reg [7:0] prev_tcnt;
always @(posedge CLOCK_50) begin
    if (dut.tcnt_value !== prev_tcnt) begin
        $display("[TCNT]   t=%0t val=%-3d  SEG=%07b DIG=%03b",
                 $time, dut.tcnt_value, SEG, DIG);
        prev_tcnt <= dut.tcnt_value;
    end
end

always @(posedge CLOCK_50) begin
    if (dut.overflow)  $display("[OVF!]   t=%0t LEDR[0]=%b", $time, LEDR[0]);
    if (dut.underflow) $display("[UNF!]   t=%0t LEDR[1]=%b", $time, LEDR[1]);
end

task wait_clk;
    input integer n;
    integer j;
    begin
        for (j = 0; j < n; j = j + 1)
            @(posedge CLOCK_50);
    end
endtask

task wait_clk2hz;
    input integer n_edges;
    integer k;
    begin
        for (k = 0; k < n_edges; k = k + 1)
            @(posedge dut.clk_2hz or negedge dut.clk_2hz);
    end
endtask

task press_key0;
    begin
        @(negedge CLOCK_50); KEY[0] = 1'b0;
        wait_clk(15);
        @(negedge CLOCK_50); KEY[0] = 1'b1;
        wait_clk(50);
    end
endtask

task press_key2;
    begin
        @(negedge CLOCK_50); KEY[2] = 1'b0;
        wait_clk(15);
        @(negedge CLOCK_50); KEY[2] = 1'b1;
        wait_clk(30);
    end
endtask

function [6:0] seg_ref;
    input [3:0] d;
    begin
        case (d)
            4'h0: seg_ref = 7'b0111111;
            4'h1: seg_ref = 7'b0000110;
            4'h2: seg_ref = 7'b1011011;
            4'h3: seg_ref = 7'b1001111;
            4'h4: seg_ref = 7'b1100110;
            4'h5: seg_ref = 7'b1101101;
            4'h6: seg_ref = 7'b1111101;
            4'h7: seg_ref = 7'b0000111;
            4'h8: seg_ref = 7'b1111111;
            4'h9: seg_ref = 7'b1101111;
            default: seg_ref = 7'b1000000;
        endcase
    end
endfunction

task check_scan;
    input [7:0] val;
    reg [3:0] eh, et, eu;
    reg [6:0] exp_seg;
    reg [2:0] exp_dig;
    integer ok;
    begin
        eh = val / 100;
        et = (val % 100) / 10;
        eu = val % 10;
        ok = 1;

        wait_clk(1);
        exp_seg = seg_ref(eu); exp_dig = 3'b001;
        if (SEG !== exp_seg || DIG !== exp_dig) begin
            $display("[SCAN NG] val=%0d UNITS: SEG=%07b(exp %07b) DIG=%03b(exp %03b)",
                     val, SEG, exp_seg, DIG, exp_dig);
            ok = 0;
        end

        @(posedge dut.u_seg.clk_1khz);
        wait_clk(1);
        exp_seg = seg_ref(et); exp_dig = 3'b010;
        if (SEG !== exp_seg || DIG !== exp_dig) begin
            $display("[SCAN NG] val=%0d TENS:  SEG=%07b(exp %07b) DIG=%03b(exp %03b)",
                     val, SEG, exp_seg, DIG, exp_dig);
            ok = 0;
        end

        @(posedge dut.u_seg.clk_1khz);
        wait_clk(1);
        exp_seg = seg_ref(eh); exp_dig = 3'b100;
        if (SEG !== exp_seg || DIG !== exp_dig) begin
            $display("[SCAN NG] val=%0d HUND:  SEG=%07b(exp %07b) DIG=%03b(exp %03b)",
                     val, SEG, exp_seg, DIG, exp_dig);
            ok = 0;
        end

        if (ok)
            $display("[SCAN OK] val=%0d  all 3 digits correct", val);
    end
endtask

initial begin
    $display("=== TB: fpga_top (2381BS multiplexed scan) ===");
    CLOCK_50 = 0; prev_tcnt = 8'hFF;
    KEY = 4'b1111; SW = 12'd0;

    KEY[1] = 1'b0; wait_clk(6);
    KEY[1] = 1'b1; wait_clk(5);
    $display("Reset done at t=%0t", $time);

    $display("\n--- Test 1: Load 10, dem len ---");
    SW = {2'b00, 1'b1, 1'b0, 8'd10};
    wait_clk(5);
    press_key0;
    SW = {2'b00, 1'b1, 1'b1, 8'd10};
    wait_clk(80);
    $display("Test 1 TCNT=%0d (exp >10)", dut.tcnt_value);
    if (dut.tcnt_value > 8'd10)
        $display("PASS: counter counting up");
    else
        $display("FAIL: counter not moving");

    $display("\n--- Test 2: Load 3, dem xuong -> underflow ---");
    SW = {2'b00, 1'b0, 1'b0, 8'd3};
    wait_clk(5);
    press_key0;
    SW = {2'b00, 1'b0, 1'b1, 8'd3};
    wait_clk(60);
    wait_clk2hz(2);
    $display("Test 2 LEDR[1](UNF)=%b", LEDR[1]);
    if (LEDR[1] === 1'b1)
        $display("PASS: Underflow LED on");
    else
        $display("FAIL: Underflow LED not on");

    $display("\n--- Test 3: Load 253, dem len -> overflow ---");
    SW = {2'b00, 1'b1, 1'b0, 8'd253};
    wait_clk(5);
    press_key0;
    SW = {2'b00, 1'b1, 1'b1, 8'd253};
    wait_clk(60);
    wait_clk2hz(2);
    $display("Test 3 LEDR[0](OVF)=%b", LEDR[0]);
    if (LEDR[0] === 1'b1)
        $display("PASS: Overflow LED on");
    else
        $display("FAIL: Overflow LED not on");

    $display("\n--- Test 4: Clear ---");
    press_key2;
    if (LEDR[0] === 1'b0 && LEDR[1] === 1'b0)
        $display("PASS: Both LEDs cleared");
    else
        $display("FAIL: LED(s) not cleared");

    $display("\n--- Test 5: Scan check val=123 ---");
    SW = {2'b00, 1'b1, 1'b0, 8'd123};
    wait_clk(5);
    press_key0;
    wait_clk(10);
    check_scan(8'd123);

    $display("\n--- Test 6: Scan check val=205 ---");
    SW = {2'b00, 1'b1, 1'b0, 8'd205};
    wait_clk(5);
    press_key0;
    wait_clk(10);
    check_scan(8'd205);

    $display("\n--- Test 7: Scan check val=0 ---");
    SW = {2'b00, 1'b1, 1'b0, 8'd0};
    wait_clk(5);
    press_key0;
    wait_clk(10);
    check_scan(8'd0);

    $display("\n--- Test 8: Heartbeat ---");
    wait_clk(3);
    if (LEDR[9] === dut.clk_2hz)
        $display("PASS: LEDR[9]=%b = clk_2hz", LEDR[9]);
    else
        $display("FAIL: LEDR[9]=%b != clk_2hz=%b", LEDR[9], dut.clk_2hz);

    $display("\n>>> fpga_top TB done <<<");
    $finish;
end

initial begin #500000; $display("TIMEOUT"); $finish; end

endmodule


module clock_divider_fast (
    input  wire clk,
    input  wire rst_n,
    output reg  clk_1khz,
    output reg  clk_1hz,
    output reg  clk_2hz
);
reg [5:0] c0, c1, c2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin c0 <= 6'd0; clk_1khz <= 1'b0; end
    else if (c0 == 6'd4) begin c0 <= 6'd0; clk_1khz <= ~clk_1khz; end
    else c0 <= c0 + 1'b1;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin c1 <= 6'd0; clk_2hz <= 1'b0; end
    else if (c1 == 6'd19) begin c1 <= 6'd0; clk_2hz <= ~clk_2hz; end
    else c1 <= c1 + 1'b1;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin c2 <= 6'd0; clk_1hz <= 1'b0; end
    else if (c2 == 6'd39) begin c2 <= 6'd0; clk_1hz <= ~clk_1hz; end
    else c2 <= c2 + 1'b1;
end
endmodule


module led_indicator_sim (
    input  wire clk,
    input  wire rst_n,
    input  wire clk_2hz,
    input  wire overflow,
    input  wire underflow,
    input  wire btn_clear,
    output wire led_overflow,
    output wire led_underflow,
    output wire led_heartbeat
);
reg bs1, bs2, bprev, bclean;
reg [4:0] dbc;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin bs1<=1'b1;bs2<=1'b1;bprev<=1'b1;bclean<=1'b1;dbc<=5'd0; end
    else begin
        bs1<=btn_clear; bs2<=bs1;
        if (bs2!=bprev) begin dbc<=5'd0; bprev<=bs2; end
        else if (dbc==5'd9) bclean<=bprev;
        else dbc<=dbc+1'b1;
    end
end
reg bd1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) bd1<=1'b1; else bd1<=bclean;
end
wire clr = (~bd1) & bclean;

localparam BT = 3'd6;
reg of, uf;
reg [2:0] oc, uc;
reg ob, ub;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin of<=0;oc<=0;ob<=0; end
    else if (overflow)  begin of<=1;oc<=BT;ob<=1; end
    else if (clr)       begin of<=0;oc<=0;ob<=0; end
    else if (clk_2hz && oc!=0) begin
        oc<=oc-1'b1;
        if (oc==3'd1) ob<=0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin uf<=0;uc<=0;ub<=0; end
    else if (underflow) begin uf<=1;uc<=BT;ub<=1; end
    else if (clr)       begin uf<=0;uc<=0;ub<=0; end
    else if (clk_2hz && uc!=0) begin
        uc<=uc-1'b1;
        if (uc==3'd1) ub<=0;
    end
end

assign led_overflow  = ob ? (of & clk_2hz) : of;
assign led_underflow = ub ? (uf & clk_2hz) : uf;
assign led_heartbeat = clk_2hz;
endmodule


module fpga_top_sim (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [11:0] SW,
    output wire [6:0]  SEG,
    output wire [2:0]  DIG,
    output wire [9:0]  LEDR,
    input  wire [3:0]  GPIO_CLK_IN
);

wire rst_n = KEY[1];

wire clk_1khz, clk_1hz, clk_2hz;
clock_divider_fast u_clkdiv (
    .clk(CLOCK_50), .rst_n(rst_n),
    .clk_1khz(clk_1khz), .clk_1hz(clk_1hz), .clk_2hz(clk_2hz)
);

reg [6:0] cnt0, cnt1, cnt2, cnt3;
reg       clk_t0, clk_t1, clk_t2, clk_t3;
always @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n) begin cnt0<=7'd0;clk_t0<=1'b0; end
    else if (cnt0==7'd4)  begin cnt0<=7'd0;clk_t0<=~clk_t0; end
    else cnt0<=cnt0+1'b1;
end
always @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n) begin cnt1<=7'd0;clk_t1<=1'b0; end
    else if (cnt1==7'd9)  begin cnt1<=7'd0;clk_t1<=~clk_t1; end
    else cnt1<=cnt1+1'b1;
end
always @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n) begin cnt2<=7'd0;clk_t2<=1'b0; end
    else if (cnt2==7'd19) begin cnt2<=7'd0;clk_t2<=~clk_t2; end
    else cnt2<=cnt2+1'b1;
end
always @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n) begin cnt3<=7'd0;clk_t3<=1'b0; end
    else if (cnt3==7'd39) begin cnt3<=7'd0;clk_t3<=~clk_t3; end
    else cnt3<=cnt3+1'b1;
end
wire [3:0] clk_in = {clk_t3, clk_t2, clk_t1, clk_t0};

wire       psel, penable, pwrite;
wire [7:0] paddr, pwdata, prdata;
wire       pready, pslverr;
apb_sw_master #(.DB_MAX(20'd9)) u_master (
    .clk(CLOCK_50),.rst_n(rst_n),.sw(SW),.key(KEY),
    .psel(psel),.penable(penable),.pwrite(pwrite),
    .paddr(paddr),.pwdata(pwdata),.prdata(prdata),
    .pready(pready),.pslverr(pslverr)
);

wire [7:0] tcnt_value;
wire       overflow, underflow;
timer_8bit_top u_timer (
    .clk(CLOCK_50),.rst_n(rst_n),.clk_in(clk_in),
    .penable(penable),.psel(psel),.pwrite(pwrite),
    .paddr(paddr),.pwdata(pwdata),.prdata(prdata),
    .pready(pready),.pslverr(pslverr),
    .tcnt_out(tcnt_value),.overflow(overflow),.underflow(underflow)
);

wire [6:0] seg_wire;
wire [2:0] dig_wire;
seg7_display u_seg (
    .clk(CLOCK_50),.rst_n(rst_n),.clk_1khz(clk_1khz),
    .value(tcnt_value),.seg(seg_wire),.dig(dig_wire)
);
assign SEG = ~seg_wire;
assign DIG = ~dig_wire;

led_indicator_sim u_led (
    .clk(CLOCK_50),.rst_n(rst_n),.clk_2hz(clk_2hz),
    .overflow(overflow),.underflow(underflow),.btn_clear(KEY[2]),
    .led_overflow(LEDR[0]),.led_underflow(LEDR[1]),.led_heartbeat(LEDR[9])
);
assign LEDR[8:2] = 7'b0;

endmodule
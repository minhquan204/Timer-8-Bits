`timescale 1ns/1ps

module fpga_top (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [11:0] SW,
    output wire [6:0]  SEG,
    output wire [2:0]  DIG,
    output wire [9:0]  LEDR
   // input  wire [3:0]  GPIO_CLK_IN
);

wire rst_n = KEY[1];

wire clk_1khz, clk_1hz, clk_2hz;

clock_divider u_clkdiv (
    .clk      (CLOCK_50),
    .rst_n    (rst_n),
    .clk_1khz (clk_1khz),
    .clk_1hz  (clk_1hz),
    .clk_2hz  (clk_2hz)
);

reg [24:0] cnt0, cnt1, cnt2, cnt3;
reg        clk_t0, clk_t1, clk_t2, clk_t3;

always @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n) begin cnt0 <= 25'd0; clk_t0 <= 1'b0; end
    else if (cnt0 == 25'd6249999) begin cnt0 <= 25'd0; clk_t0 <= ~clk_t0; end
    else cnt0 <= cnt0 + 1'b1;
end

always @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n) begin cnt1 <= 25'd0; clk_t1 <= 1'b0; end
    else if (cnt1 == 25'd12499999) begin cnt1 <= 25'd0; clk_t1 <= ~clk_t1; end
    else cnt1 <= cnt1 + 1'b1;
end

always @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n) begin cnt2 <= 25'd0; clk_t2 <= 1'b0; end
    else if (cnt2 == 25'd24999999) begin cnt2 <= 25'd0; clk_t2 <= ~clk_t2; end
    else cnt2 <= cnt2 + 1'b1;
end

always @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n) begin cnt3 <= 25'd0; clk_t3 <= 1'b0; end
    else if (cnt3 == 25'd49999999) begin cnt3 <= 25'd0; clk_t3 <= ~clk_t3; end
    else cnt3 <= cnt3 + 1'b1;
end

wire [3:0] clk_in = {clk_t3, clk_t2, clk_t1, clk_t0};

wire       psel, penable, pwrite;
wire [7:0] paddr, pwdata, prdata;
wire       pready, pslverr;

apb_sw_master u_master (
    .clk     (CLOCK_50),
    .rst_n   (rst_n),
    .sw      (SW),
    .key     (KEY),
    .psel    (psel),
    .penable (penable),
    .pwrite  (pwrite),
    .paddr   (paddr),
    .pwdata  (pwdata),
    .prdata  (prdata),
    .pready  (pready),
    .pslverr (pslverr)
);

wire [7:0] tcnt_value;
wire       overflow, underflow;

timer_8bit_top u_timer (
    .clk       (CLOCK_50),
    .rst_n     (rst_n),
    .clk_in    (clk_in),
    .penable   (penable),
    .psel      (psel),
    .pwrite    (pwrite),
    .paddr     (paddr),
    .pwdata    (pwdata),
    .prdata    (prdata),
    .pready    (pready),
    .pslverr   (pslverr),
    .tcnt_out  (tcnt_value),
    .overflow  (overflow),
    .underflow (underflow)
);

wire [6:0] seg_wire;
wire [2:0] dig_wire;

seg7_display u_seg (
    .clk      (CLOCK_50),
    .rst_n    (rst_n),
    .clk_1khz (clk_1khz),
    .value    (tcnt_value),
    .seg      (seg_wire),
    .dig      (dig_wire)
);

assign SEG = seg_wire;
assign DIG = ~dig_wire;

led_indicator u_led (
    .clk           (CLOCK_50),
    .rst_n         (rst_n),
    .clk_2hz       (clk_2hz),
    .overflow      (overflow),
    .underflow     (underflow),
    .btn_clear     (KEY[2]),
    .led_overflow  (LEDR[0]),
    .led_underflow (LEDR[1]),
    .led_heartbeat (LEDR[9])
);

assign LEDR[8:2] = 7'b0;

endmodule

module timer_8bit_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  clk_in,
    input  wire        penable,
    input  wire        psel,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [7:0]  pwdata,
    output wire [7:0]  prdata,
    output wire        pready,
    output wire        pslverr,
    output wire [7:0]  tcnt_out,
    output wire        overflow,
    output wire        underflow
);

wire [7:0] start_counter;
wire       load, up_down, enable;
wire [1:0] clk_sel;
wire       clk_ena;

apb_controller u_apb (
    .clk          (clk),
    .rst_n        (rst_n),
    .penable      (penable),
    .psel         (psel),
    .pwrite       (pwrite),
    .paddr        (paddr),
    .pwdata       (pwdata),
    .prdata       (prdata),
    .pready       (pready),
    .pslverr      (pslverr),
    .start_counter(start_counter),
    .load         (load),
    .up_down      (up_down),
    .enable       (enable),
    .clk_sel      (clk_sel),
    .overflow     (overflow),
    .underflow    (underflow)
);

counter_exp u_cnt (
    .clk           (clk),
    .rst_n         (rst_n),
    .clk_ena       (clk_ena),
    .start_counter (start_counter),
    .load          (load),
    .up_down       (up_down),
    .enable        (enable),
    .overflow      (overflow),
    .underflow     (underflow),
    .tcnt_out      (tcnt_out)
);

clock_selection u_clksel (
    .clk     (clk),
    .rst_n   (rst_n),
    .clk_in  (clk_in),
    .clk_sel (clk_sel),
    .clk_ena (clk_ena)
);

endmodule

module counter_exp (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        clk_ena,
    input  wire [7:0]  start_counter,
    input  wire        up_down,
    input  wire        load,
    input  wire        enable,
    output reg         overflow,
    output reg         underflow,
    output wire [7:0]  tcnt_out
);

reg [7:0] reg_TCNT;
reg [7:0] reg_TCNT_d1;

assign tcnt_out = reg_TCNT;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_TCNT    <= 8'd0;
        reg_TCNT_d1 <= 8'd0;
        overflow    <= 1'b0;
        underflow   <= 1'b0;
    end else begin
        if (load)
            reg_TCNT <= start_counter;
        else if (enable & clk_ena) begin
            if (up_down)
                reg_TCNT <= reg_TCNT + 1'b1;
            else
                reg_TCNT <= reg_TCNT - 1'b1;
        end
        reg_TCNT_d1 <= reg_TCNT;
        overflow    <= (reg_TCNT == 8'd0)   & (reg_TCNT_d1 == 8'd255);
        underflow   <= (reg_TCNT == 8'd255) & (reg_TCNT_d1 == 8'd0);
    end
end

endmodule
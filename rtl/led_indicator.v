`timescale 1ns/1ps

module led_indicator (
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

reg btn_s1, btn_s2, btn_prev, btn_clean;
reg [19:0] db_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        btn_s1  <= 1'b1; btn_s2   <= 1'b1;
        btn_prev <= 1'b1; btn_clean <= 1'b1;
        db_cnt  <= 20'd0;
    end else begin
        btn_s1 <= btn_clear;
        btn_s2 <= btn_s1;
        if (btn_s2 != btn_prev) begin
            db_cnt   <= 20'd0;
            btn_prev <= btn_s2;
        end else if (db_cnt == 20'd999999) begin
            btn_clean <= btn_prev;
        end else begin
            db_cnt <= db_cnt + 1'b1;
        end
    end
end

reg btn_clean_d1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) btn_clean_d1 <= 1'b1;
    else        btn_clean_d1 <= btn_clean;
end
wire clear_pulse = (~btn_clean_d1) & btn_clean;

localparam BLINK_TICKS = 3'd6;

reg ovf_flag;
reg [2:0] ovf_blink_cnt;
reg ovf_blinking;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ovf_flag      <= 1'b0;
        ovf_blink_cnt <= 3'd0;
        ovf_blinking  <= 1'b0;
    end else if (overflow) begin
        ovf_flag      <= 1'b1;
        ovf_blink_cnt <= BLINK_TICKS;
        ovf_blinking  <= 1'b1;
    end else if (clear_pulse) begin
        ovf_flag      <= 1'b0;
        ovf_blink_cnt <= 3'd0;
        ovf_blinking  <= 1'b0;
    end else if (clk_2hz && ovf_blink_cnt != 3'd0) begin
        ovf_blink_cnt <= ovf_blink_cnt - 1'b1;
        if (ovf_blink_cnt == 3'd1)
            ovf_blinking <= 1'b0;
    end
end

reg unf_flag;
reg [2:0] unf_blink_cnt;
reg unf_blinking;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        unf_flag      <= 1'b0;
        unf_blink_cnt <= 3'd0;
        unf_blinking  <= 1'b0;
    end else if (underflow) begin
        unf_flag      <= 1'b1;
        unf_blink_cnt <= BLINK_TICKS;
        unf_blinking  <= 1'b1;
    end else if (clear_pulse) begin
        unf_flag      <= 1'b0;
        unf_blink_cnt <= 3'd0;
        unf_blinking  <= 1'b0;
    end else if (clk_2hz && unf_blink_cnt != 3'd0) begin
        unf_blink_cnt <= unf_blink_cnt - 1'b1;
        if (unf_blink_cnt == 3'd1)
            unf_blinking <= 1'b0;
    end
end

assign led_overflow  = ovf_blinking ? (ovf_flag & clk_2hz) : ovf_flag;
assign led_underflow = unf_blinking ? (unf_flag & clk_2hz) : unf_flag;
assign led_heartbeat = clk_2hz;

endmodule
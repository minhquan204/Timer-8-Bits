`timescale 1ns/1ps

module clock_divider (
    input  wire clk,
    input  wire rst_n,
    output reg  clk_1khz,
    output reg  clk_1hz,
    output reg  clk_2hz
);

localparam integer CNT_1KHZ_MAX = 24999;
localparam integer CNT_2HZ_MAX  = 12499999;
localparam integer CNT_1HZ_MAX  = 24999999;

reg [14:0] cnt_1khz;
reg [23:0] cnt_2hz;
reg [24:0] cnt_1hz;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_1khz <= 15'd0;
        clk_1khz <= 1'b0;
    end else begin
        if (cnt_1khz == CNT_1KHZ_MAX) begin
            cnt_1khz <= 15'd0;
            clk_1khz <= ~clk_1khz;
        end else begin
            cnt_1khz <= cnt_1khz + 1'b1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_2hz <= 24'd0;
        clk_2hz <= 1'b0;
    end else begin
        if (cnt_2hz == CNT_2HZ_MAX) begin
            cnt_2hz <= 24'd0;
            clk_2hz <= ~clk_2hz;
        end else begin
            cnt_2hz <= cnt_2hz + 1'b1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_1hz <= 25'd0;
        clk_1hz <= 1'b0;
    end else begin
        if (cnt_1hz == CNT_1HZ_MAX) begin
            cnt_1hz <= 25'd0;
            clk_1hz <= ~clk_1hz;
        end else begin
            cnt_1hz <= cnt_1hz + 1'b1;
        end
    end
end

endmodule
`timescale 1ns/1ps
module seg7_display (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       clk_1khz,
    input  wire [7:0] value,
    output reg  [6:0] seg,
    output reg  [2:0] dig
);

wire [3:0] hundreds, tens, units;

bin2bcd u_bcd (
    .bin      (value),
    .hundreds (hundreds),
    .tens     (tens),
    .units    (units)
);

reg [1:0] scan;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        scan <= 2'd0;
    else if (clk_1khz)
        scan <= (scan == 2'd2) ? 2'd0 : scan + 1'b1;
end

reg [3:0] cur_digit;

always @(*) begin
    case (scan)
        2'd0: begin cur_digit = units;    dig = 3'b110; end
        2'd1: begin cur_digit = tens;     dig = 3'b101; end
        2'd2: begin cur_digit = hundreds; dig = 3'b011; end
        default: begin cur_digit = 4'd0;  dig = 3'b111; end
    endcase
end

always @(*) begin
    case (cur_digit)
        4'd0: seg = 7'b0111111;
        4'd1: seg = 7'b0000110;
        4'd2: seg = 7'b1011011;
        4'd3: seg = 7'b1001111;
        4'd4: seg = 7'b1100110;
        4'd5: seg = 7'b1101101;
        4'd6: seg = 7'b1111101;
        4'd7: seg = 7'b0000111;
        4'd8: seg = 7'b1111111;
        4'd9: seg = 7'b1101111;
        default: seg = 7'b1000000;
    endcase
end

endmodule
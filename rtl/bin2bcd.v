`timescale 1ns/1ps
module bin2bcd (
    input  wire [7:0] bin,
    output wire [3:0] hundreds,
    output wire [3:0] tens,
    output wire [3:0] units
);

function [15:0] add3;
    input [15:0] in;
    begin
        add3[15:12] = in[15:12];
        add3[11:8]  = (in[11:8] >= 4'd5) ? in[11:8] + 4'd3 : in[11:8];
        add3[7:4]   = (in[7:4]  >= 4'd5) ? in[7:4]  + 4'd3 : in[7:4];
        add3[3:0]   = (in[3:0]  >= 4'd5) ? in[3:0]  + 4'd3 : in[3:0];
    end
endfunction

wire [15:0] p0 = {15'b0, bin[7]};
wire [15:0] a0 = add3(p0);
wire [15:0] p1 = {a0[14:0], bin[6]};
wire [15:0] a1 = add3(p1);
wire [15:0] p2 = {a1[14:0], bin[5]};
wire [15:0] a2 = add3(p2);
wire [15:0] p3 = {a2[14:0], bin[4]};
wire [15:0] a3 = add3(p3);
wire [15:0] p4 = {a3[14:0], bin[3]};
wire [15:0] a4 = add3(p4);
wire [15:0] p5 = {a4[14:0], bin[2]};
wire [15:0] a5 = add3(p5);
wire [15:0] p6 = {a5[14:0], bin[1]};
wire [15:0] a6 = add3(p6);
wire [15:0] p7 = {a6[14:0], bin[0]};

assign hundreds = p7[11:8];
assign tens     = p7[7:4];
assign units    = p7[3:0];

endmodule
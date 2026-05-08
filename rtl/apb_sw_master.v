`timescale 1ns/1ps

module apb_sw_master #(
    parameter DB_MAX = 20'd999999

) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [11:0] sw,
    input  wire [3:0]  key,

    output reg         psel,
    output reg         penable,
    output reg         pwrite,
    output reg  [7:0]  paddr,
    output reg  [7:0]  pwdata,
    input  wire [7:0]  prdata,
    input  wire        pready,
    input  wire        pslverr
);

reg key0_s1, key0_s2, key0_prev, key0_clean;
reg [19:0] db_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key0_s1   <= 1'b1;
        key0_s2   <= 1'b1;
        key0_prev <= 1'b1;
        key0_clean <= 1'b1;
        db_cnt    <= 20'd0;
    end else begin
        key0_s1 <= key[0];
        key0_s2 <= key0_s1;
        if (key0_s2 != key0_prev) begin
            db_cnt    <= 20'd0;
            key0_prev <= key0_s2;
        end else if (db_cnt == DB_MAX) begin
            key0_clean <= key0_prev;
        end else begin
            db_cnt <= db_cnt + 1'b1;
        end
    end
end

reg key0_d1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) key0_d1 <= 1'b1;
    else        key0_d1 <= key0_clean;
end
wire load_pulse = key0_d1 & (~key0_clean);

reg [11:0] sw_prev;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) sw_prev <= 12'hFFF;
    else        sw_prev <= sw;
end
wire sw_changed = (sw != sw_prev);

localparam ST_IDLE   = 2'd0;
localparam ST_SETUP  = 2'd1;
localparam ST_ACCESS = 2'd2;

reg [1:0] state;
reg       do_tdr, do_tcr;
reg [7:0] tdr_latch, tcr_latch;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        do_tdr    <= 1'b0;
        do_tcr    <= 1'b0;
        tdr_latch <= 8'd0;
        tcr_latch <= 8'd0;
    end else begin

        if (load_pulse) begin
            tdr_latch <= sw[7:0];
            tcr_latch <= {1'b1, 1'b0, sw[9], sw[8], 2'b00, sw[11:10]};
            do_tdr    <= 1'b1;
            do_tcr    <= 1'b1;
        end else begin

            if (sw_changed && !do_tdr && !do_tcr && (state == ST_IDLE)) begin
                tcr_latch <= {1'b0, 1'b0, sw[9], sw[8], 2'b00, sw[11:10]};
                do_tcr    <= 1'b1;
            end

            if (state == ST_ACCESS && pready) begin
                if (paddr == 8'd0) do_tdr <= 1'b0;
                if (paddr == 8'd1) do_tcr <= 1'b0;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state   <= ST_IDLE;
        psel    <= 1'b0;
        penable <= 1'b0;
        pwrite  <= 1'b0;
        paddr   <= 8'd0;
        pwdata  <= 8'd0;
    end else begin
        case (state)
        ST_IDLE: begin
            psel    <= 1'b0;
            penable <= 1'b0;

            if (do_tdr) begin
                psel   <= 1'b1;
                penable <= 1'b0;
                pwrite <= 1'b1;
                paddr  <= 8'd0;
                pwdata <= tdr_latch;
                state  <= ST_SETUP;
            end else if (do_tcr) begin
                psel   <= 1'b1;
                penable <= 1'b0;
                pwrite <= 1'b1;
                paddr  <= 8'd1;
                pwdata <= tcr_latch;
                state  <= ST_SETUP;
            end
        end

        ST_SETUP: begin
            penable <= 1'b1;
            state   <= ST_ACCESS;
        end

        ST_ACCESS: begin
            if (pready) begin
                psel    <= 1'b0;
                penable <= 1'b0;
                state   <= ST_IDLE;
            end
        end

        default: state <= ST_IDLE;
        endcase
    end
end

endmodule
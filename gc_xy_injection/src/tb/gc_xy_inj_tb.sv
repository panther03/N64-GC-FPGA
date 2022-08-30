`timescale 1ns/1ns
module gc_xy_inj_tb ();

import tb_tasks::*;

    reg clk, rst_n;

    wire JB_cons, JB_ctlr;
    reg JB_cons_r, JB_ctlr_r;

    assign JB_cons = JB_cons_r;
    assign JB_ctlr = JB_ctlr_r;

task automatic send_resp(ref JB, input [23:0] resp);
    begin
    $display("Sending %h", resp);
    for (int i = 23; i >= 0; i--)
        if (resp[i]) begin
            bit1(JB);
        end else begin
            bit0(JB);
        end
    bit_stop(JB);
    end
endtask

    gc_xy_inj_top iDUT (.clk(clk), .rst_n(rst_n), .JB_cons(JB_cons), .JB_ctlr(JB_ctlr));

    integer cnt;
    logic [31:0] resp;

    initial begin
        rst_n = 1;
        clk = 0;
        JB_cons_r = 0;
        JB_ctlr_r = 1'bz;
        
        cnt = 0;

        @(posedge clk);
        rst_n = 0;

        @(negedge clk);
        rst_n = 1;

        send_resp(JB_cons_r, 24'h400301);
        @(posedge iDUT.console_cmd_done)

        $display("YAHOO! Test passed..");
        $finish();
    end

    always #20 clk = ~clk;
endmodule
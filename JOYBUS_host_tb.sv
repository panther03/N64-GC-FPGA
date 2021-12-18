`timescale 1ns/1ns
module JOYBUS_host_tb ();

import tb_tasks::*;

    reg clk, rst_n;

    wire JB;

    wire btn_A, btn_B, btn_Z;

    reg cntlr_test_write;
    reg JB_RX;

task automatic send_dummy_resp(ref RX);
    begin
    // status byte
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit1(RX);
    bit0(RX);
    bit1(RX);
    // some made up data
    bit0(RX);
    bit1(RX);
    bit1(RX);
    bit1(RX);
    bit0(RX);
    bit0(RX);
    bit1(RX);
    bit1(RX);
    // second byte
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit1(RX);
    // third byte
    bit0(RX);
    bit0(RX);
    bit1(RX);
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit0(RX);
    bit0(RX);
    // fourth byte
    bit0(RX);
    bit0(RX);
    bit1(RX);
    bit0(RX);
    bit0(RX);
    bit1(RX);
    bit0(RX);
    bit1(RX);
    bit_stop(RX);
    end
endtask

    JOYBUS_host iDUT (.*);

    initial begin
        rst_n = 1;
        clk = 0;
        cntlr_test_write = 0;
        JB_RX = 0;

        @(posedge clk);
        rst_n = 0;

        @(negedge clk);
        rst_n = 1;

        @(posedge clk);            

        wait4sig(clk, iDUT.tx_done, 2000000);

        fork
            begin: send_data
                $display("TRANSFERRING CONTROL.. time=%t", $time());
                cntlr_test_write = 1;
                send_dummy_resp(JB_RX);
                cntlr_test_write = 0;
                repeat(1000) @(posedge clk);
                $display("Error timeout for waiting for rx_done");
                $stop();
            end
            begin: wait_data
                @(posedge iDUT.rx_done);
                disable send_data;
            end
        join

        repeat (2) @(posedge clk);
        $display("Controller values received:");
        $display("A: %b B: %b Z: %b", btn_A, btn_B, btn_Z);

        $display("YAHOO! Test passed..");
        $finish();
    end

    assign JB = cntlr_test_write ? JB_RX : 1'hZ;

    always #20 clk = ~clk;
endmodule
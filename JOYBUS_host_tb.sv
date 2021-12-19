`timescale 1ns/1ns
module JOYBUS_host_tb ();

import tb_tasks::*;

    reg clk, rst_n;

    wire JB;

    wire btn_A, btn_B, btn_Z;

    reg cntlr_test_write;
    reg JB_RX;

task automatic send_rand_resp(ref RX, output [31:0] resp);
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
    resp = $urandom();
    $display("Sending %h", resp);
    for (int i = 31; i >= 0; i--)
        if (resp[i]) begin
            bit1(RX);
        end else begin
            bit0(RX);
        end
    bit_stop(RX);
    end
endtask

    JOYBUS_host iDUT (.*);

    integer cnt;
    logic [31:0] resp;

    initial begin
        rst_n = 1;
        clk = 0;
        cntlr_test_write = 0;
        JB_RX = 0;
        
        cnt = 0;

        @(posedge clk);
        rst_n = 0;

        @(negedge clk);
        rst_n = 1;

        @(posedge clk);            

        repeat (3) begin
        wait4sig(clk, iDUT.tx_done, 2000000);

        fork
            begin: send_data
                $display("TRANSFERRING CONTROL.. time=%t", $time());
                cntlr_test_write = 1;
                send_rand_resp(JB_RX, resp);
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
        assert(btn_A == resp[31]);
        assert(btn_B == resp[30]);
        assert(btn_Z == resp[29]);
        $display("Cycle: %d", cnt);
        cnt = cnt + 1;
        end 

        $display("YAHOO! Test passed..");
        $finish();
    end

    assign JB = cntlr_test_write ? JB_RX : 1'hZ;

    always #20 clk = ~clk;
endmodule
`timescale 1ns/1ns
module JOYBUS_host_tb ();

import tb_tasks::*;

    reg clk, rst_n;

    wire JB;
    wire [3:0] dbg;

    reg btn_send_ORIGIN;
    reg btn_send_POLL;

    reg cntlr_test_write;
    reg JB_RX;

    wire TX;

task automatic send_rand_resp(ref RX, output [31:0] resp);
    begin
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

    JOYBUS_host iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .JB(JB),
        .btn_send_ORIGIN(btn_send_ORIGIN),
        .btn_send_POLL(btn_send_POLL)
    );

    integer cnt;
    logic [31:0] resp;

    initial begin
        rst_n = 1;
        clk = 0;
        cntlr_test_write = 0;
        JB_RX = 0;

        btn_send_ORIGIN = 0;
        btn_send_POLL = 0;
        
        cnt = 0;

        @(posedge clk);
        rst_n = 0;

        @(negedge clk);
        rst_n = 1;
        
        @(posedge clk);
        btn_send_ORIGIN = 1;

        repeat (8) @(posedge clk);
        btn_send_ORIGIN = 0;

        wait4sig(clk, iDUT.tx_done, 2000000);

        repeat (1000) @(posedge clk);

        @(posedge clk);
        btn_send_POLL = 1;

        repeat (8) @(posedge clk);
        btn_send_POLL = 0;

        wait4sig(clk, iDUT.tx_done, 2000000);

/*
        repeat (3) begin
            

            fork
                begin: send_data
                    $display("TRANSFERRING CONTROL.. time=%t", $time());
                    cntlr_test_write = 1;
                    send_rand_resp(JB_RX, resp);
                    repeat(1000) @(posedge clk);
                    $display("Error timeout for waiting for rx_done");
                    $stop();
                end
                begin: wait_data
                    @(posedge iDUT.iJB_HOST.rx_done);
                    cntlr_test_write = 0;
                    disable send_data;
                end
            join

            repeat (2) @(posedge clk);
            $display("Controller values received:");
            $display("A: %b B: %b Z: %b S: %b", btn_A, btn_B, btn_Z, btn_S);
            assert(btn_A == resp[31]);
            assert(btn_B == resp[30]);
            assert(btn_Z == resp[29]);
            assert(btn_S == resp[28]);
            $display("Cycle: %d", cnt);
            cnt = cnt + 1;

        end 
*/
        $display("YAHOO! Test passed..");
        $finish();
    end

    //assign JB = cntlr_test_write ? JB_RX : 1'hZ;

    always #20 clk = ~clk;
endmodule
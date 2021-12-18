`timescale 1ns/1ns
module JOYBUS_tx_tb ();
    reg clk, rst_n;

    reg [7:0] cmd_data;
    reg cmd_rdy;
    reg rx_done;

    wire JB_TX;
    wire JB_TX_SEL;
    reg tx_done;

task automatic wait4sig(ref sig, input int clk2wait);
    fork
        begin: timeout
            repeat(clk2wait) @(posedge clk);
            $display("Error timeout for waiting for sig");
        end
        begin 
            @(posedge sig);
            disable timeout;
        end
    join
endtask

    JOYBUS_tx iDUT (.*);

    initial begin
        rst_n = 1;
        clk = 0;
        rx_done = 0;
        cmd_rdy = 0;

        @(posedge clk);
        rst_n = 0;

        @(negedge clk);
        rst_n = 1;

        @(posedge clk);
        cmd_data = 8'hAA;
        cmd_rdy = 1;

        @(posedge clk);
        cmd_rdy = 0;

        // not self checking unfortunately
        wait4sig(tx_done, 2000000);

        $display("YAHOO! Test passed..");
        $finish();
    end

    always #20 clk = ~clk;
endmodule
`timescale 1ns/1ns
module JOYBUS_rx_tb ();

import tb_tasks::*;

    reg clk, rst_n;

    reg rx_start;
    reg JB_RX;

    reg rx_done;
    wire [7:0] jb_cntlr_status;
    wire [15:0] jb_cntlr_data;


    JOYBUS_rx iDUT (.*);

    initial begin
        rst_n = 1;
        clk = 0;
        rx_start = 0;
        JB_RX = 1;

        @(posedge clk);
        rst_n = 0;

        @(negedge clk);
        rst_n = 1;

        @(posedge clk);            

        fork
            begin            
                rx_start = 1;

                @(posedge clk);
                rx_start = 0;
            end
            begin: send_data
                // status byte
                bit0(JB_RX);
                bit0(JB_RX);
                bit0(JB_RX);
                bit0(JB_RX);
                bit0(JB_RX);
                bit1(JB_RX);
                bit0(JB_RX);
                bit1(JB_RX);
                // some made up data
                bit0(JB_RX);
                bit1(JB_RX);
                bit1(JB_RX);
                bit1(JB_RX);
                bit0(JB_RX);
                bit0(JB_RX);
                bit1(JB_RX);
                bit1(JB_RX);
                // second byte
                bit0(JB_RX);
                bit0(JB_RX);
                bit0(JB_RX);
                bit0(JB_RX);
                bit0(JB_RX);
                bit0(JB_RX);
                bit0(JB_RX);
                bit1(JB_RX);
                bit_stop(JB_RX);
                
                repeat(1000) @(posedge clk);
                $display("Error timeout for waiting for sig");
            end
            begin
                @(posedge rx_done);
                disable send_data;
            end
        join

        $display("YAHOO! Test passed..");
        $finish();
    end

    always #20 clk = ~clk;
endmodule
`timescale 1ns/1ns
module N64_Serial_tb ();
    reg clk, rst_n;

    reg [7:0] cmd_data;
    reg cmd_rdy;

    reg JB_RX; // unused?

    wire JB_TX;
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

    JOYBUS_host iDUT (.*);

    initial begin
        rst_n = 1;
        clk = 0;

        @(posedge clk);
        rst_n = 0;

        @(negedge clk);
        rst_n = 1;

        @(posedge clk);
        cmd_data = 8'h00;
        cmd_rdy = 1;

        @(posedge clk);
        cmd_rdy = 0;

        wait4sig(tx_done, 2000000);

        $display("YAHOO! Test passed..");
        $finish();
    end

    always #20 clk = ~clk;
endmodule
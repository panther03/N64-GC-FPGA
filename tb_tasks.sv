package tb_tasks;

    task automatic wait4sig(ref clk, ref sig, input int clk2wait);
        fork
            begin: timeout
                repeat(clk2wait) @(posedge clk);
                $display("Error timeout for waiting for sig");
                $stop();
            end
            begin 
                @(posedge sig);
                disable timeout;
            end
        join
    endtask

    task automatic bit0(ref RX);
        begin
            RX = 0;
            #3000; 
            RX = 1;
            #1000;
        end
    endtask

    task automatic bit1(ref RX);
        begin
            RX = 0;
            #1000; 
            RX = 1;
            #3000;
        end
    endtask

    task automatic bit_stop (ref RX);
        begin
            RX = 0;
            #2000;
            RX = 1;
        end
    endtask

endpackage
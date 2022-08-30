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
            #6000; 
            RX = 1;
            #2000;
        end
    endtask

    task automatic bit1(ref RX);
        begin
            RX = 0;
            #2000; 
            RX = 1;
            #6000;
        end
    endtask

    task automatic bit_stop (ref RX);
        begin
            RX = 0;
            #4000;
            RX = 1;
        end
    endtask

endpackage
module seven_seg_main (
    input clk, rst_n,
    input [15:0] disp_num,
    output [3:0] dig,
    output [7:0] seg
);

localparam data_refresh_period = 500000;

logic [$clog2(data_refresh_period):0] data_wait_cnt;
wire data_wait_done = data_wait_cnt == data_refresh_period;
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        data_wait_cnt <= 0;
    else if (data_wait_done)
        data_wait_cnt <= 0;
    else
        data_wait_cnt <= data_wait_cnt + 1;

/*logic [15:0] disp_num;
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        disp_num <= 0;
    else if (data_wait_done)
        disp_num <= disp_num + 1;*/
    
seven_seg_drv iDRV(.*);

endmodule

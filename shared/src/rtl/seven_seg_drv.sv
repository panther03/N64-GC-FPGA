module seven_seg_drv (
    input clk, rst_n,
    input [15:0] disp_num,
    output reg [3:0] dig,
    output reg [7:0] seg
);

localparam digit_refresh_period = 262144;
localparam refresh_cnt_bits = $clog2(digit_refresh_period * 2);

logic [refresh_cnt_bits:0] refresh_cnt;

wire digit_refresh_done = &refresh_cnt[refresh_cnt_bits-2:0];
                        //== digit_refresh_period;
wire display_refresh_done = &refresh_cnt; //refresh_cnt == digit_refresh_period * 4;
wire [1:0] digit_sel = refresh_cnt[refresh_cnt_bits:refresh_cnt_bits-1];

always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        refresh_cnt <= 0;
    else if (display_refresh_done)
        refresh_cnt <= 0;
    else   
        refresh_cnt <= refresh_cnt + 1;

logic [15:0] disp_num_reg;
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        disp_num_reg <= 0;
    else if (display_refresh_done)
        disp_num_reg <= disp_num;
    else if (digit_refresh_done)
        disp_num_reg <= disp_num_reg << 4;

always_comb begin 
    case (disp_num_reg[15:12])
    4'h0 : seg = 8'hc0; //显示"0"
    4'h1 : seg = 8'hf9; //显示"1"
    4'h2 : seg = 8'ha4; //显示"2"
    4'h3 : seg = 8'hb0; //显示"3"
    4'h4 : seg = 8'h99; //显示"4"
    4'h5 : seg = 8'h92; //显示"5"
    4'h6 : seg = 8'h82; //显示"6"
    4'h7 : seg = 8'hf8; //显示"7"
    4'h8 : seg = 8'h80; //显示"8"
    4'h9 : seg = 8'h90; //显示"9"
    4'ha : seg = 8'h88; //显示"a"
    4'hb : seg = 8'h83; //显示"b"
    4'hc : seg = 8'hc6; //显示"c"
    4'hd : seg = 8'ha1; //显示"d"
    4'he : seg = 8'h86; //显示"e"
    4'hf : seg = 8'h8e; //显示"f"
    endcase
    case (digit_sel)
    2'b01 : dig = 4'b1011;
    2'b10 : dig = 4'b1101;
    2'b11 : dig = 4'b1110;
    default: dig = 4'b0111; // 2'b00
    endcase
end
endmodule

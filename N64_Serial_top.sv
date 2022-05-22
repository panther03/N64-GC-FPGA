module N64_Serial_top (
    input clk, rst_n,

    // JOYBUS
    inout JB,
    output btn_A,
    output btn_B,
    output btn_Z,
    output btn_S,
    output [3:0] DBG_dig,
    output [7:0] DBG_seg,
    output DBG_count_high,

    // UART
    output TX
);

wire [31:0] cntlr_data;
wire cntlr_data_rdy;

///////////////////////////
// JOYBUS INSTANTIATION //
/////////////////////////
JOYBUS_host iJB_HOST(.clk(clk), .rst_n(rst_n), .JB(JB),
    .cntlr_data_rdy(cntlr_data_rdy), .cntlr_data(cntlr_data),
    .btn_A(btn_A), .btn_B(btn_B), .btn_Z(btn_Z), .btn_S(btn_S),
    .DBG_dig(DBG_dig), .DBG_seg(DBG_seg), .DBG_count_high(DBG_count_high));

/////////////////////////
// UART INSTANTIATION //
///////////////////////
UART_host iUART_host(.clk(clk), .rst_n(rst_n), .TX(TX),
    .cntlr_data(cntlr_data),.cntlr_data_rdy(cntlr_data_rdy));

endmodule
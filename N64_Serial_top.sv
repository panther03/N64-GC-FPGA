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
    output TX,
    input RX,

    output DBG_uart,
    output rx_dbg
);

assign DBG_uart = RX; 
assign TX = rx_dbg;

wire [31:0] cntlr_data;
wire cntlr_data_rdy;

reg btn_A_r;
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        btn_A_r <= 0;
    else if (RX)
        btn_A_r <= 1; 
end

assign btn_A = btn_A_r;

///////////////////////////
// JOYBUS INSTANTIATION //
/////////////////////////
JOYBUS_host iJB_HOST(.clk(clk), .rst_n(rst_n), .JB(JB),
    .cntlr_data_rdy(cntlr_data_rdy), .cntlr_data(cntlr_data),
    .btn_A(), .btn_B(btn_B), .btn_Z(btn_Z), .btn_S(btn_S),
    .DBG_dig(DBG_dig), .DBG_seg(DBG_seg), .DBG_count_high(DBG_count_high));

/////////////////////////
// UART INSTANTIATION //
///////////////////////
UART_host iUART_host(.clk(clk), .rst_n(rst_n), .TX(rx_dbg), .RX(RX),
    .cntlr_data(cntlr_data),.set_cntlr_data_rdy(cntlr_data_rdy), .rx_dbg());

endmodule

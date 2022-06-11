module UART_host (
    input clk, rst_n,
    input [31:0] cntlr_data, // data packet from controller, assumes this is held until next packet!
    input set_cntlr_data_rdy, // new 4-byte packet is ready
    output TX, 
    input RX
);

////////////////////////////
// STATE MACHINE OUTPUTS //
//////////////////////////
reg tx_trmt; // control when to send an individual byte
reg [7:0] tx_data; // what byte to send to the UART
reg reset_cntlr_data_rdy; // when we've read a byte from the controller

reg reset_application_rdy; // when we've sent the response back to the game

////////////////////////////
// UART_TX INSTANTIATION //
//////////////////////////
wire tx_done;
UART_tx iUART_TX(.clk(clk), .rst_n(rst_n), .tx_data(tx_data),
    .trmt(tx_trmt),.tx_done(tx_done),.TX(TX));

////////////////////////////
// UART_RX INSTANTIATION //
//////////////////////////
wire [7:0] application_req;
wire rx_rdy;
UART_rx iUART_RX(.clk(clk), .rst_n(rst_n), .rx_data(application_req),
    .clr_rdy(reset_application_ready),.rdy(rx_rdy),.RX(RX));

wire set_application_rdy = rx_rdy; // magic request byte, tells us that the game is requesting controller data

////////////////////////
// cntlr_data_rdy FF //
//////////////////////

reg cntlr_data_rdy;
always_ff @(posedge clk, negedge rst_n) 
	if (!rst_n)
		cntlr_data_rdy <= 0;
	else if (set_cntlr_data_rdy)
		cntlr_data_rdy <= 1;
	else if (reset_cntlr_data_rdy)
		cntlr_data_rdy <= 0;

///////////////////////////
// application_ready FF //
/////////////////////////

reg application_rdy;
always_ff @(posedge clk, negedge rst_n) 
	if (!rst_n)
		application_rdy <= 0;
	else if (set_application_rdy)
		application_rdy <= 1;
	else if (reset_application_rdy)
		application_rdy <= 0;		

///////////////////////////////
// SEND STATE MACHINE LOGIC //
/////////////////////////////

// TODO: stupid way of doing this?
// little flexibility for adding more bytes
typedef enum reg [2:0] {IDLE, BYTE1, BYTE2, BYTE3, BYTE4} UART_host_state_t;
UART_host_state_t state, nxt_state;

// sequential logic
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

// combinational logic (next state and output ctrl)
always_comb begin
    tx_trmt = 0;
    tx_data = 8'h0;
	reset_cntlr_data_rdy = 0; 
	reset_application_rdy = 0;
	nxt_state = state;

    case (state)
		 IDLE: begin
			  if (cntlr_data_rdy && application_rdy) begin
				  	reset_cntlr_data_rdy = 1;
					reset_application_rdy = 1;
					nxt_state = BYTE1;
					tx_trmt = 1; // send first byte
					tx_data = cntlr_data[7:0];
			  end
		 end
		 BYTE1: begin
			  if (tx_done) begin
					nxt_state = BYTE2;
					tx_trmt = 1; // send second byte
					tx_data = cntlr_data[15:8];
			  end
		 end
		 BYTE2: begin
			  if (tx_done) begin
					nxt_state = BYTE3;
					tx_trmt = 1; // send third byte
					tx_data = cntlr_data[23:16];
			  end
		 end
		 BYTE3: begin
			  if (tx_done) begin
					nxt_state = BYTE4;
					tx_trmt = 1; // send fourth byte
					tx_data = cntlr_data[31:24];
			  end
		 end
		 BYTE4: begin
			  if (tx_done) begin
					nxt_state = IDLE;
			  end
		 end
		 default: nxt_state = IDLE;
	 endcase
end



endmodule

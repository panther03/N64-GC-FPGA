module UART_host (
    input clk, rst_n,
    input [31:0] cntlr_data, // data packet from controller, assumes this is held until next packet!
    input cntlr_data_rdy, // new 4-byte packet is ready
    output TX
);

////////////////////////////
// STATE MACHINE OUTPUTS //
//////////////////////////
reg tx_trmt; // control when to send an individual byte
reg [7:0] tx_data; // what byte to send to the UART

////////////////////////////
// UART_TX INSTANTIATION //
//////////////////////////
wire tx_done;
UART_tx iUART_TX(.clk(clk), .rst_n(rst_n),
    .trmt(tx_trmt),.tx_done(tx_done),.TX(TX));

//////////////////////////
// STATE MACHINE LOGIC //
////////////////////////

// TODO: stupid way of doing this?
// little flexibility for adding more bytes
typedef enum reg {IDLE, BYTE1, BYTE2, BYTE3, BYTE4} UART_host_state_t;
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

    case (state)
		 IDLE: begin
			  if (cntlr_data_rdy) begin
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
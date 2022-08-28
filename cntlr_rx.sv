`timescale 1ns/1ns
module cntlr_rx (
    input clk, rst_n,
    input JB_RX,
    input rx_start,
    output reg rx_done,
    output [31:0] jb_cntlr_data,
    output DBG_count_high,
    output [2:0] DBG_state
);

////////////////////////////
// STATE MACHINE OUTPUTS //
//////////////////////////
logic count_cycles;
logic st_high;
logic st_low;
logic shift_rx;
logic set_done;

///////////////////////////////////////
// RX line metastability prevention //
/////////////////////////////////////
logic JB_RX_ff1, JB_RX_ff2;

always_ff @(posedge clk,negedge rst_n)
    if (!rst_n) begin 
        JB_RX_ff1 <= 1;
        JB_RX_ff2 <= 1;
    end else begin
        JB_RX_ff1 <= JB_RX;
        JB_RX_ff2 <= JB_RX_ff1;
    end

/////////////////////////////
// Counter for read cycle //
///////////////////////////

// During each read cycle, keep a tally of how many low & high bytes were observed.
// Once they sum to 100 cycles (4uS), compare each to see which one was higher.
// This "voting" method helps counteract controllers with delayed timing e.g Hori Pad Mini.
// See: https://www.raphnet.net/electronique/gc_n64_usb/index_en.php#5
logic [7:0] rx_cycle_curr_count;
always_ff @(posedge clk) begin
    if (count_cycles)
        rx_cycle_curr_count <= rx_cycle_curr_count + 1;
    else 
        rx_cycle_curr_count <= 0;
end

wire rx_cycle_timeout = rx_cycle_curr_count == 8'd200;
wire rx_cycle_stop_length = rx_cycle_curr_count == 8'd100;


logic [7:0] rx_cycle_low_count;
logic [7:0] rx_cycle_high_count;
always_ff @(posedge clk, negedge rst_n) 
    if (!rst_n) begin
        rx_cycle_low_count <= 0;
        rx_cycle_high_count <= 0;
    end else begin
        if (st_low) rx_cycle_low_count <= rx_cycle_curr_count;
        if (st_high) rx_cycle_high_count <= rx_cycle_curr_count;
    end
wire rx_cycle_bit_high = rx_cycle_high_count > rx_cycle_low_count;

///////////////////////
// Shift Reg for RX //
/////////////////////

logic [31:0] jb_rx_shift_reg;
always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
        jb_rx_shift_reg <= 0; // set
    else if (shift_rx)        
        jb_rx_shift_reg <= {jb_rx_shift_reg[30:0],rx_cycle_bit_high};

assign jb_cntlr_data = jb_rx_shift_reg;

/////////////////////////
// Bit counter for RX //
///////////////////////

logic [5:0] bit_cnt;
always_ff @(posedge clk, negedge rst_n) 
    if (!rst_n)
        bit_cnt = 0;
    else if (rx_start)
        bit_cnt = 0;
    else if (shift_rx)
        bit_cnt <= bit_cnt + 1;

///////////////////
// rx_done flop //
/////////////////
always @(posedge clk)
    if (set_done)       
        rx_done <= 1;
    else
        rx_done <= 0;

//////////////////////////
// STATE MACHINE LOGIC //
////////////////////////

typedef enum reg [2:0] {IDLE = 3'h0, WAIT_FOR_LOW = 3'h1, COUNT_LOW = 3'h2, COUNT_HIGH = 3'h3, COUNT_HIGH_TRANSITION = 3'h4, SHFT = 3'h5, STOP = 3'h6} RX_state_t;
RX_state_t state, nxt_state;

// sequential logic
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;

// DEBUG: for seeing when we're reading JB
assign DBG_count_high = count_cycles;
// DEBUG: the current state of SM
assign DBG_state =state;

// combinational logic (next state and output ctrl)
always_comb begin
    count_cycles = 0; 
    st_low = 0;
    st_high = 0;
    shift_rx = 0;
    set_done = 0;

    nxt_state = state;

    case (state)
    IDLE: begin
        if (rx_start) begin
            nxt_state = WAIT_FOR_LOW;
            count_cycles = 1;
        end
    end
    WAIT_FOR_LOW: begin
        if (!JB_RX_ff2) begin
            nxt_state = COUNT_LOW;
        end else if (rx_cycle_timeout) begin // line error (didn't go low in time)
            shift_rx = 1;
            nxt_state = SHFT;
        end else
            count_cycles = 1;
    end
    COUNT_LOW: begin
        if (JB_RX_ff2) begin
            nxt_state = COUNT_HIGH;
            st_low = 1;
        end else if (rx_cycle_timeout) begin // line error (didn't go high in time)
            shift_rx = 1;
            nxt_state = SHFT;
        end else
            count_cycles = 1;
    end
    COUNT_HIGH: begin
        if (!JB_RX_ff2) begin
            nxt_state = COUNT_HIGH_TRANSITION; // transition state because we need to wait for the st_high
            st_high = 1;
        end else if (rx_cycle_timeout) begin // line error (didn't go low in time)
            shift_rx = 1;
            nxt_state = SHFT;
        end else
            count_cycles = 1;
    end
    COUNT_HIGH_TRANSITION: begin
        nxt_state = SHFT;
        shift_rx = 1;
    end
    SHFT: begin
        if (bit_cnt == 6'h20)
            nxt_state = STOP;
        else begin
            nxt_state = WAIT_FOR_LOW;
            
        end
    end
    default: begin // STOP
        // stop length hit, or it stopped early
        // and the controller pulled it back high
        if (rx_cycle_stop_length | JB_RX_ff2) begin
            nxt_state = IDLE;
            set_done = 1;
        end else
            count_cycles = 1;
    end
    endcase
end
endmodule

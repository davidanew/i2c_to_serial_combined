`timescale 1ns / 1ps

module test_buffered_uart;

    localparam INPUT_CLOCK_MHz = 48.0;
    localparam FULL_CYCLE = 1000.0 / INPUT_CLOCK_MHz;
    localparam HALF_CYCLE = FULL_CYCLE / 2.0;
    
    // The baud rate for the test uart rx
    localparam UART_RX_BAUD = 9600.0;
    // What the period would be for a normal clock for this
    localparam UART_RX_PERIOD_NOMINAL = 1000000000/UART_RX_BAUD;
    // Actual clock period for uart rx needs to be 16x less and div 2 for half cycle
    localparam UART_RX_HALF_CYCLE = UART_RX_PERIOD_NOMINAL/32;
    
    // Clock for iut
    reg clk = 0;
    // Data input for the buffered uart (4 bytes) 
    reg [31:0]data = 0;
    // Flag that the above data is valid
    reg data_valid = 0;
    reg reset = 0;
    // The output of the buffered uart
    wire tx_signal;
    // clock for test only uart rx
    reg uart_rx_clk = 0;
    // For test only uart data out
    wire [7:0] uart_rx_data_out;
    
    // The circuit under test
    buffered_uart i_buffered_uart
        (.clk(clk),
        .data(data),
        .data_valid(data_valid),
        .reset(reset),
        .tx_signal(tx_signal));
    
    // Just used for checking the output
    uart_rx i_uart_rx
        (.clk(uart_rx_clk),
        .reset(reset),
        .serial_in(tx_signal),
        .data_out(uart_rx_data_out));  
  
    initial
    begin
        $dumpfile("test_buffered_uart.vcd"); // Dump to this file
        $dumpvars(0, test_buffered_uart); // Dump all signals in the testbench
        $display ("INPUT_CLOCK_MHz = %f", INPUT_CLOCK_MHz); 
        $display ("FULL_CYCLE = %f", FULL_CYCLE); 
        $display ("HALF_CYCLE = %f", HALF_CYCLE);

        $display ("Test uart rx baud rate = %f", UART_RX_BAUD); 
        $display ("Nominal clock period for above = %f", UART_RX_PERIOD_NOMINAL); 
        $display ("Half clock period (16x less and half period) = %f", UART_RX_HALF_CYCLE);        
   
        reset = 1;
        // get past global reset period (GSR) (xilinx only)
        #100
        // Do reset
        #FULL_CYCLE   
        reset = 0;
        //
        data = "abcd";
        data_valid = 1;
        #FULL_CYCLE
        data_valid = 0;
        #10000000
        $finish;

    end

    // Clock for design    
    always
    begin
        #HALF_CYCLE clk = ~clk;
    end
    // Clock for output reader
    always
    begin
        #UART_RX_HALF_CYCLE uart_rx_clk = ~uart_rx_clk;
    end
      
endmodule

`timescale 1ns / 1ps

// Expects clock 16x baud rate
// serial input on rx_serial
// data_ready pulses high when data is valid
// data_out set when the data is valid
module uart_rx (
	input clk,
	input reset,
	input serial_in,
	output reg data_ready = 1'b0,
	output reg [7:0] data_out = 8'b0
    );
    // Counter at zero means start bit not detected
    reg [15:0] counter = 1'b0;
    // Need to store revious value so we can detect the start bit transistion
    reg prev_value = 1'b0;
    // Store data internally until we have read the entire byte 
    reg [7:0] byte_internal = 8'b0;
	always @ (posedge clk)
	begin
       if(reset)
       begin
           data_ready <= 1'b0;
           data_out <= 8'b0;
           counter <= 16'b0;
           prev_value = 1'b0;
           byte_internal <= 8'b0;                        
       end
	   // If counter has not started
	   else if (counter == 16'd0)
	   begin
	       // If start bit detected
	       if ( serial_in == 1'b0 & prev_value == 1'b0)
	       begin
	           // Setting to 1 starts counting
	           counter = 16'd1;
	       end
	   end
	   // If we are in the middle of start bit
	   else if (counter == 16'd8) // 16 * 1
	   begin
	       // check input, should be 0
	       if (serial_in == 1'b1)
	       begin
	           // Should not be 1 as it is a start bit, reset counter
	           counter = 15'b0;
	       end
	       else 
	       begin
	           // Otherwise we are ok to carry on
	           counter <= counter + 1'b1;
	       end	   
	   end	   
	   // If counter has reached end
	   else if (counter == 16'd144) // 16 * 9
	   begin
	       counter = 16'd0;
	       // Negate data_ready which should have been set earlier
	       data_ready <= 1'b0;
	   end
	   // Else normal signal checks	   
	   else
	   begin
	       case(counter)
	           32'd24 : byte_internal[0] = serial_in; // tick 8 + 1 * 16
	           32'd40 : byte_internal[1] = serial_in; // tick 8 + 2 * 16
	           32'd56 : byte_internal[2] = serial_in; // tick 8 + 3 * 16
	           32'd72 : byte_internal[3] = serial_in; // tick 8 + 4 * 16
	           32'd88 : byte_internal[4] = serial_in; // tick 8 + 5 * 16
	           32'd104 : byte_internal[5] = serial_in; // tick 8 + 6 * 16
	           32'd120 : byte_internal[6] = serial_in; // tick 8 + 7 * 16
	           32'd136 : // last bit, tick 8 + 8 * 16
	           begin
	               byte_internal[7] = serial_in; 
	               // Set data_ready and set output when we know the data is valid
	               data_ready = 1'b1;
	               data_out <= byte_internal;
	           end
	       endcase
	       counter <= counter + 1'b1;
	   end
	   prev_value = serial_in;
	end
endmodule
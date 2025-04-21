
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
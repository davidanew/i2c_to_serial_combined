
module top
    (
        output IOB_37a,
        output IOT_36b,
        output IOT_39a
    );

    wire int_osc ;
    wire scl;
    wire sda;
    SB_HFOSC u_SB_HFOSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));
    // Clock divided by 2 because of timing problems at top frequency.
    defparam u_SB_HFOSC.CLKHF_DIV = "0b01"; // 24MHz

    // reset gen
    // Relying on ICE40 behavior of reseting all DFF on power on reset.
    reg [3:0] reset_counter;
    reg reset ;
    always @(posedge int_osc) begin
        if (reset_counter < 10) begin
        reset <= 1;
        reset_counter   <= reset_counter + 1;
        end else begin
        reset <= 0;
        end
    end

    i2c_example_gen i_i2c_example_gen
    (
        .clk(int_osc),
        .reset(reset),
        .scl(IOB_37a),
        .sda(IOT_36b)
    );

    top_generic i_top_generic
    (
        .clk(int_osc),
        .reset(reset),
        .scl(IOB_37a),
        .sda(IOT_36b),
        .tx(IOT_39a)
    );

    // trigger gen
    reg [31:0] trigger_counter;
    reg trigger ;
    always @(posedge int_osc) begin
        if (trigger_counter == 2500 * 10 * 2) begin
        trigger <= 1;
        trigger_counter <= 0;
        end else begin
        trigger <= 0;
        trigger_counter <= trigger_counter + 1;
        end
    end

    uart_tx_debug i_uart_tx_debug (
        .clk(int_osc),
        .tx_data(8'b01010101),
        .tx_trigger(trigger),
        .reset(reset),
        .busy(),
        .tx_signal()
    );



endmodule

// Outputs tx_data as serial on tx_signal

module uart_tx_debug
  (
    input clk, // Input clock : currently assumes 24MHz clock which is divided in this block to 2Mbit/sec
    input [7:0] tx_data, // The byte to be sent - latched on rising edge of clock
    input tx_trigger, // Transmission starts if this is high when clock is rising
    input reset, // Syncronous reset
    output reg busy, // active high busy while data is being sent
    output reg tx_signal // The serial output
  );

  // uart_tx states
  localparam UART_WAIT_TRIGGER = 0; // Waiting for tx_trigger
  localparam UART_START_BIT = 1; // Outputting start bit (0)
  localparam UART_SEND_BITS = 2; // Outputting byte (indexed by "bit")
  localparam UART_STOP_BIT = 3; // outputting stop bit (1)
  // UART frequency 2500 cycles for 9600
  localparam UART_COUNTS_PER_BIT = 2500;
  // Count clock ticks to see if next operation is due.
  // This in incremented on clock rise before access in the code section
  reg [31:0] count;
  // Bit to be transmitted - LSB first
  reg [3:0] bit;
  // Data buffer, filled on tx_trigger
  reg [7:0] buffer;
  // Current state
  reg [1:0] state;
  always @(posedge clk)
  begin
    if(reset)
    begin
      tx_signal <= 1;
      count = 0;
      bit = 0;
      buffer <= 0;
      state <= UART_WAIT_TRIGGER;
      busy <= 0;
    end
    else
    begin
      case(state)
        // waiting for tx_trigger
        UART_WAIT_TRIGGER:
        begin
          // if the trigger line is high on this rising edge of the clock and we are waiting to start
          if(tx_trigger)
          begin
            // Keep a copy of the data
            buffer <= tx_data;
            // Start start bit send
            state <= UART_START_BIT;
            // Start bit is zero
            tx_signal <= 0;
            // Indicate as busy
            busy <= 1;
            // Assume count and bit are reset already
          end
        end
        // We are triggered and outputting the start bit
        UART_START_BIT:
        begin
          count = count + 1;
          // If we have waited long enough for the start bit to end, send bit zero
          if (count == UART_COUNTS_PER_BIT)
          begin            
            state <= UART_SEND_BITS;
            // Index "bit" should already be set to zero at initialisation or at end of last send
            tx_signal <= buffer [bit];
            // reset clock counter for next bit
            count = 0;
          end           
        end
        // We are sending (any) bit
        UART_SEND_BITS:
        begin
          count = count + 1;
          // If there has been enough clock cycles to output the next bit
          if (count == UART_COUNTS_PER_BIT)
          begin
            // If the next bit index to be written is < 8)
            if ((bit + 1) < 8)
            begin
              // Go to the next bit index
              bit = bit + 1;
              // Output the new bit
              tx_signal <= buffer[bit]; 
            end
            else
            begin
                // This is a stop bit
                state <= UART_STOP_BIT;
                // Stop bit is high
                tx_signal <= 1;                          
                // Reset bit index for next data byte
                bit = 0;
            end
            // reset clock count for next bit or cycle
            count = 0;
          end
        end 
        // We are outputting a the stop bit
        UART_STOP_BIT:
        begin
          count = count + 1;
          // If we have waited long enough for the stop bit to end
          if (count == UART_COUNTS_PER_BIT)
          begin   
            // Now wait for trigger again      
            state <= UART_WAIT_TRIGGER;
            // No need to set tx_signal high as already high from stop bit
            // Not busy any more
            busy <= 0;
            // Reset clock counter for next byte
            count = 0;
          end           
        end  
      endcase
    end  
  end
endmodule

/*

 
module top (
  //input IOB_34a, // UART RX
  output IOB_32a, // UART TX wrt fpga
  output IOB_37a, // pmod pin next to GND
  output led_red_nc  , // Red
  output led_blue_nc , // Blue
  output led_green_nc  // Green
);

//wire IOB_32a;

  wire int_osc ;
  SB_HFOSC u_SB_HFOSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));
  defparam u_SB_HFOSC.CLKHF_DIV = "0b01"; // 24MHz


  // reset gen
  // Relying on ICE40 behavior of reseting all DFF on power on reset.
  reg [3:0] reset_counter;
  reg reset ;
  always @(posedge int_osc) begin
    if (reset_counter < 10) begin
      reset <= 1;
      reset_counter   <= reset_counter + 1;
    end else begin
      reset <= 0;
    end
  end

  // trigger gen
  reg [31:0] trigger_counter;
  reg trigger ;
  always @(posedge int_osc) begin
    if (trigger_counter == 2500 * 10 * 2) begin
      trigger <= 1;
      trigger_counter <= 0;
    end else begin
      trigger <= 0;
      trigger_counter <= trigger_counter + 1;
    end
  end


  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(1'b1),
    .RGB0PWM (IOB_37a),
    .RGB1PWM (1'b0),
    .RGB2PWM (1'b0),
    .CURREN  (1'b1),
    .RGB0    (led_green_nc), //Actual Hardware connection
    .RGB1    (led_blue_nc),
    .RGB2    (led_red_nc)
  );
  defparam RGB_DRIVER.RGB0_CURRENT = "0b000001";
  defparam RGB_DRIVER.RGB1_CURRENT = "0b000001";
  defparam RGB_DRIVER.RGB2_CURRENT = "0b000001";

  uart_tx i_uart_tx (
    .clk(int_osc),
    .tx_data(8'b01010101),
    .tx_trigger(trigger),
    .reset(reset),
  //  .busy()
    .tx_signal(IOB_37a)
  );

  assign IOB_32a = IOB_37a;

endmodule

// Outputs tx_data as serial on tx_signal

module uart_tx
  (
    input clk, // Input clock : currently assumes 24MHz clock which is divided in this block to 2Mbit/sec
    input [7:0] tx_data, // The byte to be sent - latched on rising edge of clock
    input tx_trigger, // Transmission starts if this is high when clock is rising
    input reset, // Syncronous reset
    output reg busy, // active high busy while data is being sent
    output reg tx_signal // The serial output
  );

  // uart_tx states
  localparam UART_WAIT_TRIGGER = 0; // Waiting for tx_trigger
  localparam UART_START_BIT = 1; // Outputting start bit (0)
  localparam UART_SEND_BITS = 2; // Outputting byte (indexed by "bit")
  localparam UART_STOP_BIT = 3; // outputting stop bit (1)
  // UART frequency 2500 cycles for 9600
  localparam UART_COUNTS_PER_BIT = 2500;
  // Count clock ticks to see if next operation is due.
  // This in incremented on clock rise before access in the code section
  reg [31:0] count;
  // Bit to be transmitted - LSB first
  reg [3:0] bit;
  // Data buffer, filled on tx_trigger
  reg [7:0] buffer;
  // Current state
  reg [1:0] state;
  always @(posedge clk)
  begin
    if(reset)
    begin
      tx_signal <= 1;
      count = 0;
      bit = 0;
      buffer <= 0;
      state <= UART_WAIT_TRIGGER;
      busy <= 0;
    end
    else
    begin
      case(state)
        // waiting for tx_trigger
        UART_WAIT_TRIGGER:
        begin
          // if the trigger line is high on this rising edge of the clock and we are waiting to start
          if(tx_trigger)
          begin
            // Keep a copy of the data
            buffer <= tx_data;
            // Start start bit send
            state <= UART_START_BIT;
            // Start bit is zero
            tx_signal <= 0;
            // Indicate as busy
            busy <= 1;
            // Assume count and bit are reset already
          end
        end
        // We are triggered and outputting the start bit
        UART_START_BIT:
        begin
          count = count + 1;
          // If we have waited long enough for the start bit to end, send bit zero
          if (count == UART_COUNTS_PER_BIT)
          begin            
            state <= UART_SEND_BITS;
            // Index "bit" should already be set to zero at initialisation or at end of last send
            tx_signal <= buffer [bit];
            // reset clock counter for next bit
            count = 0;
          end           
        end
        // We are sending (any) bit
        UART_SEND_BITS:
        begin
          count = count + 1;
          // If there has been enough clock cycles to output the next bit
          if (count == UART_COUNTS_PER_BIT)
          begin
            // If the next bit index to be written is < 8)
            if ((bit + 1) < 8)
            begin
              // Go to the next bit index
              bit = bit + 1;
              // Output the new bit
              tx_signal <= buffer[bit]; 
            end
            else
            begin
                // This is a stop bit
                state <= UART_STOP_BIT;
                // Stop bit is high
                tx_signal <= 1;                          
                // Reset bit index for next data byte
                bit = 0;
            end
            // reset clock count for next bit or cycle
            count = 0;
          end
        end 
        // We are outputting a the stop bit
        UART_STOP_BIT:
        begin
          count = count + 1;
          // If we have waited long enough for the stop bit to end
          if (count == UART_COUNTS_PER_BIT)
          begin   
            // Now wait for trigger again      
            state <= UART_WAIT_TRIGGER;
            // No need to set tx_signal high as already high from stop bit
            // Not busy any more
            busy <= 0;
            // Reset clock counter for next byte
            count = 0;
          end           
        end  
      endcase
    end  
  end
endmodule

*/




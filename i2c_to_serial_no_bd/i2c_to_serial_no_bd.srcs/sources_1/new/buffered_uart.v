`timescale 1ns / 1ps

//`include "common.v"


module buffered_uart
    (
        input clk,
        //Data input for the buffered uart (4 bytes) 
        input [31:0]data,
        // Input data is valid on this cycle
        input data_valid,
        input reset,
        // The uart output
        output tx_signal
    );

    // Output from the buffer to the uart tx
    wire [7:0] buffer_data_out;
    // Triggers the uart (if data is valid)
    reg tx_trigger;
    // Shift the shift register
    reg shift;

 
    buffer i_buffer     
    (
        .clk(clk),
        .data_in(data),
        .load(data_valid),
        .shift(shift),
        .data_out(buffer_data_out),
        .output_valid(buffer_output_valid),
        .reset(reset)
    );

    wire busy;
    
    uart_tx i_uart_tx 
    (
        .clk(clk),
        .tx_data(buffer_data_out),
        .tx_trigger(tx_trigger),
        .reset(reset),
        .busy(busy),
        .tx_signal(tx_signal)
    );
        
    // Used for blocking tx_done and generating the shift signal  
    reg prev_busy;
    reg prev_prev_busy;
    
    always @(posedge clk)
    begin
        if(reset)
        begin
            prev_busy <= 0;
            prev_prev_busy <= 0;            
        end
        else
        begin
            prev_busy <= busy;
            prev_prev_busy <= prev_busy;
        end
    end  

    // Generate tx trigger if the data from the buffer is valid
    // Problem is uart becomes un busy while old data is on buffer output
    // Only do a tx trigger if enough time has passed since busy has cleared, hence a long interlock is needed
    // Clock rise 1 - busy is cleared and tx goes to wait for trigger
    // Clock rise 2 - shift signal is generated - race condition could happen here - block this by using prev_busy
    // Clock rise 3 - new data on shift register output and valid, this clock rise also needs to be blocked
    // Clock rise 4 - all data available trigger can be valid for this rise

    always @(posedge clk)
    begin
        if (buffer_output_valid && !busy && !prev_busy && !prev_prev_busy)
        begin
            tx_trigger <= 1'b1;
        end
        else
        begin
            tx_trigger <= 0;
        end
    end        
   
    // Always shift after tx done (busy de-assertion)
    always @(posedge clk)
    begin
        if (busy == 0 && prev_busy == 1'b1)
        begin
            shift <= 1'b1;
        end
        else
        begin
            shift <= 0;
        end
    end    
endmodule

module buffer
    (
        input clk,
        input [31:0] data_in,
        input load,
        input shift,
        output reg [7:0] data_out,
        output output_valid,
        input reset
    );
    // Four separate block RAMs for parallel write
    (* syn_ramstyle = "block_ram" *) reg [7:0] data_bytes0 [0:15];  // For bytes 0,4,8,...
    (* syn_ramstyle = "block_ram" *) reg [7:0] data_bytes1 [0:15];  // For bytes 1,5,9,...
    (* syn_ramstyle = "block_ram" *) reg [7:0] data_bytes2 [0:15];  // For bytes 2,6,10,...
    (* syn_ramstyle = "block_ram" *) reg [7:0] data_bytes3 [0:15];  // For bytes 3,7,11,...
    
    reg [63:0] valid_bits;
    reg [5:0] write_ptr;
    reg [5:0] read_ptr;
    
    wire [3:0] bank_select = read_ptr[1:0];  // Which RAM bank to read from
    wire [3:0] write_bank = write_ptr[1:0];  // Which RAM bank we're writing to
    wire [3:0] ram_addr = read_ptr[5:2];     // Address within the RAM bank
    wire [3:0] write_addr = write_ptr[5:2];  // Write address within RAM bank

    // Read port mux
    always @(posedge clk)
    begin
        case(bank_select)
            2'b00: data_out <= data_bytes0[ram_addr];
            2'b01: data_out <= data_bytes1[ram_addr];
            2'b10: data_out <= data_bytes2[ram_addr];
            2'b11: data_out <= data_bytes3[ram_addr];
        endcase
    end
    
    // Write logic for all banks
    always @(posedge clk)
    begin
        if(load)
        begin
            data_bytes0[write_addr] <= data_in[31:24];
            data_bytes1[write_addr] <= data_in[23:16];
            data_bytes2[write_addr] <= data_in[15:8];
            data_bytes3[write_addr] <= data_in[7:0];
        end
    end
    
    assign output_valid = valid_bits[read_ptr];

    always @(posedge clk)
    begin
        if(reset)
        begin
            valid_bits <= 64'b0;
            write_ptr <= 6'b0;
            read_ptr <= 6'b0;
        end
        else if(load)
        begin
            valid_bits[write_ptr] <= 1'b1;
            valid_bits[(write_ptr + 1) % 64] <= 1'b1;
            valid_bits[(write_ptr + 2) % 64] <= 1'b1;
            valid_bits[(write_ptr + 3) % 64] <= 1'b1;
            write_ptr <= (write_ptr + 4) % 64;
        end
        else if (shift)
        begin
            valid_bits[read_ptr] <= 1'b0;
            read_ptr <= (read_ptr + 1) % 64;
        end
    end
endmodule

// Outputs tx_data as serial on tx_signal

module uart_tx
  // UART frequency 5000 cycles for 9600 (lattice 48Mhz)
  // UART frequency 2500 cycles for 9600 (lattice 24Mhz)
  #(parameter UART_COUNTS_PER_BIT = 2500)

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
  // Count clock ticks to see if next operation is due.
  // This in incremented on clock rise before access in the code section
  reg [31:0] count; // TODO, sort out count and count+1 terms (blocking?)
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
      count <= 0;
      bit <= 0;
      buffer <= 0;
      state <= UART_WAIT_TRIGGER;
      busy <= 0;
    end
    else
    begin
      //unsigned integer next_count = count;
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
          //next_count = count + 1;
          // If we have waited long enough for the start bit to end, send bit zero
          // TODO: do else first, then we can deal with the +1 with the equality operator
          if ((count + 1) == UART_COUNTS_PER_BIT)
          begin            
            state <= UART_SEND_BITS;
            // Index "bit" should already be set to zero at initialisation or at end of last send
            tx_signal <= buffer [bit];
            // reset clock counter for next bit
            count <= 0;
          end
          else
          begin
            count <= count + 1;
          end           
        end
        // We are sending (any) bit
        UART_SEND_BITS:
        begin
          //count = count + 1;
          // If there has been enough clock cycles to output the next bit
          if ( (count + 1) == UART_COUNTS_PER_BIT)
          begin
            // If the next bit index to be written is < 8)
            if ((bit + 1) < 8)
            begin
              // Output the new bit
              tx_signal <= buffer[bit + 1]; 
              // Go to the next bit index
              bit <= bit + 1;
            end
            else
            begin
              // This is a stop bit
              state <= UART_STOP_BIT;
              // Stop bit is high
              tx_signal <= 1;                          
              // Reset bit index for next data byte
              bit <= 0;
            end
            // reset clock count for next bit or cycle
            count <= 0;
          end
          else
          begin
            count <= count + 1;
          end  
        end 
        // We are outputting a the stop bit
        UART_STOP_BIT:
        begin
          //count = count + 1;
          // If we have waited long enough for the stop bit to end
          if ((count + 1) == UART_COUNTS_PER_BIT)
          begin   
            // Now wait for trigger again      
            state <= UART_WAIT_TRIGGER;
            // No need to set tx_signal high as already high from stop bit
            // Not busy any more
            busy <= 0;
            // Reset clock counter for next byte
            count <= 0;
          end 
          else
          begin
            count <= count + 1;
          end            
        end  
      endcase
    end  
  end
endmodule


`timescale 1ns / 1ps

`include "common.v"

// Main state machine for decoding I2C signal 
// The output of this is "message_type" and "value", which are decode later in "message decoder"
module i2c_process
    (
        input clk,
        input sda,
        input scl,
        input reset,
        output reg [3:0] message_type,
        output reg [7:0] value
    );
    // States
    localparam STATE_I2C_WAIT_START              = 0; // Waiting for start condition
    localparam STATE_I2C_STARTED_SCL_HIGH        = 1; // Start condition done but need to wait for SCL to fall
    localparam STATE_I2C_DATA_SCL_LOW            = 2; // SCL high in data section (only if started)
    localparam STATE_I2C_DATA_SCL_HIGH           = 3; // SCL low in data section (only if started)
    localparam STATE_I2C_WAIT_ACK                = 4; // Wait for SCL to rise for ack/nack
    localparam STATE_I2C_ACK_SCL_HIGH            = 5; // ACK/NACK should be valid during SCL high
    localparam STATE_I2C_DATA7_OR_START_SCL_LOW  = 6; // After a valid sequence next SCL LOW
    localparam STATE_I2C_DATA7_OR_START_SCL_HIGH = 7; // After a valid sequence next SCL LOW
    reg [3:0] state = STATE_I2C_WAIT_START;
    // Store data read bit by bit.
    reg [7:0] data; 
    reg [3:0] index; // TODO: Maybe call data index
    // 1 if ack, 0 if nack
    reg ack_n;
    reg prev_sda;
    reg prev_scl;
    always @(posedge clk)
    begin
        if(reset)
        begin
            message_type <= `I2C_PROCESS_MESSAGE_NULL;
            value <= 0;
            index <= 7; // MSB first
            data <= 0;
            ack_n <= 0;
            prev_sda <= sda;
            prev_scl <= scl;
        end
        else
        begin
            // reset type and value every cycle, though this could cause a glitch if set later on
            message_type <= `I2C_PROCESS_MESSAGE_NULL;
            value <= 0;
            case(state)
                // Waiting for start condition
                // In this state both SDA and SCL are unknown, it is waiting for specific edges
                STATE_I2C_WAIT_START:
                begin
                    // Start - SDA falls while SCL is high
                    if(!sda && prev_sda && scl && prev_scl)
                    begin 
                        state <= STATE_I2C_STARTED_SCL_HIGH;
                        message_type <= `I2C_PROCESS_MESSAGE_START;
                    end
                end
                // Start condition has happened but we need to wait for SCL to fall
                // In this state SDA is low and SCL is high
                STATE_I2C_STARTED_SCL_HIGH:
                begin
                    // If SDA has gone high again then go back to waiting for start
                    if(sda)
                    begin
                        // Currently SDA is HIGH and SCL is HIGH
                        state <= STATE_I2C_WAIT_START;
                        // Could say this is a stop, but say it is an error
                        message_type <= `I2C_PROCESS_MESSAGE_ERROR;          
                    end
                    // else move on to data reading if SCL rises.
                    else if(!scl)
                    begin
                        // Currently SDA is LOW and SCL is LOW
                        state <= STATE_I2C_DATA_SCL_LOW;
                    end    
                end
                // Waiting for SCL to rise to latch data
                // In this state SDA is unknown and SCL is low
                STATE_I2C_DATA_SCL_LOW:
                begin
                    // Waiting for clock to rise.
                    if(scl)
                    begin
                        // Currently SDA is being read and SCL is HIGH
                        // Read data for next SCL high
                        data[index] <= sda;
                        state <= STATE_I2C_DATA_SCL_HIGH;
                    end 
                end
                // In this state SDA is being read and SCL is HIGH
                STATE_I2C_DATA_SCL_HIGH:
                begin
                    // If SCL is still high make sure data has not changed
                    if(scl)
                    begin
                        // SDA is still being read, SCL is high
                        // Check to see if data has changed
                        if (sda != prev_sda)
                        begin

                            // Stop - SDA rises when SCL is high
                            if(sda && !prev_sda)
                            begin
                                // Currently SDA is HIGH and SCL is HIGH
                                state <= STATE_I2C_WAIT_START;
                                message_type <= `I2C_PROCESS_MESSAGE_STOP;
                            end
                            // Else it must have been SDA fall
                            // This is an error
                            else
                            begin
                                // Currently SDA is LOW and SCL is HIGH
                                // Abort to STATE_I2C_WAIT_START
                                state <= STATE_I2C_WAIT_START;
                                message_type <= `I2C_PROCESS_MESSAGE_ERROR;    
                            end
                            // Reset index for next cycle
                            index <= 7;          
                        end
                    end
                    // Else SCL has gone low and we are in the clock low phase
                    else
                        // SDA is don't care, SCL is low
                        // If we have not reached the last bit then decrement index
                        if(index > 0)
                        begin
                            index <= index - 1;
                            // Carry on reading data
                            state <= STATE_I2C_DATA_SCL_LOW;
                        end
                        // Else this is the last bit so next is ACK/NACK.
                        else
                        begin
                            // Now we wait for SCL rise for ACK/NACK
                            // TODO maybe rename STATE_I2C_SCL_LOW_WAIT_ACK
                            state <= STATE_I2C_WAIT_ACK;
                            // Reset index for next cycle
                            index <= 7;
                            // Output data seen
                            message_type <= `I2C_PROCESS_MESSAGE_VALUE;
                            value <= data;       
                        end  
                    begin
                    end
                end
                // Last bit has been read and now waiting for ACK/NACK
                // In this state SDA is don't care SCL is low
                STATE_I2C_WAIT_ACK:
                begin
                    // register ACK/NACK on SCL rise
                    if(scl)
                    begin
                        // SDA is being read SCL is high 
                        ack_n <= sda;
                        // Move to SCL high state
                        state <= STATE_I2C_ACK_SCL_HIGH;
                    end
                    // Else just wait in state with SCL low              
                end
                // In this state SDA is being read SCL is high
                STATE_I2C_ACK_SCL_HIGH:
                begin
                    // If SCL is still high make sure ack has not changed
                    if(scl)
                    begin                  
                        // SDA is still being read, SCL is high
                        // Check to see if data has changed
                        if (sda != prev_sda)
                        begin
                            // Stop - SDA rises when SCL is high
                            if(sda && !prev_sda)
                            begin
                                // Currently SDA is HIGH and SCL is HIGH
                                state <= STATE_I2C_WAIT_START;
                                message_type <= `I2C_PROCESS_MESSAGE_STOP;
                            end
                            // Else it must have been SDA fall - say this is an error
                            else
                            begin
                                // Currently SDA is LOW and SCL is HIGH
                                state <= STATE_I2C_WAIT_START;
                                message_type <= `I2C_PROCESS_MESSAGE_ERROR;    
                            end
                            // Reset index for next cycle
                            index <= 7;          
                        end
                        // Else if data has not changed then all fine                                          
                    end
                    // Else SCL has fallen which means ack/nack has finished and we are waiting for 
                    // stop or repeated start
                    else            
                    begin
                        // Output that we saw ack or nack
                        if(!ack_n)
                        begin
                            message_type <= `I2C_PROCESS_MESSAGE_ACK;
                        end
                        else
                        begin
                            message_type <= `I2C_PROCESS_MESSAGE_NACK;
                        end
                        // Now we don't know if there is going to be new data for MSB (clock rise and fall with data stable)
                        // Or a stop condition (SDA rise while SCL high)
                        // Or start (SDA fall while SCL high)
                        // So we have a special state that handles this                    
                        state <= STATE_I2C_DATA7_OR_START_SCL_LOW;
                    end                
                end
                // Waiting for SCL to rise to latch data after a previous set of data has been read
                // In this state SDA is unknown and SCL is low
                STATE_I2C_DATA7_OR_START_SCL_LOW:
                begin
                    // Waiting for clock to rise.
                    if(scl)
                    begin
                        // Currently SDA is being read and SCL is HIGH
                        // Read the data
                        data[7] <= sda;
                        state <= STATE_I2C_DATA7_OR_START_SCL_HIGH;
                    end 
                end
                // In this state SDA is being read and SCL is HIGH
                // This could be the first bit read, a start condition, or a stop condition
                STATE_I2C_DATA7_OR_START_SCL_HIGH:
                begin
                    // If SCL is still high see if the data has changed
                    if(scl)
                    begin
                        // SDA is still being read, SCL is high
                        // Check to see if data has changed
                        if (sda != prev_sda)
                        begin
                            // Stop condition if SDA rises when SCL is high
                            if(sda && !prev_sda)
                            begin
                                // Currently SDA is HIGH and SCL is HIGH
                                state <= STATE_I2C_WAIT_START;
                                message_type <= `I2C_PROCESS_MESSAGE_STOP;
                            end
                            // Else start condition if SDA falls when SCL is high
                            else
                            begin
                                // Currently SDA is LOW and SCL is HIGH
                                state <= STATE_I2C_STARTED_SCL_HIGH;
                                message_type <= `I2C_PROCESS_MESSAGE_START;    
                            end
                            // Reset index for next cycle
                            index <= 7;          
                        end
                    end
                    // Else SCL has gone low and we are in the clock low phase
                    // This must be a continuation of data read - there was no start (or stop)
                    else
                    // SDA is don't care, SCL is low
                    begin
                        // Index is 6 as we already have read bit 7
                        index <= 6;
                        // Carry on reading data
                        state <= STATE_I2C_DATA_SCL_LOW;
                    end
                end
            endcase
        end
        // Save SDA and SCL values so we can detect edges later on
        // TODO: think about how this could be set at start, or at end in other code
        prev_sda <= sda;
        prev_scl <= scl;    
    end
endmodule
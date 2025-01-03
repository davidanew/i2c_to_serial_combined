`timescale 1ns / 1ps

`include "common.v"

// TODO: should be called encoder
// Takes the messages from the "i2c_process" and convert these to ascii. These are then pushed into the buffered UART
module message_decoder
    (
        input clk,
        input [3:0] message_type,
        input [7:0] value,
        input reset,
        output reg[31:0] ascii,
        output reg valid
    );
    
    wire [7:0] ascii_convert [0:15];
    assign ascii_convert[0]  = "0";
    assign ascii_convert[1]  = "1";
    assign ascii_convert[2]  = "2";
    assign ascii_convert[3]  = "3";
    assign ascii_convert[4]  = "4";
    assign ascii_convert[5]  = "5";
    assign ascii_convert[6]  = "6";
    assign ascii_convert[7]  = "7";
    assign ascii_convert[8]  = "8";
    assign ascii_convert[9]  = "9";
    assign ascii_convert[10] = "a";
    assign ascii_convert[11] = "b";
    assign ascii_convert[12] = "c";
    assign ascii_convert[13] = "d";
    assign ascii_convert[14] = "e";
    assign ascii_convert[15] = "f";
    always @(posedge clk)
    begin
        if(reset)
        begin
            ascii <= 0;
            valid <= 0;
        end
        else
        begin           
            case(message_type)
                `I2C_PROCESS_MESSAGE_NULL:
                begin
                    valid <= 0;
                end
                `I2C_PROCESS_MESSAGE_START:
                begin
                    ascii <= "STAR";
                    valid <= 1;
                end
                `I2C_PROCESS_MESSAGE_VALUE:
                begin
                    ascii[7:0] <= ascii_convert[value[3:0]];
                    ascii[15:8] <= ascii_convert[value[7:4]];
                    ascii[31:16] <= "0x";
                    valid <= 1;
                end
                `I2C_PROCESS_MESSAGE_ACK:
                begin
                    ascii <= "ACK ";
                    valid <= 1;
                end
                `I2C_PROCESS_MESSAGE_NACK:
                begin
                    ascii <= "NACK";
                    valid <= 1;
                end
                `I2C_PROCESS_MESSAGE_STOP:
                begin
                    ascii <= "STP\n";
                    valid <= 1;
                end
                `I2C_PROCESS_MESSAGE_ERROR:
                begin
                    ascii <= "ERR\n";
                    valid <= 1;
                end 
                default:
                begin
                    valid <= 0;
                end                           
            endcase 
        end       
    end
endmodule

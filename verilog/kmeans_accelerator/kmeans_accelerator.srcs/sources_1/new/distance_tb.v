`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2026 01:30:25 PM
// Design Name: 
// Module Name: distance_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module distance_tb;

    // Inputs (reg because we will change them)
    reg signed [15:0] x, y;
    reg signed [15:0] cx, cy;

    // Output (wire because it's driven by module)
    wire [31:0] distance;

    // Instantiate the Distance Unit
    distance_unit uut (
        .x(x),
        .y(y),
        .cx(cx),
        .cy(cy),
        .distance(distance)
    );

    initial begin
        // Test Case 1
        x = 2; y = 3;
        cx = 1; cy = 1;
        #10;

        // Test Case 2
        x = 10; y = 12;
        cx = 8; cy = 9;
        #10;

        // Test Case 3
        x = -5; y = -3;
        cx = -2; cy = -1;
        #10;

        // Stop simulation
        $stop;
    end

endmodule

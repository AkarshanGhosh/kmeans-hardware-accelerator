`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2026 02:32:00 PM
// Design Name: 
// Module Name: min_finder
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


module min_finder (
    input [31:0] d0,
    input [31:0] d1,
    output reg cluster_id
);

    always @(*) begin
        if (d0 <= d1)
            cluster_id = 0;
        else
            cluster_id = 1;
    end

endmodule

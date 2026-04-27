// ============================================================
//  Testbench : tb_dist_unit
//  Tests     : dist_unit.v  (Step 1 of 7)
//  Simulator : Xilinx Vivado Simulator (xsim)
// ------------------------------------------------------------
//  HOW TO RUN IN VIVADO:
//    1. Create project → Add Sources → add dist_unit.v
//    2. Add Simulation Sources → add this file
//    3. Set tb_dist_unit as top simulation module
//    4. Run Simulation → Run Behavioral Simulation
//    5. Check Tcl console for PASS / FAIL messages
//
//  HOW TEST VECTORS WERE GENERATED:
//    Python one-liner to verify any case:
//      d = (pr-cr)**2 + (pg-cg)**2 + (pb-cb)**2
//    All expected values below are pre-computed from that formula.
//
//  TEST CASES:
//    TC1 - Identical pixel and centroid → distance must be 0
//    TC2 - Single channel differs       → one term only
//    TC3 - All channels differ          → full RGB computation
//    TC4 - Worst case (0 vs 255)        → max possible distance
//    TC5 - Realistic image pixel        → cross-check with Python
// ============================================================

`timescale 1ns / 1ps

module tb_dist_unit;

    // ── DUT inputs (driven as regs) ──
    reg [7:0] pixel_r, pixel_g, pixel_b;
    reg [7:0] cent_r,  cent_g,  cent_b;

    // ── DUT output ──
    wire [17:0] dist_sq;

    // ── Instantiate the Design Under Test ──
    dist_unit uut (
        .pixel_r  (pixel_r),
        .pixel_g  (pixel_g),
        .pixel_b  (pixel_b),
        .cent_r   (cent_r),
        .cent_g   (cent_g),
        .cent_b   (cent_b),
        .dist_sq  (dist_sq)
    );

    // ── Helper variables ──
    integer pass_count = 0;
    integer fail_count = 0;
    reg [17:0] expected;

    // ── Task: apply one test vector, check, report ──
    task apply_and_check;
        input [7:0] pr, pg, pb;      // pixel
        input [7:0] cr, cg, cb;      // centroid
        input [17:0] exp;            // expected distance
        input [63:0] tc_num;         // test case number
        begin
            pixel_r = pr; pixel_g = pg; pixel_b = pb;
            cent_r  = cr; cent_g  = cg; cent_b  = cb;
            expected = exp;
            #10;  // wait one propagation window (combinational - no clock needed)

            if (dist_sq === expected) begin
                $display("TC%0d  PASS | pixel=(%0d,%0d,%0d) cent=(%0d,%0d,%0d) | dist=%0d",
                         tc_num, pr, pg, pb, cr, cg, cb, dist_sq);
                pass_count = pass_count + 1;
            end else begin
                $display("TC%0d  FAIL | pixel=(%0d,%0d,%0d) cent=(%0d,%0d,%0d) | got=%0d expected=%0d",
                         tc_num, pr, pg, pb, cr, cg, cb, dist_sq, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── Main stimulus ──
    initial begin
        $display("========================================");
        $display(" dist_unit Testbench - Step 1 of 7     ");
        $display("========================================");

        // ── TC1: Identical pixel and centroid ──
        // Python: (128-128)**2 + (64-64)**2 + (200-200)**2 = 0
        apply_and_check(128, 64, 200,   128, 64, 200,   18'd0,  1);

        // ── TC2: Only R channel differs ──
        // Python: (100-50)**2 + (0-0)**2 + (0-0)**2 = 2500
        apply_and_check(100, 0, 0,   50, 0, 0,   18'd2500,  2);

        // ── TC3: All three channels differ ──
        // Python: (200-100)**2 + (150-50)**2 + (80-30)**2
        //       = 10000 + 10000 + 2500 = 22500
        apply_and_check(200, 150, 80,   100, 50, 30,   18'd22500,  3);

        // ── TC4: Worst case - maximum possible distance ──
        // Python: (255-0)**2 + (255-0)**2 + (255-0)**2
        //       = 65025 + 65025 + 65025 = 195075
        apply_and_check(255, 255, 255,   0, 0, 0,   18'd195075,  4);

        // ── TC5: Realistic pixel from a 32×32 image ──
        // Pixel  = (180, 120, 60)   - warm brownish tone
        // Centroid = (200, 100, 80) - close warm cluster
        // Python: (180-200)**2 + (120-100)**2 + (60-80)**2
        //       = 400 + 400 + 400 = 1200
        apply_and_check(180, 120, 60,   200, 100, 80,   18'd1200,  5);

        // ── Summary ──
        $display("----------------------------------------");
        $display(" Results: %0d PASSED,  %0d FAILED", pass_count, fail_count);
        if (fail_count == 0)
            $display(" ALL TESTS PASSED - dist_unit is correct.");
        else
            $display(" FAILURES DETECTED - check wiring or bit-widths.");
        $display("========================================");

        $finish;
    end

endmodule
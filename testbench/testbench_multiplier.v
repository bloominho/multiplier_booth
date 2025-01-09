`timescale 1ns/10ps

`define N_TESTS 1000

module tb_MULTIPLIER;
    //---DATA WIDTH---
    parameter WIDTH = 17;

    //---Testbench Data---
    reg [WIDTH - 1 : 0] test_A [`N_TESTS - 1 : 0];
    reg [WIDTH - 1 : 0] test_B [`N_TESTS - 1 : 0];
    reg [2*WIDTH-1 : 0] test_R [`N_TESTS - 1 : 0];
    
    reg [WIDTH - 1 : 0] in_a;
    reg [WIDTH - 1 : 0] in_b;

    reg [2*WIDTH-1 : 0] expected_result;

    //---Simulation Result---
    wire [2*WIDTH-1 : 0] simulation_result;

    //---Simulation Status---
    integer test_count = 0; //Number of Tests Executed
    integer pass = 0; 		//Number of Tests Passes
    integer fail = 0;		//Number of Tests Failed

    //---Signals---
    reg clk = 0;
    reg reset;

    //---Clock Signal---
    always #5 clk = ~clk;

    //--- MODULE -------------------------------------
    multiplier #(WIDTH) MULT (
        .A      (in_a),
        .B      (in_b),
        .result (simulation_result)
    );

    //---Simulation---
    integer results_file; 	//file

    //---1. Read Vectors---
    initial
    begin
        $readmemb("./MultiplierTestVectorA", test_A);
        $readmemb("./MultiplierTestVectorB", test_B);
        $readmemb("./MultiplierTestVectorR", test_R);
        results_file = $fopen("./Result_Multiplier.txt");
    end

    //---2. Calculate & Assess---
    integer k = -3;
    always @(posedge clk) begin
        if(k == -3) begin
            reset = 0;
        end else if(k == -2) begin
            //--- Reset ---
            reset = 1;
        end else if(k == -1) begin
            reset = 0;
        end else begin
            //--- Feed Test Data---
            in_a <= test_A[k];
            in_b <= test_B[k];
            expected_result <= test_R[k];
        end
        
        k = k + 1;
    end

    always @(negedge clk) begin
        if(k > 0) begin
            //---Evaluate Data------
            if(simulation_result == expected_result) begin
                pass = pass + 1;
                $fdisplay (results_file,"%d: Passed, expected: %b, simul: %b", test_count, expected_result, simulation_result);	
                $display("%d: Passed", test_count);
            end else begin
                fail = fail + 1;
                $fdisplay (results_file,"%d: Failed, expected: %b, simul: %b", test_count, expected_result, simulation_result);	
                $display("%d: Failed", test_count);	
            end
            test_count = test_count + 1;

            //---Test Finished---
            if(test_count == `N_TESTS) begin
                if(pass == k) begin
                    //---Test Success---
                    $display ("Passed: %d/%d", pass, test_count);
                    $fdisplay (results_file,"Passed: %d/%d", pass, test_count);
                    $fclose(results_file);
                end else begin
                    //---Test Fail---
                    $display ("Passed: %d/%d", pass, test_count);
                    $fdisplay (results_file,"Failed: %d/%d", pass, test_count);
                    $fclose(results_file);
                end
                $finish;
            end
        end
    end

endmodule
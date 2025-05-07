module test_bench;
    reg clk1, clk2, rst;
    
    // Instantiate the pipeline
    pipeline pipe(
        .clk1(clk1),
        .clk2(clk2),
        .rst(rst)
    );
    
    // Clock generation
    initial begin
        clk1 = 0;
        clk2 = 0;
        forever begin
            #5 clk1 = ~clk1;
            #5 clk2 = ~clk2;
        end
    end
    
    // Test sequence
    initial begin
        // Initialize
        rst = 1;
        #20;
        rst = 0;
        
        // Test 1: Basic ALU operations with forwarding
        pipe.Reg[1] = 32'h00000001;
        pipe.Reg[2] = 32'h00000002;
        pipe.Mem[0] = {6'b000000, 5'b00001, 5'b00010, 5'b00011, 5'b00000, 6'b000000}; // ADD R3, R1, R2
        pipe.Mem[1] = {6'b000000, 5'b00011, 5'b00001, 5'b00100, 5'b00000, 6'b000000}; // ADD R4, R3, R1
        
        // Test 2: Load-Use Hazard
        pipe.Mem[2] = {6'b001000, 5'b00001, 5'b00101, 16'h0004}; // LW R5, 4(R1)
        pipe.Mem[3] = {6'b000000, 5'b00101, 5'b00001, 5'b00110, 5'b00000, 6'b000000}; // ADD R6, R5, R1
        
        // Test 3: Branch Prediction
        pipe.Mem[4] = {6'b001101, 5'b00001, 16'h0002}; // BNEQZ R1, 2
        pipe.Mem[5] = {6'b000000, 5'b00001, 5'b00001, 5'b00001, 5'b00000, 6'b000000}; // ADD R1, R1, R1
        
        // Test 4: Cache Access
        pipe.Mem[6] = {6'b001000, 5'b00000, 5'b00111, 16'h0008}; // LW R7, 8(R0)
        pipe.Mem[7] = {6'b001000, 5'b00000, 5'b01000, 16'h0008}; // LW R8, 8(R0) - Should hit cache
        
        // Test 5: Exception Handling
        pipe.Mem[8] = {6'b000000, 5'b00000, 5'b00000, 5'b00000, 5'b00000, 6'b001000}; // SYSCALL
        
        // Run for 1000 cycles
        #1000;
        
        // Display performance metrics
        $display("Performance Metrics:");
        $display("Total Cycles: %d", pipe.perf_unit.cycle_count);
        $display("Instructions Executed: %d", pipe.perf_unit.instruction_count);
        $display("Branch Mispredictions: %d", pipe.perf_unit.branch_mispredict_count);
        $display("Cache Misses: %d", pipe.cache_unit.cache_miss_count);
        
        // Display final register values
        $display("\nFinal Register Values:");
        for (int i = 0; i < 8; i++) begin
            $display("R%d: %h", i, pipe.Reg[i]);
        end
        
        $finish;
    end
    
    // Monitor pipeline state
    always @(posedge clk1) begin
        if (pipe.except_unit.exception_active) begin
            $display("Exception occurred: Type %d at PC %h", 
                    pipe.except_unit.exception_type, 
                    pipe.except_unit.exception_pc);
        end
    end
endmodule 
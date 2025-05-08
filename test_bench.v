module test_bench;
    reg clk1, clk2, rst;
    wire [31:0] performance_metrics;
    
    // Instantiate the pipeline
    main pipeline(
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
        pipeline.Reg[1] = 32'h00000001;
        pipeline.Reg[2] = 32'h00000002;
        pipeline.Mem[0] = {ADD, 5'b00001, 5'b00010, 5'b00011, 5'b00000, 6'b000000}; // ADD R3, R1, R2
        pipeline.Mem[1] = {ADD, 5'b00011, 5'b00001, 5'b00100, 5'b00000, 6'b000000}; // ADD R4, R3, R1
        
        // Test 2: Load-Use Hazard
        pipeline.Mem[2] = {LW, 5'b00001, 5'b00101, 16'h0004}; // LW R5, 4(R1)
        pipeline.Mem[3] = {ADD, 5'b00101, 5'b00001, 5'b00110, 5'b00000, 6'b000000}; // ADD R6, R5, R1
        
        // Test 3: Branch Prediction
        pipeline.Mem[4] = {BNEQZ, 5'b00001, 16'h0002}; // BNEQZ R1, 2
        pipeline.Mem[5] = {ADD, 5'b00001, 5'b00001, 5'b00001, 5'b00000, 6'b000000}; // ADD R1, R1, R1
        
        // Test 4: Cache Access
        pipeline.Mem[6] = {LW, 5'b00000, 5'b00111, 16'h0008}; // LW R7, 8(R0)
        pipeline.Mem[7] = {LW, 5'b00000, 5'b01000, 16'h0008}; // LW R8, 8(R0) - Should hit cache
        
        // Test 5: Exception Handling
        pipeline.Mem[8] = {6'b000000, 5'b00000, 5'b00000, 5'b00000, 5'b00000, 6'b001000}; // SYSCALL
        
        // Run for 100 cycles
        #1000;
        
        // Display performance metrics
        $display("Performance Metrics:");
        $display("Total Cycles: %d", pipeline.cycle_count);
        $display("Instructions Executed: %d", pipeline.instruction_count);
        $display("Branch Mispredictions: %d", pipeline.branch_mispredict_count);
        $display("Cache Misses: %d", pipeline.cache_miss_count);
        
        // Display final register values
        $display("\nFinal Register Values:");
        for (int i = 0; i < 8; i++) begin
            $display("R%d: %h", i, pipeline.Reg[i]);
        end
        
        $finish;
    end
    
    // Monitor pipeline state
    always @(posedge clk1) begin
        if (pipeline.exception_active) begin
            $display("Exception occurred: Type %d at PC %h", 
                    pipeline.exception_type, pipeline.exception_pc);
        end
    end
endmodule

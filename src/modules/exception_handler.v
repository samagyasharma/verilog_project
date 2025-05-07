module exception_handler(
    input clk,
    input rst,
    input [31:0] ID_EX_IR,
    input [31:0] PC,
    
    output reg [2:0] exception_type,
    output reg [31:0] exception_pc,
    output reg exception_active,
    output reg pipeline_flush
);

    // Exception handling logic
    always @(posedge clk) begin
        if (rst) begin
            exception_active <= 0;
            exception_type <= 0;
            exception_pc <= 0;
            pipeline_flush <= 0;
        end else begin
            // Check for exceptions
            if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001000) begin
                // SYSCALL
                exception_type <= 3'b001;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001100) begin
                // BREAK
                exception_type <= 3'b010;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001101) begin
                // TRAP
                exception_type <= 3'b011;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
            end else begin
                exception_active <= 0;
                pipeline_flush <= 0;
            end
        end
    end

endmodule 
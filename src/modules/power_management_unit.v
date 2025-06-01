module power_management_unit(
    input wire clk,
    input wire rst,
    input wire [31:0] instruction,
    input wire [31:0] pc,
    input wire [31:0] register_values [0:31],
    input wire cache_hit,
    input wire branch_misprediction,
    input wire exception_occurred,
    
    output reg power_save_mode,
    output reg clock_gate_enable,
    output reg [3:0] power_state,
    output reg [31:0] power_consumption_stats
);

    // Power states
    localparam POWER_STATE_ACTIVE = 4'b0000;
    localparam POWER_STATE_IDLE = 4'b0001;
    localparam POWER_STATE_SLEEP = 4'b0010;
    localparam POWER_STATE_DEEP_SLEEP = 4'b0011;

    // Power consumption tracking
    reg [31:0] instruction_count;
    reg [31:0] cache_miss_count;
    reg [31:0] branch_misprediction_count;
    reg [31:0] idle_cycles;

    // Power management parameters
    localparam IDLE_THRESHOLD = 1000;  // Cycles before entering idle
    localparam SLEEP_THRESHOLD = 5000; // Cycles before entering sleep
    localparam DEEP_SLEEP_THRESHOLD = 10000; // Cycles before deep sleep

    // Clock gating control
    reg clock_gate_counter;
    reg [31:0] activity_monitor;

    // Power state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            power_state <= POWER_STATE_ACTIVE;
            power_save_mode <= 1'b0;
            clock_gate_enable <= 1'b0;
            instruction_count <= 0;
            cache_miss_count <= 0;
            branch_misprediction_count <= 0;
            idle_cycles <= 0;
            activity_monitor <= 0;
        end else begin
            // Update activity monitor
            activity_monitor <= {activity_monitor[30:0], 
                               (instruction != 32'h0) || 
                               cache_hit || 
                               branch_misprediction || 
                               exception_occurred};

            // Power state transitions
            case (power_state)
                POWER_STATE_ACTIVE: begin
                    if (idle_cycles >= DEEP_SLEEP_THRESHOLD) begin
                        power_state <= POWER_STATE_DEEP_SLEEP;
                        power_save_mode <= 1'b1;
                        clock_gate_enable <= 1'b1;
                    end else if (idle_cycles >= SLEEP_THRESHOLD) begin
                        power_state <= POWER_STATE_SLEEP;
                        power_save_mode <= 1'b1;
                        clock_gate_enable <= 1'b0;
                    end else if (idle_cycles >= IDLE_THRESHOLD) begin
                        power_state <= POWER_STATE_IDLE;
                        power_save_mode <= 1'b0;
                        clock_gate_enable <= 1'b0;
                    end
                end

                POWER_STATE_IDLE: begin
                    if (activity_monitor != 0) begin
                        power_state <= POWER_STATE_ACTIVE;
                        idle_cycles <= 0;
                    end else if (idle_cycles >= SLEEP_THRESHOLD) begin
                        power_state <= POWER_STATE_SLEEP;
                        power_save_mode <= 1'b1;
                    end
                end

                POWER_STATE_SLEEP: begin
                    if (activity_monitor != 0) begin
                        power_state <= POWER_STATE_ACTIVE;
                        idle_cycles <= 0;
                        power_save_mode <= 1'b0;
                    end else if (idle_cycles >= DEEP_SLEEP_THRESHOLD) begin
                        power_state <= POWER_STATE_DEEP_SLEEP;
                        clock_gate_enable <= 1'b1;
                    end
                end

                POWER_STATE_DEEP_SLEEP: begin
                    if (activity_monitor != 0) begin
                        power_state <= POWER_STATE_ACTIVE;
                        idle_cycles <= 0;
                        power_save_mode <= 1'b0;
                        clock_gate_enable <= 1'b0;
                    end
                end
            endcase

            // Update statistics
            if (instruction != 32'h0) begin
                instruction_count <= instruction_count + 1;
                idle_cycles <= 0;
            end else begin
                idle_cycles <= idle_cycles + 1;
            end

            if (!cache_hit) begin
                cache_miss_count <= cache_miss_count + 1;
            end

            if (branch_misprediction) begin
                branch_misprediction_count <= branch_misprediction_count + 1;
            end

            // Calculate power consumption statistics
            power_consumption_stats <= (instruction_count * 2) + 
                                     (cache_miss_count * 5) + 
                                     (branch_misprediction_count * 3) + 
                                     (idle_cycles / 100);
        end
    end

endmodule 
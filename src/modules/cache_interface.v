module cache_interface(
    input clk,
    input rst,
    input [31:0] addr,
    input read_write,
    input [31:0] write_data,
    input [31:0] mem_data,
    
    output reg [31:0] cache_data_out,
    output reg cache_hit,
    output reg [31:0] cache_miss_count
);

    // Cache memory
    reg [31:0] cache_data [0:255];  // 256-entry cache
    reg [23:0] cache_tags [0:255];  // Cache tags
    reg [255:0] cache_valid;        // Cache valid bits

    // Cache access logic
    always @(posedge clk) begin
        if (rst) begin
            cache_valid <= 0;
            cache_miss_count <= 0;
        end else begin
            if (cache_valid[addr[9:2]] && cache_tags[addr[9:2]] == addr[31:8]) begin
                // Cache hit
                cache_hit <= 1'b1;
                if (read_write) begin
                    cache_data[addr[9:2]] <= write_data;
                end
                cache_data_out <= cache_data[addr[9:2]];
            end else begin
                // Cache miss
                cache_hit <= 1'b0;
                cache_miss_count <= cache_miss_count + 1;
                cache_data[addr[9:2]] <= mem_data;
                cache_tags[addr[9:2]] <= addr[31:8];
                cache_valid[addr[9:2]] <= 1'b1;
                cache_data_out <= mem_data;
            end
        end
    end

endmodule 
module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    
    // Basic counter design as an example
    // TODO: remove the counter design and use this module to insert your own design
    // DO NOT change the I/O header of this design

    logic [11:0] data_in, range;
    logic        go, finish, debug_error;
    logic [6:0]  led_out;
    logic [11:0] max, min;

    enum logic [1:0] {IDLE, GO, ERROR, FIN} state, nextState;

    assign data_in = io_in;
    assign io_out[6:0] = led_out;

    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            max <= 0;
            min <= 16'hFFFF;
        end else begin
            state <= nextState;

            if (!finish && go) begin
                if (data_in > max) max <= data_in;
                else max <= max;
                if (data_in < min) min <= data_in;
                else min <= min;
            end

        end
    end

    // next state logic
    always_comb begin
        case (state)
            IDLE: begin
                if (finish && go) begin
                    nextState = ERROR;
                    debug_error = 1;
                end else if (finish) begin
                    nextState = ERROR;
                    debug_error = 1;
                end else if (!finish && go) begin
                    nextState = GO;
                    debug_error = 0;
                end else begin
                    nextState = IDLE;
                    debug_error = 0;
                end

                range = 0;
            end
            GO: begin
                if (finish && go) begin
                    nextState = ERROR;
                    debug_error = 1;
                end else if (finish) begin
                    nextState = FIN;
                    debug_error = 0;
                end else begin
                    nextState = GO;
                    debug_error = 0;
                end

                range = 0;
            end
            FIN: begin
                if (finish && go) begin
                    nextState = ERROR;
                    debug_error = 1;
                end else if (go) begin
                    nextState = GO;
                    debug_error = 0;
                end else begin
                    nextState = FIN;
                    debug_error = 0;
                end

                if ((data_in > max) && (data_in < min)) range = 0;
                else if (data_in > max) range = (data_in - min);
                else if (data_in < min) range = (max - data_in);
                else range = (max - min);

            end
            ERROR: begin
                debug_error = 1;
                if (go && !finish) begin
                    nextState = GO;
                    debug_error = 0;
                end else begin
                    nextState = ERROR;
                    debug_error = 0;
                end

                range = 0;
            end
        endcase
    end

    // instantiate segment display
    seg7 seg7(.counter(range[3:0]), .segments(led_out));

endmodule
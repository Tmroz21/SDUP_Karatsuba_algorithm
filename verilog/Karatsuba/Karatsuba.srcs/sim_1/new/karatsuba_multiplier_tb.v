`timescale 1ns / 1ps

module tb_karatsuba_multiplier();
    
    parameter WIDTH = 32;
    parameter BASE_THRESHOLD = 8;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg [WIDTH-1:0] a, b;
    wire [2*WIDTH-1:0] result;
    wire done;

    // Oczekiwany wynik do porównania
    reg [2*WIDTH-1:0] expected_result;

    //  Definicja modu³u 
    karatsuba_multiplier #(
        .WIDTH(WIDTH),
        .BASE_THRESHOLD(BASE_THRESHOLD)
    ) karatsuba (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a(a),
        .b(b),
        .result(result),
        .done(done)
    );

    // zegar
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        // Inicjalizacja sygna³ów
        clk = 0;
        rst_n = 0;
        start = 0;
        a = 0;
        b = 0;

        // Sekwencja resetowania
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD);

        // Test 1: Ma³e liczby (przypadek bazowy)
        $display("=== Test 1: Ma³e liczby ===");
        test_multiplication(8'd15, 8'd12);
        
        // Test 2: Œrednie liczby
        $display("=== Test 2: Œrednie liczby ===");
        test_multiplication(16'd255, 16'd128);        
        
        // Test 3: Du¿e liczby
        $display("=== Test 3: Du¿e liczby ===");
        test_multiplication(32'hFFFF, 32'hAAAA);
        
        // Test 5: Przypadki graniczne
        $display("=== Test 4: Przypadki graniczne ===");
        test_multiplication(32'd0, 32'd12345);
        test_multiplication(32'd1, 32'd67890);
        test_multiplication(32'hFFFFFFFF, 32'd1);

        $display("=== Wszystkie testy zakoñczone ===");
        $finish;
    end
    
    //TEST
    task test_multiplication;
        input [WIDTH-1:0] test_a, test_b;
        integer timeout_counter;
        begin
            // Parametry wejœciowe
            a = test_a;
            b = test_b;
            expected_result = test_a * test_b;

            start = 1;
            #CLK_PERIOD;
            start = 0;
            
            // Oczekiwanie na zakoñczenie
            timeout_counter = 0;
            while (!done && timeout_counter < 1000) begin
                #CLK_PERIOD;
                timeout_counter = timeout_counter + 1;
            end
            
            // Weryfikacja wyników
            if (timeout_counter >= 1000) begin
                $display("Timeout");
                $display("  a = %d, b = %d", test_a, test_b);
            end else if (result == expected_result) begin
                $display("POPRAWNE: %d × %d = %d (cykle: %d)", 
                        test_a, test_b, result, timeout_counter);
            end else begin
                $display("NIE POPRAWNE: %d × %d", test_a, test_b);
                $display("  Wartoœæ oczekiwana: %d", expected_result);
                $display("  Wynik:  %d", result);
            end
            
            // Oczekiwanie na zmianê done na niski
            #(CLK_PERIOD * 2);
        end
    endtask

    // Monitorowanie czasu i stanów
    initial begin
        $monitor("Czas: %0t | Stan: %d | A: %d | B: %d | Wynik: %d | Gotowe: %b", 
                 $time, karatsuba.state, a, b, result, done);
    end
endmodule
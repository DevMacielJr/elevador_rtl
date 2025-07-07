library verilog;
use verilog.vl_types.all;
entity elevador_rtl is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        botoes_internos : in     vl_logic_vector(2 downto 0);
        botoes_externos : in     vl_logic_vector(2 downto 0);
        sensor_andar    : in     vl_logic_vector(1 downto 0);
        mostrador_7seg  : out    vl_logic_vector(6 downto 0);
        leds_direcao    : out    vl_logic_vector(1 downto 0);
        led_porta_aberta: out    vl_logic
    );
end elevador_rtl;

library verilog;
use verilog.vl_types.all;
entity elevador_rtl_vlg_check_tst is
    port(
        led_porta_aberta: in     vl_logic;
        leds_direcao    : in     vl_logic_vector(1 downto 0);
        mostrador_7seg  : in     vl_logic_vector(6 downto 0);
        sampler_rx      : in     vl_logic
    );
end elevador_rtl_vlg_check_tst;

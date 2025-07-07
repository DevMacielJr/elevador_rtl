library verilog;
use verilog.vl_types.all;
entity elevador_rtl_vlg_sample_tst is
    port(
        botoes_externos : in     vl_logic_vector(2 downto 0);
        botoes_internos : in     vl_logic_vector(2 downto 0);
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        sensor_andar    : in     vl_logic_vector(1 downto 0);
        sampler_tx      : out    vl_logic
    );
end elevador_rtl_vlg_sample_tst;

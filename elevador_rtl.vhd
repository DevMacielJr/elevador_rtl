library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity elevador_rtl is
    Port (
        clk               : in  std_logic;
        reset             : in  std_logic;
        botoes_internos   : in  std_logic_vector(2 downto 0);
        botoes_externos   : in  std_logic_vector(2 downto 0);
        sensor_andar      : in  std_logic_vector(1 downto 0);
        mostrador_7seg    : out std_logic_vector(6 downto 0);
        leds_direcao      : out std_logic_vector(1 downto 0);
        led_porta_aberta  : out std_logic
    );
end elevador_rtl;

architecture RTL of elevador_rtl is
    type tipo_estado is (S_PARADO, S_SUBINDO, S_DESCENDO, S_PORTA_ABERTA);
    signal estado_atual     : tipo_estado := S_PARADO;

    signal andar_atual      : integer range 0 to 2 := 0;
    signal andar_destino    : integer range 0 to 2 := 0;
    signal contador_porta   : integer range 0 to 50000000 := 0;

    signal chamada_solicitada : std_logic := '0';
    signal andar_solicitado   : integer range 0 to 2 := 0;
    
    constant TEMPO_PORTA : integer := 50000000;

    function decodifica_7seg(valor: integer) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case valor is
            when 0      => seg := "1000000";
            when 1      => seg := "1111001";
            when 2      => seg := "0100100";
            when others => seg := "1111111";
        end case;
        return seg;
    end;

begin
    process(botoes_internos, botoes_externos)
    begin
        chamada_solicitada <= '0';
        andar_solicitado   <= 0;
        
        if botoes_internos(0) = '1' then
            andar_solicitado <= 0; chamada_solicitada <= '1';
        elsif botoes_internos(1) = '1' then
            andar_solicitado <= 1; chamada_solicitada <= '1';
        elsif botoes_internos(2) = '1' then
            andar_solicitado <= 2; chamada_solicitada <= '1';
        elsif botoes_externos(0) = '1' then
            andar_solicitado <= 0; chamada_solicitada <= '1';
        elsif botoes_externos(1) = '1' then
            andar_solicitado <= 1; chamada_solicitada <= '1';
        elsif botoes_externos(2) = '1' then
            andar_solicitado <= 2; chamada_solicitada <= '1';
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                estado_atual  <= S_PARADO;
                contador_porta<= 0;
                andar_atual   <= 0;
                andar_destino <= 0;
            else
                case sensor_andar is
                    when "00" => andar_atual <= 0;
                    when "01" => andar_atual <= 1;
                    when "10" => andar_atual <= 2;
                    when others => andar_atual <= andar_atual;
                end case;

                case estado_atual is
                    when S_PARADO =>
                        if chamada_solicitada = '1' then
                            andar_destino <= andar_solicitado; 
                            if andar_solicitado > andar_atual then
                                estado_atual <= S_SUBINDO;
                            elsif andar_solicitado < andar_atual then
                                estado_atual <= S_DESCENDO;
                            else
                                estado_atual <= S_PORTA_ABERTA;
                                contador_porta <= 0;
                            end if;
                        end if;
                    when S_SUBINDO =>
                        if andar_atual = andar_destino then
                            estado_atual <= S_PORTA_ABERTA;
                            contador_porta <= 0;
                        end if;
                    when S_DESCENDO =>
                        if andar_atual = andar_destino then
                            estado_atual <= S_PORTA_ABERTA;
                            contador_porta <= 0;
                        end if;
                    when S_PORTA_ABERTA =>
                        if contador_porta >= TEMPO_PORTA then
                            estado_atual <= S_PARADO;
                        else
                            contador_porta <= contador_porta + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    mostrador_7seg   <= decodifica_7seg(andar_atual);
    led_porta_aberta <= '1' when estado_atual = S_PORTA_ABERTA else '0';
    with estado_atual select
        leds_direcao <= "01" when S_SUBINDO,
                        "10" when S_DESCENDO,
                        "00" when others;
end architecture;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ======================================================================
-- Entidade Principal: Controlador RTL para Elevador de 3 Andares
-- Descrição: Implementa a lógica completa de controle com máquina de estados
--            e caminho de dados para operação segura e determinística.
-- ======================================================================
entity elevador_rtl is
    Port (
        clk               : in  std_logic;                     -- Clock do sistema (50MHz)
        reset             : in  std_logic;                     -- Reset assíncrono (ativo alto)
        botoes_internos   : in  std_logic_vector(2 downto 0);  -- Botões internos [0=terreo, 1=andar1, 2=andar2]
        botoes_externos   : in  std_logic_vector(2 downto 0);  -- Botões externos [0=terreo, 1=andar1, 2=andar2]
        sensor_andar      : in  std_logic_vector(1 downto 0);  -- Sensores de andar ("00"=terreo, "01"=1, "10"=2)
        mostrador_7seg    : out std_logic_vector(6 downto 0);  -- Display 7 segmentos (ativo baixo)
        leds_direcao      : out std_logic_vector(1 downto 0);  -- Controle de LEDs: "01"=subir, "10"=descer
        led_porta_aberta  : out std_logic                      -- LED de porta aberta (ativo alto)
    );
end elevador_rtl;

architecture RTL of elevador_rtl is
    -- ==================================================================
    -- Definição dos Estados da Máquina de Estados Finitos (FSM)
    -- S_PARADO:       Aguardando chamadas
    -- S_SUBINDO:      Em movimento ascendente
    -- S_DESCENDO:     Em movimento descendente
    -- S_PORTA_ABERTA: Porta aberta no andar de destino
    -- ==================================================================
    type tipo_estado is (S_PARADO, S_SUBINDO, S_DESCENDO, S_PORTA_ABERTA);
    signal estado_atual     : tipo_estado := S_PARADO;

    -- ==================================================================
    -- Sinais do Caminho de Dados (todos registrados)
    -- andar_atual:    Posição atual do elevador (0 a 2)
    -- andar_destino:  Destino registrado da chamada atual
    -- contador_porta: Temporizador para controle do tempo de porta aberta
    -- ==================================================================
    signal andar_atual      : integer range 0 to 2 := 0;
    signal andar_destino    : integer range 0 to 2 := 0;
    signal contador_porta   : integer range 0 to 50000000 := 0;

    -- ==================================================================
    -- Sinais Intermediários da Lógica Combinacional
    -- chamada_solicitada: Indica quando há botões pressionados
    -- andar_solicitado:   Andar alvo da chamada atual
    -- ==================================================================
    signal chamada_solicitada : std_logic := '0';
    signal andar_solicitado   : integer range 0 to 2 := 0;
    
    -- ==================================================================
    -- Constante de Temporização
    -- NOTA: Para simulação, alterar para valor pequeno (ex: 10)
    -- Valor padrão: 50.000.000 ciclos = 1s @ 50MHz
    -- ==================================================================
    constant TEMPO_PORTA : integer := 50000000;

    -- ==================================================================
    -- Função: Decodificador para Display de 7 Segmentos
    -- Mapeia o número do andar para os segmentos do display (ativo baixo)
    -- ==================================================================
    function decodifica_7seg(valor: integer) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case valor is
            when 0      => seg := "1000000";  -- '0' no display
            when 1      => seg := "1111001";  -- '1' no display
            when 2      => seg := "0100100";  -- '2' no display
            when others => seg := "1111111";  -- Display apagado (estado inválido)
        end case;
        return seg;
    end;

begin
    -- ==================================================================
    -- Bloco 1: Lógica Combinacional de Codificação de Chamada
    -- Propósito: Prioriza e codifica as chamadas dos botões internos/externos
    -- Comportamento:
    -- 1. Prioridade fixa: botões internos têm precedência sobre externos
    -- 2. Gera sinal 'chamada_solicitada' e registra 'andar_solicitado'
    -- 3. Projetado para evitar latches com atribuições padrão explícitas
    -- ==================================================================
    process(botoes_internos, botoes_externos)
    begin
        -- Valores padrão (evita latches)
        chamada_solicitada <= '0';
        andar_solicitado   <= 0;
        
        -- Lógica de prioridade fixa (internos > externos)
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

    -- ==================================================================
    -- Bloco 2: Processo Principal Síncrono
    -- Contém:
    -- 1. Máquina de Estados Finitos (FSM)
    -- 2. Registradores do caminho de dados
    -- 3. Lógica de temporização da porta
    --
    -- Características:
    -- - Sensível apenas à borda de subida do clock
    -- - Reset assíncrono para inicialização determinística
    -- - Todas as transições são registradas sincronamente
    -- ==================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Reset síncrono: inicializa todos os registradores
                estado_atual  <= S_PARADO;
                contador_porta<= 0;
                andar_atual   <= 0;
                andar_destino <= 0;
            else
                -- Atualização do andar atual (lido dos sensores físicos)
                -- NOTA: Implementa tratamento seguro para valores inválidos
                case sensor_andar is
                    when "00" => andar_atual <= 0;  -- Terreo
                    when "01" => andar_atual <= 1;  -- Andar 1
                    when "10" => andar_atual <= 2;  -- Andar 2
                    when others => andar_atual <= andar_atual;  -- Mantém estado anterior se inválido
                end case;

                -- Lógica Principal da Máquina de Estados
                case estado_atual is
                    -- Estado PARADO: aguarda chamadas válidas
                    when S_PARADO =>
                        if chamada_solicitada = '1' then
                            -- Registra novo destino apenas quando parado
                            andar_destino <= andar_solicitado; 
                            
                            -- Decide direção com base na posição relativa
                            if andar_solicitado > andar_atual then
                                estado_atual <= S_SUBINDO;
                            elsif andar_solicitado < andar_atual then
                                estado_atual <= S_DESCENDO;
                            else
                                -- Chamada para o andar atual: abre porta diretamente
                                estado_atual <= S_PORTA_ABERTA;
                                contador_porta <= 0;  -- Reinicia temporizador
                            end if;
                        end if;

                    -- Estado SUBINDO: em movimento ascendente
                    when S_SUBINDO =>
                        -- Verifica se chegou ao destino
                        if andar_atual = andar_destino then
                            estado_atual <= S_PORTA_ABERTA;
                            contador_porta <= 0;  -- Prepara temporizador
                        end if;

                    -- Estado DESCENDO: em movimento descendente
                    when S_DESCENDO =>
                        -- Verifica se chegou ao destino
                        if andar_atual = andar_destino then
                            estado_atual <= S_PORTA_ABERTA;
                            contador_porta <= 0;  -- Prepara temporizador
                        end if;

                    -- Estado PORTA ABERTA: temporização controlada
                    when S_PORTA_ABERTA =>
                        if contador_porta >= TEMPO_PORTA then
                            -- Tempo esgotado: fecha porta e volta para PARADO
                            estado_atual <= S_PARADO;
                        else
                            -- Incrementa contador enquanto porta aberta
                            contador_porta <= contador_porta + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- ==================================================================
    -- Bloco 3: Lógica de Saída (Combinacional e Concorrente)
    -- Gera todas as saídas para os periféricos externos:
    -- 1. Display de 7 segmentos
    -- 2. LEDs de direção
    -- 3. Sinal de porta aberta
    --
    -- Características:
    -- - Todas as atribuições são puramente combinacionais
    -- - Sem dependência de clock para melhor responsividade
    -- ==================================================================
    
    -- Display de 7 segmentos: mostra andar atual
    -- Usa função dedicada para decodificação
    mostrador_7seg   <= decodifica_7seg(andar_atual);
    
    -- Controle do LED de porta aberta (ativo alto)
    led_porta_aberta <= '1' when estado_atual = S_PORTA_ABERTA else '0';
    
    -- Lógica concorrente para LEDs de direção (estilo "with-select")
    -- "01" = subindo, "10" = descendo, "00" = parado/indefinido
    with estado_atual select
        leds_direcao <= "01" when S_SUBINDO,  -- Subindo
                        "10" when S_DESCENDO,  -- Descendo
                        "00" when others;      -- Parado/Porta Aberta

end architecture;
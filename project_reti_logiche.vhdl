 ----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Lorenzo Tallarico & Pietro Roggero
-- Design Name:
-- Module Name: project_reti_logiche - project_reti_logiche_arch
-- Project Name: 10719257_10719258
-- Description:
--
-- Dependencies:
--
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
port (
                i_clk   : in std_logic;
                i_rst   : in std_logic;
                i_start : in std_logic;
                i_add   : in std_logic_vector(15 downto 0);
                i_k     : in std_logic_vector(9 downto 0);

                o_done      : out std_logic;

                o_mem_addr  : out std_logic_vector(15 downto 0);
                i_mem_data  : in  std_logic_vector(7 downto 0);
                o_mem_data  : out std_logic_vector(7 downto 0);
                o_mem_we    : out std_logic;
                o_mem_en    : out std_logic
        );
end project_reti_logiche;

architecture project_reti_logiche_arch of project_reti_logiche is
    TYPE state IS (INIT, INIT_INPUT, READ, WAIT_READ, WAIT_READ2, CHOICE, WRITE_P, WRITE_C, WAIT_EN, DONE);
                        
    SIGNAL curr_state, next_state: state;
    
    SIGNAL address,     address_next        : INTEGER RANGE 0 TO 16384        := 0;
    SIGNAL count,       count_next          : INTEGER RANGE 0 TO 1024         := 0;
    SIGNAL previous,    previous_next       : INTEGER RANGE 0 TO 255          := 0;
    SIGNAL credibility, credibility_next    : INTEGER RANGE 0 TO 31           := 0;
    SIGNAL first,       first_next          : BOOLEAN                         := false;
    
    SIGNAL o_done_next                      : STD_LOGIC                       := '0';
    SIGNAL o_mem_addr_next                  : STD_LOGIC_VECTOR(15 DOWNTO 0)   := "0000000000000000";
    SIGNAL o_mem_data_next                  : STD_LOGIC_VECTOR(7 DOWNTO 0)    := "00000000" ;
    SIGNAL o_mem_we_next                    : STD_LOGIC                       := '0';
    SIGNAL o_mem_en_next                    : STD_LOGIC                       := '0';

    constant trentuno:
        INTEGER RANGE 0 TO 31 := 31;

begin
    process (i_clk, i_rst)
    begin

        if (i_rst = '1') then

            previous <= 0;
            credibility <= 0;
            address <= 0;
            count <= 0;
            first <= true;
            curr_state<=INIT;
            report "reset!";
            
        elsif(rising_edge(i_clk)) then
        
            o_done <= o_done_next;
            o_mem_we <= o_mem_we_next;
            o_mem_en <= o_mem_en_next;
            o_done<= o_done_next;
            o_mem_data <= o_mem_data_next;
            o_mem_addr <= o_mem_addr_next;
            
            previous <= previous_next;
            credibility <= credibility_next;
            address <= address_next;
            count <= count_next;
            curr_state <= next_state;
            first <= first_next;
            
        end if;
        
    end process;

    process (curr_state, previous, credibility, address, count, i_start)
    begin

        o_done_next <= '0';
        o_mem_addr_next <= "0000000000000000";
        o_mem_data_next <= "00000000";
        o_mem_we_next <= '0';
        o_mem_en_next <= '0';
        
        previous_next <= previous;
        credibility_next <= credibility;
        address_next <= address;
        count_next <= count;
        first_next <= first;
        next_state <= curr_state;
        
        case curr_state is
            when INIT =>            
                if(i_start = '1') then
                    address_next <= conv_integer(i_add);
                    count_next <= conv_integer(i_k);
                    first_next <= true;
                    credibility_next <= trentuno;
                    next_state <= INIT_INPUT;                   
                end if;
                
            when INIT_INPUT =>
                    next_state <= READ;
                    
            when READ =>
                if(count /= 0 ) then
                    o_mem_addr_next <= std_logic_vector(to_unsigned(address_next, 16));
                    o_mem_we_next <= '0';
                    o_mem_en_next <= '1';
                    next_state <= WAIT_READ;
                    
                else
                    o_done_next <= '1';
                    next_state <= DONE;
                end if;
            
            when WAIT_READ =>
                next_state <= WAIT_READ2;
            
            when WAIT_READ2 =>
                next_state <= CHOICE;
                
            when CHOICE =>
                if(conv_integer(i_mem_data) = 0) then
                    if(first = true) then
                        address_next <= address + 2;
                        next_state <= INIT_INPUT;
                        
                    else 
                        next_state <= WRITE_P;
                        
                    end if;
                else
                    previous_next <= conv_integer(i_mem_data);
                    credibility_next <= trentuno;
                    next_state <= WAIT_EN;
                    
                end if;
                count_next <= count - 1;
                
                
            when WRITE_P =>
                o_mem_addr_next <= std_logic_vector(to_unsigned(address, 16));
                o_mem_data_next <= std_logic_vector(to_unsigned(previous, 8));
                o_mem_we_next <= '1';
                o_mem_en_next <= '1';
                next_state <= WAIT_EN;
            
            when WAIT_EN =>
                first_next <= false;
                next_state <= WRITE_C;
                
            when WRITE_C =>
                o_mem_addr_next <= std_logic_vector(to_unsigned(address + 1 , 16));
                o_mem_data_next <= std_logic_vector(to_unsigned(credibility, 8));
                o_mem_we_next <= '1';
                o_mem_en_next <= '1';
                address_next <= address + 2;
                if(credibility /= 0) then
                    credibility_next <= credibility - 1;
                    
                end if;
                next_state <= INIT_INPUT;
                
            when DONE =>
                if(i_start = '0') then
                    previous_next <= 0;
                    credibility_next <= 0;
                    address_next <= 0;
                    count_next <= 0;
                    first_next <= true;
                    o_done_next <= '0';
                    next_state<=INIT;
                    
                else
                    o_done_next <= '1';
                    
                end if;
        end case;
    end process;
end architecture project_reti_logiche_arch;

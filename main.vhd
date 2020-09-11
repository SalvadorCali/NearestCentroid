library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project_reti_logiche is 
    port (
        i_clk : in std_logic;
        i_start : in std_logic;	
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    ); 
end project_reti_logiche;

architecture project of project_reti_logiche is
    type state is (RESET, START, READ_MASK, READ_X, READ_Y, EVALUATE_MASK, CALC_DISTANCE, EVALUATE_DISTANCE, READ_CENTROID_X, READ_CENTROID_Y, WRITE_MEM);

    signal current_state : state := RESET;
    signal mask : std_logic_vector(7 downto 0) := (others => '0');
    signal x : std_logic_vector(7 downto 0) := (others => '0');
    signal y : std_logic_vector(7 downto 0) := (others => '0');
    signal centroid_x : std_logic_vector(7 downto 0) := (others => '0');
    signal centroid_y : std_logic_vector(7 downto 0) := (others => '0');
    signal temp_x : std_logic_vector(7 downto 0) := (others => '0');
    signal temp_y : std_logic_vector(7 downto 0) := (others => '0');
    signal distance : std_logic_vector(8 downto 0) := (others => '0');
    signal new_distance : std_logic_vector(8 downto 0) := (others => '0');
    signal address : std_logic_vector(15 downto 0) := (others => '0');
    signal centroid_number : integer := 0;
    signal distance_boolean : bit := '0';
    signal new_distance_boolean : bit := '0';
    signal first_distance_boolean : bit := '0';
    signal o_data_boolean : bit := '0';
    signal centroid_boolean : bit := '0';

begin
    process(i_clk)
        begin 
        if falling_edge(i_clk) then
            if i_rst = '1' then
                address <= (others => '0');
                mask <= (others => '0');
                x <= (others => '0');
                y <= (others => '0');
                centroid_x <= (others => '0');
                centroid_y <= (others => '0');
                temp_x <= (others => '0');
                temp_y <= (others => '0');
                distance <= (others => '0');
                new_distance <= (others => '0');
                centroid_number <= 0;
            
                o_address <= (others => '0');
                o_done <= '0';
                o_en <= '1';
                o_we <= '0';
                o_data <= (others => '0');
                
                distance_boolean <= '0';
                new_distance_boolean <= '0';
                first_distance_boolean <= '0';
                o_data_boolean <= '0';
                centroid_boolean <= '0';
                
                current_state <= START;

            elsif (i_start = '1') and (current_state = START) then
                o_done <= '0';
                o_we <= '0';
                address <= "0000000000000000";
                o_address <= "0000000000000000";
                
                current_state <= READ_MASK;

            else
                case current_state is
                    when RESET =>
                        current_state <= RESET;
                        
                    when START =>
                        o_done <= '0';
                        o_we <= '0';
                        
                        current_state <= START; 
                               
                    when READ_MASK =>
                        mask <= i_data;
                        address <= "0000000000010001";
                        o_address <= "0000000000010001";
                        
                        current_state <= READ_X;
                        
                    when READ_X =>
                        x <= i_data;
                        address <= "0000000000010010";
                        o_address <= "0000000000010010";
                        
                        current_state <= READ_Y;

                    when READ_Y =>
                        y <= i_data;
                        address <= "0000000000000001";
                        o_address <= "0000000000000001";
                        
                        current_state <= EVALUATE_MASK;

                    when EVALUATE_MASK =>
                        if(centroid_number > 7) then
                            current_state <= WRITE_MEM;
                            
                        else
                            if(mask(centroid_number) = '0') then
                                address <= std_logic_vector(unsigned(address) + "0000000000000010");
                                o_address <= std_logic_vector(unsigned(address) + "0000000000000010");
                                centroid_number <= centroid_number + 1;
                                current_state <= EVALUATE_MASK;
                            else
                                current_state <= READ_CENTROID_X;
                            end if;
                        end if;

                    when READ_CENTROID_X =>
                        centroid_x <= i_data;
                        address <= std_logic_vector(unsigned(address) + "0000000000000001");
                        o_address <= std_logic_vector(unsigned(address) + "0000000000000001");
                      
                        current_state <= READ_CENTROID_Y;

                    when READ_CENTROID_Y =>
                        centroid_y <= i_data;
                        address <= std_logic_vector(unsigned(address) + "0000000000000001");
                        o_address <= std_logic_vector(unsigned(address) + "0000000000000001");
                        current_state <= CALC_DISTANCE;
                        
                    when CALC_DISTANCE =>
                        if(x >= centroid_x) then
                            temp_x <= std_logic_vector(unsigned(x) - unsigned(centroid_x));
                        else
                            temp_x <= std_logic_vector(unsigned(centroid_x) - unsigned(x));
                        end if;
                        if(y >= centroid_y) then
                            temp_y <= std_logic_vector(unsigned(y) - unsigned(centroid_y));
                        else
                            temp_y <= std_logic_vector(unsigned(centroid_y) - unsigned(y));
                        end if;
                        
                        current_state <= EVALUATE_DISTANCE;
                        
                    when EVALUATE_DISTANCE =>
                        if(distance_boolean = '0') then
                            new_distance <= std_logic_vector(unsigned('0' & temp_x) + unsigned('0' & temp_y));
                            distance_boolean <= '1';
                            current_state <= EVALUATE_DISTANCE;
                        else
                            if(o_data_boolean = '0') then
                                if(new_distance < distance) or (first_distance_boolean = '0') then
                                    first_distance_boolean <= '1';
                                    distance <= new_distance;
                                    o_data <= (others => '0');
                                    new_distance_boolean <= '1';
                                elsif(new_distance = distance) then
                                    new_distance_boolean <= '1';
                                end if;
                                o_data_boolean <= '1';
                                current_state <= EVALUATE_DISTANCE;
                            else
                                if(new_distance_boolean = '1') then
                                    o_data(centroid_number) <= '1';
                                    new_distance_boolean <= '0';
                                end if;
                                if(centroid_boolean = '0') then
                                    centroid_boolean <= '1';
                                else
                                    centroid_number <= centroid_number + 1;
                                    centroid_boolean <= '0';
                                    distance_boolean <= '0';
                                    o_data_boolean <= '0';
                                    current_state <= EVALUATE_MASK;
                                end if;
                            end if;
                        end if;

                    when WRITE_MEM =>
                        o_address <= "0000000000010011";
                        address <= "0000000000010011";
                        
                        o_en <= '1';
                        o_we <= '1';
                        o_done <= '1';
                        
                        centroid_number <= 0;
                        distance <= (others => '0');
                        new_distance <= (others => '0');
                        
                        distance_boolean <= '0';
                        new_distance_boolean <= '0';
                        first_distance_boolean <= '0';
                        o_data_boolean <= '0';
                        centroid_boolean <= '0';
                        
                        current_state <= START;
                        
                end case;
            end if;
        end if;
    end process;
end project;
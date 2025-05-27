library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Define signed_matrix type
package Image_Types is
	type signed_matrix is array (1 to 3, 1 to 3) of signed;
end package;

use work.Image_Types.all;

entity TopModule is
	Generic (
		pictureWidth	: natural;
		pictureHeight	: natural;
		coefWidth		: natural
	);
	Port ( 
		clk				: in STD_LOGIC;

		coef			: in signed_matrix(1 to 3, 1 to 3)(coefWidth - 1 downto 0);
		inverse_divisor : in unsigned(16 downto 0);
		threshold		: in unsigned(13 downto 0);
		syncIn			: in STD_LOGIC;

		pixelIn			: in unsigned(7 downto 0);
		inputRdy		: in STD_LOGIC;

		pixelOut		: out STD_LOGIC;
		outputRdy		: out STD_LOGIC
	);
end TopModule;

architecture Behavioral of TopModule is

	-- Internal buffers and control signals
	signal kernel_result      : unsigned(15 downto 0);  -- Output from KernelConvolver
	signal edge_result        : unsigned(13 downto 0);  -- Output from SobelFilter
	signal thresholded_pixel  : STD_LOGIC;
	signal config_loaded      : STD_LOGIC := '0';

	-- Signals for buffering, pipeline control, etc.
	signal buffer_full_noise  : STD_LOGIC;
	signal buffer_full_edge   : STD_LOGIC;

	-- Internal control signals for valid data transfer
	signal valid_noise_in     : STD_LOGIC;
	signal valid_edge_in      : STD_LOGIC;

	-- Configuration registers
	signal coef_reg           : signed_matrix(1 to 3, 1 to 3)(coefWidth - 1 downto 0);
	signal inv_div_reg        : unsigned(16 downto 0);
	signal threshold_reg      : unsigned(13 downto 0);

begin

	-- Configuration load logic
	process(clk)
	begin
		if rising_edge(clk) then
			if syncIn = '1' then
				coef_reg      <= coef;
				inv_div_reg   <= inverse_divisor;
				threshold_reg <= threshold;
				config_loaded <= '1';
			end if;
		end if;
	end process;

	-- Noise Reduction Module
	NoiseReduction : entity work.KernelConvolver
		generic map (
			pictureWidth  => pictureWidth,
			pictureHeight => pictureHeight,
			coefWidth     => coefWidth
		)
		port map (
			clk           => clk,
			pixelIn       => pixelIn,
			inputRdy      => inputRdy,
			coef          => coef_reg,
			inverse_div   => inv_div_reg,
			syncIn        => syncIn,
			pixelOut      => kernel_result,
			outputRdy     => valid_noise_in
		);

	-- Edge Detection Module
	EdgeDetect : entity work.SobelFilter
		generic map (
			pictureWidth  => pictureWidth - 4,
			pictureHeight => pictureHeight - 4
		)
		port map (
			clk           => clk,
			pixelIn       => kernel_result,
			inputRdy      => valid_noise_in,
			syncIn        => syncIn,
			pixelOut      => edge_result,
			outputRdy     => valid_edge_in
		);

	-- Thresholding and Output logic
	process(clk)
	begin
		if rising_edge(clk) then
			if syncIn = '1' then
				outputRdy <= '0';
			elsif valid_edge_in = '1' then
				if edge_result < threshold_reg then
					pixelOut <= '0';
				else
					pixelOut <= '1';
				end if;
				outputRdy <= '1';
			else
				outputRdy <= '0';
			end if;
		end if;
	end process;

end Behavioral;

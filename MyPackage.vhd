library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package MyPackage is
    type unsigned_array is array (natural range <>) of unsigned;
    type unsigned_matrix is array (natural range <>) of unsigned_array;
	
    type signed_array is array (natural range <>) of signed;
    type signed_matrix is array (natural range <>) of signed_array;
end package MyPackage;

# IPv6 DASH/SHELL/BASH Libs
IPv6 lib for check, compress, uncompress, remove leading 0s and get the first IP address for IPv6 using only Bash or Dash/Shell commands.

This lib is intended to be use in BASH or DASH/SHELL scripts for routers to calculate for exampe SIT6 tunnel addresses.

It doesn't use external tools like "tr" or "sed". It intended to use only BASH or DASH/SHELL builtin functions to be as portable as possible.

I've tried to use simple approach using simple IPv6 rules and to use as much loops as possible.

# Short story
This library I've created because I couldn't find anything written for BASH or DASH. Each time I had to write a BASH and DASH script to work with IPv6 I've faced issues to work with it.

## ipv6_check()
Check if a string has IPv6 format using these rules:
1. Check if we have more than 2 consecutive compression delimiters ":". Returns 1 if is true.
2. Check if the IPv6 contains only allowed characters: 0-9, a-f, A-F and :. Returns 2 if is true.
2. Search for sub-blocks and count them.
3. If there are more the 8 sub-blocks, there is an invalid IPv6 format. Returns 3 is if true.
4. Check if the sub-block value is greater than 0xFFFF. Returns 4 if is true.
5. Returns 0 in case is it a valid IPv6 format.

## ipv6_compress()
Compress IPv6 using these rules to compress:
1. Check if is an IPv6 format using ipv6_check().
2. Check if we have a compression delimiter. If true, return the same IPv6.
3. Search for sub-blocks.
4. Count consecutive zeros sub-blocks.
5. Store each time we found a 0 sub-block and store start index.
6. Each time we find a 0 sub-block, we store the end index, until we find a non-zero sub-block.
7. Search for the remaining sub-blocks.
8. If we find a higher number of consecutive zero sub-blocks, store these start and end indexes.
9. Go through the the IPv6 until we match "start" zero sub-block.
10. Skip the next zero sub-blocks until we match "end" index of the last zero sub-block.
11. Continue to add the rest of the IPv6.
12. Return to console or in a variable the resulted compressed IPv6 with removed 0s leading.

## ipv6_decompress()
Uncompress IPv6 using these rules:
1. Check if is an IPv6 format using ipv6_check().
2. Check if we have "::". Automatically expand to "0:0:0:0:0:0:0:0".
3. Get the number of sub-blocks.
4. Split the IPv6 in 2 parts, IPv6 FRONT and IPv6 REAR, using compression delimiter "::"
5. Check if there is a compression, comparing the 2 strings.
6. Count how many sub-blocks IPv6 FRONT and REAR they have.
7. Add all front sub-blocks the delimiter to a the uncompressed IPv6.
8. Fill with zero sub-groups the difference of (8 - front_sub-blocks - rear_sub-blocks).
8. Add all rear sub-blocks the delimiter to a the uncompressed IPv6.
5. Return to console or in a variable the resulted uncompressed IPv6 with removed 0s leading.

## ipv6_leading_zero_compression()
Remove leading 0s of IPv6 using these rules:
1. Check if is an IPv6 format using ipv6_check().
2. Split the IPv6 in 2 parts, IPv6 FRONT and IPv6 REAR, using compression delimiter "::".
3. Search for IPv6 FRONT sub-blocks.
4. In case we don't have compression, return the string.
5. In case we have compression, add a ":".
6. Search for IPv6 REAR sub-blocks.
7. Return to console or in a variable the resulted IPv6 with removed 0s leading.

## ipv6_first_subnet_address()
Returns the first IPv6 address of a prefix. The format must be given like IPv6/PREFIX, where PREFIX is between 1 and 128.
To simplify the maths, we are using a list which contains 16 types of prefix masks and we will map prefixes from 0 to 15 to this array
The array will contain:
  0x0000 (0000000000000000b), 0x8000 (1000000000000000b), 0xC000 (1100000000000000b), 0xE000 (1110000000000000b), 0xF000 (1111000000000000b), 0xF800 (1111100000000000b), 0xFC00 (1111110000000000b), 0xFE00 (1111111000000000b), 0xFF00 (1111111100000000b), 0xFF80 (1111111110000000b), 0xFFC0 (1111111111000000b), 0xFFE0 (1111111111100000b), 0xFFF0 (1111111111110000b), 0xFFF8 (1111111111111000b), 0xFFFC (1111111111111100b), 0xFFFE (1111111111111110b)
We are using 16 bits of mask because IPv6 has sub-blocks of 16 bits and will be easy to map each prefix sub-block to each uncompressed IPv6 sub-block.

We will split the prefix in groups of 16 and reminder.
For example:
	Prefix 28: 28/16 = 1 and reminder 12. We will have only one group of 16 bits which by default will be 0xFFFF and second group will be 12 bits mapped to 0xFFF0 nd the reset 0x0000.
	Prefix 48: 42/16 = 2 and reminder 10. We will have only two groups of 16 bits which by default will be 0xFFFF and third group will be 10 bits mapped to 0xFFC0 nd the reset 0x0000.

1. Uncompress IPv6 and also is doing ipv6_check.
2. Walk through the uncompressed sub-blocks IPv6.
3. Copy first PREFIX/16 sub-blocks.
4. If for the next sub-block the result of PREFIX%16 (modulo) is greater than 0, get the next sub-block and find the PREFIX from PREFIX MAP using the reminder of PREFIX%16 as index. Then calculate the new sub-block by using AND bitwise between sub-block and the sub-block prefix.
5. Continue to add 0x0000 up the rest of the IPv6.
6. Compress the resulted IPv6, skipping the ipv6_check().
6. Return to  console or in a variable the resulted IPv6 with removed 0s leading.

# IPv6-BASH-Tools
IPv6 tools for check, compress, uncompress and remove leading 0s in IPv6 using only Bash commands.

This tool is intended to be use in BASH scripts for routers to calculate for exampe SIT6 tunnel addresses.

I've tried to use simple approach using simple IPv6 rules.

# Short story
This library I've created because I couldn't find anything written for BASH. Each time I had to write a BASH script to work with IPv6 I've faced issues to work with it.

## ipv6_compression()
Compress IPv6 using these rules to compress:
1. Search for sub-blocks.
2. Check if all characters of the sub-block are hexa [0-9a-fA-F].
3. Search for longest 0s continuous zeros sub-blocks.
4. Compress only the longest 0s continuous zeros sub-blocks of IPv6.
5. Return to console or in a variable the resulted IPv6 with removed 0s leading.

## ipv6_uncompress()
Uncompress IPv6 using these rules:
1. Search for compressed delimiter "::"
2. Load all sub-blocks before the delimiter in an array and check if all characters are hexa [0-9a-fA-F].
3. Load all sub-block after the delimiter in an array and check if all characters are hexa [0-9a-fA-F].
4. Compute the uncompressed IPv6 adding a number of (8 - before_sub-blocks - after_sub-blocks) of sub-blocks of 0s between "before sub-blocks" and "after sub-blocks"
5. Return to console or in a variable the resulted IPv6 with removed 0s leading.

## ipv6_leading_zero_compression()
Remove leading 0s of IPv6 using these rules:
1. Search for each IPv6 sub-blocks
2. Check if all characters of the sub-block are hexa [0-9a-fA-F].
3. Write each block in hexa.
4. Compute the new IPv6.
5. Return to console or in a variable the resulted IPv6 with removed 0s leading.

## ipv6_check()
Check if a string has IPv6 format using these rules:
1. Search for sub-blocks.
2. Check if all characters of the sub-block are hexa [0-9a-fA-F].
3. Check if we have multiple compression delimiters "::", returns 1
4. Check if we have more than 8 sub-blocks, returns 1
5. Check if we have 8 sub-blocks plus compression delimiter "::", returns 1
6. Check if we have less than 8 sub-blocks without compression delimiter "::", returns 1
7. Returns 0 in case is it a valid IPv6 format.

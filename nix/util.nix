{ pkgs }:

rec {
  portFromString = string:
    let
      hash = builtins.hashString "sha256" string;
      portHex = builtins.substring 0 4 hash;
      portHexChars = pkgs.lib.strings.stringToCharacters portHex;
      hexDigitToNum = n:
        let
          map = {
            "0" = 0;
            "1" = 1;
            "2" = 2;
            "3" = 3;
            "4" = 4;
            "5" = 5;
            "6" = 6;
            "7" = 7;
            "8" = 8;
            "9" = 9;
            "a" = 10;
            "b" = 11;
            "c" = 12;
            "d" = 13;
            "e" = 14;
            "f" = 15;
          };
        in map.${n};
      portFromHash =
        pkgs.lib.lists.foldl (prev: n: (hexDigitToNum n) + (prev * 16)) 0
        portHexChars;
    in if portFromHash <= 1024 then
      portFromString "retry_${string}"
    else
      portFromHash;
}

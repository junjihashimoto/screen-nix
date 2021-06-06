{
  description = "Screen";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-20.03;
    sixel-gnuscreen = {
      url = github:csdvrx/sixel-gnuscreen/sixel;
      flake = false;
    };
  };

  outputs = { self, nixpkgs , sixel-gnuscreen }: {

    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux"; };
      # The original code is here.
      # https://github.com/NixOS/nixpkgs/blob/8284fc30c84ea47e63209d1a892aca1dfcd6bdf3/pkgs/tools/misc/screen/default.nix
      let screenrc = ./.;
      in
        stdenv.mkDerivation rec {
          pname = "screen";
          version = "4.2.1";
  
          srcs = [
            ( let lock = builtins.fromJSON (builtins.readFile ./flake.lock);
              in fetchTarball {
                url = "https://github.com/csdvrx/sixel-gnuscreen/archive/${lock.nodes.sixel-gnuscreen.locked.rev}.tar.gz";
                sha256 = lock.nodes.sixel-gnuscreen.locked.narHash;
                name = pname;
              })
            screenrc
          ];
          sourceRoot = pname;
  
          configureFlags= [
            "--enable-telnet"
            "--enable-pam"
            "--enable-colors256"
          ];
  
#            "--with-sys-screenrc=${out}/default-screenrc"
          # patches = [
          #   (fetchpatch {
          #     # Fixes denial of services in encoding.c, remove > 4.8.0
          #     name = "CVE-2021-26937.patch";
          #     url = "https://salsa.debian.org/debian/screen/-/raw/master/debian/patches/99_CVE-2021-26937.patch";
          #     sha256 = "05f3p1c7s83nccwkhmavjzgaysxnvq41c7jffs31ra65kcpabqy0";
          #   })
          # ];
  
          postPatch = lib.optionalString (stdenv.buildPlatform != stdenv.hostPlatform)
            # XXX: Awful hack to allow cross-compilation.
            '' 
            sed -i ./configure -e 's/^as_fn_error .. \("cannot run test program while cross compiling\)/$as_echo \1/g'
            ''; # "
  
          buildInputs =
            [ ncurses ]
            # ++ lib.optional stdenv.isDarwin utmp
            ++ lib.optional stdenv.isLinux pam;

          installPhase = ''
             echo "install"
             make install
             mkdir $out/etc
             cp ${screenrc}/default-screenrc $out/etc/screenrc
          '';

          doCheck = true;
  
          meta = with lib; {
            homepage = "https://www.gnu.org/software/screen/";
            description = "A window manager that multiplexes a physical terminal";
            license = licenses.gpl2Plus;
  
            longDescription =
                    '' GNU Screen is a full-screen window manager that multiplexes a physical
           terminal between several processes, typically interactive shells.
           Each virtual terminal provides the functions of the DEC VT100
           terminal and, in addition, several control functions from the ANSI
           X3.64 (ISO 6429) and ISO 2022 standards (e.g., insert/delete line
           and support for multiple character sets).  There is a scrollback
           history buffer for each virtual terminal and a copy-and-paste
           mechanism that allows the user to move text regions between windows.
           When screen is called, it creates a single window with a shell in it
           (or the specified command) and then gets out of your way so that you
           can use the program as you normally would.  Then, at any time, you
           can create new (full-screen) windows with other programs in them
           (including more shells), kill the current window, view a list of the
           active windows, turn output logging on and off, copy text between
           windows, view the scrollback history, switch between windows, etc.
           All windows run their programs completely independent of each other.
           Programs continue to run when their window is currently not visible
           and even when the whole screen session is detached from the users
           terminal.
        '';
  
            platforms = platforms.unix;
            maintainers = with maintainers; [ peti vrthra ];
          };
        };
  };
}

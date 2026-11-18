{ pkgs, perSystem, ... }:
perSystem.devshell.mkShell {
    name = "enae601-hw05 devshell";
    motd = ''
        {141}📚 enae601-hw05{reset} devshell
        $(type -p menu &>/dev/null && menu)
    '';

    commands = [
        # helpers
        ## python
        {
            name = "pyr";
            category = "[python]";
            help = "run";
            command = "python ./submission.py $@";
        }
        {
            name = "pyl";
            category = "[python]";
            help = "lsp";
            command = "ty check -W src $@";
        }
        ## typst
        {
            name = "typ";
            category = "[typst]";
            help = "preview";
            command = "tinymist preview reports/main.typ --root=.";
        }
        {
            name = "tyl";
            category = "[typst]";
            help = "lsp";
            # command = "tinymist test --no-dashboard --ignore-system-fonts --watch reports/main.typ --root=.";
            command =
                # bash
                ''
                    p=$PWD
                    cd /tmp
                    tinymist test --no-dashboard --ignore-system-fonts --watch "$p/reports/main.typ" --root="$p"
                '';
        }
        {
            name = "tyc";
            category = "[typst]";
            help = "compile";
            # command = "nix run .#report";
            command = "tinymist compile reports/main.typ --root=.";
        }
    ];

    packages = with pkgs; [
        # python
        # WARN: python3 is overriden to unstable as python3Packages.cartopy is broken on release-26.05
        # https://github.com/NixOS/nixpkgs/issues/516636
        (perSystem.nixpkgs-unstable.python3.withPackages (
            # WARN: python packages are installed via uv instead of nix (tellurion isn't in nixpkgs, only pip)
            ps: with ps; [
                # dev packages
                uv
            ]
        ))

        # typst
        tinymist
        hayagriva
    ];

    devshell.startup = {
        activate-venv.text =
            # bash
            ''
                BLUE=$'\e[34m'
                GREEN=$'\e[32m'
                RED=$'\e[31m'
                RESET=$'\e[0m'

                if ! source .venv/bin/activate 2> /dev/null; then
                    echo "uv: ''${RED}no virtual environment found!''${RESET}"
                    echo "uv: creating virtual environment in ''${BLUE}.venv''${RESET}"
                    uv venv --clear && source .venv/bin/activate
                fi
                echo "uv: loaded virtual environment from ''${BLUE}.venv''${RESET}"
            '';
        install-py-packages.text =
            # bash
            ''
                uv pip install ty tellurion matplotlib
            '';
    };

    env = [
        {
            name = "TYPST_FONT_PATHS";
            prefix =
                with pkgs;
                lib.makeSearchPath "share/fonts/opentype" [
                    newcomputermodern
                    tex-gyre.cursor
                    tex-gyre.termes
                    nerd-fonts.iosevka-term
                ];
        }
    ];
}

{
  description = "minimal nixvim rust flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    nixvim = {
      url = "github:nix-community/nixvim";
    };
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    nixvim,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustToolchain = (pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml).override {
          extensions = ["rust-src"];
        };
        nvim = nixvim.legacyPackages.x86_64-linux.makeNixvim {
          extraPackages = with pkgs; [
            gnutar
            curl
            gcc_multi
            vscode-extensions.vadimcn.vscode-lldb.adapter
          ];
          plugins = {
            lsp = {
              enable = true;
            };
            treesitter = {
              enable = true;
            };
            dap = {
              enable = true;
              extensions = {
                dap-ui = {
                  enable = true;
                };
                dap-virtual-text = {
                  enable = true;
                };
              };
            };
            rustaceanvim = {
              enable = true;
              dap = {
                autoloadConfigurations = true;
              };
            };
          };
        };
        nativeBuildInputs = with pkgs; [
          rustToolchain
          pkg-config
        ];
        buildInputs = with pkgs; [
          rust-analyzer
          nvim
        ];
      in
        with pkgs; {
          devShells.default = mkShell {
            inherit buildInputs nativeBuildInputs;
            RUST_BACKTRACE = 1;
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          };
        }
    );
}

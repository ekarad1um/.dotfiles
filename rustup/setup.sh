
set -o errexit -o pipefail

rustup update
rustup component add rust-src
rustup component add rust-analyzer
rustup component add clippy

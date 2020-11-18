DIR="$( dirname "${BASH_SOURCE[0]}" )"

cd $DIR
swift build -c release
cp .build/release/battlesnake build/battlesnake
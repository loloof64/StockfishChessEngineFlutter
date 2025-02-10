// Taken from https://github.com/jusax23/flutter_stockfish_plugin

#include "stream_fix.h"

bool FakeStream::try_get_line(std::string& val) {
    std::unique_lock<std::mutex> lock(mutex_guard);
    if (string_queue.empty() || closed) return false;
    val = string_queue.front();
    string_queue.pop();
    return true;
}

void FakeStream::close() {
    std::lock_guard<std::mutex> lock(mutex_guard);
    closed = true;
    mutex_signal.notify_one();
}
bool FakeStream::is_closed() { return closed; }

std::streambuf* FakeStream::rdbuf() { return nullptr; }

std::streambuf* FakeStream::rdbuf(std::streambuf* buf) { return nullptr; }

bool std::getline(FakeStream& is, std::string& str) {
    if (is.is_closed()) return false;
    is >> str;
    if (is.is_closed()) return false;
    return true;
}

FakeStream fakeout;
FakeStream fakein;
FakeStream fakeerr;
std::string fakeendl("\n");
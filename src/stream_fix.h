// Taken from https://github.com/jusax23/flutter_stockfish_plugin

#ifndef _STREAM_FIX_H_
#define _STREAM_FIX_H_
#include <condition_variable>
#include <iostream>
#include <mutex>
#include <queue>
#include <sstream>

template <typename T>
inline std::string stringify(const T& input) {
    std::ostringstream output;  // from   www  .ja va  2s  . com
    output << input;
    return output.str();
}

class FakeStream {
   public:
    template <typename T>
    FakeStream& operator<<(const T& val) {
        if (closed) return *this;
        std::lock_guard<std::mutex> lock(mutex_guard);
        string_queue.push(stringify(val));
        mutex_signal.notify_one();
        return *this;
    };
    template <typename T>
    FakeStream& operator>>(T& val) {
        if (closed) return *this;
        std::unique_lock<std::mutex> lock(mutex_guard);
        mutex_signal.wait(lock,
                          [this] { return !string_queue.empty() || closed; });
        if (closed) return *this;
        val = string_queue.front();
        string_queue.pop();
        return *this;
    };

    bool try_get_line(std::string& val);

    void close();
    bool is_closed();

    std::streambuf* rdbuf();
    std::streambuf* rdbuf(std::streambuf* __sb);

   private:
    bool closed = false;
    std::queue<std::string> string_queue;
    //std::string line;
    std::mutex mutex_guard;
    std::condition_variable mutex_signal;
};

namespace std {
bool getline(FakeStream& is, std::string& str);
}  // namespace std

// #define endl fakeendl
// #define cout fakeout
// #define cin fakein

extern FakeStream fakeout;
extern FakeStream fakein;
extern std::string fakeendl;

#endif
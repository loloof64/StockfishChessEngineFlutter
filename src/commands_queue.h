#ifndef __COMMANDS_QUEUE_H
#define __COMMANDS_QUEUE_H

#include <deque>
#include <mutex>
#include <string>
#include <optional>

class CommandsQueue {
private: 
    std::mutex mutex_;
    std::deque<std::string> values_;

protected:
    CommandsQueue(){}
    ~CommandsQueue(){}

public:
    CommandsQueue(const CommandsQueue&) = delete;
    CommandsQueue& operator=(const CommandsQueue&) = delete;

    void send(const std::string &command);
    std::optional<std::string> receive();
};

class OutputsQueue : public CommandsQueue {
public:
    static OutputsQueue& getInstance();
};

class InputsQueue : public CommandsQueue {
public:
    static InputsQueue& getInstance();
};
#endif
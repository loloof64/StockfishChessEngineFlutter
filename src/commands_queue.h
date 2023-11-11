#ifndef __COMMANDS_QUEUE_H
#define __COMMANDS_QUEUE_H

#include <deque>
#include <mutex>
#include <string>
#include <optional>

class CommandsQueue {
private: 
    std::mutex commands_inputs_mutex_;
    std::mutex commands_outputs_mutex_;
    std::deque<std::string> commands_inputs_;
    std::deque<std::string> commands_outputs_;

protected:
    CommandsQueue(){}
    ~CommandsQueue(){}

public:
    CommandsQueue(const CommandsQueue&) = delete;
    CommandsQueue& operator=(const CommandsQueue&) = delete;
    static CommandsQueue& getInstance();

    void send_command_input(const std::string &command);
    std::optional<std::string> receive_command_input();
    void send_command_output(const std::string &output);
    std::optional<std::string> receive_command_output();
};
#endif
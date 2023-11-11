#include "commands_queue.h"

CommandsQueue& CommandsQueue::getInstance() {
    static CommandsQueue instance;
    return instance;
}

void CommandsQueue::send_command_input(const std::string &command) {
    std::lock_guard<std::mutex> lock(commands_inputs_mutex_);
    commands_inputs_.push_back(command);
}

std::optional<std::string> CommandsQueue::receive_command_input() {
    std::lock_guard<std::mutex> lock(commands_inputs_mutex_);
    if (commands_inputs_.empty()) {
        return std::nullopt;
    }
    else {
        auto command = commands_inputs_.front();
        commands_inputs_.pop_front();
        std::optional result(command);
        return result;
    }
}

void CommandsQueue::send_command_output(const std::string &output) {
    std::lock_guard<std::mutex> lock(commands_outputs_mutex_);
    commands_outputs_.push_back(output);
}

std::optional<std::string> CommandsQueue::receive_command_output() {
    std::lock_guard<std::mutex> lock(commands_outputs_mutex_);
    if (commands_outputs_.empty()) {
        return std::nullopt;
    }
    else {
        std::string output = commands_outputs_.front();
        commands_outputs_.pop_front();
        std::optional result(output);
        return result;
    }
}
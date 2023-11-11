#include "commands_queue.h"

void CommandsQueue::send(const std::string &command) {
    std::lock_guard<std::mutex> lock(mutex_);
    values_.push_back(command);
}

std::optional<std::string> CommandsQueue::receive() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (values_.empty()) {
        return std::nullopt;
    }
    else {
        auto command = values_.front();
        values_.pop_front();
        std::optional result(command);
        return result;
    }
}

InputsQueue& InputsQueue::getInstance() {
    static InputsQueue instance;
    return instance;
}

OutputsQueue& OutputsQueue::getInstance() {
    static OutputsQueue instance;
    return instance;
}
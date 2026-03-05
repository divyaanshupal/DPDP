// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AppEventLog {
    uint256 public total;

    event AppEvent(
        string event_type,
        string user_type,
        string uuid,
        string metadata,
        uint256 timestamp
    );

    function log(
        string calldata event_type,
        string calldata user_type,
        string calldata uuid,
        string calldata metadata
    ) external {
        emit AppEvent(event_type, user_type, uuid, metadata, block.timestamp);
        total++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Committee} from "./Committee.sol";

contract CommitteeDeployer {
    function deployCommittee(
        Committee.CommitteeConfig memory config,
        Committee.ExternalContracts memory contracts,
        address multiSigAccount
    ) external returns (address committee) {
        committee = address(new Committee(config, contracts, multiSigAccount));
    }
}

interface ICommitteeDeployer {
    function deployCommittee(
        Committee.CommitteeConfig calldata config,
        Committee.ExternalContracts calldata contracts,
        address multiSigAccount
    ) external returns (address);
}

// SPDX-License-Identifier: UNTITLED
pragma solidity >=0.8.0;

import "@perimetersec/fuzzlib/src/FuzzBase.sol";
import "forge-std/Test.sol";

contract FuzzActors is FuzzBase, Test {
    address internal constant owner = address(0xfffff);

    address internal constant USER1 = address(0x10000);
    address internal constant USER2 = address(0x20000);
    address internal constant USER3 = address(0x30000);

    address[] internal USERS = [USER1, USER2, USER3];

    address internal recipient = address(0x40000);
    address internal recipientTwo = address(0x50000);
    address internal emergency = address(0x60000);
    address internal admin = address(0x70000);
    address internal HEART = address(0x80000);
    address internal OPERATOR = address(0x90000);
}

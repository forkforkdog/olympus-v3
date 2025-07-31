// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 >=0.8.15 ^0.8 ^0.8.0 ^0.8.15 ^0.8.4;

// dependencies/clones-with-immutable-args-1.1.2/src/Clone.sol

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset) internal pure returns (address arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(
        uint256 argOffset,
        uint64 arrLen
    ) internal pure returns (uint256[] memory arr) {
        uint256 offset = _getImmutableArgsOffset();
        uint256 el;
        arr = new uint256[](arrLen);
        for (uint64 i = 0; i < arrLen; i++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                el := calldataload(add(add(offset, argOffset), mul(i, 32)))
            }
            arr[i] = el;
        }
        return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset) internal pure returns (uint64 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }
}

// dependencies/clones-with-immutable-args-1.1.2/src/ClonesWithImmutableArgs.sol

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth, nick.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    /// @dev The CREATE3 proxy bytecode.
    uint256 private constant _CREATE3_PROXY_BYTECODE = 0x67363d3d37363d34f03d5260086018f3;

    /// @dev Hash of the `_CREATE3_PROXY_BYTECODE`.
    /// Equivalent to `keccak256(abi.encodePacked(hex"67363d3d37363d34f03d5260086018f3"))`.
    bytes32 private constant _CREATE3_PROXY_BYTECODE_HASH =
        0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    error CreateFail();
    error InitializeFail();

    enum CloneType {
        CREATE,
        CREATE2,
        PREDICT_CREATE2
    }

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(
        address implementation,
        bytes memory data
    ) internal returns (address payable instance) {
        return clone(implementation, data, 0);
    }

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @param value The amount of wei to transfer to the created clone
    /// @return instance The address of the created clone
    function clone(
        address implementation,
        bytes memory data,
        uint256 value
    ) internal returns (address payable instance) {
        bytes memory creationcode = getCreationBytecode(implementation, data);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            instance := create(value, add(creationcode, 0x20), mload(creationcode))
        }
        if (instance == address(0)) {
            revert CreateFail();
        }
    }

    /// @notice Creates a clone proxy of the implementation contract, with immutable args,
    ///         using CREATE2
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone2(
        address implementation,
        bytes memory data
    ) internal returns (address payable instance) {
        return clone2(implementation, data, 0);
    }

    /// @notice Creates a clone proxy of the implementation contract, with immutable args,
    ///         using CREATE2
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @param value The amount of wei to transfer to the created clone
    /// @return instance The address of the created clone
    function clone2(
        address implementation,
        bytes memory data,
        uint256 value
    ) internal returns (address payable instance) {
        bytes memory creationcode = getCreationBytecode(implementation, data);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            instance := create2(value, add(creationcode, 0x20), mload(creationcode), 0)
        }
        if (instance == address(0)) {
            revert CreateFail();
        }
    }

    /// @notice Computes the address of a clone created using CREATE2
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the clone
    function addressOfClone2(
        address implementation,
        bytes memory data
    ) internal view returns (address payable instance) {
        bytes memory creationcode = getCreationBytecode(implementation, data);
        bytes32 bytecodeHash = keccak256(creationcode);
        instance = payable(
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(bytes1(0xff), address(this), bytes32(0), bytecodeHash)
                        )
                    )
                )
            )
        );
    }

    /// @notice Computes bytecode for a clone
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return ret Creation bytecode for the clone contract
    function getCreationBytecode(
        address implementation,
        bytes memory data
    ) internal pure returns (bytes memory ret) {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x41 + extraLength;
            uint256 runSize = creationSize - 10;
            uint256 dataPtr;
            uint256 ptr;

            // solhint-disable-next-line no-inline-assembly
            assembly {
                ret := mload(0x40)
                mstore(ret, creationSize)
                mstore(0x40, add(ret, creationSize))
                ptr := add(ret, 0x20)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (10 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 61 runtime  | PUSH2 runtime (r)     | r                             | –
                mstore(ptr, 0x6100000000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x01), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0a
                // 3d          | RETURNDATASIZE        | 0 r                           | –
                // 81          | DUP2                  | r 0 r                         | –
                // 60 creation | PUSH1 creation (c)    | c r 0 r                       | –
                // 3d          | RETURNDATASIZE        | 0 c r 0 r                     | –
                // 39          | CODECOPY              | 0 r                           | [0-runSize): runtime code
                // f3          | RETURN                |                               | [0-runSize): runtime code

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME (55 bytes + extraLength)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                             | –
                // 3d          | RETURNDATASIZE        | 0 0                           | –
                // 3d          | RETURNDATASIZE        | 0 0 0                         | –
                // 3d          | RETURNDATASIZE        | 0 0 0 0                       | –
                // 36          | CALLDATASIZE          | cds 0 0 0 0                   | –
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0                 | –
                // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0               | –
                // 37          | CALLDATACOPY          | 0 0 0 0                       | [0, cds) = calldata
                // 61          | PUSH2 extra           | extra 0 0 0 0                 | [0, cds) = calldata
                mstore(
                    add(ptr, 0x03),
                    0x3d81600a3d39f33d3d3d3d363d3d376100000000000000000000000000000000
                )
                mstore(add(ptr, 0x13), shl(240, extraLength))

                // 60 0x37     | PUSH1 0x37            | 0x37 extra 0 0 0 0            | [0, cds) = calldata // 0x37 (55) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x37 extra 0 0 0 0        | [0, cds) = calldata
                // 39          | CODECOPY              | 0 0 0 0                       | [0, cds) = calldata, [cds, cds+extra) = extraData
                // 36          | CALLDATASIZE          | cds 0 0 0 0                   | [0, cds) = calldata, [cds, cds+extra) = extraData
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+extra) = extraData
                mstore(
                    add(ptr, 0x15),
                    0x6037363936610000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0 0             | [0, cds) = calldata, [cds, cds+extra) = extraData
                // 3d          | RETURNDATASIZE        | 0 cds+extra 0 0 0 0           | [0, cds) = calldata, [cds, cds+extra) = extraData
                // 73 addr     | PUSH20 0x123…         | addr 0 cds+extra 0 0 0 0      | [0, cds) = calldata, [cds, cds+extra) = extraData
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds+extra 0 0 0 0  | [0, cds) = calldata, [cds, cds+extra) = extraData
                // f4          | DELEGATECALL          | success 0 0                   | [0, cds) = calldata, [cds, cds+extra) = extraData
                // 3d          | RETURNDATASIZE        | rds success 0 0               | [0, cds) = calldata, [cds, cds+extra) = extraData
                // 3d          | RETURNDATASIZE        | rds rds success 0 0           | [0, cds) = calldata, [cds, cds+extra) = extraData
                // 93          | SWAP4                 | 0 rds success 0 rds           | [0, cds) = calldata, [cds, cds+extra) = extraData
                // 80          | DUP1                  | 0 0 rds success 0 rds         | [0, cds) = calldata, [cds, cds+extra) = extraData
                // 3e          | RETURNDATACOPY        | success 0 rds                 | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
                // 60 0x35     | PUSH1 0x35            | 0x35 sucess 0 rds             | [0, rds) = return data
                // 57          | JUMPI                 | 0 rds                         | [0, rds) = return data
                // fd          | REVERT                | –                             | [0, rds) = return data
                // 5b          | JUMPDEST              | 0 rds                         | [0, rds) = return data
                // f3          | RETURN                | –                             | [0, rds) = return data
                mstore(
                    add(ptr, 0x34),
                    0x5af43d3d93803e603557fd5bf300000000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x41;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256 ** (32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
        }
    }

    /// @notice Creates a clone proxy of the implementation contract, with immutable args. Uses CREATE3
    /// to implement deterministic deployment.
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @param salt The salt used by the CREATE3 deployment
    /// @return deployed The address of the created clone
    function clone3(
        address implementation,
        bytes memory data,
        bytes32 salt
    ) internal returns (address deployed) {
        return clone3(implementation, data, salt, 0);
    }

    /// @notice Creates a clone proxy of the implementation contract, with immutable args. Uses CREATE3
    /// to implement deterministic deployment.
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @param salt The salt used by the CREATE3 deployment
    /// @param value The amount of wei to transfer to the created clone
    /// @return deployed The address of the created clone
    function clone3(
        address implementation,
        bytes memory data,
        bytes32 salt,
        uint256 value
    ) internal returns (address deployed) {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x43 + extraLength;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (11 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 61 runtime  | PUSH2 runtime (r)     | r 0                     | –
                mstore(ptr, 0x3d61000000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x02), shl(240, sub(creationSize, 11))) // size of the contract running bytecode (16 bits)

                // creation size = 0b
                // 80          | DUP1                  | r r 0                   | –
                // 60 creation | PUSH1 creation (c)    | c r r 0                 | –
                // 3d          | RETURNDATASIZE        | 0 c r r 0               | –
                // 39          | CODECOPY              | r 0                     | [0-2d]: runtime code
                // 81          | DUP2                  | 0 c  0                  | [0-2d]: runtime code
                // f3          | RETURN                | 0                       | [0-2d]: runtime code
                mstore(
                    add(ptr, 0x04),
                    0x80600b3d3981f300000000000000000000000000000000000000000000000000
                )

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME
                // -------------------------------------------------------------------------------------------------------------

                // 36          | CALLDATASIZE          | cds                     | –
                // 3d          | RETURNDATASIZE        | 0 cds                   | –
                // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
                // 37          | CALLDATACOPY          | –                       | [0, cds] = calldata
                // 61          | PUSH2 extra           | extra                   | [0, cds] = calldata
                mstore(
                    add(ptr, 0x0b),
                    0x363d3d3761000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x10), shl(240, extraLength))

                // 60 0x38     | PUSH1 0x38            | 0x38 extra              | [0, cds] = calldata // 0x38 (56) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x38 extra          | [0, cds] = calldata
                // 39          | CODECOPY              | _                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0                     | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0 0                   | [0, cds] = calldata
                // 36          | CALLDATASIZE          | cds 0 0 0               | [0, cds] = calldata
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0         | [0, cds] = calldata
                mstore(
                    add(ptr, 0x12),
                    0x603836393d3d3d36610000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0         | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0             | [0, cds] = calldata
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0        | [0, cds] = calldata
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0    | [0, cds] = calldata
                // f4          | DELEGATECALL          | success 0               | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | rds success 0           | [0, cds] = calldata
                // 82          | DUP3                  | 0 rds success 0         | [0, cds] = calldata
                // 80          | DUP1                  | 0 0 rds success 0       | [0, cds] = calldata
                // 3e          | RETURNDATACOPY        | success 0               | [0, rds] = return data (there might be some irrelevant leftovers in memory [rds, cds] when rds < cds)
                // 90          | SWAP1                 | 0 success               | [0, rds] = return data
                // 3d          | RETURNDATASIZE        | rds 0 success           | [0, rds] = return data
                // 91          | SWAP2                 | success 0 rds           | [0, rds] = return data
                // 60 0x36     | PUSH1 0x36            | 0x36 sucess 0 rds       | [0, rds] = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds] = return data
                // fd          | REVERT                | –                       | [0, rds] = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds] = return data
                // f3          | RETURN                | –                       | [0, rds] = return data

                mstore(
                    add(ptr, 0x34),
                    0x5af43d82803e903d91603657fd5bf30000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x43;
            uint256 dataPtr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256 ** (32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }

            /// @solidity memory-safe-assembly
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Store the `_PROXY_BYTECODE` into scratch space.
                mstore(0x00, _CREATE3_PROXY_BYTECODE)
                // Deploy a new contract with our pre-made bytecode via CREATE2.
                let proxy := create2(0, 0x10, 0x10, salt)

                // If the result of `create2` is the zero address, revert.
                if iszero(proxy) {
                    // Store the function selector of `CreateFail()`.
                    mstore(0x00, 0xebfef188)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                // Store the proxy's address.
                mstore(0x14, proxy)
                // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
                // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
                mstore(0x00, 0xd694)
                // Nonce of the proxy contract (1).
                mstore8(0x34, 0x01)

                deployed := and(keccak256(0x1e, 0x17), 0xffffffffffffffffffffffffffffffffffffffff)

                // If the `call` fails or the code size of `deployed` is zero, revert.
                // The second argument of the or() call is evaluated first, which is important
                // here because extcodesize(deployed) is only non-zero after the call() to the proxy
                // is made and the contract is successfully deployed.
                if or(
                    iszero(extcodesize(deployed)),
                    iszero(
                        call(
                            gas(), // Gas remaining.
                            proxy, // Proxy's address.
                            value, // Ether value.
                            ptr, // Pointer to the creation code
                            creationSize, // Size of the creation code
                            0x00, // Offset of output.
                            0x00 // Length of output.
                        )
                    )
                ) {
                    // Store the function selector of `InitializeFail()`.
                    mstore(0x00, 0x8f86d2f1)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @notice Returns the CREATE3 deterministic address of the contract deployed via cloneDeterministic().
    /// @dev Forked from https://github.com/Vectorized/solady/blob/main/src/utils/CREATE3.sol
    /// @param salt The salt used by the CREATE3 deployment
    function addressOfClone3(bytes32 salt) internal view returns (address deployed) {
        /// @solidity memory-safe-assembly
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Cache the free memory pointer.
            let m := mload(0x40)
            // Store `address(this)`.
            mstore(0x00, address())
            // Store the prefix.
            mstore8(0x0b, 0xff)
            // Store the salt.
            mstore(0x20, salt)
            // Store the bytecode hash.
            mstore(0x40, _CREATE3_PROXY_BYTECODE_HASH)

            // Store the proxy's address.
            mstore(0x14, keccak256(0x0b, 0x55))
            // Restore the free memory pointer.
            mstore(0x40, m)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := and(keccak256(0x1e, 0x17), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }
}

// dependencies/openzeppelin-4.8.0/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// dependencies/solmate-6.2.0/src/tokens/ERC20.sol

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// dependencies/openzeppelin-4.8.0/contracts/utils/structs/EnumerableSet.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// dependencies/openzeppelin-4.8.0/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// src/interfaces/IERC20.sol

// Imported from forge-std

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

// src/interfaces/IERC6909Wrappable.sol

/// @title IERC6909Wrappable
/// @notice Declares interface for an ERC6909 implementation that allows for wrapping and unwrapping ERC6909 tokens to and from ERC20 tokens
interface IERC6909Wrappable {
    // ========== ERRORS ========== //

    error ERC6909Wrappable_TokenIdAlreadyExists(uint256 tokenId);
    error ERC6909Wrappable_InvalidTokenId(uint256 tokenId);
    error ERC6909Wrappable_InvalidERC20Implementation(address erc20Implementation);
    error ERC6909Wrappable_ZeroAmount();

    // ========== WRAP/UNWRAP FUNCTIONS ========== //

    /// @notice Wraps an ERC6909 token to an ERC20 token
    ///
    /// @param onBehalfOf_   The address to wrap the token on behalf of
    /// @param tokenId_      The ID of the ERC6909 token
    /// @param amount_       The amount of tokens to wrap
    /// @return wrappedToken The address of the wrapped ERC20 token
    function wrap(
        address onBehalfOf_,
        uint256 tokenId_,
        uint256 amount_
    ) external returns (address wrappedToken);

    /// @notice Unwraps an ERC20 token to an ERC6909 token
    ///
    /// @param onBehalfOf_   The address to unwrap the token on behalf of
    /// @param tokenId_      The ID of the ERC6909 token
    /// @param amount_       The amount of tokens to unwrap
    function unwrap(address onBehalfOf_, uint256 tokenId_, uint256 amount_) external;

    /// @notice Returns the address of the wrapped ERC20 token for a given token ID
    ///
    /// @param  tokenId_        The ID of the ERC6909 token
    /// @return wrappedToken    The address of the wrapped ERC20 token (or zero address)
    function getWrappedToken(uint256 tokenId_) external view returns (address wrappedToken);

    // ========== TOKEN FUNCTIONS ========== //

    /// @notice Returns whether a token ID is valid
    ///
    /// @param  tokenId_        The ID of the ERC6909 token
    /// @return isValid         Whether the token ID is valid
    function isValidTokenId(uint256 tokenId_) external view returns (bool isValid);

    /// @notice Returns the token IDs and wrapped token addresses of all tokens
    ///
    /// @return tokenIds        The IDs of all tokens
    /// @return wrappedTokens   The wrapped token addresses of all tokens
    function getWrappableTokens()
        external
        view
        returns (uint256[] memory tokenIds, address[] memory wrappedTokens);
}

// src/periphery/interfaces/IEnabler.sol

/// @title IEnabler
/// @notice Interface for contracts that can be enabled and disabled
/// @dev    This is designed for usage by periphery contracts that cannot inherit from `PolicyEnabler`. Authorization is deliberately left open to the implementing contract.
interface IEnabler {
    // ============ EVENTS ============ //

    /// @notice Emitted when the contract is enabled
    event Enabled();

    /// @notice Emitted when the contract is disabled
    event Disabled();

    // ============ ERRORS ============ //

    /// @notice Thrown when the contract is not enabled
    error NotEnabled();

    /// @notice Thrown when the contract is not disabled
    error NotDisabled();

    // ============ FUNCTIONS ============ //

    /// @notice         Returns true if the contract is enabled
    /// @return enabled True if the contract is enabled, false otherwise
    function isEnabled() external view returns (bool enabled);

    /// @notice             Enables the contract
    /// @dev                Implementing contracts should implement permissioning logic
    ///
    /// @param enableData_  Optional data to pass to a custom enable function
    function enable(bytes calldata enableData_) external;

    /// @notice             Disables the contract
    /// @dev                Implementing contracts should implement permissioning logic
    ///
    /// @param disableData_ Optional data to pass to a custom disable function
    function disable(bytes calldata disableData_) external;
}

// src/Kernel.sol

//     ███████    █████       █████ █████ ██████   ██████ ███████████  █████  █████  █████████
//   ███░░░░░███ ░░███       ░░███ ░░███ ░░██████ ██████ ░░███░░░░░███░░███  ░░███  ███░░░░░███
//  ███     ░░███ ░███        ░░███ ███   ░███░█████░███  ░███    ░███ ░███   ░███ ░███    ░░░
// ░███      ░███ ░███         ░░█████    ░███░░███ ░███  ░██████████  ░███   ░███ ░░█████████
// ░███      ░███ ░███          ░░███     ░███ ░░░  ░███  ░███░░░░░░   ░███   ░███  ░░░░░░░░███
// ░░███     ███  ░███      █    ░███     ░███      ░███  ░███         ░███   ░███  ███    ░███
//  ░░░███████░   ███████████    █████    █████     █████ █████        ░░████████  ░░█████████
//    ░░░░░░░    ░░░░░░░░░░░    ░░░░░    ░░░░░     ░░░░░ ░░░░░          ░░░░░░░░    ░░░░░░░░░

//============================================================================================//
//                                        GLOBAL TYPES                                        //
//============================================================================================//

/// @notice Actions to trigger state changes in the kernel. Passed by the executor
enum Actions {
    InstallModule,
    UpgradeModule,
    ActivatePolicy,
    DeactivatePolicy,
    ChangeExecutor,
    MigrateKernel
}

/// @notice Used by executor to select an action and a target contract for a kernel action
struct Instruction {
    Actions action;
    address target;
}

/// @notice Used to define which module functions a policy needs access to
struct Permissions {
    Keycode keycode;
    bytes4 funcSelector;
}

type Keycode is bytes5;

//============================================================================================//
//                                       UTIL FUNCTIONS                                       //
//============================================================================================//

error TargetNotAContract(address target_);
error InvalidKeycode(Keycode keycode_);

// solhint-disable-next-line func-visibility
function toKeycode(bytes5 keycode_) pure returns (Keycode) {
    return Keycode.wrap(keycode_);
}

// solhint-disable-next-line func-visibility
function fromKeycode(Keycode keycode_) pure returns (bytes5) {
    return Keycode.unwrap(keycode_);
}

// solhint-disable-next-line func-visibility
function ensureContract(address target_) view {
    if (target_.code.length == 0) revert TargetNotAContract(target_);
}

// solhint-disable-next-line func-visibility
function ensureValidKeycode(Keycode keycode_) pure {
    bytes5 unwrapped = Keycode.unwrap(keycode_);
    for (uint256 i = 0; i < 5; ) {
        bytes1 char = unwrapped[i];
        if (char < 0x41 || char > 0x5A) revert InvalidKeycode(keycode_); // A-Z only
        unchecked {
            i++;
        }
    }
}

//============================================================================================//
//                                        COMPONENTS                                          //
//============================================================================================//

/// @notice Generic adapter interface for kernel access in modules and policies.
abstract contract KernelAdapter {
    error KernelAdapter_OnlyKernel(address caller_);

    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    /// @notice Modifier to restrict functions to be called only by kernel.
    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert KernelAdapter_OnlyKernel(msg.sender);
        _;
    }

    /// @notice Function used by kernel when migrating to a new kernel.
    function changeKernel(Kernel newKernel_) external onlyKernel {
        kernel = newKernel_;
    }
}

/// @notice Base level extension of the kernel. Modules act as independent state components to be
///         interacted with and mutated through policies.
/// @dev    Modules are installed and uninstalled via the executor.
abstract contract Module is KernelAdapter {
    error Module_PolicyNotPermitted(address policy_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Modifier to restrict which policies have access to module functions.
    modifier permissioned() {
        if (
            msg.sender == address(kernel) ||
            !kernel.modulePermissions(KEYCODE(), Policy(msg.sender), msg.sig)
        ) revert Module_PolicyNotPermitted(msg.sender);
        _;
    }

    /// @notice 5 byte identifier for a module.
    function KEYCODE() public pure virtual returns (Keycode) {}

    /// @notice Returns which semantic version of a module is being implemented.
    /// @return major - Major version upgrade indicates breaking change to the interface.
    /// @return minor - Minor version change retains backward-compatible interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}

    /// @notice Initialization function for the module
    /// @dev    This function is called when the module is installed or upgraded by the kernel.
    /// @dev    MUST BE GATED BY onlyKernel. Used to encompass any initialization or upgrade logic.
    function INIT() external virtual onlyKernel {}
}

/// @notice Policies are application logic and external interface for the kernel and installed modules.
/// @dev    Policies are activated and deactivated in the kernel by the executor.
/// @dev    Module dependencies and function permissions must be defined in appropriate functions.
abstract contract Policy is KernelAdapter {
    error Policy_ModuleDoesNotExist(Keycode keycode_);
    error Policy_WrongModuleVersion(bytes expected_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Easily accessible indicator for if a policy is activated or not.
    function isActive() external view returns (bool) {
        return kernel.isPolicyActive(this);
    }

    /// @notice Function to grab module address from a given keycode.
    function getModuleAddress(Keycode keycode_) internal view returns (address) {
        address moduleForKeycode = address(kernel.getModuleForKeycode(keycode_));
        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode_);
        return moduleForKeycode;
    }

    /// @notice Define module dependencies for this policy.
    /// @return dependencies - Keycode array of module dependencies.
    function configureDependencies() external virtual returns (Keycode[] memory dependencies) {}

    /// @notice Function called by kernel to set module function permissions.
    /// @return requests - Array of keycodes and function selectors for requested permissions.
    function requestPermissions() external view virtual returns (Permissions[] memory requests) {}
}

/// @notice Main contract that acts as a central component registry for the protocol.
/// @dev    The kernel manages modules and policies. The kernel is mutated via predefined Actions,
/// @dev    which are input from any address assigned as the executor. The executor can be changed as needed.
contract Kernel {
    // =========  EVENTS ========= //

    event PermissionsUpdated(
        Keycode indexed keycode_,
        Policy indexed policy_,
        bytes4 funcSelector_,
        bool granted_
    );
    event ActionExecuted(Actions indexed action_, address indexed target_);

    // =========  ERRORS ========= //

    error Kernel_OnlyExecutor(address caller_);
    error Kernel_ModuleAlreadyInstalled(Keycode module_);
    error Kernel_InvalidModuleUpgrade(Keycode module_);
    error Kernel_PolicyAlreadyActivated(address policy_);
    error Kernel_PolicyNotActivated(address policy_);

    // =========  PRIVILEGED ADDRESSES ========= //

    /// @notice Address that is able to initiate Actions in the kernel. Can be assigned to a multisig or governance contract.
    address public executor;

    // =========  MODULE MANAGEMENT ========= //

    /// @notice Array of all modules currently installed.
    Keycode[] public allKeycodes;

    /// @notice Mapping of module address to keycode.
    mapping(Keycode => Module) public getModuleForKeycode;

    /// @notice Mapping of keycode to module address.
    mapping(Module => Keycode) public getKeycodeForModule;

    /// @notice Mapping of a keycode to all of its policy dependents. Used to efficiently reconfigure policy dependencies.
    mapping(Keycode => Policy[]) public moduleDependents;

    /// @notice Helper for module dependent arrays. Prevents the need to loop through array.
    mapping(Keycode => mapping(Policy => uint256)) public getDependentIndex;

    /// @notice Module <> Policy Permissions.
    /// @dev    Keycode -> Policy -> Function Selector -> bool for permission
    mapping(Keycode => mapping(Policy => mapping(bytes4 => bool))) public modulePermissions;

    // =========  POLICY MANAGEMENT ========= //

    /// @notice List of all active policies
    Policy[] public activePolicies;

    /// @notice Helper to get active policy quickly. Prevents need to loop through array.
    mapping(Policy => uint256) public getPolicyIndex;

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    constructor() {
        executor = msg.sender;
    }

    /// @notice Modifier to check if caller is the executor.
    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    function isPolicyActive(Policy policy_) public view returns (bool) {
        return activePolicies.length > 0 && activePolicies[getPolicyIndex[policy_]] == policy_;
    }

    /// @notice Main kernel function. Initiates state changes to kernel depending on Action passed in.
    function executeAction(Actions action_, address target_) external onlyExecutor {
        if (action_ == Actions.InstallModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _installModule(Module(target_));
        } else if (action_ == Actions.UpgradeModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _upgradeModule(Module(target_));
        } else if (action_ == Actions.ActivatePolicy) {
            ensureContract(target_);
            _activatePolicy(Policy(target_));
        } else if (action_ == Actions.DeactivatePolicy) {
            ensureContract(target_);
            _deactivatePolicy(Policy(target_));
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        } else if (action_ == Actions.MigrateKernel) {
            ensureContract(target_);
            _migrateKernel(Kernel(target_));
        }

        emit ActionExecuted(action_, target_);
    }

    function _installModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();

        if (address(getModuleForKeycode[keycode]) != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
        allKeycodes.push(keycode);

        newModule_.INIT();
    }

    function _upgradeModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();
        Module oldModule = getModuleForKeycode[keycode];

        if (address(oldModule) == address(0) || oldModule == newModule_)
            revert Kernel_InvalidModuleUpgrade(keycode);

        getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        newModule_.INIT();

        _reconfigurePolicies(keycode);
    }

    function _activatePolicy(Policy policy_) internal {
        if (isPolicyActive(policy_)) revert Kernel_PolicyAlreadyActivated(address(policy_));

        // Add policy to list of active policies
        activePolicies.push(policy_);
        getPolicyIndex[policy_] = activePolicies.length - 1;

        // Record module dependencies
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depLength = dependencies.length;

        for (uint256 i; i < depLength; ) {
            Keycode keycode = dependencies[i];

            moduleDependents[keycode].push(policy_);
            getDependentIndex[keycode][policy_] = moduleDependents[keycode].length - 1;

            unchecked {
                ++i;
            }
        }

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);
    }

    function _deactivatePolicy(Policy policy_) internal {
        if (!isPolicyActive(policy_)) revert Kernel_PolicyNotActivated(address(policy_));

        // Revoke permissions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, false);

        // Remove policy from all policy data structures
        uint256 idx = getPolicyIndex[policy_];
        Policy lastPolicy = activePolicies[activePolicies.length - 1];

        activePolicies[idx] = lastPolicy;
        activePolicies.pop();
        getPolicyIndex[lastPolicy] = idx;
        delete getPolicyIndex[policy_];

        // Remove policy from module dependents
        _pruneFromDependents(policy_);
    }

    /// @notice All functionality will move to the new kernel. WARNING: ACTION WILL BRICK THIS KERNEL.
    /// @dev    New kernel must add in all of the modules and policies via executeAction.
    /// @dev    NOTE: Data does not get cleared from this kernel.
    function _migrateKernel(Kernel newKernel_) internal {
        uint256 keycodeLen = allKeycodes.length;
        for (uint256 i; i < keycodeLen; ) {
            Module module = Module(getModuleForKeycode[allKeycodes[i]]);
            module.changeKernel(newKernel_);
            unchecked {
                ++i;
            }
        }

        uint256 policiesLen = activePolicies.length;
        for (uint256 j; j < policiesLen; ) {
            Policy policy = activePolicies[j];

            // Deactivate before changing kernel
            policy.changeKernel(newKernel_);
            unchecked {
                ++j;
            }
        }
    }

    function _reconfigurePolicies(Keycode keycode_) internal {
        Policy[] memory dependents = moduleDependents[keycode_];
        uint256 depLength = dependents.length;

        for (uint256 i; i < depLength; ) {
            dependents[i].configureDependencies();

            unchecked {
                ++i;
            }
        }
    }

    function _setPolicyPermissions(
        Policy policy_,
        Permissions[] memory requests_,
        bool grant_
    ) internal {
        uint256 reqLength = requests_.length;
        for (uint256 i = 0; i < reqLength; ) {
            Permissions memory request = requests_[i];
            modulePermissions[request.keycode][policy_][request.funcSelector] = grant_;

            emit PermissionsUpdated(request.keycode, policy_, request.funcSelector, grant_);

            unchecked {
                ++i;
            }
        }
    }

    function _pruneFromDependents(Policy policy_) internal {
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depcLength = dependencies.length;

        for (uint256 i; i < depcLength; ) {
            Keycode keycode = dependencies[i];
            Policy[] storage dependents = moduleDependents[keycode];

            uint256 origIndex = getDependentIndex[keycode][policy_];
            Policy lastPolicy = dependents[dependents.length - 1];

            // Swap with last and pop
            dependents[origIndex] = lastPolicy;
            dependents.pop();

            // Record new index and delete deactivated policy index
            getDependentIndex[keycode][lastPolicy] = origIndex;
            delete getDependentIndex[keycode][policy_];

            unchecked {
                ++i;
            }
        }
    }
}

// src/policies/utils/RoleDefinitions.sol

/// @dev Allows enabling/disabling the protocol/policies in an emergency
bytes32 constant EMERGENCY_ROLE = "emergency";
/// @dev Administrative access, e.g. configuration parameters. Typically assigned to on-chain governance.
bytes32 constant ADMIN_ROLE = "admin";
/// @dev Managerial access, e.g. managing specific protocol parameters. Typically assigned to a multisig/council.
bytes32 constant MANAGER_ROLE = "manager";
/// @dev Heart role, e.g. performing periodic tasks.
bytes32 constant HEART_ROLE = "heart";

// src/libraries/String.sol

library String {
    error EndBeforeStartIndex(uint256 startIndex, uint256 endIndex);
    error EndIndexOutOfBounds(uint256 endIndex, uint256 length);

    /// @notice Truncates a string to 32 bytes
    function truncate32(string memory str_) internal pure returns (string memory) {
        return string(abi.encodePacked(bytes32(abi.encodePacked(str_))));
    }

    /// @notice Returns a substring of a string
    ///
    /// @param  str_            The string to get the substring of
    /// @param  startIndex_     The index to start the substring at
    /// @param  endIndex_       The index to end the substring at
    /// @return resultString    The substring
    function substring(
        string memory str_,
        uint256 startIndex_,
        uint256 endIndex_
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str_);

        if (endIndex_ < startIndex_) revert EndBeforeStartIndex(startIndex_, endIndex_);
        if (endIndex_ > strBytes.length) revert EndIndexOutOfBounds(endIndex_, strBytes.length);

        bytes memory result = new bytes(endIndex_ - startIndex_);
        for (uint256 i = startIndex_; i < endIndex_; i++) {
            result[i - startIndex_] = strBytes[i];
        }
        return string(result);
    }

    /// @notice Returns a substring of a string from a given index
    ///
    /// @param  str_ The string to get the substring of
    /// @param  startIndex_ The index to start the substring at
    /// @return resultString The substring
    function substringFrom(
        string memory str_,
        uint256 startIndex_
    ) internal pure returns (string memory) {
        return substring(str_, startIndex_, bytes(str_).length);
    }
}

// src/libraries/Uint2Str.sol

// Some fancy math to convert a uint into a string, courtesy of Provable Things.
// Updated to work with solc 0.8.0.
// https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
function uint2str(uint256 _i) pure returns (string memory) {
    if (_i == 0) {
        return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
        k = k - 1;
        uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
}

// dependencies/openzeppelin-4.8.0/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// src/bases/interfaces/IAssetManager.sol

/// @title  IAssetManager
/// @notice This interface defines the functions for custodying assets.
///         A depositor can deposit assets into a vault, and withdraw them later.
///         An operator is the contract that acts on behalf of the depositor. Only operators can interact with the contract. The deposits facilitated by an operator are siloed from other operators.
interface IAssetManager {
    // ========== ERRORS ========== //

    error AssetManager_NotConfigured();

    error AssetManager_InvalidAsset();

    error AssetManager_AssetAlreadyConfigured();

    error AssetManager_VaultAssetMismatch();

    error AssetManager_ZeroAmount();

    error AssetManager_DepositCapExceeded(
        address asset,
        uint256 existingDepositAmount,
        uint256 depositCap
    );

    // ========== EVENTS ========== //

    event AssetConfigured(address indexed asset, address indexed vault, uint256 depositCap);

    event AssetDepositCapSet(address indexed asset, uint256 depositCap);

    event AssetDeposited(
        address indexed asset,
        address indexed depositor,
        address indexed operator,
        uint256 amount,
        uint256 shares
    );

    event AssetWithdrawn(
        address indexed asset,
        address indexed withdrawer,
        address indexed operator,
        uint256 amount,
        uint256 shares
    );

    // ========== DATA STRUCTURES ========== //

    /// @notice Configuration for an asset
    ///
    /// @param isConfigured  Whether the asset is configured
    /// @param depositCap    The maximum amount of assets that can be deposited. Set to 0 to disable deposits.
    /// @param vault         The ERC4626 vault that the asset is deposited into
    struct AssetConfiguration {
        bool isConfigured;
        uint256 depositCap;
        address vault;
    }

    // ========== ASSET FUNCTIONS ========== //

    /// @notice Get the number of assets deposited for an asset and operator
    ///
    /// @param  asset_          The asset to get the deposited shares for
    /// @param  operator_       The operator to get the deposited shares for
    /// @return shares          The number of shares deposited
    /// @return sharesInAssets  The number of shares deposited (in terms of assets)
    function getOperatorAssets(
        IERC20 asset_,
        address operator_
    ) external view returns (uint256 shares, uint256 sharesInAssets);

    /// @notice Get the configuration for an asset
    ///
    /// @param  asset_          The asset to get the configuration for
    /// @return configuration   The configuration for the asset
    function getAssetConfiguration(
        IERC20 asset_
    ) external view returns (AssetConfiguration memory configuration);

    /// @notice Get the assets that are configured
    ///
    /// @return assets  The assets that are configured
    function getConfiguredAssets() external view returns (IERC20[] memory assets);
}

// src/interfaces/IDepositReceiptToken.sol

/// @title  IDepositReceiptToken
/// @notice Interface for a deposit receipt token
/// @dev    This interface adds additional metadata to the IERC20 interface that is necessary for deposit receipt tokens.
interface IDepositReceiptToken is IERC20 {
    // ========== ERRORS ========== //

    error OnlyOwner();

    // ========== VIEW FUNCTIONS ========== //

    function owner() external view returns (address _owner);

    function asset() external view returns (IERC20 _asset);

    function depositPeriod() external view returns (uint8 _depositPeriod);
}

// dependencies/openzeppelin-4.8.0/contracts/interfaces/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

// src/interfaces/IERC20BurnableMintable.sol

interface IERC20BurnableMintable is IERC20 {
    /// @notice Mints tokens to the specified address
    ///
    /// @param to_      The address to mint tokens to
    /// @param amount_  The amount of tokens to mint
    function mintFor(address to_, uint256 amount_) external;

    /// @notice Burns tokens from the specified address
    ///
    /// @param from_    The address to burn tokens from
    /// @param amount_  The amount of tokens to burn
    function burnFrom(address from_, uint256 amount_) external;
}

// src/interfaces/IERC4626.sol

// Imported from forge-std

/// @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
/// https://eips.ethereum.org/EIPS/eip-4626
interface IERC4626 is IERC20 {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /// @notice Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
    /// @dev
    /// - MUST be an ERC-20 token contract.
    /// - MUST NOT revert.
    function asset() external view returns (address assetTokenAddress);

    /// @notice Returns the total amount of the underlying asset that is “managed” by Vault.
    /// @dev
    /// - SHOULD include any compounding that occurs from yield.
    /// - MUST be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT revert.
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /// @notice Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
    /// scenario where all the conditions are met.
    /// @dev
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
    /// - MUST NOT revert.
    ///
    /// NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
    /// “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
    /// from.
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
    /// scenario where all the conditions are met.
    /// @dev
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
    /// - MUST NOT revert.
    ///
    /// NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
    /// “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
    /// from.
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
    /// through a deposit call.
    /// @dev
    /// - MUST return a limited value if receiver is subject to some deposit limit.
    /// - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
    /// - MUST NOT revert.
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
    /// current on-chain conditions.
    /// @dev
    /// - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
    ///   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
    ///   in the same transaction.
    /// - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
    ///   deposit would be accepted, regardless if the user has enough tokens approved, etc.
    /// - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
    /// - MUST NOT revert.
    ///
    /// NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
    /// share price or some other type of condition, meaning the depositor will lose assets by depositing.
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /// @notice Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
    /// @dev
    /// - MUST emit the Deposit event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
    ///   deposit execution, and are accounted for during deposit.
    /// - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
    ///   approving enough underlying tokens to the Vault contract, etc).
    ///
    /// NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
    /// @dev
    /// - MUST return a limited value if receiver is subject to some mint limit.
    /// - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
    /// - MUST NOT revert.
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
    /// current on-chain conditions.
    /// @dev
    /// - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
    ///   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
    ///   same transaction.
    /// - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
    ///   would be accepted, regardless if the user has enough tokens approved, etc.
    /// - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
    /// - MUST NOT revert.
    ///
    /// NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
    /// share price or some other type of condition, meaning the depositor will lose assets by minting.
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /// @notice Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
    /// @dev
    /// - MUST emit the Deposit event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
    ///   execution, and are accounted for during mint.
    /// - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
    ///   approving enough underlying tokens to the Vault contract, etc).
    ///
    /// NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /// @notice Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
    /// Vault, through a withdraw call.
    /// @dev
    /// - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
    /// - MUST NOT revert.
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    /// @dev
    /// - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
    ///   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
    ///   called
    ///   in the same transaction.
    /// - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
    ///   the withdrawal would be accepted, regardless if the user has enough shares, etc.
    /// - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
    /// - MUST NOT revert.
    ///
    /// NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
    /// share price or some other type of condition, meaning the depositor will lose assets by depositing.
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /// @notice Burns shares from owner and sends exactly assets of underlying tokens to receiver.
    /// @dev
    /// - MUST emit the Withdraw event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
    ///   withdraw execution, and are accounted for during withdraw.
    /// - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
    ///   not having enough shares, etc).
    ///
    /// Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
    /// Those methods should be performed separately.
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /// @notice Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
    /// through a redeem call.
    /// @dev
    /// - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
    /// - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
    /// - MUST NOT revert.
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    /// @dev
    /// - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
    ///   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
    ///   same transaction.
    /// - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
    ///   redemption would be accepted, regardless if the user has enough shares, etc.
    /// - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
    /// - MUST NOT revert.
    ///
    /// NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
    /// share price or some other type of condition, meaning the depositor will lose assets by redeeming.
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /// @notice Burns exactly shares from owner and sends assets of underlying tokens to receiver.
    /// @dev
    /// - MUST emit the Withdraw event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
    ///   redeem execution, and are accounted for during redeem.
    /// - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
    ///   not having enough shares, etc).
    ///
    /// NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
    /// Those methods should be performed separately.
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// src/modules/ROLES/ROLES.v1.sol

abstract contract ROLESv1 is Module {
    // =========  EVENTS ========= //

    event RoleGranted(bytes32 indexed role_, address indexed addr_);
    event RoleRevoked(bytes32 indexed role_, address indexed addr_);

    // =========  ERRORS ========= //

    error ROLES_InvalidRole(bytes32 role_);
    error ROLES_RequireRole(bytes32 role_);
    error ROLES_AddressAlreadyHasRole(address addr_, bytes32 role_);
    error ROLES_AddressDoesNotHaveRole(address addr_, bytes32 role_);
    error ROLES_RoleDoesNotExist(bytes32 role_);

    // =========  STATE ========= //

    /// @notice Mapping for if an address has a policy-defined role.
    mapping(address => mapping(bytes32 => bool)) public hasRole;

    // =========  FUNCTIONS ========= //

    /// @notice Function to grant policy-defined roles to some address. Can only be called by admin.
    function saveRole(bytes32 role_, address addr_) external virtual;

    /// @notice Function to revoke policy-defined roles from some address. Can only be called by admin.
    function removeRole(bytes32 role_, address addr_) external virtual;

    /// @notice "Modifier" to restrict policy function access to certain addresses with a role.
    /// @dev    Roles are defined in the policy and granted by the ROLES admin.
    function requireRole(bytes32 role_, address caller_) external virtual;

    /// @notice Function that checks if role is valid (all lower case)
    function ensureValidRole(bytes32 role_) external pure virtual;
}

// src/libraries/TransferHelper.sol

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap & old Solmate (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
library TransferHelper {
    function safeTransferFrom(ERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(ERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(ERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }
}

// src/external/clones/CloneERC20.sol

/// @notice Modern and gas efficient ERC20 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract CloneERC20 is Clone, IERC20 {
    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0)));
    }

    function symbol() external pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0x20)));
    }

    function decimals() external pure returns (uint8) {
        return _getArgUint8(0x40);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] += amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] -= amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// src/modules/ROLES/OlympusRoles.sol

/// @notice Abstract contract to have the `onlyRole` modifier
/// @dev    Inheriting this automatically makes ROLES module a dependency
abstract contract RolesConsumer {
    ROLESv1 public ROLES;

    modifier onlyRole(bytes32 role_) {
        ROLES.requireRole(role_, msg.sender);
        _;
    }
}

/// @notice Module that holds multisig roles needed by various policies.
contract OlympusRoles is ROLESv1 {
    //============================================================================================//
    //                                        MODULE SETUP                                        //
    //============================================================================================//

    constructor(Kernel kernel_) Module(kernel_) {}

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("ROLES");
    }

    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc ROLESv1
    function saveRole(bytes32 role_, address addr_) external override permissioned {
        if (hasRole[addr_][role_]) revert ROLES_AddressAlreadyHasRole(addr_, role_);

        ensureValidRole(role_);

        // Grant role to the address
        hasRole[addr_][role_] = true;

        emit RoleGranted(role_, addr_);
    }

    /// @inheritdoc ROLESv1
    function removeRole(bytes32 role_, address addr_) external override permissioned {
        if (!hasRole[addr_][role_]) revert ROLES_AddressDoesNotHaveRole(addr_, role_);

        hasRole[addr_][role_] = false;

        emit RoleRevoked(role_, addr_);
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc ROLESv1
    function requireRole(bytes32 role_, address caller_) external view override {
        if (!hasRole[caller_][role_]) revert ROLES_RequireRole(role_);
    }

    /// @inheritdoc ROLESv1
    function ensureValidRole(bytes32 role_) public pure override {
        for (uint256 i = 0; i < 32; ) {
            bytes1 char = role_[i];
            if ((char < 0x61 || char > 0x7A) && char != 0x5f && char != 0x00) {
                revert ROLES_InvalidRole(role_); // a-z only
            }
            unchecked {
                i++;
            }
        }
    }
}

// dependencies/openzeppelin-new-5.3.0/contracts/interfaces/draft-IERC6909.sol

// OpenZeppelin Contracts (last updated v5.3.0) (interfaces/draft-IERC6909.sol)

// pragma solidity ^0.8.20;
//Changed from 0.8.20 to 0.8.15 by fuzzer

// import {IERC165} from "../utils/introspection/IERC165.sol";
//Changed from 5.3.0 to 4.9.0 by fuzzer

/**
 * @dev Required interface of an ERC-6909 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-6909[ERC].
 */
interface IERC6909 is IERC165 {
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set for a token of type `id`.
     * The new allowance is `amount`.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id,
        uint256 amount
    );

    /**
     * @dev Emitted when `owner` grants or revokes operator status for a `spender`.
     */
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    /**
     * @dev Emitted when `amount` tokens of type `id` are moved from `sender` to `receiver` initiated by `caller`.
     */
    event Transfer(
        address caller,
        address indexed sender,
        address indexed receiver,
        uint256 indexed id,
        uint256 amount
    );

    /**
     * @dev Returns the amount of tokens of type `id` owned by `owner`.
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens of type `id` that `spender` is allowed to spend on behalf of `owner`.
     *
     * NOTE: Does not include operator allowances.
     */
    function allowance(address owner, address spender, uint256 id) external view returns (uint256);

    /**
     * @dev Returns true if `spender` is set as an operator for `owner`.
     */
    function isOperator(address owner, address spender) external view returns (bool);

    /**
     * @dev Sets an approval to `spender` for `amount` of tokens of type `id` from the caller's tokens. An `amount` of
     * `type(uint256).max` signifies an unlimited approval.
     *
     * Must return true.
     */
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);

    /**
     * @dev Grants or revokes unlimited transfer permission of any token id to `spender` for the caller's tokens.
     *
     * Must return true.
     */
    function setOperator(address spender, bool approved) external returns (bool);

    /**
     * @dev Transfers `amount` of token type `id` from the caller's account to `receiver`.
     *
     * Must return true.
     */
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);

    /**
     * @dev Transfers `amount` of token type `id` from `sender` to `receiver`.
     *
     * Must return true.
     */
    function transferFrom(
        address sender,
        address receiver,
        uint256 id,
        uint256 amount
    ) external returns (bool);
}

/**
 * @dev Optional extension of {IERC6909} that adds metadata functions.
 */
interface IERC6909Metadata is IERC6909 {
    /**
     * @dev Returns the name of the token of type `id`.
     */
    function name(uint256 id) external view returns (string memory);

    /**
     * @dev Returns the ticker symbol of the token of type `id`.
     */
    function symbol(uint256 id) external view returns (string memory);

    /**
     * @dev Returns the number of decimals for the token of type `id`.
     */
    function decimals(uint256 id) external view returns (uint8);
}

/**
 * @dev Optional extension of {IERC6909} that adds content URI functions.
 */
interface IERC6909ContentURI is IERC6909 {
    /**
     * @dev Returns URI for the contract.
     */
    function contractURI() external view returns (string memory);

    /**
     * @dev Returns the URI for the token of type `id`.
     */
    function tokenURI(uint256 id) external view returns (string memory);
}

/**
 * @dev Optional extension of {IERC6909} that adds a token supply function.
 */
interface IERC6909TokenSupply is IERC6909 {
    /**
     * @dev Returns the total supply of the token of type `id`.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}

// src/policies/interfaces/deposits/IDepositManager.sol

/// @title  Deposit Manager
/// @notice Defines an interface for a policy that manages deposits on behalf of other contracts. It is meant to be used by the facilities, and is not an end-user policy.
///
///         Key terms for the contract:
///         - Asset: an ERC20 asset that can be deposited into the contract
///         - Asset vault: an optional ERC4626 vault that assets are deposited into
///         - Asset period: the combination of an asset and deposit period
interface IDepositManager is IAssetManager {
    // ========== EVENTS ========== //

    event ClaimedYield(
        address indexed asset,
        address indexed depositor,
        address indexed operator,
        uint256 amount
    );

    event AssetPeriodConfigured(
        uint256 indexed receiptTokenId,
        address indexed asset,
        uint8 depositPeriod
    );

    event AssetPeriodEnabled(
        uint256 indexed receiptTokenId,
        address indexed asset,
        uint8 depositPeriod
    );

    event AssetPeriodDisabled(
        uint256 indexed receiptTokenId,
        address indexed asset,
        uint8 depositPeriod
    );

    event AssetPeriodReclaimRateSet(address indexed asset, uint8 depositPeriod, uint16 reclaimRate);

    // Borrowing Events
    event BorrowingWithdrawal(
        address indexed asset,
        address indexed operator,
        address indexed recipient,
        uint256 amount
    );

    event BorrowingRepayment(
        address indexed asset,
        address indexed operator,
        address indexed payer,
        uint256 amount
    );

    event BorrowingDefault(
        address indexed asset,
        address indexed operator,
        address indexed payer,
        uint256 amount
    );

    // ========== ERRORS ========== //

    error DepositManager_Insolvent(address asset, uint256 requiredAssets);

    error DepositManager_ZeroAddress();

    error DepositManager_OutOfBounds();

    error DepositManager_InvalidAssetPeriod(address asset, uint8 depositPeriod);

    error DepositManager_AssetPeriodExists(address asset, uint8 depositPeriod);

    error DepositManager_AssetPeriodEnabled(address asset, uint8 depositPeriod);

    error DepositManager_AssetPeriodDisabled(address asset, uint8 depositPeriod);

    // Borrowing Errors
    error DepositManager_BorrowingLimitExceeded(
        address asset,
        address operator,
        uint256 requested,
        uint256 available
    );

    error DepositManager_BorrowedAmountExceeded(
        address asset,
        address operator,
        uint256 amount,
        uint256 borrowed
    );

    // ========== STRUCTS ========== //

    /// @notice Parameters for the {deposit} function
    ///
    /// @param asset           The underlying ERC20 asset
    /// @param depositPeriod   The deposit period, in months
    /// @param depositor       The depositor
    /// @param amount          The amount to deposit
    /// @param shouldWrap      Whether the receipt token should be wrapped
    struct DepositParams {
        IERC20 asset;
        uint8 depositPeriod;
        address depositor;
        uint256 amount;
        bool shouldWrap;
    }

    /// @notice Parameters for the {withdraw} function
    ///
    /// @param asset            The underlying ERC20 asset
    /// @param depositPeriod    The deposit period, in months
    /// @param depositor        The depositor that is holding the receipt tokens
    /// @param recipient        The recipient of the withdrawn asset
    /// @param amount           The amount to withdraw
    /// @param isWrapped        Whether the receipt token is wrapped
    struct WithdrawParams {
        IERC20 asset;
        uint8 depositPeriod;
        address depositor;
        address recipient;
        uint256 amount;
        bool isWrapped;
    }

    /// @notice An asset period configuration, representing an asset and period combination
    ///
    /// @param isEnabled       Whether the asset period is enabled for new deposits
    /// @param depositPeriod   The deposit period, in months
    /// @param reclaimRate     The reclaim rate for the asset period (see the implementation contract for scale)
    /// @param asset           The underlying ERC20 asset
    struct AssetPeriod {
        bool isEnabled;
        uint8 depositPeriod;
        uint16 reclaimRate;
        address asset;
    }

    /// @notice Status of an asset period
    ///
    /// @param isConfigured    Whether the asset period is configured
    /// @param isEnabled       Whether the asset period is enabled for new deposits
    struct AssetPeriodStatus {
        bool isConfigured;
        bool isEnabled;
    }

    /// @notice Parameters for borrowing withdrawal operations
    ///
    /// @param asset           The underlying ERC20 asset
    /// @param recipient       The recipient of the borrowed funds
    /// @param amount          The amount to borrow
    struct BorrowingWithdrawParams {
        IERC20 asset;
        address recipient;
        uint256 amount;
    }

    /// @notice Parameters for borrowing repayment operations
    ///
    /// @param asset           The underlying ERC20 asset
    /// @param payer           The address making the repayment
    /// @param amount          The amount to repay
    struct BorrowingRepayParams {
        IERC20 asset;
        address payer;
        uint256 amount;
    }

    /// @notice Parameters for borrowing default operations
    ///
    /// @param asset           The underlying ERC20 asset
    /// @param depositPeriod   The deposit period, in months
    /// @param payer           The address making the default
    /// @param amount          The amount to default
    struct BorrowingDefaultParams {
        IERC20 asset;
        uint8 depositPeriod;
        address payer;
        uint256 amount;
    }

    // ========== BORROWING FUNCTIONS ========== //

    /// @notice Borrows funds from deposits
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Validating borrowing limits and capacity
    ///         - Transferring the underlying asset from the contract to the recipient
    ///         - Updating borrowing state
    ///         - Checking solvency
    ///
    /// @param  params_         The parameters for the borrowing withdrawal
    /// @return actualAmount    The quantity of underlying assets transferred to the recipient
    function borrowingWithdraw(
        BorrowingWithdrawParams calldata params_
    ) external returns (uint256 actualAmount);

    /// @notice Repays borrowed funds
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Transferring the underlying asset from the payer to the contract
    ///         - Updating borrowing state
    ///         - Checking solvency
    ///
    /// @param  params_         The parameters for the borrowing repayment
    /// @return actualAmount    The quantity of underlying assets received from the payer
    function borrowingRepay(
        BorrowingRepayParams calldata params_
    ) external returns (uint256 actualAmount);

    /// @notice Defaults on a borrowed amount
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Burning the receipt tokens from the payer for the default amount
    ///         - Updating borrowing state
    ///         - Updating liabilities
    function borrowingDefault(BorrowingDefaultParams calldata params_) external;

    /// @notice Gets the current borrowed amount for an operator
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  operator_       The address of the operator
    /// @return borrowed        The current borrowed amount for the operator
    function getBorrowedAmount(
        IERC20 asset_,
        address operator_
    ) external view returns (uint256 borrowed);

    /// @notice Gets the available borrowing capacity for an operator
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  operator_       The address of the operator
    /// @return capacity        The available borrowing capacity for the operator
    function getBorrowingCapacity(
        IERC20 asset_,
        address operator_
    ) external view returns (uint256 capacity);

    // ========== DEPOSIT/WITHDRAW FUNCTIONS ========== //

    /// @notice Deposits the given amount of the underlying asset in exchange for a receipt token
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Transferring the underlying asset from the depositor to the contract
    ///         - Minting the receipt token to the depositor
    ///         - Updating the amount of deposited funds
    ///
    /// @param  params_         The parameters for the deposit
    /// @return receiptTokenId  The ID of the receipt token
    /// @return actualAmount    The quantity of receipt tokens minted to the depositor
    function deposit(
        DepositParams calldata params_
    ) external returns (uint256 receiptTokenId, uint256 actualAmount);

    /// @notice Returns the maximum yield that can be claimed for an asset and operator pair
    ///
    /// @param  asset_        The address of the underlying asset
    /// @param  operator_     The address of the operator
    /// @return yieldAssets   The amount of yield that can be claimed
    function maxClaimYield(
        IERC20 asset_,
        address operator_
    ) external view returns (uint256 yieldAssets);

    /// @notice Claims the yield from the underlying asset
    ///         This does not burn receipt tokens, but should reduce the amount of shares the caller has in the vault.
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Transferring the underlying asset from the contract to the recipient
    ///         - Updating the amount of deposited funds
    ///         - Checking solvency
    ///
    /// @param  asset_        The address of the underlying asset
    /// @param  recipient_    The recipient of the claimed yield
    /// @param  amount_       The amount to claim yield for
    function claimYield(IERC20 asset_, address recipient_, uint256 amount_) external;

    /// @notice Withdraws the given amount of the underlying asset
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Burning the receipt token
    ///         - Transferring the underlying asset from the contract to the recipient
    ///         - Updating the amount of deposited funds
    ///
    /// @param  params_         The parameters for the withdrawal
    /// @return actualAmount    The quantity of underlying assets transferred to the recipient
    function withdraw(WithdrawParams calldata params_) external returns (uint256 actualAmount);

    /// @notice Returns the liabilities for an asset and operator pair
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  operator_       The address of the operator
    /// @return liabilities     The quantity of assets that the contract is custodying for the operator's depositors
    function getOperatorLiabilities(
        IERC20 asset_,
        address operator_
    ) external view returns (uint256 liabilities);

    // ========== DEPOSIT CONFIGURATIONS ========== //

    /// @notice Adds a new asset
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Configuring the asset
    ///         - Emitting an event
    ///
    /// @param  asset_      The address of the underlying asset
    /// @param  vault_      The address of the ERC4626 vault to deposit the asset into (or the zero address)
    /// @param  depositCap_ The deposit cap of the asset
    function addAsset(IERC20 asset_, IERC4626 vault_, uint256 depositCap_) external;

    /// @notice Sets the deposit cap for an asset
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Setting the deposit cap for the asset
    ///         - Emitting an event
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  depositCap_     The deposit cap to set for the asset
    function setAssetDepositCap(IERC20 asset_, uint256 depositCap_) external;

    /// @notice Adds a new asset period
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Creating a new receipt token
    ///         - Emitting an event
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  depositPeriod_  The deposit period, in months
    /// @param  reclaimRate_    The reclaim rate to set for the deposit
    /// @return receiptTokenId  The ID of the new receipt token
    function addAssetPeriod(
        IERC20 asset_,
        uint8 depositPeriod_,
        uint16 reclaimRate_
    ) external returns (uint256 receiptTokenId);

    /// @notice Disables an asset period, which prevents new deposits
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Disabling the asset period
    ///         - Emitting an event
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  depositPeriod_  The deposit period, in months
    function disableAssetPeriod(IERC20 asset_, uint8 depositPeriod_) external;

    /// @notice Enables an asset period, which allows new deposits
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Enabling the asset period
    ///         - Emitting an event
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  depositPeriod_  The deposit period, in months
    function enableAssetPeriod(IERC20 asset_, uint8 depositPeriod_) external;

    /// @notice Returns the asset period for an asset and period
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  depositPeriod_  The deposit period, in months
    /// @return configuration   The asset period
    function getAssetPeriod(
        IERC20 asset_,
        uint8 depositPeriod_
    ) external view returns (AssetPeriod memory configuration);

    /// @notice Returns the asset period from a receipt token ID
    ///
    /// @param  tokenId_        The ID of the receipt token
    /// @return configuration   The asset period
    function getAssetPeriod(
        uint256 tokenId_
    ) external view returns (AssetPeriod memory configuration);

    /// @notice Returns whether a deposit asset and period combination are configured
    /// @dev    A asset period that is disabled will not accept further deposits
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  depositPeriod_  The deposit period, in months
    /// @return status          The status of the asset period
    function isAssetPeriod(
        IERC20 asset_,
        uint8 depositPeriod_
    ) external view returns (AssetPeriodStatus memory status);

    /// @notice Returns the asset periods
    ///
    /// @return depositConfigurations   The asset periods
    function getAssetPeriods() external view returns (AssetPeriod[] memory depositConfigurations);

    // ========== RECLAIM RATE ========== //

    /// @notice Sets the reclaim rate for an asset period
    /// @dev    The implementing contract is expected to handle the following:
    ///         - Validating that the caller has the correct role
    ///         - Setting the reclaim rate for the asset period
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  depositPeriod_  The deposit period, in months
    /// @param  reclaimRate_    The reclaim rate to set
    function setAssetPeriodReclaimRate(
        IERC20 asset_,
        uint8 depositPeriod_,
        uint16 reclaimRate_
    ) external;

    /// @notice Returns the reclaim rate for an asset period
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  depositPeriod_  The deposit period, in months
    /// @return reclaimRate     The reclaim rate for the asset period
    function getAssetPeriodReclaimRate(
        IERC20 asset_,
        uint8 depositPeriod_
    ) external view returns (uint16 reclaimRate);

    // ========== RECEIPT TOKEN FUNCTIONS ========== //

    /// @notice Returns the ID of the receipt token for an asset period
    /// @dev    The ID returned is not a guarantee that the asset period is configured or enabled. {isAssetPeriod} should be used for that purpose.
    ///
    /// @param  asset_          The address of the underlying asset
    /// @param  depositPeriod_  The deposit period, in months
    /// @return receiptTokenId  The ID of the receipt token
    function getReceiptTokenId(IERC20 asset_, uint8 depositPeriod_) external view returns (uint256);

    /// @notice Returns the name of a receipt token
    ///
    /// @param  tokenId_    The ID of the receipt token
    /// @return name        The name of the receipt token
    function getReceiptTokenName(uint256 tokenId_) external view returns (string memory);

    /// @notice Returns the symbol of a receipt token
    ///
    /// @param  tokenId_    The ID of the receipt token
    /// @return symbol      The symbol of the receipt token
    function getReceiptTokenSymbol(uint256 tokenId_) external view returns (string memory);

    /// @notice Returns the decimals of a receipt token
    ///
    /// @param  tokenId_    The ID of the receipt token
    /// @return decimals    The decimals of the receipt token
    function getReceiptTokenDecimals(uint256 tokenId_) external view returns (uint8);

    /// @notice Returns the owner of a receipt token
    ///
    /// @param  tokenId_    The ID of the receipt token
    /// @return owner       The owner of the receipt token
    function getReceiptTokenOwner(uint256 tokenId_) external view returns (address);

    /// @notice Returns the asset of a receipt token
    ///
    /// @param  tokenId_    The ID of the receipt token
    /// @return asset       The asset of the receipt token
    function getReceiptTokenAsset(uint256 tokenId_) external view returns (IERC20);

    /// @notice Returns the deposit period of a receipt token
    ///
    /// @param  tokenId_        The ID of the receipt token
    /// @return depositPeriod   The deposit period of the receipt token
    function getReceiptTokenDepositPeriod(
        uint256 tokenId_
    ) external view returns (uint8 depositPeriod);
}

// src/policies/utils/PolicyAdmin.sol

abstract contract PolicyAdmin is RolesConsumer {
    error NotAuthorised();

    /// @notice Modifier that reverts if the caller does not have the emergency or admin role
    modifier onlyEmergencyOrAdminRole() {
        if (!_isEmergency(msg.sender) && !_isAdmin(msg.sender)) revert NotAuthorised();
        _;
    }

    /// @notice Modifier that reverts if the caller does not have the manager or admin role
    modifier onlyManagerOrAdminRole() {
        if (!_isManager(msg.sender) && !_isAdmin(msg.sender)) revert NotAuthorised();
        _;
    }

    /// @notice Modifier that reverts if the caller does not have the admin role
    modifier onlyAdminRole() {
        if (!_isAdmin(msg.sender)) revert ROLESv1.ROLES_RequireRole(ADMIN_ROLE);
        _;
    }

    /// @notice Modifier that reverts if the caller does not have the emergency role
    modifier onlyEmergencyRole() {
        if (!_isEmergency(msg.sender)) revert ROLESv1.ROLES_RequireRole(EMERGENCY_ROLE);
        _;
    }

    /// @notice Modifier that reverts if the caller does not have the manager role
    modifier onlyManagerRole() {
        if (!_isManager(msg.sender)) revert ROLESv1.ROLES_RequireRole(MANAGER_ROLE);
        _;
    }

    /// @notice Check if an account has the admin role
    ///
    /// @param  account_ The account to check
    /// @return true if the account has the admin role, false otherwise
    function _isAdmin(address account_) internal view returns (bool) {
        return ROLES.hasRole(account_, ADMIN_ROLE);
    }

    /// @notice Check if an account has the emergency role
    ///
    /// @param  account_ The account to check
    /// @return true if the account has the emergency role, false otherwise
    function _isEmergency(address account_) internal view returns (bool) {
        return ROLES.hasRole(account_, EMERGENCY_ROLE);
    }

    /// @notice Check if an account has the manager role
    ///
    /// @param  account_ The account to check
    /// @return true if the account has the manager role, false otherwise
    function _isManager(address account_) internal view returns (bool) {
        return ROLES.hasRole(account_, MANAGER_ROLE);
    }
}

// src/bases/BaseAssetManager.sol

// Interfaces

// Libraries

/// @title  BaseAssetManager
/// @notice This is a base contract for managing asset deposits and withdrawals. It is designed to be inherited by another contract.
///         This contract supports multiple assets, and can store them idle or in an ERC4626 vault (specified at the time of configuration). Once an approach is specified, it cannot be changed. This is to avoid the threat of a governance attack that shifts the deposited funds to a different vault in order to steal them.
///         Future versions of the contract could add support for more complex strategies and/or strategy migration, while addressing the concern of funds theft.
abstract contract BaseAssetManager is IAssetManager {
    using TransferHelper for ERC20;

    // ========== STATE VARIABLES ========== //

    /// @notice Array of configured assets
    IERC20[] internal _configuredAssets;

    /// @notice Mapping of assets to a configuration
    mapping(IERC20 => AssetConfiguration) internal _assetConfigurations;

    /// @notice Mapping of assets and operators to the number of shares they have deposited
    mapping(bytes32 => uint256) internal _operatorShares;

    // ========== ACTION FUNCTIONS ========== //

    /// @notice Deposit assets into the configured vault
    /// @dev    This function will pull the assets from the depositor and deposit them into the vault. If the vault is the zero address, the assets will be kept idle.
    ///
    ///         When an ERC4626 vault is configured for an asset, the amount of assets that can be withdrawn may be 1 less than what was originally deposited. To be conservative, this function returns the actual amount.
    ///
    ///         This function will revert if:
    ///         - The vault is not approved
    ///         - It is unable to pull the assets from the depositor
    ///
    /// @param  asset_          The asset to deposit
    /// @param  depositor_      The depositor
    /// @param  amount_         The amount of assets to deposit
    /// @return actualAmount    The actual amount of assets redeemable by the shares
    /// @return shares          The number of shares received
    function _depositAsset(
        IERC20 asset_,
        address depositor_,
        uint256 amount_
    ) internal onlyConfiguredAsset(asset_) returns (uint256 actualAmount, uint256 shares) {
        AssetConfiguration memory assetConfiguration = _assetConfigurations[asset_];

        // Validate that adding the deposit will not exceed the deposit cap
        {
            (, uint256 assetAmountBefore) = getOperatorAssets(asset_, msg.sender);
            if (assetAmountBefore + amount_ > assetConfiguration.depositCap) {
                revert AssetManager_DepositCapExceeded(
                    address(asset_),
                    assetAmountBefore,
                    assetConfiguration.depositCap
                );
            }
        }

        // Pull the assets from the depositor
        ERC20 asset = ERC20(address(asset_));
        uint256 balanceBefore = asset.balanceOf(address(this));
        asset.safeTransferFrom(depositor_, address(this), amount_);
        // Revert if the asset is a fee-on-transfer token
        if (asset.balanceOf(address(this)) != balanceBefore + amount_) {
            revert AssetManager_InvalidAsset();
        }

        // If the vault is the zero address, the asset is to be kept idle
        if (assetConfiguration.vault == address(0)) {
            shares = amount_;
            actualAmount = amount_;
        }
        // Otherwise, deposit the assets into the vault
        else {
            IERC4626 vault = IERC4626(assetConfiguration.vault);
            asset.safeApprove(address(vault), amount_);
            shares = vault.deposit(amount_, address(this));

            // The amount of assets redeemable by the shares can be different from the amount deposited
            // due to rounding errors in the ERC4626 vault
            // To avoid minting more receipt tokens than the actual redeemable amount,
            // we should use the previewRedeem function to get the actual amount of assets redeemable by the shares.
            actualAmount = vault.previewRedeem(shares);
        }

        // Amount of shares must be non-zero
        if (shares == 0) revert AssetManager_ZeroAmount();

        // Update the shares deposited by the caller (operator)
        _operatorShares[_getOperatorKey(asset_, msg.sender)] += shares;

        emit AssetDeposited(address(asset_), depositor_, msg.sender, actualAmount, shares);
        return (actualAmount, shares);
    }

    /// @notice Withdraw assets from the configured vault
    /// @dev    This function will withdraw the assets from the vault and send them to the depositor. If the vault is the zero address, the assets will be kept idle.
    ///
    ///         This function will revert if:
    ///         - The vault is not approved
    ///
    /// @param  asset_      The asset to withdraw
    /// @param  depositor_  The depositor
    /// @param  amount_     The amount of assets to withdraw
    /// @return shares      The number of shares withdrawn
    function _withdrawAsset(
        IERC20 asset_,
        address depositor_,
        uint256 amount_
    ) internal onlyConfiguredAsset(asset_) returns (uint256 shares, uint256 assetAmount) {
        // If the vault is the zero address, the asset is idle and kept in this contract
        AssetConfiguration memory assetConfiguration = _assetConfigurations[asset_];
        if (assetConfiguration.vault == address(0)) {
            shares = amount_;
            assetAmount = amount_;
            ERC20(address(asset_)).safeTransfer(depositor_, amount_);
        }
        // Otherwise, withdraw the assets from the vault
        else {
            shares = IERC4626(assetConfiguration.vault).withdraw(
                amount_,
                depositor_,
                address(this)
            );
            assetAmount = amount_;
        }

        // Amount of shares must be non-zero
        if (shares == 0) revert AssetManager_ZeroAmount();

        // Update the shares deposited by the caller (operator)
        _operatorShares[_getOperatorKey(asset_, msg.sender)] -= shares;

        emit AssetWithdrawn(address(asset_), depositor_, msg.sender, assetAmount, shares);
        return (shares, assetAmount);
    }

    /// @inheritdoc IAssetManager
    function getOperatorAssets(
        IERC20 asset_,
        address operator_
    ) public view override returns (uint256 shares, uint256 sharesInAssets) {
        shares = _operatorShares[_getOperatorKey(asset_, operator_)];

        // Convert from shares to assets
        AssetConfiguration memory assetConfiguration = _assetConfigurations[asset_];
        if (assetConfiguration.vault == address(0)) {
            sharesInAssets = shares;
        } else {
            sharesInAssets = IERC4626(assetConfiguration.vault).previewRedeem(shares);
        }

        return (shares, sharesInAssets);
    }

    /// @notice Get the key for the operator shares
    function _getOperatorKey(IERC20 asset_, address operator_) internal pure returns (bytes32) {
        return keccak256(abi.encode(address(asset_), operator_));
    }

    // ========== ADMIN FUNCTIONS ========== //

    /// @notice Configure an asset to be deposited into a vault
    /// @dev    This function will configure an asset to be deposited into a vault. If the vault is the zero address, the assets will be kept idle.
    ///
    ///         Note that the asset can only be configured once. This is to prevent the assets from being moved between vaults and exposing the deposited assets to the risk of theft.
    ///
    ///         This function will revert if:
    ///         - The asset is already configured
    ///         - The vault asset does not match the asset
    ///
    /// @param asset_       The asset to configure
    /// @param vault_       The vault to use
    /// @param depositCap_  The deposit cap of the asset
    function _addAsset(IERC20 asset_, IERC4626 vault_, uint256 depositCap_) internal {
        // Validate that the asset is not the zero address
        if (address(asset_) == address(0)) {
            revert AssetManager_InvalidAsset();
        }

        // Validate that the vault is not already configured
        if (_assetConfigurations[asset_].isConfigured) {
            revert AssetManager_AssetAlreadyConfigured();
        }

        // Validate that the vault asset matches
        if (address(vault_) != address(0) && address(vault_.asset()) != address(asset_)) {
            revert AssetManager_VaultAssetMismatch();
        }

        // Configure the asset
        _assetConfigurations[asset_] = AssetConfiguration({
            isConfigured: true,
            vault: address(vault_),
            depositCap: depositCap_
        });

        // Add the asset to the array of configured assets
        _configuredAssets.push(asset_);

        emit AssetConfigured(address(asset_), address(vault_), depositCap_);
        emit AssetDepositCapSet(address(asset_), depositCap_);
    }

    /// @notice Set the deposit cap for an asset
    /// @dev    This function will set the deposit cap for an asset.
    ///
    ///         This function will revert if:
    ///         - The asset is not configured
    ///
    /// @param asset_          The asset to set the deposit cap for
    /// @param depositCap_     The deposit cap to set for the asset
    function _setAssetDepositCap(IERC20 asset_, uint256 depositCap_) internal {
        // Validate that the asset is configured
        if (!_isConfiguredAsset(asset_)) revert AssetManager_NotConfigured();

        // Set the deposit cap
        _assetConfigurations[asset_].depositCap = depositCap_;
        emit AssetDepositCapSet(address(asset_), depositCap_);
    }

    function _isConfiguredAsset(IERC20 asset_) internal view returns (bool) {
        return _assetConfigurations[asset_].isConfigured;
    }

    modifier onlyConfiguredAsset(IERC20 asset_) {
        if (!_isConfiguredAsset(asset_)) revert AssetManager_NotConfigured();
        _;
    }

    /// @notice Get the configuration for an asset
    ///
    /// @param  asset_          The asset to get the configuration for
    /// @return configuration   The configuration for the asset
    function getAssetConfiguration(
        IERC20 asset_
    ) public view override returns (AssetConfiguration memory configuration) {
        return _assetConfigurations[asset_];
    }

    /// @inheritdoc IAssetManager
    function getConfiguredAssets() public view override returns (IERC20[] memory assets) {
        return _configuredAssets;
    }

    // ========== ERC165 ========== //

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IAssetManager).interfaceId;
    }
}

// src/libraries/CloneableReceiptToken.sol

// Interfaces

// Libraries

/// @title  CloneableReceiptToken
/// @notice ERC20 implementation that is deployed as a clone
///         with immutable arguments for each supported input token.
contract CloneableReceiptToken is CloneERC20, IERC20BurnableMintable, IDepositReceiptToken {
    // ========== IMMUTABLE ARGS ========== //

    // Storage layout:
    // 0x00 - name, 32 bytes
    // 0x20 - symbol, 32 bytes
    // 0x40 - decimals, 1 byte
    // 0x41 - owner, 20 bytes
    // 0x55 - asset, 20 bytes
    // 0x69 - depositPeriod, 1 byte

    /// @notice The owner of the clone
    /// @return _owner The owner address stored in immutable args
    function owner() public pure returns (address _owner) {
        _owner = _getArgAddress(0x41);
    }

    /// @notice The underlying asset
    /// @return _asset The asset address stored in immutable args
    function asset() public pure returns (IERC20 _asset) {
        _asset = IERC20(_getArgAddress(0x55));
    }

    /// @notice The deposit period (in months)
    /// @return _depositPeriod The deposit period stored in immutable args
    function depositPeriod() public pure returns (uint8 _depositPeriod) {
        _depositPeriod = _getArgUint8(0x69);
    }

    // ========== OWNER-ONLY FUNCTIONS ========== //

    /// @notice Only the owner can call this function
    modifier onlyOwner() {
        if (msg.sender != owner()) revert OnlyOwner();
        _;
    }

    /// @notice Mint tokens to the specified address
    /// @dev    This is owner-only, as the underlying token is custodied by the owner.
    ///         Minting should be performed through the owner contract.
    ///
    /// @param to_ The address to mint tokens to
    /// @param amount_ The amount of tokens to mint
    function mintFor(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    /// @notice Burn tokens from the specified address
    /// @dev    This is gated to the owner, as burning is controlled.
    ///         Burning should be performed through the owner contract.
    ///
    /// @dev    This function reverts if:
    ///         - The amount is greater than the allowance
    ///
    /// @param from_ The address to burn tokens from
    /// @param amount_ The amount of tokens to burn
    function burnFrom(address from_, uint256 amount_) external onlyOwner {
        uint256 allowed = allowance[from_][msg.sender];

        if (allowed != type(uint256).max) {
            allowance[from_][msg.sender] = allowed - amount_;
        }

        _burn(from_, amount_);
    }

    // ========== ERC165 ========== //

    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        // super does not implement ERC165, so no need to call it
        return
            interfaceId_ == type(IERC20).interfaceId ||
            interfaceId_ == type(IERC20BurnableMintable).interfaceId ||
            interfaceId_ == type(IDepositReceiptToken).interfaceId;
    }
}

// dependencies/openzeppelin-new-5.3.0/contracts/token/ERC6909/draft-ERC6909.sol

// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC6909/draft-ERC6909.sol)

// pragma solidity ^0.8.20;
//Changed from 0.8.20 to 0.8.15 by fuzzer

// import {Context} from "../../utils/Context.sol";
//Changed from 5.3.0 to 4.9.0 by fuzzer
// import {IERC165, ERC165} from "../../utils/introspection/ERC165.sol";
//Changed from 5.3.0 to 4.9.0 by fuzzer

/**
 * @dev Implementation of ERC-6909.
 * See https://eips.ethereum.org/EIPS/eip-6909
 */
contract ERC6909 is Context, ERC165, IERC6909 {
    mapping(address owner => mapping(uint256 id => uint256)) private _balances;

    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;

    mapping(address owner => mapping(address spender => mapping(uint256 id => uint256)))
        private _allowances;

    error ERC6909InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 id);
    error ERC6909InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed,
        uint256 id
    );
    error ERC6909InvalidApprover(address approver);
    error ERC6909InvalidReceiver(address receiver);
    error ERC6909InvalidSender(address sender);
    error ERC6909InvalidSpender(address spender);

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC6909).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC6909
    function balanceOf(address owner, uint256 id) public view virtual override returns (uint256) {
        return _balances[owner][id];
    }

    /// @inheritdoc IERC6909
    function allowance(
        address owner,
        address spender,
        uint256 id
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender][id];
    }

    /// @inheritdoc IERC6909
    function isOperator(
        address owner,
        address spender
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][spender];
    }

    /// @inheritdoc IERC6909
    function approve(
        address spender,
        uint256 id,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, id, amount);
        return true;
    }

    /// @inheritdoc IERC6909
    function setOperator(address spender, bool approved) public virtual override returns (bool) {
        _setOperator(_msgSender(), spender, approved);
        return true;
    }

    /// @inheritdoc IERC6909
    function transfer(
        address receiver,
        uint256 id,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), receiver, id, amount);
        return true;
    }

    /// @inheritdoc IERC6909
    function transferFrom(
        address sender,
        address receiver,
        uint256 id,
        uint256 amount
    ) public virtual override returns (bool) {
        address caller = _msgSender();
        if (sender != caller && !isOperator(sender, caller)) {
            _spendAllowance(sender, caller, id, amount);
        }
        _transfer(sender, receiver, id, amount);
        return true;
    }

    /**
     * @dev Creates `amount` of token `id` and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address to, uint256 id, uint256 amount) internal {
        if (to == address(0)) {
            revert ERC6909InvalidReceiver(address(0));
        }
        _update(address(0), to, id, amount);
    }

    /**
     * @dev Moves `amount` of token `id` from `from` to `to` without checking for approvals. This function verifies
     * that neither the sender nor the receiver are address(0), which means it cannot mint or burn tokens.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 id, uint256 amount) internal {
        if (from == address(0)) {
            revert ERC6909InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC6909InvalidReceiver(address(0));
        }
        _update(from, to, id, amount);
    }

    /**
     * @dev Destroys a `amount` of token `id` from `account`.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address from, uint256 id, uint256 amount) internal {
        if (from == address(0)) {
            revert ERC6909InvalidSender(address(0));
        }
        _update(from, address(0), id, amount);
    }

    /**
     * @dev Transfers `amount` of token `id` from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 id, uint256 amount) internal virtual {
        address caller = _msgSender();

        if (from != address(0)) {
            uint256 fromBalance = _balances[from][id];
            if (fromBalance < amount) {
                revert ERC6909InsufficientBalance(from, fromBalance, amount, id);
            }
            unchecked {
                // Overflow not possible: amount <= fromBalance.
                _balances[from][id] = fromBalance - amount;
            }
        }
        if (to != address(0)) {
            _balances[to][id] += amount;
        }

        emit Transfer(caller, from, to, id, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`'s `id` tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to e.g. set automatic allowances for certain
     * subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 id, uint256 amount) internal virtual {
        if (owner == address(0)) {
            revert ERC6909InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC6909InvalidSpender(address(0));
        }
        _allowances[owner][spender][id] = amount;
        emit Approval(owner, spender, id, amount);
    }

    /**
     * @dev Approve `spender` to operate on all of `owner`'s tokens
     *
     * This internal function is equivalent to `setOperator`, and can be used to e.g. set automatic allowances for
     * certain subsystems, etc.
     *
     * Emits an {OperatorSet} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _setOperator(address owner, address spender, bool approved) internal virtual {
        if (owner == address(0)) {
            revert ERC6909InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC6909InvalidSpender(address(0));
        }
        _operatorApprovals[owner][spender] = approved;
        emit OperatorSet(owner, spender, approved);
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 id,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender, id);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < amount) {
                revert ERC6909InsufficientAllowance(spender, currentAllowance, amount, id);
            }
            unchecked {
                _allowances[owner][spender][id] = currentAllowance - amount;
            }
        }
    }
}

// src/policies/utils/PolicyEnabler.sol

/// @title  PolicyEnabler
/// @notice This contract is designed to be inherited by contracts that need to be enabled or disabled. It replaces the inconsistent usage of `active` and `locallyActive` state variables across the codebase.
/// @dev    A contract that inherits from this contract should use the `onlyEnabled` and `onlyDisabled` modifiers to gate access to certain functions.
///
///         Inheriting contracts must do the following:
///         - In `configureDependencies()`, assign the module address to the `ROLES` state variable, e.g. `ROLES = ROLESv1(getModuleAddress(toKeycode("ROLES")));`
///
///         The following are optional:
///         - Override the `_enable()` and `_disable()` functions if custom logic and/or parameters are needed for the enable/disable functions.
///           - For example, `enable()` could be called with initialisation data that is decoded, validated and assigned in `_enable()`.
abstract contract PolicyEnabler is IEnabler, PolicyAdmin {
    // ===== STATE VARIABLES ===== //

    /// @notice Whether the policy functionality is enabled
    bool public isEnabled;

    // ===== MODIFIERS ===== //

    /// @notice Modifier that reverts if the policy is not enabled
    modifier onlyEnabled() {
        if (!isEnabled) revert NotEnabled();
        _;
    }

    /// @notice Modifier that reverts if the policy is enabled
    modifier onlyDisabled() {
        if (isEnabled) revert NotDisabled();
        _;
    }

    // ===== ENABLEABLE FUNCTIONS ===== //

    /// @notice Enable the contract
    /// @dev    This function performs the following steps:
    ///         1. Validates that the caller has the admin role
    ///         2. Validates that the contract is disabled
    ///         3. Calls the implementation-specific `_enable()` function
    ///         4. Changes the state of the contract to enabled
    ///         5. Emits the `Enabled` event
    ///
    /// @param  enableData_ The data to pass to the implementation-specific `_enable()` function
    function enable(bytes calldata enableData_) public onlyAdminRole onlyDisabled {
        // Call the implementation-specific enable function
        _enable(enableData_);

        // Change the state
        isEnabled = true;

        // Emit the enabled event
        emit Enabled();
    }

    /// @notice Implementation-specific enable function
    /// @dev    This function is called by the `enable()` function
    ///
    ///         The implementing contract can override this function and perform the following:
    ///         1. Validate any parameters (if needed) or revert
    ///         2. Validate state (if needed) or revert
    ///         3. Perform any necessary actions, apart from modifying the `isEnabled` state variable
    ///
    /// @param  enableData_ Custom data that can be used by the implementation. The format of this data is
    ///         left to the discretion of the implementation.
    function _enable(bytes calldata enableData_) internal virtual {}

    /// @notice Disable the contract
    /// @dev    This function performs the following steps:
    ///         1. Validates that the caller has the admin or emergency role
    ///         2. Validates that the contract is enabled
    ///         3. Calls the implementation-specific `_disable()` function
    ///         4. Changes the state of the contract to disabled
    ///         5. Emits the `Disabled` event
    ///
    /// @param  disableData_ The data to pass to the implementation-specific `_disable()` function
    function disable(bytes calldata disableData_) public onlyEmergencyOrAdminRole onlyEnabled {
        // Call the implementation-specific disable function
        _disable(disableData_);

        // Change the state
        isEnabled = false;

        // Emit the disabled event
        emit Disabled();
    }

    /// @notice Implementation-specific disable function
    /// @dev    This function is called by the `disable()` function.
    ///
    ///         The implementing contract can override this function and perform the following:
    ///         1. Validate any parameters (if needed) or revert
    ///         2. Validate state (if needed) or revert
    ///         3. Perform any necessary actions, apart from modifying the `isEnabled` state variable
    ///
    /// @param  disableData_ Custom data that can be used by the implementation. The format of this data is
    ///         left to the discretion of the implementation.
    function _disable(bytes calldata disableData_) internal virtual {}

    // ========== ERC165 ========== //

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IEnabler).interfaceId;
    }
}

// dependencies/openzeppelin-new-5.3.0/contracts/token/ERC6909/extensions/draft-ERC6909Metadata.sol

// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC6909/extensions/draft-ERC6909Metadata.sol)

// pragma solidity ^0.8.20;
//Changed from 0.8.20 to 0.8.15 by fuzzer

/**
 * @dev Implementation of the Metadata extension defined in ERC6909. Exposes the name, symbol, and decimals of each token id.
 */
contract ERC6909Metadata is ERC6909, IERC6909Metadata {
    struct TokenMetadata {
        string name;
        string symbol;
        uint8 decimals;
    }

    mapping(uint256 id => TokenMetadata) private _tokenMetadata;

    /// @dev The name of the token of type `id` was updated to `newName`.
    event ERC6909NameUpdated(uint256 indexed id, string newName);

    /// @dev The symbol for the token of type `id` was updated to `newSymbol`.
    event ERC6909SymbolUpdated(uint256 indexed id, string newSymbol);

    /// @dev The decimals value for token of type `id` was updated to `newDecimals`.
    event ERC6909DecimalsUpdated(uint256 indexed id, uint8 newDecimals);

    /// @inheritdoc IERC6909Metadata
    function name(uint256 id) public view virtual override returns (string memory) {
        return _tokenMetadata[id].name;
    }

    /// @inheritdoc IERC6909Metadata
    function symbol(uint256 id) public view virtual override returns (string memory) {
        return _tokenMetadata[id].symbol;
    }

    /// @inheritdoc IERC6909Metadata
    function decimals(uint256 id) public view virtual override returns (uint8) {
        return _tokenMetadata[id].decimals;
    }

    /**
     * @dev Sets the `name` for a given token of type `id`.
     *
     * Emits an {ERC6909NameUpdated} event.
     */
    function _setName(uint256 id, string memory newName) internal virtual {
        _tokenMetadata[id].name = newName;

        emit ERC6909NameUpdated(id, newName);
    }

    /**
     * @dev Sets the `symbol` for a given token of type `id`.
     *
     * Emits an {ERC6909SymbolUpdated} event.
     */
    function _setSymbol(uint256 id, string memory newSymbol) internal virtual {
        _tokenMetadata[id].symbol = newSymbol;

        emit ERC6909SymbolUpdated(id, newSymbol);
    }

    /**
     * @dev Sets the `decimals` for a given token of type `id`.
     *
     * Emits an {ERC6909DecimalsUpdated} event.
     */
    function _setDecimals(uint256 id, uint8 newDecimals) internal virtual {
        _tokenMetadata[id].decimals = newDecimals;

        emit ERC6909DecimalsUpdated(id, newDecimals);
    }
}

// src/libraries/ERC6909Wrappable.sol

// Interfaces

// import {IERC165} from "@openzeppelin-5.3.0/interfaces/IERC165.sol";
//Changed from 5.3.0 to 4.9.0 by fuzzer

// Libraries

// import {EnumerableSet} from "@openzeppelin-5.3.0/utils/structs/EnumerableSet.sol";

/// @title ERC6909Wrappable
/// @notice This abstract contract extends ERC6909 to allow for wrapping and unwrapping of the token to an ERC20 token.
///         It extends the ERC6909Metadata contract, and additionally implements the IERC6909TokenSupply interface.
abstract contract ERC6909Wrappable is ERC6909Metadata, IERC6909Wrappable, IERC6909TokenSupply {
    using ClonesWithImmutableArgs for address;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice The address of the implementation of the ERC20 contract
    address private immutable _ERC20_IMPLEMENTATION;

    /// @notice The set of all token IDs
    EnumerableSet.UintSet internal _wrappableTokenIds;

    /// @notice The total supply of each token
    mapping(uint256 tokenId => uint256) private _totalSupplies;

    /// @notice Additional metadata for each token
    mapping(uint256 tokenId => bytes) private _tokenMetadataAdditional;

    /// @notice The address of the wrapped ERC20 token for each token
    mapping(uint256 tokenId => address) internal _wrappedTokens;

    constructor(address erc20Implementation_) {
        // Validate that the ERC20 implementation implements the required interface
        if (
            !IERC165(erc20Implementation_).supportsInterface(
                type(IERC20BurnableMintable).interfaceId
            )
        ) revert ERC6909Wrappable_InvalidERC20Implementation(erc20Implementation_);

        _ERC20_IMPLEMENTATION = erc20Implementation_;
    }

    /// @notice Returns the clone initialisation data for a given token ID
    function _getTokenData(uint256 tokenId_) internal view returns (bytes memory) {
        bytes memory additionalMetadata = _tokenMetadataAdditional[tokenId_];

        return
            abi.encodePacked(
                bytes32(bytes(name(tokenId_))),
                bytes32(bytes(symbol(tokenId_))),
                decimals(tokenId_),
                additionalMetadata
            );
    }

    // ========== MINT/BURN FUNCTIONS ========== //

    /// @notice Mints the ERC6909 or ERC20 wrapped token to the recipient
    ///
    /// @param onBehalfOf_   The address to mint the token to
    /// @param tokenId_      The ID of the ERC6909 token
    /// @param amount_       The amount of tokens to mint
    /// @param shouldWrap_   Whether to wrap the token to an ERC20 token
    function _mint(
        address onBehalfOf_,
        uint256 tokenId_,
        uint256 amount_,
        bool shouldWrap_
    ) internal onlyValidTokenId(tokenId_) {
        if (amount_ == 0) revert ERC6909Wrappable_ZeroAmount();
        if (onBehalfOf_ == address(0)) revert ERC6909InvalidReceiver(onBehalfOf_);

        if (shouldWrap_) {
            _getWrappedToken(tokenId_).mintFor(onBehalfOf_, amount_);
        } else {
            _mint(onBehalfOf_, tokenId_, amount_);
        }
    }

    /// @notice Burns the ERC6909 or ERC20 wrapped token from the recipient
    ///
    /// @param onBehalfOf_   The address to burn the token from
    /// @param tokenId_      The ID of the ERC6909 token
    /// @param amount_       The amount of tokens to burn
    /// @param wrapped_      Whether the token is wrapped
    function _burn(
        address onBehalfOf_,
        uint256 tokenId_,
        uint256 amount_,
        bool wrapped_
    ) internal onlyValidTokenId(tokenId_) {
        if (amount_ == 0) revert ERC6909Wrappable_ZeroAmount();
        if (onBehalfOf_ == address(0)) revert ERC6909InvalidSender(onBehalfOf_);

        if (wrapped_) {
            // Will revert if the caller has not approved spending
            _getWrappedToken(tokenId_).burnFrom(onBehalfOf_, amount_);
        } else {
            // Spend allowance (since it is not implemented in _burn())
            _spendAllowance(onBehalfOf_, address(this), tokenId_, amount_);

            // Burn the ERC6909 token
            _burn(onBehalfOf_, tokenId_, amount_);
        }
    }

    // ========== TOTAL SUPPLY EXTENSION ========== //

    /// @inheritdoc IERC6909TokenSupply
    function totalSupply(uint256 tokenId_) public view virtual override returns (uint256) {
        return _totalSupplies[tokenId_];
    }

    /// @dev Copied from draft-ERC6909TokenSupply.sol
    function _update(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        // Calls ERC6909Metadata._update()
        super._update(from, to, id, amount);

        if (from == address(0)) {
            _totalSupplies[id] += amount;
        }
        if (to == address(0)) {
            unchecked {
                // amount <= _balances[from][id] <= _totalSupplies[id]
                _totalSupplies[id] -= amount;
            }
        }
    }

    // ========== WRAP/UNWRAP FUNCTIONS ========== //

    /// @dev Returns the address of the wrapped ERC20 token for a given token ID, or creates a new one if it does not exist
    function _getWrappedToken(
        uint256 tokenId_
    ) internal returns (IERC20BurnableMintable wrappedToken) {
        // Validate that the token id exists
        if (decimals(tokenId_) == 0) revert ERC6909Wrappable_InvalidTokenId(tokenId_);

        // If the wrapped token exists, return it
        if (_wrappedTokens[tokenId_] != address(0))
            return IERC20BurnableMintable(_wrappedTokens[tokenId_]);

        // Otherwise, create a new wrapped token
        bytes memory tokenData = _getTokenData(tokenId_);
        wrappedToken = IERC20BurnableMintable(_ERC20_IMPLEMENTATION.clone(tokenData));
        _wrappedTokens[tokenId_] = address(wrappedToken);
        return wrappedToken;
    }

    /// @inheritdoc IERC6909Wrappable
    function getWrappedToken(uint256 tokenId_) public view returns (address wrappedToken) {
        return _wrappedTokens[tokenId_];
    }

    /// @inheritdoc IERC6909Wrappable
    function wrap(
        address onBehalfOf_,
        uint256 tokenId_,
        uint256 amount_
    ) public returns (address wrappedToken) {
        // Burn the ERC6909 token
        _burn(onBehalfOf_, tokenId_, amount_, false);

        // Mint the wrapped ERC20 token to the recipient
        IERC20BurnableMintable wrappedToken_ = _getWrappedToken(tokenId_);
        wrappedToken_.mintFor(onBehalfOf_, amount_);
        return address(wrappedToken_);
    }

    /// @inheritdoc IERC6909Wrappable
    function unwrap(address onBehalfOf_, uint256 tokenId_, uint256 amount_) public {
        // Burn the wrapped ERC20 token
        _burn(onBehalfOf_, tokenId_, amount_, true);

        // Mint the ERC6909 token
        _mint(onBehalfOf_, tokenId_, amount_);
    }

    // ========== TOKEN FUNCTIONS ========== //

    /// @inheritdoc IERC6909Wrappable
    function isValidTokenId(uint256 tokenId_) public view returns (bool) {
        return decimals(tokenId_) > 0;
    }

    modifier onlyValidTokenId(uint256 tokenId_) {
        if (!isValidTokenId(tokenId_)) revert ERC6909Wrappable_InvalidTokenId(tokenId_);
        _;
    }

    /// @notice Creates a new wrappable token
    /// @dev    Reverts if the token ID already exists
    function _createWrappableToken(
        uint256 tokenId_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        bytes memory additionalMetadata_,
        bool createWrappedToken_
    ) internal {
        // If the token ID already exists, revert
        if (_wrappableTokenIds.contains(tokenId_))
            revert ERC6909Wrappable_TokenIdAlreadyExists(tokenId_);

        _setName(tokenId_, name_);
        _setSymbol(tokenId_, symbol_);
        _setDecimals(tokenId_, decimals_);
        _tokenMetadataAdditional[tokenId_] = additionalMetadata_;

        if (createWrappedToken_) {
            _getWrappedToken(tokenId_);
        }

        // Record the token ID
        _wrappableTokenIds.add(tokenId_);
    }

    /// @inheritdoc IERC6909Wrappable
    function getWrappableTokens()
        public
        view
        override
        returns (uint256[] memory tokenIds, address[] memory wrappedTokens)
    {
        tokenIds = _wrappableTokenIds.values();
        wrappedTokens = new address[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; ++i) {
            wrappedTokens[i] = _wrappedTokens[tokenIds[i]];
        }

        return (tokenIds, wrappedTokens);
    }

    // ========== ERC165 ========== //

    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override(ERC6909, IERC165) returns (bool) {
        return
            interfaceId_ == type(IERC6909Wrappable).interfaceId ||
            interfaceId_ == type(IERC6909Metadata).interfaceId ||
            interfaceId_ == type(IERC6909TokenSupply).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}

// src/policies/deposits/DepositManager.sol

// Interfaces

// Libraries

// import {EnumerableSet} from "@openzeppelin-5.3.0/utils/structs/EnumerableSet.sol";
//Changed from 5.3.0 to 4.9.0 by fuzzer

// Bophades

/// @title Deposit Manager
/// @notice This policy is used to manage deposits on behalf of other protocol contracts. For each deposit, a receipt token is minted 1:1 to the depositor.
/// @dev    This contract combines functionality from a number of inherited contracts, in order to simplify contract implementation.
///         Receipt tokens are ERC6909 tokens in order to reduce gas costs. They can optionally be wrapped to an ERC20 token.
contract DepositManager is
    Policy,
    PolicyEnabler,
    IDepositManager,
    BaseAssetManager,
    ERC6909Wrappable
{
    using TransferHelper for ERC20;
    using String for string;
    using EnumerableSet for EnumerableSet.UintSet;

    // ========== CONSTANTS ========== //

    /// @notice The role that is allowed to deposit and withdraw funds
    bytes32 public constant ROLE_DEPOSIT_OPERATOR = "deposit_operator";

    // Tasks
    // [X] Rename to DepositManager
    // [X] Idle/vault strategy for deposited tokens
    // [X] ERC6909 migration
    // [X] Rename to receipt tokens
    // [X] ReceiptTokenSupply to depositor supply
    // [X] borrowing and repayment of deposited funds
    // [X] consider shifting away from policy
    // [X] consider if asset configuration should require a different role

    // ========== STATE VARIABLES ========== //

    /// @notice Maps asset liabilities key to the number of receipt tokens that have been minted
    /// @dev    This is used to ensure that the receipt tokens are solvent
    ///         As with the BaseAssetManager, deposited asset tokens with different deposit periods are co-mingled.
    mapping(bytes32 key => uint256 receiptTokenSupply) internal _assetLiabilities;

    /// @notice Maps token ID to the asset period
    mapping(uint256 tokenId => AssetPeriod) internal _assetPeriods;

    /// @notice Constant equivalent to 100%
    uint16 public constant ONE_HUNDRED_PERCENT = 100e2;

    // ========== BORROWING STATE VARIABLES ========== //

    /// @notice Maps asset-operator key to current borrowed amounts
    /// @dev    The key is the keccak256 of the asset address and the operator address
    mapping(bytes32 key => uint256 borrowedAmount) internal _borrowedAmounts;

    // ========== MODIFIERS ========== //

    /// @notice Reverts if the asset period is not configured
    modifier onlyAssetPeriodExists(IERC20 asset_, uint8 depositPeriod_) {
        if (address(_assetPeriods[getReceiptTokenId(asset_, depositPeriod_)].asset) == address(0)) {
            revert DepositManager_InvalidAssetPeriod(address(asset_), depositPeriod_);
        }
        _;
    }

    /// @notice Reverts if the asset period is not enabled
    modifier onlyAssetPeriodEnabled(IERC20 asset_, uint8 depositPeriod_) {
        AssetPeriod memory assetPeriod = _assetPeriods[getReceiptTokenId(asset_, depositPeriod_)];
        if (assetPeriod.asset == address(0)) {
            revert DepositManager_InvalidAssetPeriod(address(asset_), depositPeriod_);
        }

        if (!assetPeriod.isEnabled) {
            revert DepositManager_AssetPeriodDisabled(address(asset_), depositPeriod_);
        }
        _;
    }

    // ========== CONSTRUCTOR ========== //

    constructor(
        address kernel_
    ) Policy(Kernel(kernel_)) ERC6909Wrappable(address(new CloneableReceiptToken())) {
        // Disabled by default by PolicyEnabler
    }

    // ========== Policy Configuration ========== //

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](1);
        dependencies[0] = toKeycode("ROLES");

        ROLES = ROLESv1(getModuleAddress(dependencies[0]));
    }

    /// @inheritdoc Policy
    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory permissions)
    {}

    function VERSION() external pure returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;

        return (major, minor);
    }

    // ========== DEPOSIT/WITHDRAW FUNCTIONS ========== //

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by addresses with the deposit operator role
    function deposit(
        DepositParams calldata params_
    )
        external
        onlyEnabled
        onlyRole(ROLE_DEPOSIT_OPERATOR)
        onlyAssetPeriodEnabled(params_.asset, params_.depositPeriod)
        returns (uint256 receiptTokenId, uint256 actualAmount)
    {
        // Deposit into vault
        // This will revert if the asset is not configured
        (actualAmount, ) = _depositAsset(params_.asset, params_.depositor, params_.amount);

        // Mint the receipt token to the caller
        receiptTokenId = getReceiptTokenId(params_.asset, params_.depositPeriod);
        _mint(params_.depositor, receiptTokenId, actualAmount, params_.shouldWrap);

        // Update the asset liabilities for the caller (operator)
        _assetLiabilities[_getAssetLiabilitiesKey(params_.asset, msg.sender)] += actualAmount;

        return (receiptTokenId, actualAmount);
    }

    /// @inheritdoc IDepositManager
    function maxClaimYield(IERC20 asset_, address operator_) external view returns (uint256) {
        (, uint256 depositedSharesInAssets) = getOperatorAssets(asset_, operator_);
        bytes32 assetLiabilitiesKey = _getAssetLiabilitiesKey(asset_, operator_);
        uint256 operatorLiabilities = _assetLiabilities[assetLiabilitiesKey];
        uint256 borrowedAmount = _borrowedAmounts[assetLiabilitiesKey];

        // Avoid reverting
        // Adjust by 1 to account for the different behaviour in ERC4626.previewRedeem and ERC4626.previewWithdraw, which could leave the receipt token insolvent
        if (depositedSharesInAssets + borrowedAmount < operatorLiabilities + 1) return 0;

        return depositedSharesInAssets + borrowedAmount - operatorLiabilities - 1;
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by addresses with the deposit operator role
    function claimYield(
        IERC20 asset_,
        address recipient_,
        uint256 amount_
    ) external onlyEnabled onlyRole(ROLE_DEPOSIT_OPERATOR) onlyConfiguredAsset(asset_) {
        // Withdraw the funds from the vault
        (, uint256 actualAmount) = _withdrawAsset(asset_, recipient_, amount_);

        // The receipt token supply is not adjusted here, as there is no minting/burning of receipt tokens

        // Post-withdrawal, there should be at least as many underlying asset tokens as there are receipt tokens, otherwise the receipt token is not redeemable
        (, uint256 depositedSharesInAssets) = getOperatorAssets(asset_, msg.sender);
        bytes32 assetLiabilitiesKey = _getAssetLiabilitiesKey(asset_, msg.sender);
        uint256 borrowedAmount = _borrowedAmounts[assetLiabilitiesKey];
        if (_assetLiabilities[assetLiabilitiesKey] > depositedSharesInAssets + borrowedAmount) {
            revert DepositManager_Insolvent(
                address(asset_),
                _assetLiabilities[assetLiabilitiesKey]
            );
        }

        // Emit an event
        emit ClaimedYield(address(asset_), recipient_, msg.sender, actualAmount);
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by addresses with the deposit operator role
    function withdraw(
        WithdrawParams calldata params_
    ) external onlyEnabled onlyRole(ROLE_DEPOSIT_OPERATOR) returns (uint256 actualAmount) {
        // Validate that the recipient is not the zero address
        if (params_.recipient == address(0)) revert DepositManager_ZeroAddress();

        // Burn the receipt token from the depositor
        // Will revert if the asset configuration is not valid/invalid receipt token ID
        _burn(
            params_.depositor,
            getReceiptTokenId(params_.asset, params_.depositPeriod),
            params_.amount,
            params_.isWrapped
        );

        // Update the asset liabilities for the caller (operator)
        _assetLiabilities[_getAssetLiabilitiesKey(params_.asset, msg.sender)] -= params_.amount;

        // Withdraw the funds from the vault to the recipient
        // This will revert if the asset is not configured
        (, actualAmount) = _withdrawAsset(params_.asset, params_.recipient, params_.amount);

        return actualAmount;
    }

    /// @inheritdoc IDepositManager
    function getOperatorLiabilities(
        IERC20 asset_,
        address operator_
    ) external view returns (uint256) {
        return _assetLiabilities[_getAssetLiabilitiesKey(asset_, operator_)];
    }

    /// @notice Get the key for the asset liabilities mapping
    /// @dev    The key is the keccak256 of the asset address and the operator address
    function _getAssetLiabilitiesKey(
        IERC20 asset_,
        address operator_
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(address(asset_), operator_));
    }

    // ========== ASSET PERIOD ========== //

    /// @inheritdoc IDepositManager
    function isAssetPeriod(
        IERC20 asset_,
        uint8 depositPeriod_
    ) public view override returns (AssetPeriodStatus memory status) {
        uint256 receiptTokenId = getReceiptTokenId(asset_, depositPeriod_);
        status.isConfigured = address(_assetPeriods[receiptTokenId].asset) != address(0);
        status.isEnabled = _assetPeriods[receiptTokenId].isEnabled;

        return status;
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by the manager or admin role
    function addAsset(
        IERC20 asset_,
        IERC4626 vault_,
        uint256 depositCap_
    ) external onlyEnabled onlyManagerOrAdminRole {
        _addAsset(asset_, vault_, depositCap_);
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by the manager or admin role
    function setAssetDepositCap(
        IERC20 asset_,
        uint256 depositCap_
    ) external onlyEnabled onlyManagerOrAdminRole {
        _setAssetDepositCap(asset_, depositCap_);
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by the manager or admin role
    function addAssetPeriod(
        IERC20 asset_,
        uint8 depositPeriod_,
        uint16 reclaimRate_
    )
        external
        onlyEnabled
        onlyManagerOrAdminRole
        onlyConfiguredAsset(asset_)
        returns (uint256 receiptTokenId)
    {
        // Validate that the deposit period is not 0
        if (depositPeriod_ == 0) revert DepositManager_OutOfBounds();

        // Validate that the asset and deposit period combination is not already configured
        if (isAssetPeriod(asset_, depositPeriod_).isConfigured) {
            revert DepositManager_AssetPeriodExists(address(asset_), depositPeriod_);
        }

        // Configure the ERC6909 receipt token
        receiptTokenId = _setReceiptTokenData(asset_, depositPeriod_);

        // Set the asset period
        _assetPeriods[receiptTokenId] = AssetPeriod({
            isEnabled: true,
            depositPeriod: depositPeriod_,
            reclaimRate: 0,
            asset: address(asset_)
        });

        // Set the reclaim rate (which does validation and emits an event)
        _setAssetPeriodReclaimRate(asset_, depositPeriod_, reclaimRate_);

        // Emit event
        emit AssetPeriodConfigured(receiptTokenId, address(asset_), depositPeriod_);

        return receiptTokenId;
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by the manager or admin role
    function enableAssetPeriod(
        IERC20 asset_,
        uint8 depositPeriod_
    ) external onlyEnabled onlyManagerOrAdminRole onlyAssetPeriodExists(asset_, depositPeriod_) {
        // Validate that the asset period is disabled
        uint256 tokenId = getReceiptTokenId(asset_, depositPeriod_);
        if (_assetPeriods[tokenId].isEnabled) {
            revert DepositManager_AssetPeriodEnabled(address(asset_), depositPeriod_);
        }

        // Enable the asset period
        _assetPeriods[getReceiptTokenId(asset_, depositPeriod_)].isEnabled = true;

        // Emit event
        emit AssetPeriodEnabled(tokenId, address(asset_), depositPeriod_);
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by the manager or admin role
    function disableAssetPeriod(
        IERC20 asset_,
        uint8 depositPeriod_
    ) external onlyEnabled onlyManagerOrAdminRole onlyAssetPeriodExists(asset_, depositPeriod_) {
        // Validate that the asset period is enabled
        uint256 tokenId = getReceiptTokenId(asset_, depositPeriod_);
        if (!_assetPeriods[tokenId].isEnabled) {
            revert DepositManager_AssetPeriodDisabled(address(asset_), depositPeriod_);
        }

        // Disable the asset period
        _assetPeriods[getReceiptTokenId(asset_, depositPeriod_)].isEnabled = false;

        // Emit event
        emit AssetPeriodDisabled(tokenId, address(asset_), depositPeriod_);
    }

    /// @inheritdoc IDepositManager
    function getAssetPeriods() external view returns (AssetPeriod[] memory) {
        uint256 tokenIdsLength = _wrappableTokenIds.length();
        AssetPeriod[] memory depositAssets = new AssetPeriod[](tokenIdsLength);
        for (uint256 i; i < tokenIdsLength; ++i) {
            depositAssets[i] = _assetPeriods[_wrappableTokenIds.at(i)];
        }
        return depositAssets;
    }

    /// @inheritdoc IDepositManager
    function getAssetPeriod(uint256 tokenId_) public view override returns (AssetPeriod memory) {
        return _assetPeriods[tokenId_];
    }

    /// @inheritdoc IDepositManager
    function getAssetPeriod(
        IERC20 asset_,
        uint8 depositPeriod_
    ) public view override returns (AssetPeriod memory) {
        return _assetPeriods[getReceiptTokenId(asset_, depositPeriod_)];
    }

    // ========== DEPOSIT RECLAIM RATE ========== //

    /// @dev Assumes that the token ID is valid
    function _setAssetPeriodReclaimRate(
        IERC20 asset_,
        uint8 depositPeriod_,
        uint16 reclaimRate_
    ) internal {
        if (reclaimRate_ > ONE_HUNDRED_PERCENT) revert DepositManager_OutOfBounds();

        _assetPeriods[getReceiptTokenId(asset_, depositPeriod_)].reclaimRate = reclaimRate_;
        emit AssetPeriodReclaimRateSet(address(asset_), depositPeriod_, reclaimRate_);
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by the manager or admin role
    function setAssetPeriodReclaimRate(
        IERC20 asset_,
        uint8 depositPeriod_,
        uint16 reclaimRate_
    ) external onlyEnabled onlyManagerOrAdminRole onlyAssetPeriodExists(asset_, depositPeriod_) {
        _setAssetPeriodReclaimRate(asset_, depositPeriod_, reclaimRate_);
    }

    /// @inheritdoc IDepositManager
    function getAssetPeriodReclaimRate(
        IERC20 asset_,
        uint8 depositPeriod_
    ) external view returns (uint16) {
        return _assetPeriods[getReceiptTokenId(asset_, depositPeriod_)].reclaimRate;
    }

    // ========== BORROWING FUNCTIONS ========== //

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by addresses with the deposit operator role
    function borrowingWithdraw(
        BorrowingWithdrawParams calldata params_
    ) external onlyEnabled onlyRole(ROLE_DEPOSIT_OPERATOR) returns (uint256 actualAmount) {
        // Validate that the recipient is not the zero address
        if (params_.recipient == address(0)) revert DepositManager_ZeroAddress();

        // Validate that the asset is configured
        if (!_isConfiguredAsset(params_.asset)) revert AssetManager_NotConfigured();

        // Check borrowing capacity
        uint256 availableCapacity = getBorrowingCapacity(params_.asset, msg.sender);
        if (params_.amount > availableCapacity) {
            revert DepositManager_BorrowingLimitExceeded(
                address(params_.asset),
                msg.sender,
                params_.amount,
                availableCapacity
            );
        }

        // Withdraw the funds from the vault to the recipient
        (, actualAmount) = _withdrawAsset(params_.asset, params_.recipient, params_.amount);

        // Update borrowed amount
        // This is done after the withdraw, as the actual amount is not known ahead of time
        _borrowedAmounts[_getAssetLiabilitiesKey(params_.asset, msg.sender)] += actualAmount;

        // Emit event
        emit BorrowingWithdrawal(
            address(params_.asset),
            msg.sender,
            params_.recipient,
            actualAmount
        );

        return actualAmount;
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by addresses with the deposit operator role
    function borrowingRepay(
        BorrowingRepayParams calldata params_
    ) external onlyEnabled onlyRole(ROLE_DEPOSIT_OPERATOR) returns (uint256 actualAmount) {
        // Validate that the asset is configured
        if (!_isConfiguredAsset(params_.asset)) revert AssetManager_NotConfigured();

        // Get the borrowing key
        bytes32 borrowingKey = _getAssetLiabilitiesKey(params_.asset, msg.sender);

        // Check that the operator is not over-paying
        // This would cause accounting issues
        uint256 currentBorrowed = _borrowedAmounts[borrowingKey];
        if (currentBorrowed < params_.amount) {
            revert DepositManager_BorrowedAmountExceeded(
                address(params_.asset),
                msg.sender,
                params_.amount,
                currentBorrowed
            );
        }

        // Transfer funds from payer to this contract
        // We ignore the actual amount deposited into the vault, as the payer will not be able to over-pay in case of an off-by-one issue
        _depositAsset(params_.asset, params_.payer, params_.amount);

        // Update borrowed amount
        _borrowedAmounts[borrowingKey] -= params_.amount;

        // Emit event
        emit BorrowingRepayment(address(params_.asset), msg.sender, params_.payer, params_.amount);

        return params_.amount;
    }

    /// @inheritdoc IDepositManager
    /// @dev        This function is only callable by addresses with the deposit operator role
    function borrowingDefault(
        BorrowingDefaultParams calldata params_
    ) external onlyEnabled onlyRole(ROLE_DEPOSIT_OPERATOR) {
        // Validate that the asset is configured
        if (!_isConfiguredAsset(params_.asset)) revert AssetManager_NotConfigured();

        // Get the borrowing key
        bytes32 borrowingKey = _getAssetLiabilitiesKey(params_.asset, msg.sender);

        // Check that the operator is not over-paying
        // This would cause accounting issues
        uint256 currentBorrowed = _borrowedAmounts[borrowingKey];
        if (currentBorrowed < params_.amount) {
            revert DepositManager_BorrowedAmountExceeded(
                address(params_.asset),
                msg.sender,
                params_.amount,
                currentBorrowed
            );
        }

        // Burn the receipt tokens from the payer
        _burn(
            params_.payer,
            getReceiptTokenId(params_.asset, params_.depositPeriod),
            params_.amount,
            false
        );

        // Update the asset liabilities for the caller (operator)
        _assetLiabilities[_getAssetLiabilitiesKey(params_.asset, msg.sender)] -= params_.amount;

        // Update the borrowed amount
        _borrowedAmounts[borrowingKey] -= params_.amount;

        // No need to update the operator shares, as the balance has already been adjusted upon withdraw/repay

        // Emit event
        emit BorrowingDefault(address(params_.asset), msg.sender, params_.payer, params_.amount);
    }

    /// @inheritdoc IDepositManager
    function getBorrowedAmount(
        IERC20 asset_,
        address operator_
    ) public view returns (uint256 borrowed) {
        return _borrowedAmounts[_getAssetLiabilitiesKey(asset_, operator_)];
    }

    /// @inheritdoc IDepositManager
    function getBorrowingCapacity(
        IERC20 asset_,
        address operator_
    ) public view returns (uint256 capacity) {
        uint256 operatorLiabilities = _assetLiabilities[_getAssetLiabilitiesKey(asset_, operator_)];
        uint256 currentBorrowed = getBorrowedAmount(asset_, operator_);

        // This is unlikely to happen, but included to avoid a revert
        if (currentBorrowed >= operatorLiabilities) {
            return 0;
        }

        return operatorLiabilities - currentBorrowed;
    }

    // ========== RECEIPT TOKEN FUNCTIONS ========== //

    function _setReceiptTokenData(
        IERC20 asset_,
        uint8 depositPeriod_
    ) internal returns (uint256 tokenId) {
        // Generate a unique token ID for the token and deposit period combination
        tokenId = getReceiptTokenId(asset_, depositPeriod_);

        // Create the receipt token
        _createWrappableToken(
            tokenId,
            string
                .concat(asset_.name(), " Receipt - ", uint2str(depositPeriod_), " months")
                .truncate32(),
            string.concat("r", asset_.symbol(), "-", uint2str(depositPeriod_), "m").truncate32(),
            asset_.decimals(),
            abi.encodePacked(
                address(this), // Owner
                address(asset_), // Asset
                depositPeriod_ // Deposit Period
            ),
            false
        );

        return tokenId;
    }

    /// @inheritdoc IDepositManager
    function getReceiptTokenId(
        IERC20 asset_,
        uint8 depositPeriod_
    ) public pure override returns (uint256) {
        return uint256(keccak256(abi.encode(asset_, depositPeriod_)));
    }

    /// @inheritdoc IDepositManager
    /// @dev        This is the same as the ERC6909 name() function, but is included for consistency
    function getReceiptTokenName(uint256 tokenId_) external view override returns (string memory) {
        return name(tokenId_);
    }

    /// @inheritdoc IDepositManager
    /// @dev        This is the same as the ERC6909 symbol() function, but is included for consistency
    function getReceiptTokenSymbol(
        uint256 tokenId_
    ) external view override returns (string memory) {
        return symbol(tokenId_);
    }

    /// @inheritdoc IDepositManager
    /// @dev        This is the same as the ERC6909 decimals() function, but is included for consistency
    function getReceiptTokenDecimals(uint256 tokenId_) external view override returns (uint8) {
        return decimals(tokenId_);
    }

    /// @inheritdoc IDepositManager
    function getReceiptTokenOwner(uint256) external view override returns (address) {
        return address(this);
    }

    /// @inheritdoc IDepositManager
    function getReceiptTokenAsset(uint256 tokenId_) external view override returns (IERC20) {
        return IERC20(_assetPeriods[tokenId_].asset);
    }

    /// @inheritdoc IDepositManager
    function getReceiptTokenDepositPeriod(uint256 tokenId_) external view override returns (uint8) {
        return _assetPeriods[tokenId_].depositPeriod;
    }

    // ========== ERC165 ========== //

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC6909Wrappable, BaseAssetManager, PolicyEnabler)
        returns (bool)
    {
        return
            interfaceId == type(IDepositManager).interfaceId ||
            ERC6909Wrappable.supportsInterface(interfaceId) ||
            BaseAssetManager.supportsInterface(interfaceId) ||
            PolicyEnabler.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library TestStringUtils {
    error WordIndexOutOfBounds();

    /**
     * @notice Reads the nth word from a string. A word is defined as a sequence of characters separated by spaces.
     * @param input The input string
     * @param n The index of the word to return (0-indexed). Negative values are supported, where -1 is the last word,
     * -2 the second to last, etc.
     * @return word The nth word
     */
    function getNthWord(string memory input, int256 n) internal pure returns (string memory) {
        bytes memory strBytes = bytes(input);
        uint256 targetIndex = _resolveTargetIndex(strBytes, n);
        return _extractWord(strBytes, targetIndex);
    }

    function _countWords(bytes memory strBytes) private pure returns (uint256 wordCount) {
        uint256 length = strBytes.length;
        bool inWord = false;

        for (uint256 i = 0; i <= length; i++) {
            if (i == length || strBytes[i] == 0x20) {
                if (inWord) {
                    wordCount++;
                    inWord = false;
                }
            } else if (!inWord) {
                inWord = true;
            }
        }
    }

    function _resolveTargetIndex(bytes memory strBytes, int256 n) private pure returns (uint256) {
        uint256 wordCount = _countWords(strBytes);

        if (wordCount == 0) {
            revert WordIndexOutOfBounds();
        }

        int256 targetIndexSigned;
        if (n >= 0) {
            if (uint256(n) >= wordCount) {
                revert WordIndexOutOfBounds();
            }
            targetIndexSigned = n;
        } else {
            // Negative index: -1 is last word, -2 is second to last, etc.
            targetIndexSigned = int256(wordCount) + n;
            if (targetIndexSigned < 0 || uint256(targetIndexSigned) >= wordCount) {
                revert WordIndexOutOfBounds();
            }
        }

        return uint256(targetIndexSigned);
    }

    function _extractWord(bytes memory strBytes, uint256 targetIndex) private pure returns (string memory) {
        uint256 length = strBytes.length;
        uint256 wordStart = 0;
        uint256 currentIndex = 0;
        bool inWord = false;

        for (uint256 i = 0; i <= length; i++) {
            if (i == length || strBytes[i] == 0x20) {
                if (inWord) {
                    if (currentIndex == targetIndex) {
                        uint256 wordLength = i - wordStart;
                        bytes memory wordBytes = new bytes(wordLength);
                        for (uint256 j = 0; j < wordLength; j++) {
                            wordBytes[j] = strBytes[wordStart + j];
                        }
                        return string(wordBytes);
                    }
                    currentIndex++;
                    inWord = false;
                }
            } else if (!inWord) {
                inWord = true;
                wordStart = i;
            }
        }

        revert WordIndexOutOfBounds();
    }
}


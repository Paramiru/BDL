# Blockchain and Distributed Ledgers (2021 - 2022)
Year 4 course
Grade: 


## Matching Pennies
Tis smart contract implements a secure Matching Pennies game in Solidity ready to be deployed on the Ethereum blockchain. The game follows several steps:

1. Two players register in the game and place their bet.
2. Each player picks a move and a salt value. They compute their commitment with it and send it to the smart contract.
3. After both players have sent their commitments, they will reveal their moves.
4. The winner will be computed and s/he will be able to retrieve the money.
5. The game is resetted and can be played again.

All the implementation details can be found in the <a href="https://github.com/Paramiru/BlockchainCourse/blob/main/MatchingPennies/MatchingPenniesReport.pdf">coursework-document.pdf</a>

## BDL Token
This folder contains the api for defining an ERC-20 token which can be bought, transferred and sold.

## Chess Game

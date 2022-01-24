// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.7.0 <0.9.0;

contract MatchingPennies {
    
    uint constant public AMOUNT_TO_BET = 1 ether; // Value of the bet of each player
    uint32 constant public TIMEOUT = 5 minutes; // after TIMEOUT results the game can be finished
    
    uint private startTime;
    
    enum Choices { Heads, Tails, NA }
    enum Results { Player1, Player2, Draw }
    
    struct Player {
        address _address;
        bytes32 commitment;
        Choices choice;
    }
    
    mapping(uint32 => Player) players;
    mapping(address => uint) private balances;
    
    modifier isCorrectAmountSent() {
        require(msg.value == AMOUNT_TO_BET);
        _;
    }
    
    modifier isAddressNotRegistered() {
        require(msg.sender != players[1]._address && msg.sender != players[2]._address);
        _;
    }
    
    function register() public payable isCorrectAmountSent isAddressNotRegistered returns (string memory) {
        if (players[1]._address == address(0)) {
            Player memory player1 = Player(msg.sender, 0, Choices.NA);
            players[1] = player1;
            return "You have been assigned to Player 1";
        } else if (players[2]._address == address(0)) {
            Player memory player2 = Player(msg.sender, 0, Choices.NA);
            players[2] = player2;
            return "You have been assigned to Player 2";
        } else {
            return "Sorry, there are two players already. You will be able to play when they finish! ;)";
        }
    }
        
    // Choice is "1" for Heads and "2" for Tails
    // Salt is a random string to compute the hash value. Similar as how passwords are stored in your laptop.
    // e.g. with trueValue = "1" and salt = "HelloWorld!" we are commiting to Heads!
    function computeCommitment(string memory choice, string memory salt) public pure returns (bytes32 commitment) {
        return keccak256(abi.encodePacked(choice, salt));
    }
    
    modifier isPlayer1() {
        require(msg.sender == players[1]._address);
        _;
    }
    
    // Store player's commitment if he/she is registered and has not played
    function play1(bytes32 commitment) public isPlayer1 {
        if (players[1].commitment == 0) {
            players[1].commitment = commitment;
        }
    }
    
    modifier hasPlayer1Committed() {
        require(players[1].commitment != 0);
        _;
    }
    
    modifier isPlayer2() {
        require(msg.sender == players[2]._address);
        _;
    }
    
    function play2(bytes32 commitment) public isPlayer2 hasPlayer1Committed {
        if (players[2].commitment == 0) {
            players[2].commitment = commitment;
        }
    }
    
    
    function getChoiceFromDecryptedCommitment(bytes memory decryptedCommitment) private pure returns (Choices) {
        // Get first byte
        bytes1 firstByte = decryptedCommitment[0];
        // 0x31 corresponds to char '1' in HEX
        // 1 corresponds to heads; 2 to Tails
        if (firstByte == 0x31) {
            return Choices.Heads;
        } else if (firstByte == 0x32) {
            return Choices.Tails;
        } else {
            return Choices.NA;
        }
    }
    
    modifier haveAllPlayersCommitted() {
        require(players[1].commitment != 0 && players[2].commitment != 0);
        _;
    }
    
    modifier isAddressRegistered() {
        require(msg.sender == players[1]._address || msg.sender == players[2]._address);
        _;
    }
    
    function revealChoiceFromCommitment(
        string memory revealedChoice, 
        string memory salt
        ) public isAddressRegistered haveAllPlayersCommitted returns (Choices) {
        
        bytes memory decryptedCommitment = abi.encodePacked(revealedChoice, salt);
        bytes32 commitmentFromInputValue = keccak256(decryptedCommitment);
        Choices choice = getChoiceFromDecryptedCommitment(decryptedCommitment);
        
        if (msg.sender == players[1]._address && commitmentFromInputValue == players[1].commitment) {
            players[1].choice = choice;
        } else if (msg.sender == players[2]._address && commitmentFromInputValue == players[2].commitment) {
            players[2].choice = choice;
        } else {
            return Choices.NA;
        }
        
        if (startTime == 0) {
            startTime = block.timestamp;
        }
        
        return choice;
    }
    
    modifier canComputeResult() {
        require(
            (block.timestamp > startTime + TIMEOUT) ||
            (players[1].choice != Choices.NA && players[2].choice != Choices.NA)
        );
        _;
    }
    
    function finishGame() public canComputeResult returns (Results) {
        Results result;
        
        bool player1Wins = players[2].choice == Choices.NA || 
            players[1].choice == players[2].choice;

        if (players[1].choice == Choices.NA && players[2].choice == Choices.NA) {
            result = Results.Draw;
        } else if (player1Wins) {
            result = Results.Player1;
        } else {
            result = Results.Player2;
        }
        
        address payable address1 = payable(players[1]._address);
        address payable address2 = payable(players[2]._address);
        
        reset();
        updateBalances(address1, address2, result);
        
        return result;
    }
    
    function reset() private {
        startTime = 0;
        Player memory emptyPlayer = Player(address(0), 0, Choices.NA);
        players[1] = emptyPlayer;
        players[2] = emptyPlayer;
    }
    
    function updateBalances(address payable address1, address payable address2, Results result) private {
        if (result == Results.Player1) {
            balances[address1] += AMOUNT_TO_BET * 2;
        } else if (result == Results.Player2) {
            balances[address2] += AMOUNT_TO_BET * 2;
        } else {
            balances[address1] += AMOUNT_TO_BET;
            balances[address2] += AMOUNT_TO_BET;
        }
    }
    
    function withdraw() public {
        uint balance = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }
    
    modifier canPlayer1CancelBet() {
        require(msg.sender == players[1]._address && players[2]._address == address(0));
        _;
    }
    function cancelBet() public canPlayer1CancelBet {
        Player memory emptyPlayer = Player(address(0), 0, Choices.NA);
        players[1] = emptyPlayer;
        balances[msg.sender] += AMOUNT_TO_BET;
    }
    
    function checkBalanceInContract() public view returns(uint) {
        return balances[msg.sender];
    }
    
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function whoAmI() public view returns (string memory) {
        if (msg.sender == players[1]._address) {
            return "You are player 1";
        } else if (msg.sender == players[2]._address) {
            return "You are player 2";
        } else {
            return "You are not playing the game";
        }
    }
    
    function timeForTimerToEnd() public view returns (uint) {
        if (startTime != 0) {
            uint remainingTime = startTime + TIMEOUT - block.timestamp;
            if (remainingTime < 0) {
                return 0;
            } else {
                return remainingTime;
            }
        }
        return TIMEOUT;
    }
    
    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Experimental contracts by Blipn

// This contract is a reward erc20 token used by the BlockchainTextPublisher contract
contract RewardToken is ERC20, Ownable {
    constructor() ERC20("Blockchain Text Publisher", "BTP") Ownable(msg.sender) {}

    function mintForEach(address author, address voter, uint256 authorAmount, uint256 voterAmount) external onlyOwner {
        _mint(author, authorAmount);
        _mint(voter, voterAmount);
    }
}

// This contract may be use to store text data in a blockchain
contract BlockchainTextPublisher is Ownable(msg.sender) {
    RewardToken public rewardToken;

    struct Book {
        uint256 id;
        string text;
        string title;
        uint256 categoryId;
        address author;
        uint256 timestamp;
        int256 votes; // Total votes count for the book
    }

    struct Category {
        string name;
        uint256 count;
    }

    struct Vote {
        uint256 bookId;
        address voter;
        bool upvote;
        uint256 timestamp;
    }

    uint256 public nextBookId = 1;
    uint256 public nextVoteId = 1;
    uint256 public nextCategoryId = 1;
    mapping(uint256 => Book) public books; // Mapping from bookId to Book
    mapping(uint256 => Vote) public votes; // Mapping from voteId to Vote
    mapping(uint256 => uint256[]) public votesByBook; // Mapping bookId to voteIds list
    mapping(address => mapping(uint256 => bool)) public hasVoted; // Vote address => BookId => hasVoted

    mapping(uint256 => Category) public categories; // Mapping from categoryId to Category
    mapping(uint256 => uint256[]) private booksByCategory;

    constructor() {
        rewardToken = new RewardToken();
    }

    // Function to add a new category
    function addCategory(string calldata name) public {
        categories[nextCategoryId] = Category(name, 0);
        nextCategoryId++;
    }

    function getBooksByCategory(uint256 categoryId) external view returns (uint256[] memory) {
        return booksByCategory[categoryId];
    }

    function addBook(string calldata title, uint256 categoryId, string calldata text) external {
        require(categoryId < nextCategoryId, "Invalid category ID");
        categories[categoryId].count += 1; // Increment the count for the given category

        books[nextBookId] = Book(nextBookId, text, title, categoryId, msg.sender, block.timestamp, 0);
        booksByCategory[categoryId].push(nextBookId);

        nextBookId++;
    }

    function voteOnBook(uint256 bookId, bool upvote) external {
        require(books[bookId].author != address(0), "Book does not exist.");
        require(!hasVoted[msg.sender][bookId], "Already voted on this book.");

        hasVoted[msg.sender][bookId] = true;
        if(upvote) {
            books[bookId].votes++;
        } else {
            books[bookId].votes--;
        }

        votes[nextVoteId] = Vote(bookId, msg.sender, upvote, block.timestamp);
        votesByBook[bookId].push(nextVoteId);
        nextVoteId++;

        // Mint reward tokens for voting and for the book's author
        rewardToken.mintForEach(books[bookId].author, msg.sender, 1, 1);

    }

    function getVotesByBookId(uint256 bookId) external view returns (uint256[] memory) {
        return votesByBook[bookId];
    }
}

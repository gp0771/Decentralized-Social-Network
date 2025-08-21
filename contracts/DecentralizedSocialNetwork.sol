// SPDX-License-Identifier: mit
pragma solidity ^0.8.19;

contract DecentralizedSocialNetwork {
    struct Post {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        uint256 likes;
        bool exists;
    }

    struct User {
        address userAddress;
        string username;
        string bio;
        uint256 postCount;
        bool exists;
    }

    mapping(address => User) public users;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(address => uint256[]) public userPosts;

    uint256 public totalPosts;
    uint256 public totalUsers;

    event UserRegistered(address indexed user, string username);
    event PostCreated(uint256 indexed postId, address indexed author, string content);
    event PostLiked(uint256 indexed postId, address indexed liker);

    modifier onlyRegisteredUser() {
        require(users[msg.sender].exists, "User not registered");
        _;
    }

    modifier validPost(uint256 _postId) {
        require(posts[_postId].exists, "Post does not exist");
        _;
    }

    // Register a new user
    function registerUser(string memory _username, string memory _bio) external {
        require(!users[msg.sender].exists, "User already registered");
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(bytes(_username).length <= 50, "Username too long");
        require(bytes(_bio).length <= 200, "Bio too long");

        users[msg.sender] = User({
            userAddress: msg.sender,
            username: _username,
            bio: _bio,
            postCount: 0,
            exists: true
        });

        totalUsers++;
        emit UserRegistered(msg.sender, _username);
    }

    // Create a new post
    function createPost(string memory _content) external onlyRegisteredUser {
        require(bytes(_content).length > 0, "Content cannot be empty");

        uint256 postId = totalPosts++;
        posts[postId] = Post({
            id: postId,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            exists: true
        });

        userPosts[msg.sender].push(postId);
        users[msg.sender].postCount++;

        emit PostCreated(postId, msg.sender, _content);
    }

    // Like or Unlike a post
    function toggleLike(uint256 _postId) external onlyRegisteredUser validPost(_postId) {
        require(posts[_postId].author != msg.sender, "Cannot like your own post");

        if (hasLiked[_postId][msg.sender]) {
            posts[_postId].likes--;
            hasLiked[_postId][msg.sender] = false;
        } else {
            posts[_postId].likes++;
            hasLiked[_postId][msg.sender] = true;
            emit PostLiked(_postId, msg.sender);
        }
    }

    // Get a user profile
    function getUser(address _userAddress) external view returns (User memory) {
        require(users[_userAddress].exists, "User does not exist");
        return users[_userAddress];
    }

    // Get a post
    function getPost(uint256 _postId) external view returns (Post memory) {
        require(posts[_postId].exists, "Post does not exist");
        return posts[_postId];
    }

    // Get all post IDs of a user
    function getUserPosts(address _userAddress) external view returns (uint256[] memory) {
        return userPosts[_userAddress];
    }

    // Get latest N posts (up to 50)
    function getLatestPosts(uint256 count) external view returns (Post[] memory) {
        require(count > 0 && count <= 50, "Count must be between 1 and 50");

        uint256 resultCount = count > totalPosts ? totalPosts : count;
        Post[] memory latestPosts = new Post[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            latestPosts[i] = posts[totalPosts - 1 - i];
        }

        return latestPosts;
    }
}






// SPDX-License-Identifier: mit
pragma solidity ^0.8.19;

contract DecentralizedSocialNetwork {
    struct Post {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        uint256 likes;
        uint256 commentCount;
        bool exists;
    }

    struct User {
        address userAddress;
        string username;
        string bio;
        uint256 postCount;
        uint256 commentCount;
        bool exists;
    }

    struct Comment {
        uint256 id;
        uint256 postId;
        address author;
        string content;
        uint256 timestamp;
        uint256 likes;
        uint256 parentCommentId; // 0 if top-level comment
        uint256 replyCount;
        bool exists;
    }

    mapping(address => User) public users;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => Comment) public comments;
    mapping(uint256 => mapping(address => bool)) public hasLikedPost;
    mapping(uint256 => mapping(address => bool)) public hasLikedComment;
    mapping(address => uint256[]) public userPosts;
    mapping(address => uint256[]) public userComments;
    mapping(uint256 => uint256[]) public postComments; // postId => commentIds
    mapping(uint256 => uint256[]) public commentReplies; // commentId => replyIds

    uint256 public totalPosts;
    uint256 public totalUsers;
    uint256 public totalComments;

    event UserRegistered(address indexed user, string username);
    event PostCreated(uint256 indexed postId, address indexed author, string content);
    event PostLiked(uint256 indexed postId, address indexed liker);
    event PostUnliked(uint256 indexed postId, address indexed unliker);
    event CommentCreated(uint256 indexed commentId, uint256 indexed postId, address indexed author, string content);
    event CommentLiked(uint256 indexed commentId, address indexed liker);
    event CommentUnliked(uint256 indexed commentId, address indexed unliker);
    event ReplyCreated(uint256 indexed replyId, uint256 indexed parentCommentId, address indexed author, string content);

    modifier onlyRegisteredUser() {
        require(users[msg.sender].exists, "User not registered");
        _;
    }

    modifier validPost(uint256 _postId) {
        require(posts[_postId].exists, "Post does not exist");
        _;
    }

    modifier validComment(uint256 _commentId) {
        require(comments[_commentId].exists, "Comment does not exist");
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
            commentCount: 0,
            exists: true
        });

        totalUsers++;
        emit UserRegistered(msg.sender, _username);
    }

    // Create a new post
    function createPost(string memory _content) external onlyRegisteredUser {
        require(bytes(_content).length > 0, "Content cannot be empty");
        require(bytes(_content).length <= 1000, "Content too long");

        uint256 postId = totalPosts++;
        posts[postId] = Post({
            id: postId,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            commentCount: 0,
            exists: true
        });

        userPosts[msg.sender].push(postId);
        users[msg.sender].postCount++;

        emit PostCreated(postId, msg.sender, _content);
    }

    // Like or Unlike a post
    function togglePostLike(uint256 _postId) external onlyRegisteredUser validPost(_postId) {
        require(posts[_postId].author != msg.sender, "Cannot like your own post");

        if (hasLikedPost[_postId][msg.sender]) {
            posts[_postId].likes--;
            hasLikedPost[_postId][msg.sender] = false;
            emit PostUnliked(_postId, msg.sender);
        } else {
            posts[_postId].likes++;
            hasLikedPost[_postId][msg.sender] = true;
            emit PostLiked(_postId, msg.sender);
        }
    }

    // Create a new comment on a post
    function createComment(uint256 _postId, string memory _content) external onlyRegisteredUser validPost(_postId) {
        require(bytes(_content).length > 0, "Comment cannot be empty");
        require(bytes(_content).length <= 500, "Comment too long");

        uint256 commentId = totalComments++;
        comments[commentId] = Comment({
            id: commentId,
            postId: _postId,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            parentCommentId: 0, // Top-level comment
            replyCount: 0,
            exists: true
        });

        postComments[_postId].push(commentId);
        userComments[msg.sender].push(commentId);
        posts[_postId].commentCount++;
        users[msg.sender].commentCount++;

        emit CommentCreated(commentId, _postId, msg.sender, _content);
    }

    // Reply to an existing comment
    function replyToComment(uint256 _parentCommentId, string memory _content) external onlyRegisteredUser validComment(_parentCommentId) {
        require(bytes(_content).length > 0, "Reply cannot be empty");
        require(bytes(_content).length <= 500, "Reply too long");

        uint256 postId = comments[_parentCommentId].postId;
        uint256 replyId = totalComments++;

        comments[replyId] = Comment({
            id: replyId,
            postId: postId,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            parentCommentId: _parentCommentId,
            replyCount: 0,
            exists: true
        });

        commentReplies[_parentCommentId].push(replyId);
        userComments[msg.sender].push(replyId);
        comments[_parentCommentId].replyCount++;
        posts[postId].commentCount++;
        users[msg.sender].commentCount++;

        emit ReplyCreated(replyId, _parentCommentId, msg.sender, _content);
    }

    // Like or Unlike a comment
    function toggleCommentLike(uint256 _commentId) external onlyRegisteredUser validComment(_commentId) {
        require(comments[_commentId].author != msg.sender, "Cannot like your own comment");

        if (hasLikedComment[_commentId][msg.sender]) {
            comments[_commentId].likes--;
            hasLikedComment[_commentId][msg.sender] = false;
            emit CommentUnliked(_commentId, msg.sender);
        } else {
            comments[_commentId].likes++;
            hasLikedComment[_commentId][msg.sender] = true;
            emit CommentLiked(_commentId, msg.sender);
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

    // Get a comment
    function getComment(uint256 _commentId) external view returns (Comment memory) {
        require(comments[_commentId].exists, "Comment does not exist");
        return comments[_commentId];
    }

    // Get all post IDs of a user
    function getUserPosts(address _userAddress) external view returns (uint256[] memory) {
        return userPosts[_userAddress];
    }

    // Get all comment IDs of a user
    function getUserComments(address _userAddress) external view returns (uint256[] memory) {
        return userComments[_userAddress];
    }

    // Get all comments for a specific post
    function getPostComments(uint256 _postId) external view validPost(_postId) returns (Comment[] memory) {
        uint256[] memory commentIds = postComments[_postId];
        Comment[] memory postCommentsArray = new Comment[](commentIds.length);

        for (uint256 i = 0; i < commentIds.length; i++) {
            postCommentsArray[i] = comments[commentIds[i]];
        }

        return postCommentsArray;
    }

    // Get all replies to a specific comment
    function getCommentReplies(uint256 _commentId) external view validComment(_commentId) returns (Comment[] memory) {
        uint256[] memory replyIds = commentReplies[_commentId];
        Comment[] memory repliesArray = new Comment[](replyIds.length);

        for (uint256 i = 0; i < replyIds.length; i++) {
            repliesArray[i] = comments[replyIds[i]];
        }

        return repliesArray;
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

    // Get latest N comments for a post (up to 100)
    function getLatestPostComments(uint256 _postId, uint256 count) external view validPost(_postId) returns (Comment[] memory) {
        require(count > 0 && count <= 100, "Count must be between 1 and 100");

        uint256[] memory commentIds = postComments[_postId];
        uint256 resultCount = count > commentIds.length ? commentIds.length : count;
        Comment[] memory latestComments = new Comment[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 commentIndex = commentIds.length - 1 - i;
            latestComments[i] = comments[commentIds[commentIndex]];
        }

        return latestComments;
    }

    // Check if user has liked a post
    function hasUserLikedPost(uint256 _postId, address _user) external view returns (bool) {
        return hasLikedPost[_postId][_user];
    }

    // Check if user has liked a comment
    function hasUserLikedComment(uint256 _commentId, address _user) external view returns (bool) {
        return hasLikedComment[_commentId][_user];
    }

    // Get total counts for dashboard/stats
    function getStats() external view returns (uint256, uint256, uint256) {
        return (totalUsers, totalPosts, totalComments);
    }
}












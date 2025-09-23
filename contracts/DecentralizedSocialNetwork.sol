// SPDX-License-Identifier: 
pragma solidity ^0.8.19;

contract DecentralizedSocialNetwork {
    struct Post {
        uint256 id;
        address author;
        string content;
        string[] tags; // Array of tags for this post
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
        uint256 followerCount;
        uint256 followingCount;
        uint256 messagesSent;
        uint256 messagesReceived;
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

    struct DirectMessage {
        uint256 id;
        address sender;
        address recipient;
        string encryptedContent; // Encrypted message content
        uint256 timestamp;
        bool isRead;
        bool exists;
    }

    struct Conversation {
        address user1;
        address user2;
        uint256 messageCount;
        uint256 lastMessageId;
        uint256 lastMessageTimestamp;
        bool exists;
    }

    struct Tag {
        string name;
        uint256 postCount;
        uint256 createdTimestamp;
        address creator;
        bool exists;
    }

    mapping(address => User) public users;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => Comment) public comments;
    mapping(uint256 => DirectMessage) public messages;
    mapping(uint256 => mapping(address => bool)) public hasLikedPost;
    mapping(uint256 => mapping(address => bool)) public hasLikedComment;
    mapping(address => uint256[]) public userPosts;
    mapping(address => uint256[]) public userComments;
    mapping(uint256 => uint256[]) public postComments; // postId => commentIds
    mapping(uint256 => uint256[]) public commentReplies; // commentId => replyIds
    
    // Follow System Mappings
    mapping(address => mapping(address => bool)) public isFollowing; // follower => following => bool
    mapping(address => address[]) public followers; // user => followers array
    mapping(address => address[]) public following; // user => following array
    mapping(address => mapping(address => uint256)) public followingIndex; // for efficient removal
    mapping(address => mapping(address => uint256)) public followerIndex; // for efficient removal

    // Direct Messages Mappings
    mapping(bytes32 => Conversation) public conversations; // conversationId => Conversation
    mapping(bytes32 => uint256[]) public conversationMessages; // conversationId => messageIds
    mapping(address => bytes32[]) public userConversations; // user => conversationIds
    mapping(address => uint256[]) public userSentMessages; // user => sentMessageIds
    mapping(address => uint256[]) public userReceivedMessages; // user => receivedMessageIds
    mapping(address => uint256) public unreadMessageCount; // user => unread count

    // Tag System Mappings
    mapping(string => Tag) public tags; // tagName => Tag struct
    mapping(string => uint256[]) public tagPosts; // tagName => postIds
    mapping(uint256 => mapping(string => bool)) public postHasTag; // postId => tagName => bool
    string[] public allTags; // Array of all tag names
    mapping(string => uint256) public tagIndex; // tagName => index in allTags array

    uint256 public totalPosts;
    uint256 public totalUsers;
    uint256 public totalComments;
    uint256 public totalFollowRelations;
    uint256 public totalMessages;
    uint256 public totalTags;

    uint256 public constant MAX_TAGS_PER_POST = 5;
    uint256 public constant MAX_TAG_LENGTH = 30;

    event UserRegistered(address indexed user, string username);
    event PostCreated(uint256 indexed postId, address indexed author, string content, string[] tags);
    event PostLiked(uint256 indexed postId, address indexed liker);
    event PostUnliked(uint256 indexed postId, address indexed unliker);
    event CommentCreated(uint256 indexed commentId, uint256 indexed postId, address indexed author, string content);
    event CommentLiked(uint256 indexed commentId, address indexed liker);
    event CommentUnliked(uint256 indexed commentId, address indexed unliker);
    event ReplyCreated(uint256 indexed replyId, uint256 indexed parentCommentId, address indexed author, string content);
    event UserFollowed(address indexed follower, address indexed following);
    event UserUnfollowed(address indexed follower, address indexed unfollowing);
    event MessageSent(uint256 indexed messageId, address indexed sender, address indexed recipient, bytes32 indexed conversationId);
    event MessageRead(uint256 indexed messageId, address indexed reader);
    event ConversationStarted(bytes32 indexed conversationId, address indexed user1, address indexed user2);
    event TagCreated(string indexed tagName, address indexed creator);
    event PostTagged(uint256 indexed postId, string indexed tagName);

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

    modifier validUser(address _userAddress) {
        require(users[_userAddress].exists, "User does not exist");
        _;
    }

    modifier validMessage(uint256 _messageId) {
        require(messages[_messageId].exists, "Message does not exist");
        _;
    }

    modifier validTag(string memory _tagName) {
        require(tags[_tagName].exists, "Tag does not exist");
        _;
    }

    // Generate conversation ID between two users
    function getConversationId(address _user1, address _user2) public pure returns (bytes32) {
        // Ensure consistent ordering to generate same ID regardless of parameter order
        if (_user1 < _user2) {
            return keccak256(abi.encodePacked(_user1, _user2));
        } else {
            return keccak256(abi.encodePacked(_user2, _user1));
        }
    }

    // Validate and format tag name
    function formatTag(string memory _tag) internal pure returns (string memory) {
        bytes memory tagBytes = bytes(_tag);
        require(tagBytes.length > 0, "Tag cannot be empty");
        require(tagBytes.length <= MAX_TAG_LENGTH, "Tag too long");
        
        // Convert to lowercase and remove spaces (simple validation)
        for (uint256 i = 0; i < tagBytes.length; i++) {
            require(
                (tagBytes[i] >= 0x30 && tagBytes[i] <= 0x39) || // 0-9
                (tagBytes[i] >= 0x61 && tagBytes[i] <= 0x7A) || // a-z
                (tagBytes[i] >= 0x41 && tagBytes[i] <= 0x5A) || // A-Z
                tagBytes[i] == 0x5F, // underscore
                "Tag contains invalid characters"
            );
            
            // Convert uppercase to lowercase
            if (tagBytes[i] >= 0x41 && tagBytes[i] <= 0x5A) {
                tagBytes[i] = bytes1(uint8(tagBytes[i]) + 32);
            }
        }
        
        return string(tagBytes);
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
            followerCount: 0,
            followingCount: 0,
            messagesSent: 0,
            messagesReceived: 0,
            exists: true
        });

        totalUsers++;
        emit UserRegistered(msg.sender, _username);
    }

    // Create a new post with tags
    function createPost(string memory _content, string[] memory _tags) external onlyRegisteredUser {
        require(bytes(_content).length > 0, "Content cannot be empty");
        require(bytes(_content).length <= 1000, "Content too long");
        require(_tags.length <= MAX_TAGS_PER_POST, "Too many tags");

        uint256 postId = totalPosts++;
        
        // Format and validate tags
        string[] memory formattedTags = new string[](_tags.length);
        for (uint256 i = 0; i < _tags.length; i++) {
            formattedTags[i] = formatTag(_tags[i]);
            
            // Check for duplicate tags in this post
            for (uint256 j = 0; j < i; j++) {
                require(
                    keccak256(abi.encodePacked(formattedTags[i])) != keccak256(abi.encodePacked(formattedTags[j])),
                    "Duplicate tags not allowed"
                );
            }
        }

        posts[postId] = Post({
            id: postId,
            author: msg.sender,
            content: _content,
            tags: formattedTags,
            timestamp: block.timestamp,
            likes: 0,
            commentCount: 0,
            exists: true
        });

        // Process tags
        for (uint256 i = 0; i < formattedTags.length; i++) {
            string memory tagName = formattedTags[i];
            
            // Create tag if it doesn't exist
            if (!tags[tagName].exists) {
                tags[tagName] = Tag({
                    name: tagName,
                    postCount: 0,
                    createdTimestamp: block.timestamp,
                    creator: msg.sender,
                    exists: true
                });
                
                allTags.push(tagName);
                tagIndex[tagName] = allTags.length - 1;
                totalTags++;
                
                emit TagCreated(tagName, msg.sender);
            }
            
            // Add post to tag
            tagPosts[tagName].push(postId);
            postHasTag[postId][tagName] = true;
            tags[tagName].postCount++;
            
            emit PostTagged(postId, tagName);
        }

        userPosts[msg.sender].push(postId);
        users[msg.sender].postCount++;

        emit PostCreated(postId, msg.sender, _content, formattedTags);
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

    // Follow a user
    function followUser(address _userToFollow) external onlyRegisteredUser validUser(_userToFollow) {
        require(_userToFollow != msg.sender, "Cannot follow yourself");
        require(!isFollowing[msg.sender][_userToFollow], "Already following this user");

        // Add to following array and set index
        following[msg.sender].push(_userToFollow);
        followingIndex[msg.sender][_userToFollow] = following[msg.sender].length - 1;

        // Add to followers array and set index
        followers[_userToFollow].push(msg.sender);
        followerIndex[_userToFollow][msg.sender] = followers[_userToFollow].length - 1;

        // Update follow status and counts
        isFollowing[msg.sender][_userToFollow] = true;
        users[msg.sender].followingCount++;
        users[_userToFollow].followerCount++;
        totalFollowRelations++;

        emit UserFollowed(msg.sender, _userToFollow);
    }

    // Unfollow a user
    function unfollowUser(address _userToUnfollow) external onlyRegisteredUser validUser(_userToUnfollow) {
        require(isFollowing[msg.sender][_userToUnfollow], "Not following this user");

        // Remove from following array
        uint256 followingIdx = followingIndex[msg.sender][_userToUnfollow];
        uint256 lastFollowingIdx = following[msg.sender].length - 1;
        
        if (followingIdx != lastFollowingIdx) {
            address lastFollowing = following[msg.sender][lastFollowingIdx];
            following[msg.sender][followingIdx] = lastFollowing;
            followingIndex[msg.sender][lastFollowing] = followingIdx;
        }
        following[msg.sender].pop();
        delete followingIndex[msg.sender][_userToUnfollow];

        // Remove from followers array
        uint256 followerIdx = followerIndex[_userToUnfollow][msg.sender];
        uint256 lastFollowerIdx = followers[_userToUnfollow].length - 1;
        
        if (followerIdx != lastFollowerIdx) {
            address lastFollower = followers[_userToUnfollow][lastFollowerIdx];
            followers[_userToUnfollow][followerIdx] = lastFollower;
            followerIndex[_userToUnfollow][lastFollower] = followerIdx;
        }
        followers[_userToUnfollow].pop();
        delete followerIndex[_userToUnfollow][msg.sender];

        // Update follow status and counts
        isFollowing[msg.sender][_userToUnfollow] = false;
        users[msg.sender].followingCount--;
        users[_userToUnfollow].followerCount--;
        totalFollowRelations--;

        emit UserUnfollowed(msg.sender, _userToUnfollow);
    }

    // Send a direct message
    function sendDirectMessage(address _recipient, string memory _encryptedContent) external onlyRegisteredUser validUser(_recipient) {
        require(_recipient != msg.sender, "Cannot send message to yourself");
        require(bytes(_encryptedContent).length > 0, "Message cannot be empty");
        require(bytes(_encryptedContent).length <= 1000, "Message too long");

        bytes32 conversationId = getConversationId(msg.sender, _recipient);
        uint256 messageId = totalMessages++;

        // Create the message
        messages[messageId] = DirectMessage({
            id: messageId,
            sender: msg.sender,
            recipient: _recipient,
            encryptedContent: _encryptedContent,
            timestamp: block.timestamp,
            isRead: false,
            exists: true
        });

        // Initialize conversation if it doesn't exist
        if (!conversations[conversationId].exists) {
            conversations[conversationId] = Conversation({
                user1: msg.sender < _recipient ? msg.sender : _recipient,
                user2: msg.sender < _recipient ? _recipient : msg.sender,
                messageCount: 0,
                lastMessageId: 0,
                lastMessageTimestamp: 0,
                exists: true
            });

            userConversations[msg.sender].push(conversationId);
            userConversations[_recipient].push(conversationId);
            
            emit ConversationStarted(conversationId, msg.sender, _recipient);
        }

        // Update conversation
        conversations[conversationId].messageCount++;
        conversations[conversationId].lastMessageId = messageId;
        conversations[conversationId].lastMessageTimestamp = block.timestamp;

        // Update message arrays
        conversationMessages[conversationId].push(messageId);
        userSentMessages[msg.sender].push(messageId);
        userReceivedMessages[_recipient].push(messageId);

        // Update user stats
        users[msg.sender].messagesSent++;
        users[_recipient].messagesReceived++;
        unreadMessageCount[_recipient]++;
        totalMessages++;

        emit MessageSent(messageId, msg.sender, _recipient, conversationId);
    }

    // Mark a message as read
    function markMessageAsRead(uint256 _messageId) external onlyRegisteredUser validMessage(_messageId) {
        DirectMessage storage message = messages[_messageId];
        require(message.recipient == msg.sender, "Can only mark your own received messages as read");
        require(!message.isRead, "Message already marked as read");

        message.isRead = true;
        unreadMessageCount[msg.sender]--;

        emit MessageRead(_messageId, msg.sender);
    }

    // Mark all messages in a conversation as read
    function markConversationAsRead(bytes32 _conversationId) external onlyRegisteredUser {
        require(conversations[_conversationId].exists, "Conversation does not exist");
        
        address user1 = conversations[_conversationId].user1;
        address user2 = conversations[_conversationId].user2;
        require(msg.sender == user1 || msg.sender == user2, "Not a participant in this conversation");

        uint256[] memory messageIds = conversationMessages[_conversationId];
        
        for (uint256 i = 0; i < messageIds.length; i++) {
            DirectMessage storage message = messages[messageIds[i]];
            if (message.recipient == msg.sender && !message.isRead) {
                message.isRead = true;
                unreadMessageCount[msg.sender]--;
                emit MessageRead(messageIds[i], msg.sender);
            }
        }
    }

    // Get posts by tag with pagination
    function getPostsByTag(string memory _tagName, uint256 _limit) external view validTag(_tagName) returns (Post[] memory) {
        require(_limit > 0 && _limit <= 50, "Limit must be between 1 and 50");

        uint256[] memory postIds = tagPosts[_tagName];
        uint256 resultCount = _limit > postIds.length ? postIds.length : _limit;
        Post[] memory taggedPosts = new Post[](resultCount);

        // Return latest posts (reverse order)
        for (uint256 i = 0; i < resultCount; i++) {
            uint256 postIndex = postIds.length - 1 - i;
            taggedPosts[i] = posts[postIds[postIndex]];
        }

        return taggedPosts;
    }

    // Get trending tags (sorted by post count)
    function getTrendingTags(uint256 _limit) external view returns (string[] memory, uint256[] memory) {
        require(_limit > 0 && _limit <= 100, "Limit must be between 1 and 100");

        uint256 resultCount = _limit > allTags.length ? allTags.length : _limit;
        string[] memory trendingTagNames = new string[](resultCount);
        uint256[] memory postCounts = new uint256[](resultCount);

        // Simple sorting by post count (descending)
        string[] memory sortedTags = new string[](allTags.length);
        uint256[] memory sortedCounts = new uint256[](allTags.length);

        for (uint256 i = 0; i < allTags.length; i++) {
            sortedTags[i] = allTags[i];
            sortedCounts[i] = tags[allTags[i]].postCount;
        }

        // Bubble sort (simple for demonstration)
        for (uint256 i = 0; i < sortedTags.length - 1; i++) {
            for (uint256 j = 0; j < sortedTags.length - i - 1; j++) {
                if (sortedCounts[j] < sortedCounts[j + 1]) {
                    // Swap counts
                    uint256 tempCount = sortedCounts[j];
                    sortedCounts[j] = sortedCounts[j + 1];
                    sortedCounts[j + 1] = tempCount;
                    
                    // Swap tag names
                    string memory tempTag = sortedTags[j];
                    sortedTags[j] = sortedTags[j + 1];
                    sortedTags[j + 1] = tempTag;
                }
            }
        }

        for (uint256 i = 0; i < resultCount; i++) {
            trendingTagNames[i] = sortedTags[i];
            postCounts[i] = sortedCounts[i];
        }

        return (trendingTagNames, postCounts);
    }

    // Get all tags (for discovery)
    function getAllTags() external view returns (string[] memory) {
        return allTags;
    }

    // Get tag details
    function getTag(string memory _tagName) external view validTag(_tagName) returns (Tag memory) {
        return tags[_tagName];
    }

    // Search posts by multiple tags (AND operation)
    function searchPostsByTags(string[] memory _tagNames, uint256 _limit) external view returns (Post[] memory) {
        require(_tagNames.length > 0 && _tagNames.length <= 5, "Invalid number of tags");
        require(_limit > 0 && _limit <= 50, "Limit must be between 1 and 50");

        // Validate all tags exist
        for (uint256 i = 0; i < _tagNames.length; i++) {
            require(tags[_tagNames[i]].exists, "One or more tags do not exist");
        }

        // Find posts that have ALL specified tags
        uint256[] memory candidatePosts = tagPosts[_tagNames[0]];
        uint256 matchCount = 0;

        // Count matches first
        for (uint256 i = 0; i < candidatePosts.length; i++) {
            uint256 postId = candidatePosts[i];
            bool hasAllTags = true;

            for (uint256 j = 1; j < _tagNames.length; j++) {
                if (!postHasTag[postId][_tagNames[j]]) {
                    hasAllTags = false;
                    break;
                }
            }

            if (hasAllTags) {
                matchCount++;
            }
        }

        // Create result array
        uint256 resultCount = _limit > matchCount ? matchCount : _limit;
        Post[] memory matchingPosts = new Post[](resultCount);
        uint256 resultIndex = 0;

        // Fill result array (latest first)
        for (uint256 i = candidatePosts.length; i > 0 && resultIndex < resultCount; i--) {
            uint256 postId = candidatePosts[i - 1];
            bool hasAllTags = true;

            for (uint256 j = 1; j < _tagNames.length; j++) {
                if (!postHasTag[postId][_tagNames[j]]) {
                    hasAllTags = false;
                    break;
                }
            }

            if (hasAllTags) {
                matchingPosts[resultIndex] = posts[postId];
                resultIndex++;
            }
        }

        return matchingPosts;
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

    // Get a direct message
    function getMessage(uint256 _messageId) external view validMessage(_messageId) returns (DirectMessage memory) {
        DirectMessage memory message = messages[_messageId];
        require(message.sender == msg.sender || message.recipient == msg.sender, "Not authorized to view this message");
        return message;
    }

    // Get conversation details
    function getConversation(bytes32 _conversationId) external view returns (Conversation memory) {
        require(conversations[_conversationId].exists, "Conversation does not exist");
        Conversation memory conversation = conversations[_conversationId];
        require(msg.sender == conversation.user1 || msg.sender == conversation.user2, "Not a participant in this conversation");
        return conversation;
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

    // Get followers of a user
    function getFollowers(address _userAddress) external view validUser(_userAddress) returns (address[] memory) {
        return followers[_userAddress];
    }

    // Get users that a user is following
    function getFollowing(address _userAddress) external view validUser(_userAddress) returns (address[] memory) {
        return following[_userAddress];
    }

    // Get user's conversations
    function getUserConversations() external view onlyRegisteredUser returns (bytes32[] memory) {
        return userConversations[msg.sender];
    }

    // Get messages in a conversation
    function getConversationMessages(bytes32 _conversationId, uint256 _limit) external view returns (DirectMessage[] memory) {
        require(conversations[_conversationId].exists, "Conversation does not exist");
        
        address user1 = conversations[_conversationId].user1;
        address user2 = conversations[_conversationId].user2;
        require(msg.sender == user1 || msg.sender == user2, "Not a participant in this conversation");

        uint256[] memory messageIds = conversationMessages[_conversationId];
        uint256 resultCount = _limit > 0 && _limit < messageIds.length ? _limit : messageIds.length;
        
        DirectMessage[] memory conversationMessagesArray = new DirectMessage[](resultCount);
        
        // Return latest messages (reverse order)
        for (uint256 i = 0; i < resultCount; i++) {
            uint256 messageIndex = messageIds.length - 1 - i;
            conversationMessagesArray[i] = messages[messageIds[messageIndex]];
        }

        return conversationMessagesArray;
    }

    // Get unread message count for current user
    function getUnreadMessageCount() external view onlyRegisteredUser returns (uint256) {
        return unreadMessageCount[msg.sender];
    }

    // Get recent conversations with last message preview
    function getRecentConversations(uint256 _limit) external view onlyRegisteredUser returns (bytes32[] memory, DirectMessage[] memory) {
        bytes32[] memory userConversationIds = userConversations[msg.sender];
        uint256 resultCount = _limit > 0 && _limit < userConversationIds.length ? _limit : userConversationIds.length;
        
        bytes32[] memory recentConversationIds = new bytes32[](resultCount);
        DirectMessage[] memory lastMessages = new DirectMessage[](resultCount);
        
        // Sort conversations by last message timestamp (simple bubble sort for small arrays)
        bytes32[] memory sortedIds = new bytes32[](userConversationIds.length);
        for (uint256 i = 0; i < userConversationIds.length; i++) {
            sortedIds[i] = userConversationIds[i];
        }
        
        for (uint256 i = 0; i < sortedIds.length - 1; i++) {
            for (uint256 j = 0; j < sortedIds.length - i - 1; j++) {
                if (conversations[sortedIds[j]].lastMessageTimestamp < conversations[sortedIds[j + 1]].lastMessageTimestamp) {
                    bytes32 temp = sortedIds[j];
                    sortedIds[j] = sortedIds[j + 1];
                    sortedIds[j + 1] = temp;
                }
            }
        }
        
        for (uint256 i = 0; i < resultCount; i++) {
            recentConversationIds[i] = sortedIds[i];
            lastMessages[i] = messages[conversations[sortedIds[i]].lastMessageId];
        }
        
        return (recentConversationIds, lastMessages);
    }

    // Get follower count
    function getFollowerCount(address _userAddress) external view validUser(_userAddress) returns (uint256) {
        return users[_userAddress].followerCount;
    }

    // Get following count
    function getFollowingCount(address _userAddress) external view validUser(_userAddress) returns (uint256) {
        return users[_userAddress].followingCount;
    }

    // Check if user A follows user B
    function checkFollowStatus(address _follower, address _following) external view returns (bool) {
        return isFollowing[_follower][_following];
    }

    // Get posts from users that the caller follows (feed)
    function getFollowingFeed(uint256 count) external view onlyRegisteredUser returns (Post[] memory) {
        require(count > 0 && count <= 50, "Count must be between 1 and 50");

        address[] memory userFollowing = following[msg.sender];
        
        // Count total posts from followed users
        uint256 totalFeedPosts = 0;
        for (uint256 i = 0; i < userFollowing.length; i++) {
            totalFeedPosts += users[userFollowing[i]].postCount;
        }

        if (totalFeedPosts == 0) {
            return new Post[](0);
        }

        // Create array to store all posts with timestamps
        uint256[] memory allPostIds = new uint256[](totalFeedPosts);
        uint256 postIndex = 0;

        // Collect all post IDs from followed users
        for (uint256 i = 0; i < userFollowing.length; i++) {
            uint256[] memory userPostIds = userPosts[userFollowing[i]];
            for (uint256 j = 0; j < userPostIds.length; j++) {
                allPostIds[postIndex] = userPostIds[j];
                postIndex++;
            }
        }

        // Simple sorting by post ID (newer posts have higher IDs)
        for (uint256 i = 0; i < allPostIds.length - 1; i++) {
            for (uint256 j = 0; j < allPostIds.length - i - 1; j++) {
                if (allPostIds[j] < allPostIds[j + 1]) {
                    uint256 temp = allPostIds[j];
                    allPostIds[j] = allPostIds[j + 1];
                    allPostIds[j + 1] = temp;
                }
            }
        }

        // Return requested number of posts
        uint256 resultCount = count > totalFeedPosts ? totalFeedPosts : count;
        Post[] memory feedPosts = new Post[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            feedPosts[i] = posts[allPostIds[i]];
        }

        return feedPosts;
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
    function getStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (totalUsers, totalPosts, totalComments, totalFollowRelations, totalMessages, totalTags);
    }

    // Get mutual followers between two users
    function getMutualFollowers(address _user1, address _user2) external view validUser(_user1) validUser(_user2) returns (address[] memory) {
        address[] memory user1Followers = followers[_user1];
        address[] memory user2Followers = followers[_user2];
        
        // Count mutual followers first
        uint256 mutualCount = 0;
        for (uint256 i = 0; i < user1Followers.length; i++) {
            for (uint256 j = 0; j < user2Followers.length; j++) {
                if (user1Followers[i] == user2Followers[j]) {
                    mutualCount++;
                    break;
                }
            }
        }

        // Create array for mutual followers
        address[] memory mutualFollowers = new address[](mutualCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < user1Followers.length; i++) {
            for (uint256 j = 0; j < user2Followers.length; j++) {
                if (user1Followers[i] == user2Followers[j]) {
                    mutualFollowers[index] = user1Followers[i];
                    index++;
                    break;
                }
            }
        }

        return mutualFollowers;
    }
}


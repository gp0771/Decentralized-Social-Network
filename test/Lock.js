const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("DecentralizedSocialNetwork", function () {
  // Fixture to deploy the contract
  async function deployDecentralizedSocialNetworkFixture() {
    const [owner, user1, user2, user3] = await ethers.getSigners();
    
    const DecentralizedSocialNetwork = await ethers.getContractFactory("DecentralizedSocialNetwork");
    const socialNetwork = await DecentralizedSocialNetwork.deploy();
    
    return { socialNetwork, owner, user1, user2, user3 };
  }

  describe("Deployment", function () {
    it("Should deploy with correct initial values", async function () {
      const { socialNetwork } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      expect(await socialNetwork.totalUsers()).to.equal(0);
      expect(await socialNetwork.totalPosts()).to.equal(0);
    });
  });

  describe("User Registration", function () {
    it("Should register a new user successfully", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      const username = "alice";
      const bio = "Blockchain enthusiast";
      
      await expect(socialNetwork.connect(user1).registerUser(username, bio))
        .to.emit(socialNetwork, "UserRegistered")
        .withArgs(user1.address, username);
      
      const user = await socialNetwork.getUser(user1.address);
      expect(user.username).to.equal(username);
      expect(user.bio).to.equal(bio);
      expect(user.exists).to.be.true;
      expect(user.postCount).to.equal(0);
      
      expect(await socialNetwork.totalUsers()).to.equal(1);
    });

    it("Should not allow duplicate user registration", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio 1");
      
      await expect(
        socialNetwork.connect(user1).registerUser("alice2", "Bio 2")
      ).to.be.revertedWith("User already registered");
    });

    it("Should not allow empty username", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await expect(
        socialNetwork.connect(user1).registerUser("", "Valid bio")
      ).to.be.revertedWith("Username cannot be empty");
    });

    it("Should not allow username longer than 50 characters", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      const longUsername = "a".repeat(51);
      
      await expect(
        socialNetwork.connect(user1).registerUser(longUsername, "Valid bio")
      ).to.be.revertedWith("Username too long");
    });

    it("Should not allow bio longer than 200 characters", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      const longBio = "a".repeat(201);
      
      await expect(
        socialNetwork.connect(user1).registerUser("validuser", longBio)
      ).to.be.revertedWith("Bio too long");
    });

    it("Should allow maximum length username and bio", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      const maxUsername = "a".repeat(50);
      const maxBio = "b".repeat(200);
      
      await expect(
        socialNetwork.connect(user1).registerUser(maxUsername, maxBio)
      ).to.not.be.reverted;
      
      const user = await socialNetwork.getUser(user1.address);
      expect(user.username).to.equal(maxUsername);
      expect(user.bio).to.equal(maxBio);
    });
  });

  describe("Post Creation", function () {
    it("Should create a post successfully", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      // Register user first
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      const content = "Hello, decentralized world!";
      
      await expect(socialNetwork.connect(user1).createPost(content))
        .to.emit(socialNetwork, "PostCreated")
        .withArgs(1, user1.address, content);
      
      const post = await socialNetwork.getPost(1);
      expect(post.id).to.equal(1);
      expect(post.author).to.equal(user1.address);
      expect(post.content).to.equal(content);
      expect(post.likes).to.equal(0);
      expect(post.exists).to.be.true;
      
      expect(await socialNetwork.totalPosts()).to.equal(1);
      
      // Check user's post count updated
      const user = await socialNetwork.getUser(user1.address);
      expect(user.postCount).to.equal(1);
    });

    it("Should not allow unregistered users to create posts", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await expect(
        socialNetwork.connect(user1).createPost("Hello world")
      ).to.be.revertedWith("User not registered");
    });

    it("Should not allow empty post content", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      await expect(
        socialNetwork.connect(user1).createPost("")
      ).to.be.revertedWith("Post content cannot be empty");
    });

    it("Should not allow post content longer than 500 characters", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      const longContent = "a".repeat(501);
      
      await expect(
        socialNetwork.connect(user1).createPost(longContent)
      ).to.be.revertedWith("Post content too long");
    });

    it("Should allow maximum length post content", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      const maxContent = "a".repeat(500);
      
      await expect(
        socialNetwork.connect(user1).createPost(maxContent)
      ).to.not.be.reverted;
      
      const post = await socialNetwork.getPost(1);
      expect(post.content).to.equal(maxContent);
    });

    it("Should create multiple posts with correct IDs", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      await socialNetwork.connect(user1).createPost("Post 1");
      await socialNetwork.connect(user1).createPost("Post 2");
      await socialNetwork.connect(user1).createPost("Post 3");
      
      expect(await socialNetwork.totalPosts()).to.equal(3);
      
      const post1 = await socialNetwork.getPost(1);
      const post2 = await socialNetwork.getPost(2);
      const post3 = await socialNetwork.getPost(3);
      
      expect(post1.content).to.equal("Post 1");
      expect(post2.content).to.equal("Post 2");
      expect(post3.content).to.equal("Post 3");
      
      // Check user's post count
      const user = await socialNetwork.getUser(user1.address);
      expect(user.postCount).to.equal(3);
    });

    it("Should track user posts correctly", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      await socialNetwork.connect(user1).createPost("Post 1");
      await socialNetwork.connect(user1).createPost("Post 2");
      
      const userPosts = await socialNetwork.getUserPosts(user1.address);
      expect(userPosts).to.have.lengthOf(2);
      expect(userPosts[0]).to.equal(1);
      expect(userPosts[1]).to.equal(2);
    });
  });

  describe("Like System", function () {
    it("Should like a post successfully", async function () {
      const { socialNetwork, user1, user2 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      // Register users
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      await socialNetwork.connect(user2).registerUser("bob", "Bio");
      
      // Create post
      await socialNetwork.connect(user1).createPost("Hello world");
      
      // Like the post
      await expect(socialNetwork.connect(user2).toggleLike(1))
        .to.emit(socialNetwork, "PostLiked")
        .withArgs(1, user2.address);
      
      const post = await socialNetwork.getPost(1);
      expect(post.likes).to.equal(1);
      
      // Check if user has liked the post
      expect(await socialNetwork.hasLiked(1, user2.address)).to.be.true;
    });

    it("Should unlike a post when toggling like again", async function () {
      const { socialNetwork, user1, user2 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      await socialNetwork.connect(user2).registerUser("bob", "Bio");
      
      await socialNetwork.connect(user1).createPost("Hello world");
      
      // Like the post
      await socialNetwork.connect(user2).toggleLike(1);
      expect((await socialNetwork.getPost(1)).likes).to.equal(1);
      
      // Unlike the post
      await socialNetwork.connect(user2).toggleLike(1);
      expect((await socialNetwork.getPost(1)).likes).to.equal(0);
      expect(await socialNetwork.hasLiked(1, user2.address)).to.be.false;
    });

    it("Should not allow users to like their own posts", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      await socialNetwork.connect(user1).createPost("My post");
      
      await expect(
        socialNetwork.connect(user1).toggleLike(1)
      ).to.be.revertedWith("Cannot like your own post");
    });

    it("Should not allow unregistered users to like posts", async function () {
      const { socialNetwork, user1, user2 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      await socialNetwork.connect(user1).createPost("Hello world");
      
      await expect(
        socialNetwork.connect(user2).toggleLike(1)
      ).to.be.revertedWith("User not registered");
    });

    it("Should not allow liking non-existent posts", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      await expect(
        socialNetwork.connect(user1).toggleLike(999)
      ).to.be.revertedWith("Post does not exist");
    });

    it("Should handle multiple users liking the same post", async function () {
      const { socialNetwork, user1, user2, user3 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      // Register users
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      await socialNetwork.connect(user2).registerUser("bob", "Bio");
      await socialNetwork.connect(user3).registerUser("charlie", "Bio");
      
      // Create post
      await socialNetwork.connect(user1).createPost("Popular post");
      
      // Multiple users like the post
      await socialNetwork.connect(user2).toggleLike(1);
      await socialNetwork.connect(user3).toggleLike(1);
      
      const post = await socialNetwork.getPost(1);
      expect(post.likes).to.equal(2);
      
      expect(await socialNetwork.hasLiked(1, user2.address)).to.be.true;
      expect(await socialNetwork.hasLiked(1, user3.address)).to.be.true;
    });
  });

  describe("View Functions", function () {
    it("Should get user information correctly", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Crypto lover");
      
      const user = await socialNetwork.getUser(user1.address);
      expect(user.userAddress).to.equal(user1.address);
      expect(user.username).to.equal("alice");
      expect(user.bio).to.equal("Crypto lover");
      expect(user.postCount).to.equal(0);
      expect(user.exists).to.be.true;
    });

    it("Should revert when getting non-existent user", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await expect(
        socialNetwork.getUser(user1.address)
      ).to.be.revertedWith("User does not exist");
    });

    it("Should get post information correctly", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      await socialNetwork.connect(user1).createPost("Test post");
      
      const post = await socialNetwork.getPost(1);
      expect(post.id).to.equal(1);
      expect(post.author).to.equal(user1.address);
      expect(post.content).to.equal("Test post");
      expect(post.likes).to.equal(0);
      expect(post.exists).to.be.true;
      expect(post.timestamp).to.be.greaterThan(0);
    });

    it("Should revert when getting non-existent post", async function () {
      const { socialNetwork } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await expect(
        socialNetwork.getPost(999)
      ).to.be.revertedWith("Post does not exist");
    });

    it("Should get latest posts correctly", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      // Create multiple posts
      await socialNetwork.connect(user1).createPost("Post 1");
      await socialNetwork.connect(user1).createPost("Post 2");
      await socialNetwork.connect(user1).createPost("Post 3");
      
      const latestPosts = await socialNetwork.getLatestPosts(2);
      expect(latestPosts).to.have.lengthOf(2);
      
      // Latest posts should be in reverse order (newest first)
      expect(latestPosts[0].content).to.equal("Post 3");
      expect(latestPosts[1].content).to.equal("Post 2");
    });

    it("Should handle getLatestPosts when requesting more than available", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      await socialNetwork.connect(user1).createPost("Only post");
      
      const latestPosts = await socialNetwork.getLatestPosts(10);
      expect(latestPosts).to.have.lengthOf(1);
      expect(latestPosts[0].content).to.equal("Only post");
    });

    it("Should revert getLatestPosts with invalid count", async function () {
      const { socialNetwork } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await expect(
        socialNetwork.getLatestPosts(0)
      ).to.be.revertedWith("Invalid count range");
      
      await expect(
        socialNetwork.getLatestPosts(51)
      ).to.be.revertedWith("Invalid count range");
    });

    it("Should get user posts correctly", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      await socialNetwork.connect(user1).createPost("Post 1");
      await socialNetwork.connect(user1).createPost("Post 2");
      
      const userPosts = await socialNetwork.getUserPosts(user1.address);
      expect(userPosts).to.have.lengthOf(2);
      expect(userPosts[0]).to.equal(1);
      expect(userPosts[1]).to.equal(2);
    });
  });

  describe("Edge Cases and Security", function () {
    it("Should handle timestamp correctly", async function () {
      const { socialNetwork, user1 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      
      const beforeTime = await time.latest();
      await socialNetwork.connect(user1).createPost("Timestamped post");
      const afterTime = await time.latest();
      
      const post = await socialNetwork.getPost(1);
      expect(post.timestamp).to.be.at.least(beforeTime);
      expect(post.timestamp).to.be.at.most(afterTime);
    });

    it("Should handle multiple users and posts correctly", async function () {
      const { socialNetwork, user1, user2, user3 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      // Register multiple users
      await socialNetwork.connect(user1).registerUser("alice", "Bio 1");
      await socialNetwork.connect(user2).registerUser("bob", "Bio 2");
      await socialNetwork.connect(user3).registerUser("charlie", "Bio 3");
      
      // Create posts from different users
      await socialNetwork.connect(user1).createPost("Alice's post");
      await socialNetwork.connect(user2).createPost("Bob's post");
      await socialNetwork.connect(user3).createPost("Charlie's post");
      
      expect(await socialNetwork.totalUsers()).to.equal(3);
      expect(await socialNetwork.totalPosts()).to.equal(3);
      
      // Verify post authors
      expect((await socialNetwork.getPost(1)).author).to.equal(user1.address);
      expect((await socialNetwork.getPost(2)).author).to.equal(user2.address);
      expect((await socialNetwork.getPost(3)).author).to.equal(user3.address);
    });

    it("Should maintain correct state after complex interactions", async function () {
      const { socialNetwork, user1, user2 } = await loadFixture(deployDecentralizedSocialNetworkFixture);
      
      // Register users
      await socialNetwork.connect(user1).registerUser("alice", "Bio");
      await socialNetwork.connect(user2).registerUser("bob", "Bio");
      
      // Create posts
      await socialNetwork.connect(user1).createPost("Post 1");
      await socialNetwork.connect(user1).createPost("Post 2");
      
      // Like and unlike operations
      await socialNetwork.connect(user2).toggleLike(1); // Like
      await socialNetwork.connect(user2).toggleLike(2); // Like
      await socialNetwork.connect(user2).toggleLike(1); // Unlike
      
      // Verify final state
      expect((await socialNetwork.getPost(1)).likes).to.equal(0);
      expect((await socialNetwork.getPost(2)).likes).to.equal(1);
      expect(await socialNetwork.hasLiked(1, user2.address)).to.be.false;
      expect(await socialNetwork.hasLiked(2, user2.address)).to.be.true;
    });
  });
});

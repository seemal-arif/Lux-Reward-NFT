# Lux-Reward-NFT
ERC721A contract for Web3 Game NFTs with Reward Cards, Loot Boxes, and Surprise NFTs.

## Deployment Details  
- **Network:** Arbitrum Sepolia  
- **Contract Address:** `0x0fF44514D66528d23Ab31778567010cc5f3CAF13`  
- **Block Explorer:** [Arbiscan Link](https://sepolia.arbiscan.io/address/0x0fF44514D66528d23Ab31778567010cc5f3CAF13#code)

## Description  
The **LuxRewardNFT** contract is an **ERC721A-based NFT contract** designed for a Web3 game where players can acquire **Reward NFTs, Loot Boxes, and Surprise NFTs** by purchasing them using either **TLN tokens (equity coin)** or **in-game currency**. Reward NFTs grant special in-game benefits, while Loot Boxes contain multiple NFTs, each with unique powers that enhance gameplay. Surprise NFTs introduce an element of mystery, as their attributes and abilities remain hidden until activated in-game. The contract utilizes **signature-based minting** with **ECDSA** for secure Web2 purchases and integrates **SafeERC20** for seamless TLN token transactions. It also implements **ERC2981** to facilitate royalty payments .

## Challenges 
- One of the key challenges in developing this contract was ensuring that users could not exploit the minting functions to create NFTs for free by calling the contract directly with manipulated parameters. Since the functions are accessible on-chain, a potential vulnerability existed where malicious users could attempt to bypass the intended payment mechanisms.  

## Solutions
- To address this, I implemented **signature-based authorization**, where only a designated **moderator** can generate valid signatures for minting transactions. 
  Each signature is created using **ECDSA** and includes the necessary parameters (such as the user's address, quantity, and price) to ensure authenticity. Before 
  processing a minting request, the contract verifies the **signature** to confirm that it was issued by the trusted moderator, preventing unauthorized NFT creation. 
  This approach ensures that only legitimate transactions, approved by the backend, can successfully mint NFTs while maintaining a seamless and secure user 
  experience.
  
## Role
- **Lead Blockchain Developer**: Led the blockchain development of the project.
- **Client Communication & Requirement Gathering**: Managed client communication and gathered project requirements.
 --- 

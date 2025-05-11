# 🧩 Cryptic Crosswords Smart Contract

A Clarity smart contract for managing a collaborative, team-based cryptic crossword puzzle game on the Stacks blockchain. Players form teams, solve clues within puzzles, earn points, and compete for rewards in a decentralized and gamified environment.

---

## 📚 Overview

This smart contract enables:

* Creation and management of crossword puzzles by the contract manager.
* Clue submission and answer validation.
* Team formation and collaboration.
* Tracking of puzzle progress and team contributions.
* Distribution of rewards based on performance.
* Administrative controls for system security and integrity.

---

## ⚙️ Key Features

* 🧠 **Team-Based Puzzle Solving:** Players can create and join teams to tackle puzzles together.
* 🏁 **Timed Puzzle Challenges:** Each puzzle has a start and end block height, allowing for weekly or time-bound competitions.
* 💰 **Entry Fees and Prize Pools:** Optional entry fees contribute to a reward pool that is distributed upon puzzle completion.
* 📊 **Leaderboards and Rankings:** Simplified ranking system shows team status and prize eligibility.
* 🔐 **Admin Controls:** Only the contract manager can create puzzles and manage system state.

---

## 🏗️ Data Models

* `puzzles`: Stores all created puzzles and their metadata.
* `puzzle-clues`: Contains individual clues tied to puzzles.
* `teams`: Stores team metadata including points and completion stats.
* `team-members`: Tracks player participation within teams.
* `team-puzzle-progress`: Tracks a team’s progress on a specific puzzle.
* `team-clue-solutions`: Stores attempts and results for each clue by a team.
* `reward-claims`: Tracks whether a team has claimed its prize.

---

## 🛠️ Public Functions

| Function          | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `create-puzzle`   | Manager creates a new puzzle                           |
| `add-puzzle-clue` | Manager adds a clue to an existing puzzle              |
| `create-team`     | Any player can create a team                           |
| `join-team`       | Allows a player to join an existing team               |
| `start-puzzle`    | Starts a puzzle for a team (with optional entry fee)   |
| `submit-solution` | Submit a solution to a puzzle clue                     |
| `end-puzzle`      | Manager marks a puzzle as complete                     |
| `archive-puzzle`  | Manager archives a completed puzzle                    |
| `claim-prize`     | Team founder claims the reward after puzzle completion |

---

## 🔍 Read-Only Functions

| Function              | Description                       |
| --------------------- | --------------------------------- |
| `get-puzzle`          | Retrieve puzzle metadata          |
| `get-clue`            | Retrieve a specific clue          |
| `get-team`            | Get team info                     |
| `get-team-member`     | Get player’s membership details   |
| `get-team-progress`   | Track team's progress in a puzzle |
| `get-solution-status` | Check clue status for a team      |
| `get-team-rank`       | Get the team’s placeholder rank   |
| `calculate-prize`     | Calculate team’s reward share     |

---

## 🧾 Error Codes

| Code   | Meaning                  |
| ------ | ------------------------ |
| `u100` | No permission            |
| `u101` | Puzzle not found         |
| `u102` | Team already exists      |
| `u103` | Puzzle closed            |
| `u104` | Clue not found           |
| `u105` | Answer already submitted |
| `u106` | Wrong answer             |
| `u107` | Puzzle inactive          |
| `u108` | Not a team member        |
| `u109` | Payment failed           |
| `u110` | Reward already claimed   |
| `u111` | Not eligible             |
| `u112` | Team full                |
| `u113` | System locked            |
| `u114` | Team not found           |
| `u115` | Already a team member    |
| `u116` | Invalid input            |

---

## 🔐 Admin Functions

Only the `contract-manager` can call these:

* `set-manager` — Transfer contract control.
* `set-lock` — Lock/unlock the contract.
* `create-puzzle`
* `add-puzzle-clue`
* `end-puzzle`
* `archive-puzzle`

---

## 🧪 Testing Suggestions

Use Clarity REPL or Clarinet to simulate:

* Puzzle creation and clue addition.
* Creating and joining teams.
* Starting puzzles and submitting answers.
* Testing reward claiming and system locking.

---

## 🚀 Future Enhancements

* Real leaderboard ranking logic.
* Case-insensitive solution matching.
* Event emissions for front-end integration.
* Support for NFT rewards or badges.

---

## 👨‍💻 Developed With

* [Clarity](https://docs.stacks.co/docs/clarity/overview/) – Secure smart contract language for the Stacks blockchain.

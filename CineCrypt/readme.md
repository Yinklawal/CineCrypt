# CineCrypt Smart Contract

A Clarity smart contract for creating and managing prediction markets on cinema and entertainment projects on the Stacks blockchain.

## Overview

CineCrypt enables users to create prediction markets for entertainment projects (movies, shows, etc.) and stake STX tokens on their predictions. The contract manages project lifecycles, stake validation, and outcome resolution.

## Features

- **Project Creation**: Create prediction markets for entertainment projects
- **Staking System**: Users can stake STX tokens on binary outcomes (true/false predictions)
- **Time-based Validation**: Projects have lock periods and evaluation cutoffs
- **Curator Controls**: Administrative functions for managing contract parameters
- **Stake Limits**: Configurable minimum and maximum stake amounts

## Contract Structure

### Constants

The contract defines various error codes (`ERR-D1` through `ERR-D16`) and validation ranges:

- `RANGE-X1`: 52,560 (maximum lock duration in blocks)
- `RANGE-X2`: 144 (minimum lock duration in blocks)  
- `RANGE-X3`: 105,120 (maximum evaluation period in blocks)
- `TITLE-LEN-MIN`: 10 (minimum title length)

### Data Structures

#### Projects Map
```clarity
cinecrypt-projects: {
  prj-id: uint,
  ttl: string-ascii(256),     // Project title
  outcome: optional(bool),    // Final outcome (none until resolved)
  lock: uint,                 // Lock block height
  cutoff: uint,              // Evaluation cutoff block
  creator: principal         // Project creator
}
```

#### Stakes Map
```clarity
cinecrypt-stakes: {
  prj-id: uint,
  addr: principal,
  amt: uint,                 // Staked amount
  pred: bool                 // Prediction (true/false)
}
```

## Public Functions

### `cinecrypt-init`
```clarity
(cinecrypt-init (title string-ascii(256)) (lock uint)) -> (response uint uint)
```
Creates a new prediction market project.

**Parameters:**
- `title`: Project title (10-256 characters)
- `lock`: Block height when staking locks

**Returns:** Project ID on success

**Validations:**
- Title length must be 10-256 characters
- Lock period must be between 144-52,560 blocks from current block
- Evaluation period (lock + delay) must not exceed 105,120 blocks

### `cinecrypt-stake`
```clarity
(cinecrypt-stake (pid uint) (pred bool) (amt uint)) -> (response bool uint)
```
Stake STX tokens on a prediction.

**Parameters:**
- `pid`: Project ID
- `pred`: Prediction (true/false)
- `amt`: Amount to stake in microSTX

**Returns:** Success boolean

**Validations:**
- Project must exist and not be resolved
- Stake amount must be within configured limits
- User must have sufficient STX balance
- Total user stake cannot exceed maximum

### Configuration Functions (Curator Only)

#### `set-cinecrypt-eval-delay`
Set the evaluation delay period (1,000 - 52,560 blocks).

#### `set-cinecrypt-min-stake`
Set minimum stake amount (1 - 1,000,000 microSTX).

#### `set-cinecrypt-max-stake`
Set maximum stake amount (1,000 - 1,000,000,000,000 microSTX).

#### `transfer-cinecrypt-curator`
Transfer curator role to another principal.

### Read-Only Functions

#### `get-cinecrypt-curator`
Returns the current curator principal.

## Usage Examples

### Creating a Project
```clarity
(contract-call? .cinecrypt cinecrypt-init "Avatar 3 Box Office Success" u1000000)
```

### Staking on a Project
```clarity
(contract-call? .cinecrypt cinecrypt-stake u1 true u100000)
```

### Checking Curator
```clarity
(contract-call? .cinecrypt get-cinecrypt-curator)
```

## Error Codes

- `ERR-D1` (u1): Invalid lock period
- `ERR-D3` (u3): Project already resolved
- `ERR-D4` (u4): Invalid stake amount
- `ERR-D5` (u5): Invalid project ID
- `ERR-D6` (u6): Insufficient STX balance
- `ERR-D13` (u13): Unauthorized (not curator)
- `ERR-D15` (u15): Stake would exceed maximum
- `ERR-D16` (u16): General validation error

## Security Features

1. **Access Control**: Only curator can modify contract parameters
2. **Stake Validation**: Enforces minimum/maximum stake limits
3. **Time Constraints**: Projects have defined lock and evaluation periods
4. **Balance Checks**: Verifies user has sufficient STX before staking
5. **Duplicate Prevention**: Prevents multiple outcomes for same project

## Deployment

This contract is written in Clarity and designed for deployment on the Stacks blockchain. Ensure you have the necessary Stacks development environment set up.

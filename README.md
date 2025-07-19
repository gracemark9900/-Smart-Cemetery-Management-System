# Smart Cemetery Management System

A comprehensive blockchain-based cemetery management system built on Stacks using Clarity smart contracts.

## Overview

This system manages all aspects of cemetery operations through five interconnected smart contracts:

1. **Burial Plot Allocation** - Manages grave site assignments and records
2. **Maintenance Scheduling** - Coordinates groundskeeping and upkeep tasks
3. **Memorial Service** - Handles funeral arrangement logistics
4. **Genealogy Tracking** - Maintains family history and burial records
5. **Perpetual Care** - Ensures long-term cemetery maintenance funding

## Features

### Burial Plot Allocation
- Plot reservation and assignment
- Plot status tracking (available, reserved, occupied)
- Plot pricing and payment processing
- Plot transfer capabilities

### Maintenance Scheduling
- Task creation and assignment
- Priority-based scheduling
- Completion tracking
- Resource allocation

### Memorial Service
- Service booking and scheduling
- Capacity management
- Service type categorization
- Payment processing

### Genealogy Tracking
- Family tree maintenance
- Burial record linkage
- Historical data preservation
- Search and retrieval functions

### Perpetual Care
- Endowment fund management
- Interest calculation and distribution
- Care level definitions
- Fund allocation tracking

## Contract Architecture

Each contract operates independently with its own state management and access controls. The system uses principal-based authentication and role-based permissions.

## Data Types

- **Plot Records**: Location, status, owner, pricing
- **Maintenance Tasks**: Type, priority, schedule, completion
- **Service Bookings**: Date, type, capacity, payment
- **Genealogy Records**: Family relationships, burial connections
- **Care Funds**: Balance, interest rate, allocation rules

## Getting Started

1. Install dependencies: \`npm install\`
2. Run tests: \`npm test\`
3. Deploy contracts using Clarinet
4. Initialize contract data through admin functions

## Testing

The system includes comprehensive tests using Vitest covering:
- Contract deployment and initialization
- Core functionality for each contract
- Error handling and edge cases
- Access control and permissions

## Security

- Principal-based access control
- Input validation and sanitization
- Overflow protection for numeric operations
- State consistency checks

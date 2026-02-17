Commerce Flow System
Operational Infrastructure for a Small Retail Bakery
Overview

This project is a modular commerce and operations system built for a small independent bakery.

The goal is to reduce administrative overhead, digitize in-store sales tracking, and centralize operational data — without relying on expensive SaaS platforms or complex enterprise software.

The system currently supports:

Structured custom cake order intake

In-store Point of Sale (POS)

Product management via messaging

Daily accounting synchronization

Centralized operational visibility

This project is being prepared for live deployment in a real bakery environment.

Business Context

The bakery previously relied on:

Custom cake orders managed manually through text conversations

Paper-based accounting

No centralized sales tracking

Manual product updates for new items

This created:

Time-consuming back-and-forth communication

Risk of missing order details

Fragmented information storage

Limited financial visibility

Repetitive administrative work

The goal of this system is to impose structure on these workflows while keeping the technology lightweight and maintainable.

System Architecture

The system is divided into distinct but connected operational components.

1. Custom Cake Order Manager

Customers interact through a guided messaging flow (Telegram integration)

Required order details are collected automatically

Orders are stored in a structured database

Admin interface allows review, approval, and scheduling

Provides a centralized view of upcoming baking commitments

This replaces unstructured text conversations with structured intake and tracking.

2. Point of Sale (POS)

Vue.js frontend for in-store sales

Cart and checkout functionality

Transactions stored in PostgreSQL

Designed for simplicity and speed in a retail environment

This replaces paper-based sales tracking with structured digital records.

3. Product Management via Messaging

New products can be added by sending a message:

“Add Double Chocolate Cake $100”

Product images can be uploaded via message

Images are stored and served through Nginx

Product data updates immediately in the POS interface

This allows rapid product updates without logging into admin dashboards.

4. Accounting Synchronization

Daily scheduled aggregation of POS sales

Aggregated sales written into accounting software 

Enables digital financial tracking instead of paper reconciliation

This creates a structured financial reporting pipeline.

5. Orchestration Layer

n8n is used as the automation and orchestration engine to:

Handle Telegram bot interactions

Manage database reads and writes

Trigger scheduled workflows

Coordinate cross-system communication

This keeps business logic modular and adaptable.

6. Infrastructure

Dockerized services

Reverse proxy via Nginx

Separate image server

PostgreSQL database

Designed for low-cost deployment on a single server

The architecture prioritizes clarity and maintainability over complexity.

Operational Impact

When deployed, this system will:

Reduce time spent managing custom cake orders

Eliminate repetitive manual data entry

Provide centralized visibility into upcoming baking schedules

Digitize in-store sales records

Automate daily accounting updates

Improve decision-making through structured data

The objective is not technological sophistication, but operational stability and clarity.

Current Status

POS core functionality complete

Custom order intake functional

Product management via messaging operational

Accounting aggregation implemented

Ingredients and recipe management in progress

Preparing for live deployment

Design Philosophy

This system was built with the following principles:

Solve real workflow problems first

Use lightweight tools where possible

Keep data ownership local

Avoid unnecessary SaaS dependence

Favor clear data flow over feature bloat
